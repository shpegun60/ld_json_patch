# json_patch - JSON Patch for GNU ld

Portable patch package for adding the `--dump-script-json` feature to GNU `ld`.

This folder contains the linker-side JSON patch used by this repository. Its purpose is to extend GNU `ld` so it can emit a stable linker JSON file that can then be consumed by tools such as `ld_viewer` and workflows such as `ld_sniffer`.

This folder is standalone and does not modify source files by itself. Use the `hooks/*.fragment` files when porting the patch into another Binutils/ld tree.

## Prerequisite: Matching STM32 GNU Tools Source Tree

Before applying this patch, clone or unpack the matching STM32 GNU Tools source tree for the linker version you want to patch.

The patch is meant to be integrated into the ST-provided Binutils/ld source layout under:

- `src/binutils/ld`

In this workspace, the matching source tree example is:

- [gnu-tools-for-stm32-13.3.rel1.20250523-0900](../gnu-tools-for-stm32-13.3.rel1.20250523-0900)

Use a source tree that matches the linker/toolchain build you intend to patch. Do not apply the patch blindly to an unrelated Binutils version and expect identical anchors or APIs.

## Related Documents

- [how_to_add_json.md](how_to_add_json.md): end-to-end reference for integrating the patch, rebuilding GNU `ld`, and validating the generated JSON.
- [README-CubeIDE.txt](README-CubeIDE.txt): short CubeIDE-oriented note for using a patched linker build.
- [README-CubeIDE-DETAILED.md](README-CubeIDE-DETAILED.md): longer CubeIDE-oriented explanation of how the patched linker fits with `ld_viewer` and `ld_sniffer`.

## Files
- `ldjson_options.def`: single source of truth for CLI option rows (X-macro).
- `ldjson_compat.h`: format metadata + portability macros for small cross-tree API differences.
- `ldscript_json_impl.inc`: standalone implementation block to include from `ldlang.c`.
- `FORMAT.md`: stable parser contract for the indexed top-level schema.
- `validate_core.jq`: validator for the indexed contract.
- `examples/sample_universal.json`: compact example of the canonical shape.
- `examples/sample_h7s_fiber_test_ldscript.json`: STM32-oriented example using the same schema.
- `hooks/ld.h.fragment`: snippet for `args_type` in `src/binutils/ld/ld.h`.
- `hooks/ldlex.h.fragment`: snippet for `option_values` in `src/binutils/ld/ldlex.h`.
- `hooks/lexsup.c.fragment`: snippets for `ld_options[]` and `parse_args(...)`.
- `hooks/ldlang.c.fragment`: snippets for include and call site in `ldlang.c`.
- `hooks/Makefile.am.fragment`: snippet for `Makefile.am` so `make dist` and gettext include the new files.

## What `hooks/` Is
- `hooks/*.fragment` files are not compiled and are not included automatically.
- They are convenience snippets for the person porting this patch by hand.
- The real feature implementation is in:
  - `ldjson_options.def`
  - `ldjson_compat.h`
  - `ldscript_json_impl.inc`
- Typical usage is:
  - open the matching `hooks/*.fragment`;
  - copy that small glue block;
  - paste it into the corresponding `src/binutils/ld/...` file.

## Minimal Porting Flow
1. Copy `ldjson_options.def`, `ldjson_compat.h`, and `ldscript_json_impl.inc` into target `src/binutils/ld`.
2. Apply snippets from `hooks/*.fragment`.
   - `hooks/ld.h.fragment`: insert into `args_type`, in this tree directly after `char *default_script;`.
   - `hooks/ldlex.h.fragment`: insert into `enum option_values`, in this tree directly after `OPTION_DEFAULT_SCRIPT,`.
   - `hooks/lexsup.c.fragment`:
     - add the `ld_options[]` row block after the existing `default-script` / `dT` entries;
     - add the `parse_args(...)` switch block after `case OPTION_DEFAULT_SCRIPT:`.
   - `hooks/ldlang.c.fragment`:
     - apply Fragment A in file scope after `print_statements()` and before `insert_pad(...)`;
     - apply Fragment B in `lang_process()`, immediately after `lang_end ();`.
   - `hooks/Makefile.am.fragment`: append near the existing `HFILES = ...` and `EXTRA_DIST = ...` assignments.
   - If your tree ships `Makefile.in`, regenerate it after editing `Makefile.am`.
3. Build `ld`, then verify:
   - `arm-none-eabi-ld --help | grep dump-script-json`
   - smoke test with `--dump-script-json=out.json`
4. Validate the JSON contract:
   - `jq -e -f json_patch/validate_core.jq out.json`
   - success => prints `{ "ok": true, ... }` and returns exit code `0`
   - failure => prints contract errors and returns non-zero

## This Repo Integration Map
- `src/binutils/ld/ld.h`: the insertion anchor is the `default_script` field in `args_type`.
- `src/binutils/ld/ldlex.h`: the insertion anchor is `OPTION_DEFAULT_SCRIPT` in `enum option_values`.
- `src/binutils/ld/lexsup.c`: use the `default-script` option rows and `case OPTION_DEFAULT_SCRIPT:` as anchors.
- `src/binutils/ld/ldlang.c`: use `print_statements()` / `insert_pad(...)` for the include anchor and `lang_end ();` inside `lang_process()` for the call-site anchor.
- `src/binutils/ld/Makefile.am`: append the new filenames to `HFILES` and `EXTRA_DIST`; this also feeds `SRC_POTFILES`, so gettext sees the new help/error strings.

## Canonical Skeleton
```json
{
  "format": { "name": "ldscript-json", "major": 10, "minor": 0 },
  "output": { "entry_symbol": "Reset_Handler" },
  "memory_regions": { "items": [], "by_name": {}, "null_name_ids": [] },
  "output_sections": { "items": [], "by_name": {}, "null_name_ids": [] },
  "script_variables": { "items": [], "by_name": {}, "null_name_ids": [] }
}
```

## JSON Shape
- The canonical machine-readable model now lives directly in the top-level collections:
  - `memory_regions`
  - `output_sections`
  - `script_variables`
- Each of these is an indexed object with:
  - `items`
  - `by_name`
  - `null_name_ids`
- In `memory_regions.items[*]`, `attrs` is a compact flag string such as `axw`.
- In `output`, the canonical payload is intentionally minimal: `entry_symbol`.
- `output.entry_symbol` is the final string carried by `ld`; depending on the
  link result, it may be a symbol name or a numeric string.
- In `output_sections.items[*]`, the canonical payload is intentionally minimal:
  `id`, `name`, `vma_region`, `lma_region`, `script_subsections`.
- In `script_variables.items[*]`, the canonical payload is intentionally minimal:
  `id`, `name`, `value_hex`, `section`.
- `script_variables` now includes only symbols that `ld` marks as defined by the
  linker script itself (`ldscript_def`). User code symbols and functions are
  intentionally excluded from this collection.
- `views` is no longer emitted.
- `core` is no longer emitted as a duplicate copy of the same data.

## Behavioral Notes
- `script_variables` is always emitted as an indexed object and is limited to
  linker-script-defined symbols.
- JSON is written to a temporary sibling file and then renamed into place, so partial writes do not leave a truncated final JSON artifact behind.
- Hex values are canonicalized to lowercase `0x...` strings.
- Non-ASCII bytes in strings are always escaped as `\u00XX`.
- The current reference contract in this package is `format` `10.0`.
- Versioning now relies only on `format.major` and `format.minor`.
- The patch now has a single fixed JSON mode; there are no feature flags that change schema shape.
- In `script_variables`, `value_hex: null` means the linker did not resolve a concrete numeric value.

## Scope Notes
- In this repo, port only into `src/binutils/ld/ldlang.c` (not `src/gdb/ld/ldlang.c`).
- The new `Makefile.am` hook is important if you ship source tarballs or regenerate gettext catalogs.

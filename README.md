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

- [FORMAT.md](FORMAT.md): parser-stable JSON contract.
- [how_to_add_json.md](how_to_add_json.md): end-to-end reference for integrating the patch, rebuilding GNU `ld`, and validating the generated JSON.
- [README-CubeIDE.txt](README-CubeIDE.txt): short CubeIDE-oriented note for using a patched linker build.
- [README-CubeIDE-DETAILED.md](README-CubeIDE-DETAILED.md): longer CubeIDE-oriented explanation of how the patched linker fits with `ld_viewer` and `ld_sniffer`.

## Files
- `ldjson_options.def`: single source of truth for CLI option rows (X-macro).
- `ldjson_compat.h`: format metadata + portability macros for small cross-tree API differences.
- `ldscript_json_impl.inc`: standalone implementation block to include from `ldlang.c`.
- `FORMAT.md`: stable parser contract for the canonical top-level schema.
- `validate_core.jq`: validator for the canonical contract.
- `examples/sample_universal.json`: compact example of the canonical shape.
- `examples/sample_h7s_fiber_test_ldscript.json`: curated excerpt from a real `h7s_fiber_test` smoke-test output using the same schema.
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
3. Build `ld`, then verify:
   - `arm-none-eabi-ld --help | grep dump-script-json`
   - smoke test with `--dump-script-json=out.json`
4. Validate the JSON contract:
   - `jq -e -f json_patch/validate_core.jq out.json`
   - success => prints `{ "ok": true, ... }` and returns exit code `0`
   - failure => prints contract errors and returns non-zero

## Canonical Skeleton
```json
{
  "format": { "name": "ldscript-json", "major": 10, "minor": 0 },
  "output": { "entry_symbol": "Reset_Handler" },
  "memory_regions": { "items": [], "by_name": {}, "null_name_ids": [] },
  "output_sections": { "items": [], "by_name": {}, "null_name_ids": [] },
  "input_sections": { "items": [], "by_name": {}, "null_name_ids": [] },
  "discarded_input_sections": [],
  "symbols": { "items": [], "by_name": {}, "null_name_ids": [] }
}
```

## JSON Shape
- The canonical machine-readable model lives directly in the top-level collections:
  - `memory_regions`
  - `output_sections`
  - `input_sections`
  - `discarded_input_sections`
  - `symbols`
- `memory_regions`, `output_sections`, `input_sections`, and `symbols` are indexed objects with:
  - `items`
  - `by_name`
  - `null_name_ids`
- `discarded_input_sections` is a plain list of discard records.

### `output`
- The canonical payload is intentionally minimal:
  - `entry_symbol`
- `entry_symbol` may be a symbol-like name such as `Reset_Handler` or a numeric string such as `0x8000c09`.

### `memory_regions.items[*]`
- `id`
- `name`
- `origin_hex`
- `length_hex`
- `attrs.required`
- `attrs.forbidden`
- `attrs.flags_hex`
- `attrs.not_flags_hex`

### `output_sections.items[*]`
- `id`
- `name`
- `vma_region`
- `lma_region`
- `vma_hex`
- `lma_hex`
- `size_hex`
- `script_subsections`
- optional `flags.letters`
- optional `flags.hex`

### `input_sections.items[*]`
- `id`
- `name`
- `discarded`
- `output_section_id`
- `owner_file`
- `value_hex`
- `size_hex`
- `output_offset_hex`
- `flags.letters`
- `flags.hex`

### `discarded_input_sections[*]`
- `input_section_id`
- `discard_reason`

### `symbols.items[*]`
- `id`
- `name`
- `state`
- `value_hex`
- `size_hex`
- `section`
- `output_section_id`
- `input_section_id`
- `script_defined`

## Behavioral Notes
- JSON is written to a temporary sibling file and then renamed into place, so partial writes do not leave a truncated final JSON artifact behind.
- Hex values are canonicalized to lowercase `0x...` strings.
- Non-ASCII bytes in strings are always escaped as `\u00XX`.
- The current reference contract in this package is `format` `10.0`.
- Versioning now relies only on `format.major` and `format.minor`.
- The patch now has a single fixed JSON mode; there are no feature flags that change schema shape.
- `symbols.state` is the normalized linker-visible symbol state, not raw `bfd_link_hash_type`.
- `symbols.script_defined` is `true` only for symbols defined by the linker script itself.
- Absolute script-defined symbols created from expressions such as `LOADADDR(.data)` remain `section = "ABS"` with `output_section_id = null`; the contract preserves the final linker value, not the source-expression provenance.

## Parser Assumptions
- `output.entry_symbol` is the final entry string from `ld`; on ARM/Thumb targets it may be the function address plus the Thumb bit, so it can legitimately differ by `+1` from the corresponding function symbol value.
- Non-discarded `input_sections` should be expected to carry `output_section_id` whenever the linker can identify a unique output section, even when `value_hex` and `output_offset_hex` are still `null`.
- This matters for sections such as `.debug_str` and `.comment`: they may be linked to a final output section by name while still lacking per-input placement addresses.
- Defined symbols with non-`ABS` `section` and `output_section_id = null` should be interpreted together with `input_section_id`; in practice they usually correspond to discarded input sections rather than a broken export.

## Scope Notes
- In this repo, port only into `src/binutils/ld/ldlang.c` (not `src/gdb/ld/ldlang.c`).
- The new `Makefile.am` hook is important if you ship source tarballs or regenerate gettext catalogs.

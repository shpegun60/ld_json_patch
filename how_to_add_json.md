# How To Add --dump-script-json

This document is the end-to-end reference for:
- wiring `--dump-script-json` into ST GNU ld in this workspace;
- understanding the final JSON contract;
- building the patched linker;
- verifying the new command on a real STM32 project.

Workspace root:
- `C:\Users\admin\Documents\my_workspace\gnu\gnu-tools-for-stm32`

Patched source tree (git repository):
- `C:\Users\admin\Documents\my_workspace\gnu\gnu-tools-for-stm32\gnu-tools-for-stm32-13.3.rel1.20250523-0900`

Reference patch package:
- `C:\Users\admin\Documents\my_workspace\gnu\gnu-tools-for-stm32\json_patch`

Build/output folder for this revision:
- `C:\Users\admin\Documents\my_workspace\gnu\gnu-tools-for-stm32\build_02`

## READ THIS FIRST: hooks vs real files

There are two different kinds of files in `json_patch`, and they do different jobs.

Real feature files:
- `json_patch/ldjson_options.def`
- `json_patch/ldjson_compat.h`
- `json_patch/ldscript_json_impl.inc`

These three files are the real implementation.
They must be copied into:
- `gnu-tools-for-stm32-13.3.rel1.20250523-0900/src/binutils/ld`

After you copy them, the real build uses them.
These are the files that matter to the compiler and linker build.

Helper snippet files:
- `json_patch/hooks/ld.h.fragment`
- `json_patch/hooks/ldlex.h.fragment`
- `json_patch/hooks/lexsup.c.fragment`
- `json_patch/hooks/ldlang.c.fragment`
- `json_patch/hooks/Makefile.am.fragment`

These `hooks/*.fragment` files are only helper snippets for a human.
They are:
- not compiled;
- not included automatically;
- not used by the build directly.

Their only purpose is:
- open the fragment;
- copy the tiny glue block;
- paste it into the matching real source file.

If you are confused, use this rule:
- the `hooks/*.fragment` files tell you what to paste;
- the `ldjson_*.def/.h` and `ldscript_json_impl.inc` files are the real code.

## FASTEST PATH

If the source tree is already patched and you only want to build:
1. Run `build_02/_run_build_02.sh`.
2. Check that `build_02/_cubeide-arm-linker-.../ld.exe --help` shows `dump-script-json`.
3. Run `build_02/_smoke_test_h7s_fiber_test.ps1`.

If the source tree is not patched yet and you want the full process:
1. Copy the three real feature files into `src/binutils/ld`.
2. Edit the five glue files in `src/binutils/ld` exactly as shown below.
3. Run the build command from section `7`.
4. Run the verification command from section `8`.
5. Run the real project smoke test from section `9`.

If you want the shortest possible mental model:
1. Copy real code files.
2. Paste tiny glue snippets into five existing ld files.
3. Build.
4. Check `--help`.
5. Generate JSON.

## COPY THESE FILES

Copy exactly these files:

- `C:\Users\admin\Documents\my_workspace\gnu\gnu-tools-for-stm32\json_patch\ldjson_options.def`
  -> `C:\Users\admin\Documents\my_workspace\gnu\gnu-tools-for-stm32\gnu-tools-for-stm32-13.3.rel1.20250523-0900\src\binutils\ld\ldjson_options.def`
- `C:\Users\admin\Documents\my_workspace\gnu\gnu-tools-for-stm32\json_patch\ldjson_compat.h`
  -> `C:\Users\admin\Documents\my_workspace\gnu\gnu-tools-for-stm32\gnu-tools-for-stm32-13.3.rel1.20250523-0900\src\binutils\ld\ldjson_compat.h`
- `C:\Users\admin\Documents\my_workspace\gnu\gnu-tools-for-stm32\json_patch\ldscript_json_impl.inc`
  -> `C:\Users\admin\Documents\my_workspace\gnu\gnu-tools-for-stm32\gnu-tools-for-stm32-13.3.rel1.20250523-0900\src\binutils\ld\ldscript_json_impl.inc`

Do not copy these as code files:
- `json_patch\hooks\ld.h.fragment`
- `json_patch\hooks\ldlex.h.fragment`
- `json_patch\hooks\lexsup.c.fragment`
- `json_patch\hooks\ldlang.c.fragment`
- `json_patch\hooks\Makefile.am.fragment`

These `hooks` files are only copy-paste helpers.

## POWERSHELL COPY COMMANDS

If you do not want to copy files by hand, run exactly these commands in PowerShell:

```powershell
Copy-Item -Force `
  "C:\Users\admin\Documents\my_workspace\gnu\gnu-tools-for-stm32\json_patch\ldjson_options.def" `
  "C:\Users\admin\Documents\my_workspace\gnu\gnu-tools-for-stm32\gnu-tools-for-stm32-13.3.rel1.20250523-0900\src\binutils\ld\ldjson_options.def"

Copy-Item -Force `
  "C:\Users\admin\Documents\my_workspace\gnu\gnu-tools-for-stm32\json_patch\ldjson_compat.h" `
  "C:\Users\admin\Documents\my_workspace\gnu\gnu-tools-for-stm32\gnu-tools-for-stm32-13.3.rel1.20250523-0900\src\binutils\ld\ldjson_compat.h"

Copy-Item -Force `
  "C:\Users\admin\Documents\my_workspace\gnu\gnu-tools-for-stm32\json_patch\ldscript_json_impl.inc" `
  "C:\Users\admin\Documents\my_workspace\gnu\gnu-tools-for-stm32\gnu-tools-for-stm32-13.3.rel1.20250523-0900\src\binutils\ld\ldscript_json_impl.inc"
```

What these commands do:
- overwrite the destination files with the current reference files from `json_patch`;
- do not touch `ld.h`, `ldlex.h`, `lexsup.c`, `ldlang.c`, or `Makefile.am`;
- do not use `hooks/*.fragment` automatically, because those still must be pasted by hand into the five glue files.

## PATCH CHECK BEFORE BUILD

Before you start the build, you can run one automatic check that verifies:
- the three real files were copied into `src/binutils/ld`;
- all five glue insertion points are present in the expected files.

Run this:

```powershell
powershell -ExecutionPolicy Bypass -File "C:/Users/admin/Documents/my_workspace/gnu/gnu-tools-for-stm32/build_02/_check_patch_applied.ps1"
```

If the patch is correct, the script prints a success object like this:

```text
ok      : True
message : all required files and glue snippets are present
```

If the patch is incomplete, the script exits with an error and tells you which
required file or glue block is missing.

## ONE SCREEN CHECKLIST

1. Open `gnu-tools-for-stm32-13.3.rel1.20250523-0900\src\binutils\ld`.
2. Copy `ldjson_options.def`, `ldjson_compat.h`, `ldscript_json_impl.inc` from `json_patch` into that folder.
3. Open `json_patch\hooks\ld.h.fragment` and paste that snippet into `src\binutils\ld\ld.h`.
4. Open `json_patch\hooks\ldlex.h.fragment` and paste that snippet into `src\binutils\ld\ldlex.h`.
5. Open `json_patch\hooks\lexsup.c.fragment` and paste both snippets into `src\binutils\ld\lexsup.c`.
6. Open `json_patch\hooks\ldlang.c.fragment` and paste both snippets into `src\binutils\ld\ldlang.c`.
7. Open `json_patch\hooks\Makefile.am.fragment` and add those two lines into `src\binutils\ld\Makefile.am`.
8. Save all files.
9. Run `powershell -ExecutionPolicy Bypass -File "C:/Users/admin/Documents/my_workspace/gnu/gnu-tools-for-stm32/build_02/_check_patch_applied.ps1"`.
10. If the patch check says `ok : True`, run `C:\msys64\msys2_shell.cmd -defterm -no-start -mingw64 -here -c "/usr/bin/bash /c/Users/admin/Documents/my_workspace/gnu/gnu-tools-for-stm32/build_02/_run_build_02.sh"`.
11. Run `& "C:/Users/admin/Documents/my_workspace/gnu/gnu-tools-for-stm32/build_02/_cubeide-arm-linker-st-13.3.rel1.20250523-0900-jsonpatch/ld.exe" --help | Select-String "dump-script-json"`.
12. Run `powershell -ExecutionPolicy Bypass -File "C:/Users/admin/Documents/my_workspace/gnu/gnu-tools-for-stm32/build_02/_smoke_test_h7s_fiber_test.ps1"`.
13. If step 11 shows `dump-script-json` and step 12 prints `indexed contract is valid`, the patch/build worked.

## BUILD ONLY

If patching is already done and you only want to build the linker, do exactly this:

1. Run:

```powershell
C:\msys64\msys2_shell.cmd -defterm -no-start -mingw64 -here -c "/usr/bin/bash /c/Users/admin/Documents/my_workspace/gnu/gnu-tools-for-stm32/build_02/_run_build_02.sh"
```

2. Wait until the command finishes without an error.
3. Check this file exists:
   - `C:\Users\admin\Documents\my_workspace\gnu\gnu-tools-for-stm32\build_02\_cubeide-arm-linker-st-13.3.rel1.20250523-0900-jsonpatch\ld.exe`
4. Run:

```powershell
& "C:/Users/admin/Documents/my_workspace/gnu/gnu-tools-for-stm32/build_02/_cubeide-arm-linker-st-13.3.rel1.20250523-0900-jsonpatch/ld.exe" --help | Select-String "dump-script-json"
```

5. If you see `dump-script-json`, the build worked.

If you are not sure whether the source tree is patched correctly, run this first:

```powershell
powershell -ExecutionPolicy Bypass -File "C:/Users/admin/Documents/my_workspace/gnu/gnu-tools-for-stm32/build_02/_check_patch_applied.ps1"
```

## ONE SCREEN BUILD CHECKLIST

1. Make sure the source tree is already patched.
2. Run `build_02/_run_build_02.sh` through the MSYS2 command shown below.
3. Wait until the command exits normally.
4. Open `build_02`.
5. Confirm these folders now exist:
   - `_build-ld-st-13.3.rel1-mingw64-jsonpatch`
   - `_install-ld-st-13.3.rel1-mingw64-jsonpatch`
   - `_cubeide-arm-linker-st-13.3.rel1.20250523-0900-jsonpatch`
6. Open `_cubeide-arm-linker-st-13.3.rel1.20250523-0900-jsonpatch`.
7. Confirm `ld.exe` exists.
8. Confirm `ld.bfd.exe` exists.
9. Run `ld.exe --help | Select-String "dump-script-json"`.
10. If you see the option text, the linker build is good.
11. Run the smoke test script.
12. If the smoke test prints `indexed contract is valid`, the end-to-end build is good.

## EXPECTED SUCCESS OUTPUT

After a successful build, you should have these files:
- `build_02\_cubeide-arm-linker-st-13.3.rel1.20250523-0900-jsonpatch\ld.exe`
- `build_02\_cubeide-arm-linker-st-13.3.rel1.20250523-0900-jsonpatch\ld.bfd.exe`
- `build_02\_cubeide-arm-linker-st-13.3.rel1.20250523-0900-jsonpatch\arm-none-eabi-ld.exe`
- `build_02\_cubeide-arm-linker-st-13.3.rel1.20250523-0900-jsonpatch\arm-none-eabi-ld.bfd.exe`
- `build_02\_cubeide-arm-linker-st-13.3.rel1.20250523-0900-jsonpatch\libwinpthread-1.dll`
- `build_02\_cubeide-arm-linker-st-13.3.rel1.20250523-0900-jsonpatch\libzstd.dll`

After a successful help check, you should see a line like this:

```text
--dump-script-json FILE     Write linker script data as indexed JSON
```

After a successful smoke test, you should see output that includes:

```text
"ok": true
"message": "indexed contract is valid"
```

And the smoke test should produce:
- `build_02\h7s_fiber_test_Boot.json`

After a successful patch check, you should see:

```text
ok      : True
message : all required files and glue snippets are present
```

## EXPECTED FAILURE OUTPUT

If something is wrong, these are the most common failures and what they mean.

If the build command fails and you do not get a new `ld.exe`:
- the source tree is not patched correctly yet;
- one of the copied files is missing;
- one of the five glue edits was not inserted in the right place.

If the patch check says:

```text
Patch check failed.
```

it means:
- one of the three copied files is missing;
- or one of the five glue insertion snippets was not found where expected;
- fix the missing piece first, then run the patch check again.

If the help check does not show `dump-script-json`:
- the patched source was not rebuilt yet;
- you are checking the wrong `ld.exe`;
- the `lexsup.c` or `ldlex.h` glue code was not inserted correctly.

If the smoke test says:

```text
Required file is missing: ...\Boot\Debug\objects.list
```

it means:
- the `h7s_fiber_test` project has not been built yet;
- build that STM32 project once first, so `objects.list` exists.

If the smoke test says:

```text
arm-none-eabi-g++.exe was not found. Put it on PATH or set $env:STM32_GCC ...
```

it means:
- the compiler was not found automatically;
- add the compiler to `PATH`, or set `STM32_GCC` to the full executable path.

If the smoke test says:

```text
jq.exe was not found on PATH
```

it means:
- `jq` is missing from `PATH`;
- install `jq` or add its folder to `PATH`.

If you run `ld.exe` directly for the real STM32 smoke test and see:

```text
cannot find libc.a
```

it means:
- you bypassed the compiler driver;
- use `build_02/_smoke_test_h7s_fiber_test.ps1` or `arm-none-eabi-g++.exe`, not a direct raw `ld.exe` call for this project.

If the smoke test finishes linking but validation fails:
- the JSON contract no longer matches `json_patch/validate_core.jq`;
- the serializer code and the validator are out of sync;
- re-check `ldscript_json_impl.inc`, `ldjson_compat.h`, and the example JSON files.

## 1. What The Command Adds

New linker option:
- `--dump-script-json=FILE`

When passed to `ld`, the linker writes a compact parser-stable JSON document after
`lang_end()` completes.

The current canonical top-level shape is:
- `format`
- `output`
- `memory_regions`
- `output_sections`
- `script_variables`

The current reference contract is:
- `format.name = "ldscript-json"`
- `format.major = 10`
- `format.minor = 0`

## 2. Final JSON Shape

The final JSON intentionally keeps one universal schema. There are no alternate
profiles, no `views`, no `core`, no `capabilities`, no `schema_version`, and no
`extensions`.

Canonical skeleton:

```json
{
  "format": { "name": "ldscript-json", "major": 10, "minor": 0 },
  "output": { "entry_symbol": "Reset_Handler" },
  "memory_regions": { "items": [], "by_name": {}, "null_name_ids": [] },
  "output_sections": { "items": [], "by_name": {}, "null_name_ids": [] },
  "script_variables": { "items": [], "by_name": {}, "null_name_ids": [] }
}
```

Per-section payloads:
- `output.entry_symbol`
- `memory_regions.items[*]`: `id`, `name`, `origin_hex`, `length_hex`, `attrs`
- `output_sections.items[*]`: `id`, `name`, `vma_region`, `lma_region`, `script_subsections`
- `script_variables.items[*]`: `id`, `name`, `value_hex`, `section`

`output.entry_symbol` is an opaque string copied from `ld`'s final
`entry_symbol`. In practice it can be:
- a symbol name such as `Reset_Handler`;
- or a resolved numeric string such as `0x8000c09`.

`script_variables` is intentionally narrow:
- it includes only symbols that `ld` marks as defined by the linker script;
- it does not include regular user-code functions or data symbols from `.o` files.

Indexed collections always use:
- `items`
- `by_name`
- `null_name_ids`

`script_variables.value_hex`:
- a hex string when the linker resolved a concrete value;
- `null` when the linker could not resolve a final numeric value.

For the strict machine-readable contract, see:
- `json_patch/FORMAT.md`
- `json_patch/validate_core.jq`

## 3. Source Of Truth Files

The patch package that should be treated as the source of truth is:
- `json_patch/ldjson_options.def`
- `json_patch/ldjson_compat.h`
- `json_patch/ldscript_json_impl.inc`
- `json_patch/hooks/*.fragment`

Important distinction:
- `ldjson_options.def`, `ldjson_compat.h`, and `ldscript_json_impl.inc` are the
  real feature files that are copied into `src/binutils/ld` and then used by the
  build;
- `json_patch/hooks/*.fragment` are not compiled and are not included anywhere by
  themselves;
- `json_patch/hooks/*.fragment` are only ready-to-copy insertion snippets for the
  human doing the port.

If you want the "show me the exact tiny glue block" version, use these files:
- `json_patch/hooks/ld.h.fragment`
- `json_patch/hooks/ldlex.h.fragment`
- `json_patch/hooks/lexsup.c.fragment`
- `json_patch/hooks/ldlang.c.fragment`
- `json_patch/hooks/Makefile.am.fragment`

The real integrated copies used by the build live in:
- `gnu-tools-for-stm32-13.3.rel1.20250523-0900/src/binutils/ld/ldjson_options.def`
- `gnu-tools-for-stm32-13.3.rel1.20250523-0900/src/binutils/ld/ldjson_compat.h`
- `gnu-tools-for-stm32-13.3.rel1.20250523-0900/src/binutils/ld/ldscript_json_impl.inc`

If you change the patch package later, re-copy the three files above into
`src/binutils/ld` before rebuilding.

The most important file among these is `ldjson_options.def`, because all CLI
wiring expands from it. In this revision, the effective row must be:

```c
X(DUMP_SCRIPT_JSON,
  "dump-script-json",
  required_argument,
  "FILE",
  "Write linker script data as indexed JSON",
  dump_script_json)
```

Why this matters:
- `DUMP_SCRIPT_JSON` becomes `OPTION_DUMP_SCRIPT_JSON` in `ldlex.h`;
- `"dump-script-json"` becomes the long CLI option text in `lexsup.c`;
- `"FILE"` becomes the help metavariable;
- `dump_script_json` becomes the `args_type` field name in `ld.h`.

If this row is renamed or mistyped, the generated pieces shown below will no
longer match each other.

## 4. Exact Integration Points In ST ld

Apply changes only in:
- `src/binutils/ld/...`

Do not patch:
- `src/gdb/ld/ldlang.c`

### 4.0 Patch Order (Do This In Order)

1. Copy these three files from `json_patch` into `src/binutils/ld`:
   - `ldjson_options.def`
   - `ldjson_compat.h`
   - `ldscript_json_impl.inc`
2. Edit only these five files in `src/binutils/ld`:
   - `ld.h`
   - `ldlex.h`
   - `lexsup.c`
   - `ldlang.c`
   - `Makefile.am`
3. Build and verify with `build_02/_run_build_02.sh`.

Important:
- copy the three files first, because the inserted code includes them by name;
- all snippets below are for the real ST source tree in
  `gnu-tools-for-stm32-13.3.rel1.20250523-0900/src/binutils/ld`;
- the goal is not to manually type `dump_script_json` in five places, but to wire
  the X-macro file once and let the repeated pieces expand from
  `ldjson_options.def`.

Exact files touched by the command wiring:
- `src/binutils/ld/ld.h`
- `src/binutils/ld/ldlex.h`
- `src/binutils/ld/lexsup.c`
- `src/binutils/ld/ldlang.c`
- `src/binutils/ld/Makefile.am`

### 4.1 ld.h

File:
- `src/binutils/ld/ld.h`

Insertion anchor:
- directly after `char *default_script;` in `args_type`

What is added:
- an X-macro expansion that adds `char *dump_script_json;`

If you want the exact ready-to-copy helper snippet, see:
- `json_patch/hooks/ld.h.fragment`

Find this fragment:

```c
  /* Default linker script.  */
  char *default_script;

} args_type;
```

After patch, it must look like this:

```c
  /* Default linker script.  */
  char *default_script;

#define X(ENUM_ID, LONGOPT, HAS_ARG, METAVAR, HELP_TEXT, ARGS_FIELD) \
  char *ARGS_FIELD;
#include "ldjson_options.def"
#undef X
} args_type;
```

Result:
- `args_type` gains `char *dump_script_json;` through the X-macro;
- do not manually hardcode `char *dump_script_json;`, because the X-macro keeps all
  option wiring in one place.

### 4.2 ldlex.h

File:
- `src/binutils/ld/ldlex.h`

Insertion anchor:
- directly after `OPTION_DEFAULT_SCRIPT,` in `enum option_values`

What is added:
- an X-macro expansion that adds `OPTION_DUMP_SCRIPT_JSON,`

If you want the exact ready-to-copy helper snippet, see:
- `json_patch/hooks/ldlex.h.fragment`

Find this fragment:

```c
  OPTION_DEFAULT_SCRIPT,
  OPTION_PRINT_OUTPUT_FORMAT,
```

After patch, it must look like this:

```c
  OPTION_DEFAULT_SCRIPT,
#define X(ENUM_ID, LONGOPT, HAS_ARG, METAVAR, HELP_TEXT, ARGS_FIELD) \
  OPTION_##ENUM_ID,
#include "ldjson_options.def"
#undef X
  OPTION_PRINT_OUTPUT_FORMAT,
```

Result:
- `enum option_values` gains `OPTION_DUMP_SCRIPT_JSON,`;
- again, the enum member comes from `ldjson_options.def`, not from a handwritten
  extra line.

### 4.3 lexsup.c

File:
- `src/binutils/ld/lexsup.c`

Two insertion points:

1. `ld_options[]`
- place the generated option rows after the existing `default-script` / `dT` rows

2. `parse_args(...)`
- place the generated `case OPTION_DUMP_SCRIPT_JSON:` block after
  `case OPTION_DEFAULT_SCRIPT:`

If you want the exact ready-to-copy helper snippet, see:
- `json_patch/hooks/lexsup.c.fragment`

For `ld_options[]`, find this exact neighborhood:

```c
  { {"script", required_argument, NULL, 'T'},
    'T', N_("FILE"), N_("Read linker script"), TWO_DASHES },
  { {"default-script", required_argument, NULL, OPTION_DEFAULT_SCRIPT},
    '\0', N_("FILE"), N_("Read default linker script"), TWO_DASHES },
  { {"dT", required_argument, NULL, OPTION_DEFAULT_SCRIPT},
    '\0', NULL, NULL, ONE_DASH },
  { {"undefined", required_argument, NULL, 'u'},
    'u', N_("SYMBOL"), N_("Start with undefined reference to SYMBOL"),
    TWO_DASHES },
```

After patch, it must look like this:

```c
  { {"script", required_argument, NULL, 'T'},
    'T', N_("FILE"), N_("Read linker script"), TWO_DASHES },
  { {"default-script", required_argument, NULL, OPTION_DEFAULT_SCRIPT},
    '\0', N_("FILE"), N_("Read default linker script"), TWO_DASHES },
  { {"dT", required_argument, NULL, OPTION_DEFAULT_SCRIPT},
    '\0', NULL, NULL, ONE_DASH },
#define X(ENUM_ID, LONGOPT, HAS_ARG, METAVAR, HELP_TEXT, ARGS_FIELD) \
  { {LONGOPT, HAS_ARG, NULL, OPTION_##ENUM_ID}, '\0', \
    N_(METAVAR), N_(HELP_TEXT), TWO_DASHES },
#include "ldjson_options.def"
#undef X
  { {"undefined", required_argument, NULL, 'u'},
    'u', N_("SYMBOL"), N_("Start with undefined reference to SYMBOL"),
    TWO_DASHES },
```

That is what creates the visible CLI option row:
- `--dump-script-json FILE     Write linker script data as indexed JSON`

Inside `parse_args(...)`, find this exact neighborhood:

```c
  case OPTION_DEFAULT_SCRIPT:
    command_line.default_script = optarg;
    break;
  case OPTION_SECTION_START:
```

After patch, it must look like this:

```c
  case OPTION_DEFAULT_SCRIPT:
    command_line.default_script = optarg;
    break;
#define X(ENUM_ID, LONGOPT, HAS_ARG, METAVAR, HELP_TEXT, ARGS_FIELD) \
  case OPTION_##ENUM_ID: \
    command_line.ARGS_FIELD = optarg; \
    break;
#include "ldjson_options.def"
#undef X
  case OPTION_SECTION_START:
```

Result:
- `parse_args(...)` stores the CLI filename into `command_line.dump_script_json`.

### 4.4 ldlang.c

File:
- `src/binutils/ld/ldlang.c`

Two insertion points:

1. File-scope include anchor
- place `#include "ldscript_json_impl.inc"` after `print_statements()`
- place it before `insert_pad(...)`

2. Runtime call-site
- inside `lang_process()`, immediately after `lang_end ();`
- add `lang_dump_script_json ();`

If you want the exact ready-to-copy helper snippet, see:
- `json_patch/hooks/ldlang.c.fragment`

For the file-scope include, find this fragment:

```c
static void
print_statements (void)
{
  print_statement_list (statement_list.head, abs_output_section);
}

/* Print the first N statements in statement list S to STDERR.
```

After patch, it must look like this:

```c
static void
print_statements (void)
{
  print_statement_list (statement_list.head, abs_output_section);
}

#include "ldscript_json_impl.inc"

/* Print the first N statements in statement list S to STDERR.
```

For the runtime call-site, find this fragment inside `lang_process()`:

```c
  ldlang_check_require_defined_symbols ();

  lang_end ();
}
```

After patch, it must look like this:

```c
  ldlang_check_require_defined_symbols ();

  lang_end ();
  lang_dump_script_json ();
}
```

Result:
- the serializer implementation is compiled into `ldlang.c`;
- `lang_dump_script_json()` runs only after the linker has finished layout and
  symbol finalization.

### 4.5 Makefile.am

File:
- `src/binutils/ld/Makefile.am`

What is added:
- `HFILES += ldjson_options.def ldjson_compat.h ldscript_json_impl.inc`
- `EXTRA_DIST += ldjson_options.def ldjson_compat.h ldscript_json_impl.inc`

Why:
- keeps the extra files in source tarballs;
- makes gettext source scanning pick up the new help/error strings because
  `SRC_POTFILES` is derived from `$(CFILES) $(HFILES)`.

If you want the exact ready-to-copy helper snippet, see:
- `json_patch/hooks/Makefile.am.fragment`

Important:
- `Makefile.am` is maintainer metadata; normal local builds use `Makefile.in`.
- You do not need to regenerate `Makefile.in` just to test the local build.
- You do need to regenerate it if you want the autotools-generated files updated.

For `HFILES`, find this fragment:

```make
HFILES = ld.h ldctor.h ldemul.h ldexp.h ldfile.h \
	ldlang.h ldlex.h ldmain.h ldmisc.h ldver.h \
	ldwrite.h mri.h deffile.h pe-dll.h pep-dll.h \
	elf-hints-local.h plugin.h ldbuildid.h ldelf.h ldelfgen.h \
	pdb.h
```

After patch, it must look like this:

```make
HFILES = ld.h ldctor.h ldemul.h ldexp.h ldfile.h \
	ldlang.h ldlex.h ldmain.h ldmisc.h ldver.h \
	ldwrite.h mri.h deffile.h pe-dll.h pep-dll.h \
	elf-hints-local.h plugin.h ldbuildid.h ldelf.h ldelfgen.h \
	pdb.h
HFILES += ldjson_options.def ldjson_compat.h ldscript_json_impl.inc
```

For `EXTRA_DIST`, find this fragment:

```make
EXTRA_DIST = ldgram.c ldgram.h ldlex.c emultempl/spu_ovl.@OBJEXT@_c \
	     emultempl/spu_icache.@OBJEXT@_c deffilep.c deffilep.h $(man_MANS)
```

After patch, it must look like this:

```make
EXTRA_DIST = ldgram.c ldgram.h ldlex.c emultempl/spu_ovl.@OBJEXT@_c \
	     emultempl/spu_icache.@OBJEXT@_c deffilep.c deffilep.h $(man_MANS)
EXTRA_DIST += ldjson_options.def ldjson_compat.h ldscript_json_impl.inc
```

Result:
- `make dist` includes the JSON patch files;
- gettext scanning sees the new help/error strings when autotools metadata is
  regenerated.

## 5. Existing Build Dependency: pex-win32 Fallback

This workspace already contains a local fallback change in:
- `gnu-tools-for-stm32-13.3.rel1.20250523-0900/src/binutils/libiberty/pex-win32.c`

Why it exists:
- ST longpath runtime wrapper generation can be unstable in this local Windows/MSYS2
  environment.
- The fallback keeps the linker build working when the ST longpath runtime wrappers
  are not generated.

This fallback is part of the current working build flow for `build_02`.

## 6. Build Instructions Moved To build_02

All build instructions for the current patched linker revision live in:
- `build_02/README-BUILD.md`
- `build_02/README-CubeIDE.txt`
- `build_02/_run_build_02.sh`

`build_02` is the authoritative folder for:
- the build script;
- the build and install directories;
- the packaged drop-in linker folder;
- the validation outputs for this revision.

## 7. How To Run The Build

Use the script:
- `build_02/_run_build_02.sh`

From PowerShell:

```powershell
C:\msys64\msys2_shell.cmd -defterm -no-start -mingw64 -here -c "/usr/bin/bash /c/Users/admin/Documents/my_workspace/gnu/gnu-tools-for-stm32/build_02/_run_build_02.sh"
```

The script:
- creates a clean build directory;
- configures `src/binutils` for a MINGW64 host;
- builds `all-ld`;
- installs `install-ld`;
- packages a CubeIDE-style drop-in folder inside `build_02`;
- checks that `ld --help` exposes `dump-script-json`.

## 8. How To Validate The New Command

After build, validate the command itself:

```powershell
& "C:/Users/admin/Documents/my_workspace/gnu/gnu-tools-for-stm32/build_02/_cubeide-arm-linker-st-13.3.rel1.20250523-0900-jsonpatch/ld.exe" --help | Select-String "dump-script-json"
```

Validate the JSON contract on any produced file:

```powershell
jq -e -f "C:/Users/admin/Documents/my_workspace/gnu/gnu-tools-for-stm32/json_patch/validate_core.jq" out.json
```

## 9. Real Project Smoke Test

Project available for a real linker test:
- `C:\Users\admin\Documents\my_workspace\stm32\experiments\h7s_fiber_test`

The tested smoke-test entrypoint for this workspace is:
- `build_02/_smoke_test_h7s_fiber_test.ps1`

Run it from PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File "C:/Users/admin/Documents/my_workspace/gnu/gnu-tools-for-stm32/build_02/_smoke_test_h7s_fiber_test.ps1"
```

What it does:
- locates `arm-none-eabi-g++.exe` in this order:
  - `STM32_GCC` environment variable;
  - `arm-none-eabi-g++.exe` from `PATH`;
  - the newest matching toolchain under `C:\ST`;
- injects the patched linker from `build_02` through `-B...`;
- re-links the real `h7s_fiber_test` object set using
  `h7s_fiber_test\Boot\Debug\objects.list`;
- adds `-Wl,--dump-script-json=...`;
- writes:
  - `build_02/h7s_fiber_test_Boot.jsoncheck.elf`
  - `build_02/h7s_fiber_test_Boot.jsoncheck.map`
  - `build_02/h7s_fiber_test_Boot.json`
- validates the resulting JSON with `json_patch/validate_core.jq` using `jq.exe`
  from `PATH`.

Prerequisites for the smoke test:
- the `h7s_fiber_test` project must already be built at least once, so that
  `Boot\Debug\objects.list` already exists;
- `jq.exe` must be available on `PATH`;
- if the compiler is not on `PATH`, set `STM32_GCC` to the full path of
  `arm-none-eabi-g++.exe`.

Why the script uses `arm-none-eabi-g++.exe` instead of calling `ld.exe` directly:
- this linker script contains a `/DISCARD/` block that references `libc.a`, `libm.a`,
  and `libgcc.a`;
- calling `ld.exe` directly without the toolchain library search paths fails with
  `cannot find libc.a`;
- the compiler driver supplies the correct search paths automatically and still routes
  the actual link through the patched `build_02` linker via `-B...`.

If the build/test process uncovers anything missing, update:
- this file;
- `json_patch/README.md`;
- `build_02/README-BUILD.md`

so the instructions remain complete.

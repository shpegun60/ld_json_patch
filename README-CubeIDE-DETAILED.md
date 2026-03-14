# README-CubeIDE-DETAILED

## What This Document Is

This is a CubeIDE-oriented companion note for the `json_patch` package.

It explains how the patched GNU `ld` produced from this patch is intended to be used from STM32CubeIDE, and how it relates to the other tools in this repository.

## What the Patched Linker Adds

The patched linker adds one new command-line feature:

- `--dump-script-json`

This allows GNU `ld` to emit a structured linker JSON file describing:

- memory regions
- output sections
- linker-script-defined variables
- indexed name lookup structures

The exact parser contract is documented in:

- [FORMAT.md](FORMAT.md)
- [validate_core.jq](validate_core.jq)

## How It Fits into This Repository

- `json_patch`
  This folder contains the actual GNU `ld` patch package and integration helpers.

- `ld_viewer`
  This is the Qt desktop viewer for the generated linker JSON.

- `ld_sniffer`
  This is a wrapper that can sit in front of the original CubeIDE linker, keep the original linker as the real build linker, and mirror the invocation into the patched linker to generate JSON.

- `build_00`, `build_01`, `build_02`, `build_03`
  These folders contain concrete local build notes and artifacts for specific patched-linker revisions in this workspace.

## Source Tree Requirement

Before using this patch, you need a matching ST GNU Tools for STM32 source tree.

The patch is intended for the ST source layout under:

- `src/binutils/ld`

Reference source tree in this workspace:

- [gnu-tools-for-stm32-13.3.rel1.20250523-0900](../gnu-tools-for-stm32-13.3.rel1.20250523-0900)

Use a matching source tree and linker version. Do not assume identical anchors or compatibility on an unrelated ST/Binutils release.

## Typical CubeIDE Usage Models

### Model 1: Direct Patched Linker Replacement

Use the patched linker directly from CubeIDE by adding its directory through:

```text
-B"C:/path/to/patched-linker-folder/"
```

This makes GCC / `collect2` search that directory for:

- `ld.exe`
- `ld.bfd.exe`
- possibly target-prefixed names such as `arm-none-eabi-ld.exe`

This model is simple, but the patched linker becomes the effective build linker.

### Model 2: Use `ld_sniffer`

Use `ld_sniffer` as the CubeIDE `-B".../"` wrapper directory instead.

In that model:

- the original ST linker still performs the real build
- the patched linker is invoked only as a mirrored secondary step
- JSON is generated without replacing the effective build linker

This is the safer workflow if you want diagnostics and JSON generation without changing the main linker used for the final build artifact.

## Recommended Verification

After wiring the patched linker or `ld_sniffer` into CubeIDE, add this once:

```text
-Wl,-v
```

Then verify in the CubeIDE build console that the expected linker is actually being invoked.

## Full End-to-End Guide

For the full integration and rebuild process, use:

- [how_to_add_json.md](how_to_add_json.md)

That document is the detailed reference for:

- copying the real patch files
- applying the glue snippets
- building the patched linker
- validating the JSON contract
- testing on a real STM32 project

CubeIDE patched linker reference

English overview:
- This file describes how a patched GNU `ld` build can be used as a CubeIDE drop-in linker replacement.
- The patched linker adds the `--dump-script-json` feature.
- The generated JSON is intended for analysis with `ld_viewer`.
- If you want to keep the original ST linker as the real build linker and mirror the invocation into the patched linker, use `ld_sniffer` instead of replacing the linker directly.
- CubeIDE integration is done through the linker `-B".../"` flag, which points to a directory containing `ld.exe` / `ld.bfd.exe` style entry points.

Typical usage:
- build a patched linker from the matching ST GNU Tools for STM32 source tree
- prepare a CubeIDE drop-in folder containing the linker executables
- add that folder to CubeIDE linker flags through `-B".../"`
- optionally add `-Wl,-v` once to verify that CubeIDE is really executing the patched linker

Recommended follow-up documents in this folder:
- `README-CubeIDE-DETAILED.md` for the detailed CubeIDE-oriented explanation
- `how_to_add_json.md` for the full end-to-end patch integration and rebuild workflow

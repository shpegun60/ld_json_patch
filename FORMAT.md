# Stable JSON Format Contract

This document defines the parser-stable contract for `--dump-script-json`.
The current reference contract in this package is `format` `10.0`.

## Goals
- Keep a single canonical shape for machine parsing.
- Preserve duplicate names and null names without data loss.

## Top-Level Keys
Producers should always emit these keys:
- `format` (object)
- `output` (object)
- `memory_regions` (indexed object)
- `output_sections` (indexed object)
- `script_variables` (indexed object)

## Versioning Rules
- `format.name`: stable identifier (`ldscript-json`).
- `format.major`: breaking changes only.
- `format.minor`: additive, backward-compatible changes.
- Parsers should reject unknown `format.major`.
- Parsers should tolerate larger `format.minor`.

## Stability Guarantees (Normative)
For any two producers with the same `format.name` and same `format.major`:
- Producers MUST keep all top-level keys listed above with the same meaning.
- Producers MUST keep field types stable.
- Producers MUST NOT rename or remove existing required fields.
- Producers MAY add optional fields.
- Producers SHOULD emit unsupported optional payloads as empty/default values.

Breaking changes requiring `format.major` increment:
- removing or renaming an existing field;
- changing a field type;
- changing the semantic meaning of an existing field.

Non-breaking changes (`format.minor`):
- adding optional fields;
- adding optional nested objects.

## Encoding Rules
- Hex values are canonical strings:
  - lowercase;
  - `0x` prefix;
  - no unnecessary leading zeros.
- Booleans are JSON booleans.
- Missing optional values are `null` (or empty arrays/objects where specified).
- Strings are JSON-escaped.
- Non-ASCII bytes SHOULD be escaped as `\u00XX` to keep output valid JSON even for non-UTF8 host encodings.

## Indexed Collections (Normative)
The following top-level keys use the same shape:
- `memory_regions`
- `output_sections`
- `script_variables`

Each collection is an object with required keys:
- `items` (array of objects with stable per-document `id`)
- `by_name` (object: `name -> [id, ...]`)
- `null_name_ids` (array of ids whose `name` is `null`)

Contract:
- `items` is the source of truth.
- `by_name` is an index only.
- `by_name` MUST always map to arrays, never to single objects.
- `null_name_ids` MUST include every item whose `name` is `null`.

Recommended id prefixes:
- `r` for `memory_regions`
- `s` for `output_sections`
- `v` for `script_variables`

For `memory_regions.items[*]`:
- `attrs` SHOULD be a compact flag string such as `axr` or `axw`.

## Output
For the `output` object:
- `entry_symbol` MAY be `null`.
- when present, `entry_symbol` is the final string carried by `ld`; it may be a
  symbol-like name or a numeric string such as `0x8000c09`
- `filename`, `target`, `entry_from_cmdline`, `is_relocatable`, `is_shared`, and `is_pie` MUST NOT be emitted.

Minimal shape:
```json
{ "entry_symbol": "Reset_Handler" }
```

## Output Sections
For each `output_sections.items[*]` object:
- The canonical section payload is intentionally minimal.
- `vma_region` is the VMA region.
- `lma_region` is the LMA/load region.
- `region` MUST NOT be emitted.
- `script_subsections` MAY be emitted as an array of linker-script match expressions.

## Script Variables
For each `script_variables.items[*]` object:
- `script_variables` is reserved for linker-script-defined symbols only.
- `value_hex` MAY be `null`.
- `section` MAY be `null`.

Parsers SHOULD use `value_hex != null` to detect resolved values.

## Parser Guidance
- Prefer the indexed top-level collections.
- Prefer presence checks over strict field counts.
- Prefer `format.major` / `format.minor` for version checks.
- Do not rely on array ordering for semantic meaning.
- Do not collapse `by_name` into `name -> object`; always handle arrays of ids.

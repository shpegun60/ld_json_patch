# Stable JSON Format Contract

This document defines the parser-stable contract for `--dump-script-json`.
The current reference contract in this package is `format` `10.0`.

## Goals
- Keep one canonical shape for machine parsing.
- Preserve duplicate names and null names without data loss.
- Keep layout data separate from symbol data.

## Top-Level Keys
Producers should always emit these keys:
- `format` (object)
- `output` (object)
- `memory_regions` (indexed object)
- `output_sections` (indexed object)
- `input_sections` (indexed object)
- `discarded_input_sections` (array)
- `symbols` (indexed object)

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
- Producers SHOULD emit unsupported optional payloads as `null`, empty arrays, or empty objects as appropriate.

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
- `input_sections`
- `symbols`

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
- `is` for `input_sections`
- `v` for `symbols`

## Output
For the `output` object:
- `entry_symbol` MAY be `null`.
- When present, `entry_symbol` is the final string carried by `ld`; it may be a symbol-like name or a numeric string such as `0x8000c09`.
- `filename`, `target`, `entry_from_cmdline`, `is_relocatable`, `is_shared`, and `is_pie` MUST NOT be emitted.

Minimal shape:
```json
{ "entry_symbol": "Reset_Handler" }
```

## Memory Regions
For each `memory_regions.items[*]` object:
- required fields:
  - `id`
  - `name`
  - `origin_hex`
  - `length_hex`
  - `attrs`
- `attrs` MUST be an object with:
  - `required`
  - `forbidden`
  - `flags_hex`
  - `not_flags_hex`
- `attrs` MUST NOT be emitted as a plain compact string.
- `origin_exp`, `length_exp`, `current`, `last_os`, and `had_full_message` MUST NOT be emitted.

## Output Sections
For each `output_sections.items[*]` object:
- required fields:
  - `id`
  - `name`
  - `vma_region`
  - `lma_region`
  - `vma_hex`
  - `lma_hex`
  - `size_hex`
  - `script_subsections`
- `vma_region` and `lma_region` MAY be `null`.
- `vma_hex`, `lma_hex`, and `size_hex` MAY be `null`.
- `script_subsections` MUST be an array of linker-script match expressions.
- optional `flags` MAY be emitted as an object with:
  - `letters`
  - `hex`
- raw `bfd_section` MUST NOT be emitted.
- legacy `region` MUST NOT be emitted.

## Input Sections
For each `input_sections.items[*]` object:
- required fields:
  - `id`
  - `name`
  - `discarded`
  - `output_section_id`
  - `owner_file`
  - `value_hex`
  - `size_hex`
  - `output_offset_hex`
  - `flags`
- `discarded` MUST be a boolean.
- `output_section_id`, `owner_file`, `value_hex`, `size_hex`, and `output_offset_hex` MAY be `null`.
- Producers SHOULD emit `output_section_id` for non-discarded input sections whenever a unique output section can be identified, even if `value_hex` and `output_offset_hex` remain `null`.
- `flags` MUST be an object with:
  - `letters`
  - `hex`
- `object_file`, `archive_file`, `archive_member`, `input_statement_file`, and `rawsize_hex` MUST NOT be part of the canonical contract.

## Discarded Input Sections
`discarded_input_sections` is a plain top-level array.

For each `discarded_input_sections[*]` object:
- required fields:
  - `input_section_id`
  - `discard_reason`

Contract:
- `input_section_id` MUST reference an existing `input_sections.items[*].id`.
- If an input section has `discarded = true`, there MUST be exactly one matching discard record.
- If a discard record exists, the referenced input section MUST have `discarded = true`.

## Symbols
For each `symbols.items[*]` object:
- required fields:
  - `id`
  - `name`
  - `state`
  - `value_hex`
  - `size_hex`
  - `section`
  - `output_section_id`
  - `input_section_id`
  - `script_defined`
- Preferred `state` values are:
  - `defined`
  - `undefined`
  - `common`
  - `alias`
  - `warning`
- `state` intentionally does not encode weak-vs-strong detail.
- `value_hex` MAY be `null`.
- `size_hex` MAY be `null`.
- `section` MAY be `null`.
- `output_section_id` MAY be `null`.
- `input_section_id` MAY be `null`.
- `script_defined` MUST be a boolean.
- Script-defined symbols whose expressions resolve to absolute values (for example `LOADADDR(.data)`) MAY legitimately appear as `section = "ABS"` with `output_section_id = null`.
- raw `hash_type` MUST NOT be part of the canonical contract.

## Parser Guidance
- Prefer the indexed top-level collections.
- Prefer presence checks over strict field counts.
- Prefer `format.major` / `format.minor` for version checks.
- Do not rely on array ordering for semantic meaning.
- Do not collapse `by_name` into `name -> object`; always handle arrays of ids.
- Treat `discarded_input_sections` as discard metadata only; `input_sections.items[*]` remains the source of truth for each input section.
- `output.entry_symbol` may be an architecture-encoded final entry value rather than a plain symbol name; on ARM/Thumb targets it can legitimately equal the function address plus `1`.
- A defined symbol with non-`ABS` `section` and `output_section_id = null` is not automatically an error; check `input_section_id` and the corresponding `input_sections.items[*].discarded` state first.

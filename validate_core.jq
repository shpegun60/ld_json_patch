# validate_core.jq
# Usage:
#   jq -e -f json_patch/validate_core.jq out.json

def chk($cond; $msg):
  if $cond then [] else [$msg] end;

def is_obj: type == "object";
def is_arr: type == "array";
def is_bool: type == "boolean";
def is_str: type == "string";
def is_str_or_null: (type == "string" or . == null);
def is_id_array: (type == "array") and all(.[]; type == "string");

def is_by_name_index:
  if type != "object" then
    false
  else
    all(to_entries[]; (.value | is_id_array))
  end;

def has_indexed_block_shape:
  (type == "object")
  and (.items | is_arr)
  and (.by_name | is_by_name_index)
  and (.null_name_ids | is_id_array);

def has_id_and_name:
  (type == "object")
  and (.id? | is_str)
  and (.name? | is_str_or_null);

def symbol_item_ok:
  has_id_and_name
  and (.section? | is_str_or_null)
  and (.value_hex? | is_str_or_null);

def script_subsections_ok:
  ((has("script_subsections") | not)
   or (.script_subsections | is_arr and all(.[]; type == "string")));

def section_item_ok:
  has_id_and_name
  and (.vma_region | is_str_or_null)
  and (.lma_region | is_str_or_null)
  and script_subsections_ok
  and ((has("region")) | not);

def checks:
  chk((type == "object"); "root must be object")

  + chk((.format? | is_obj); "missing format object")
  + chk((.format.name? == "ldscript-json"); "format.name must be ldscript-json")
  + chk((.format.major? | type) == "number"; "format.major must be number")
  + chk((.format.minor? | type) == "number"; "format.minor must be number")
  + chk((has("capabilities") | not); "capabilities is not part of the current format")
  + chk((has("schema_version") | not); "schema_version is not part of the current format")
  + chk((has("extensions") | not); "extensions is not part of the current format")

  + chk((.output? | is_obj); "missing output object")
  + chk((.output.entry_symbol? | is_str_or_null); "output.entry_symbol must be string|null")
  + chk((.output.filename? == null); "output.filename is not part of the current format")
  + chk((.output.target? == null); "output.target is not part of the current format")
  + chk((.output.entry_from_cmdline? == null); "output.entry_from_cmdline is not part of the current format")
  + chk((.output.is_relocatable? == null); "output.is_relocatable is not part of the current format")
  + chk((.output.is_shared? == null); "output.is_shared is not part of the current format")
  + chk((.output.is_pie? == null); "output.is_pie is not part of the current format")

  + chk((.memory_regions? | has_indexed_block_shape); "memory_regions must have items/by_name/null_name_ids with id arrays")
  + chk((.memory_regions.items? | is_arr and all(.[]; has_id_and_name)); "memory_regions.items[] must contain id and name")

  + chk((.output_sections? | has_indexed_block_shape); "output_sections must have items/by_name/null_name_ids with id arrays")
  + chk((.output_sections.items? | is_arr and all(.[]; section_item_ok)); "output_sections.items[] must contain id/name/vma_region/lma_region and must not contain region")

  + chk((.script_variables? | has_indexed_block_shape); "script_variables must have items/by_name/null_name_ids with id arrays")
  + chk((.script_variables.items? | is_arr and all(.[]; symbol_item_ok)); "every script_variables.items[] must contain id, name, value_hex, and section")
;

(checks) as $errors
| if ($errors | length) == 0 then
    { "ok": true, "message": "indexed contract is valid" }
  else
    error($errors | join("\n"))
  end

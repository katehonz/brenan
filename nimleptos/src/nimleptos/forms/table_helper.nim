import std/tables

proc newFormData*(pairs: seq[(string, string)]): TableRef[string, string] =
  result = newTable[string, string]()
  for (k, v) in pairs:
    result[k] = v

proc lookupValue*(data: TableRef[string, string], key: string): string =
  data.getOrDefault(key, "")

proc formDataLen*(data: TableRef[string, string]): int =
  data.len

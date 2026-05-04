import std/tables

type InterpValue* = ref object
  case kind*: range[0..2]
  of 0: strVal*: string
  of 1: intVal*: int
  of 2: floatVal*: float

proc `$`*(val: InterpValue): string =
  case val.kind
  of 0: val.strVal
  of 1: $val.intVal
  of 2: $val.floatVal

proc str*(v: string): InterpValue =
  InterpValue(kind: 0, strVal: v)

proc intv*(v: int): InterpValue =
  InterpValue(kind: 1, intVal: v)

proc floatv*(v: float): InterpValue =
  InterpValue(kind: 2, floatVal: v)

type InterpParams* = Table[string, InterpValue]

proc interpolate*(templateStr: string, params: InterpParams): string =
  result = ""
  var i = 0
  while i < templateStr.len:
    if templateStr[i] == '{' and i + 1 < templateStr.len:
      var j = i + 1
      while j < templateStr.len and templateStr[j] != '}':
        inc(j)
      if j < templateStr.len:
        let key = templateStr[i + 1 .. j - 1]
        if params.hasKey(key):
          result.add($params[key])
        else:
          result.add("{" & key & "}")
        i = j + 1
      else:
        result.add(templateStr[i])
        inc(i)
    else:
      result.add(templateStr[i])
      inc(i)

proc interpolateNamed*(templateStr: string, params: openArray[(string, string)]): string =
  var tbl: InterpParams
  for (k, v) in params:
    tbl[k] = str(v)
  return interpolate(templateStr, tbl)

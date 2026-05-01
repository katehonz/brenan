import nimmax/validater
import ./form
import ./table_helper
import std/strutils

export validater

type
  NimLeptosValidator* = ref object
    nimmax*: FormValidator
    fieldLabels*: seq[(string, string)]

proc newNimLeptosValidator*(): NimLeptosValidator =
  NimLeptosValidator(
    nimmax: newFormValidator(),
    fieldLabels: @[]
  )

proc addRule*(v: NimLeptosValidator, field: string, rule: Validator, label = "") =
  v.nimmax.addRule(field, rule)
  if label.len > 0:
    v.fieldLabels.add((field, label))

proc validateFormFields*(v: NimLeptosValidator, form: FormDef, values: seq[(string, string)]): bool =
  let data = newFormData(values)
  let res = v.nimmax.validate(data)
  result = res.valid
  if not result:
    for err in res.errors:
      let parts = err.split(": ", 1)
      if parts.len == 2:
        form.setFieldError(parts[0], parts[1])

proc addRequired*(v: NimLeptosValidator, field: string, label = "") =
  v.addRule(field, required(), label)

proc addEmail*(v: NimLeptosValidator, field: string, label = "") =
  v.addRule(field, isEmail(), label)

proc addMinLen*(v: NimLeptosValidator, field: string, minLen: int, label = "") =
  v.addRule(field, minLength(minLen), label)

proc addMaxLen*(v: NimLeptosValidator, field: string, maxLen: int, label = "") =
  v.addRule(field, maxLength(maxLen), label)

proc addIntRange*(v: NimLeptosValidator, field: string, minVal, maxVal: int, label = "") =
  v.addRule(field, isInt(), label)
  v.addRule(field, minValue(float(minVal)), label)
  v.addRule(field, maxValue(float(maxVal)), label)

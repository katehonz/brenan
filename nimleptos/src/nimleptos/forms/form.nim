import nimmax
import ../dom/node
import ../dom/elements

type
  FormField* = object
    name*: string
    label*: string
    kind*: string
    value*: string
    errors*: seq[string]
    required*: bool
    attrs*: seq[(string, string)]

  FormDef* = ref object
    fields*: seq[FormField]
    action*: string
    httpMethod*: string
    attrs*: seq[(string, string)]

proc newFormDef*(action: string, httpMethod = "POST"): FormDef =
  FormDef(fields: @[], action: action, httpMethod: httpMethod, attrs: @[])

proc addField*(form: FormDef, name: string, label: string, kind = "text",
               value = "", required = false, attrs: seq[(string, string)] = @[]) =
  form.fields.add(FormField(
    name: name, label: label, kind: kind, value: value,
    errors: @[], required: required, attrs: attrs
  ))

proc renderFormField*(field: FormField): HtmlNode =
  let labelNode = elLabel([("for", field.name)], text(field.label))
  var inputAttrs = @[("type", field.kind), ("name", field.name), ("id", field.name)]
  if field.value.len > 0:
    inputAttrs.add(("value", field.value))
  if field.required:
    inputAttrs.add(("required", "required"))
  for (k, v) in field.attrs:
    inputAttrs.add((k, v))
  let inputNode = elInput(inputAttrs)
  var children: seq[HtmlNode] = @[labelNode, inputNode]
  for err in field.errors:
    children.add(elSpan([("class", "field-error")], text(err)))
  elDiv([("class", "form-field")], children)

proc renderForm*(form: FormDef): HtmlNode =
  var children: seq[HtmlNode] = @[]
  for field in form.fields:
    children.add(renderFormField(field))
  children.add(elButton([("type", "submit")], text("Submit")))
  elForm([("action", form.action), ("method", form.httpMethod)], children)

proc getFieldValues*(ctx: Context, form: FormDef): seq[(string, string)] =
  result = @[]
  for field in form.fields:
    result.add((field.name, ctx.getPostParam(field.name)))

proc populateForm*(form: FormDef, ctx: Context) =
  for i in 0 ..< form.fields.len:
    form.fields[i].value = ctx.getPostParam(form.fields[i].name)

proc setFieldError*(form: FormDef, fieldName: string, error: string) =
  for i in 0 ..< form.fields.len:
    if form.fields[i].name == fieldName:
      form.fields[i].errors.add(error)
      break

proc hasErrors*(form: FormDef): bool =
  for field in form.fields:
    if field.errors.len > 0:
      return true

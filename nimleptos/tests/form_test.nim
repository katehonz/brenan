import std/strutils
import ../src/nimleptos/forms/form
import ../src/nimleptos/dom/node

proc testNewFormDef() =
  let form = newFormDef("/submit", "POST")
  doAssert form.action == "/submit"
  doAssert form.httpMethod == "POST"
  doAssert form.fields.len == 0
  echo "PASS: newFormDef"

proc testAddField() =
  let form = newFormDef("/register")
  form.addField("name", "Your Name", kind = "text", value = "Alice", required = true)
  doAssert form.fields.len == 1
  doAssert form.fields[0].name == "name"
  doAssert form.fields[0].label == "Your Name"
  doAssert form.fields[0].kind == "text"
  doAssert form.fields[0].value == "Alice"
  doAssert form.fields[0].required == true
  echo "PASS: addField"

proc testRenderTextField() =
  let field = FormField(
    name: "email",
    label: "Email",
    kind: "email",
    value: "a@b.com",
    required: true,
    errors: @[],
    attrs: @[],
    options: @[]
  )
  let node = renderFormField(field)
  let html = renderToHtml(node)
  doAssert html.contains("<label")
  doAssert html.contains("Email")
  doAssert html.contains("type=\"email\"")
  doAssert html.contains("name=\"email\"")
  doAssert html.contains("value=\"a@b.com\"")
  doAssert html.contains("required")
  echo "PASS: render text field"

proc testRenderTextareaField() =
  let field = FormField(
    name: "bio",
    label: "Biography",
    kind: "textarea",
    value: "Hello world",
    required: false,
    errors: @[],
    attrs: @[],
    options: @[]
  )
  let node = renderFormField(field)
  let html = renderToHtml(node)
  doAssert html.contains("<textarea")
  doAssert html.contains("Hello world")
  doAssert html.contains("name=\"bio\"")
  echo "PASS: render textarea field"

proc testRenderSelectField() =
  let field = FormField(
    name: "country",
    label: "Country",
    kind: "select",
    value: "bg",
    required: true,
    errors: @[],
    attrs: @[],
    options: @[("us", "USA"), ("bg", "Bulgaria")]
  )
  let node = renderFormField(field)
  let html = renderToHtml(node)
  doAssert html.contains("<select")
  doAssert html.contains("USA")
  doAssert html.contains("Bulgaria")
  doAssert html.contains("value=\"bg\"")
  doAssert html.contains("selected")
  doAssert html.contains("required")
  echo "PASS: render select field"

proc testRenderCheckboxField() =
  let field = FormField(
    name: "agree",
    label: "I agree",
    kind: "checkbox",
    value: "true",
    required: true,
    errors: @[],
    attrs: @[],
    options: @[]
  )
  let node = renderFormField(field)
  let html = renderToHtml(node)
  doAssert html.contains("type=\"checkbox\"")
  doAssert html.contains("checked")
  doAssert html.contains("required")
  echo "PASS: render checkbox field"

proc testRenderCheckboxUnchecked() =
  let field = FormField(
    name: "agree",
    label: "I agree",
    kind: "checkbox",
    value: "false",
    required: false,
    errors: @[],
    attrs: @[],
    options: @[]
  )
  let node = renderFormField(field)
  let html = renderToHtml(node)
  doAssert html.contains("type=\"checkbox\"")
  doAssert not html.contains("checked")
  echo "PASS: render checkbox unchecked"

proc testRenderForm() =
  let form = newFormDef("/login", "POST")
  form.addField("username", "Username", required = true)
  form.addField("password", "Password", kind = "password", required = true)
  let node = renderForm(form)
  let html = renderToHtml(node)
  doAssert html.contains("<form")
  doAssert html.contains("action=\"/login\"")
  doAssert html.contains("method=\"POST\"")
  doAssert html.contains("Username")
  doAssert html.contains("Password")
  doAssert html.contains("type=\"submit\"")
  echo "PASS: render form"

proc testSetFieldError() =
  let form = newFormDef("/contact")
  form.addField("email", "Email")
  doAssert not form.hasErrors()
  form.setFieldError("email", "Invalid email")
  doAssert form.hasErrors()
  doAssert form.fields[0].errors.len == 1
  doAssert form.fields[0].errors[0] == "Invalid email"
  echo "PASS: set field error"

proc testRenderFieldWithErrors() =
  let field = FormField(
    name: "name",
    label: "Name",
    kind: "text",
    value: "",
    required: false,
    errors: @["Required", "Too short"],
    attrs: @[],
    options: @[]
  )
  let node = renderFormField(field)
  let html = renderToHtml(node)
  doAssert html.contains("Required")
  doAssert html.contains("Too short")
  doAssert html.contains("field-error")
  echo "PASS: render field with errors"

proc testFieldCustomAttrs() =
  let field = FormField(
    name: "age",
    label: "Age",
    kind: "number",
    value: "25",
    required: false,
    errors: @[],
    attrs: @[("min", "18"), ("max", "99")],
    options: @[]
  )
  let node = renderFormField(field)
  let html = renderToHtml(node)
  doAssert html.contains("min=\"18\"")
  doAssert html.contains("max=\"99\"")
  echo "PASS: field custom attrs"

proc testFormMultipleFields() =
  let form = newFormDef("/survey")
  form.addField("q1", "Question 1", kind = "textarea")
  form.addField("q2", "Question 2", kind = "select", options = @[("a", "A"), ("b", "B")])
  form.addField("q3", "Question 3", kind = "checkbox", value = "on")
  let html = renderToHtml(renderForm(form))
  doAssert html.contains("<textarea")
  doAssert html.contains("<select")
  doAssert html.contains("<option")
  doAssert html.contains("type=\"checkbox\"")
  echo "PASS: form multiple field kinds"

when isMainModule:
  testNewFormDef()
  testAddField()
  testRenderTextField()
  testRenderTextareaField()
  testRenderSelectField()
  testRenderCheckboxField()
  testRenderCheckboxUnchecked()
  testRenderForm()
  testSetFieldError()
  testRenderFieldWithErrors()
  testFieldCustomAttrs()
  testFormMultipleFields()
  echo ""
  echo "All form tests passed!"

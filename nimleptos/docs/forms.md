# Forms & Validation

Declarative form rendering integrated with NimMax's validation system.

---

## FormDef

```nim
let form = newFormDef("/submit")
form.addField("name", "Your Name", required = true)
form.addField("email", "Email", kind = "email", required = true)
form.addField("bio", "Biography", kind = "textarea")
form.addField("country", "Country", kind = "select",
  options = @[("us", "USA"), ("bg", "Bulgaria"), ("uk", "UK")])
form.addField("agree", "I agree", kind = "checkbox")
form.addField("age", "Age", kind = "number")
form.addField("password", "Password", kind = "password")
```

### Field Types

| Kind | Renders As | Notes |
|------|-----------|-------|
| `text` (default) | `<input type="text">` | Default |
| `email` | `<input type="email">` | |
| `password` | `<input type="password">` | |
| `number` | `<input type="number">` | |
| `textarea` | `<textarea>` | Multi-line text |
| `select` | `<select>` with `<option>` | Requires `options` parameter |
| `checkbox` | `<input type="checkbox">` | `value="true"` → checked |

### Select Options

For `select` fields, pass `options` as `seq[(value, label)]`:

```nim
form.addField("role", "Role", kind = "select",
  options = @[
    ("admin", "Administrator"),
    ("editor", "Editor"),
    ("viewer", "Viewer")
  ])
```

### Checkbox

Checkbox fields use `value` to determine checked state: `"true"`, `"on"`, or `"1"` → checked.

---

## Rendering

```nim
let html = renderForm(form)   # returns HtmlNode
let rendered = renderToHtml(html)  # returns string
```

Each field renders as:
```html
<div class="form-field">
  <label for="name">Your Name</label>
  <input type="text" name="name" id="name" required="required">
  <span class="field-error">Error message</span>  <!-- if errors -->
</div>
```

---

## Validation

```nim
let v = newNimLeptosValidator()
v.addRequired("email", "Email")
v.addEmail("email", "Email")
v.addMinLen("password", 8, "Password")
v.addMaxLen("name", 100, "Name")
v.addIntRange("age", 0, 150, "Age")
```

### Validation Flow

```nim
app.post("/register", proc(ctx: Context) {.async.} =
  let form = newFormDef("/register")
  form.addField("email", "Email", kind = "email")
  form.addField("password", "Password", kind = "password")

  populateForm(form, ctx)  # fill values from POST data

  let values = getFieldValues(ctx, form)
  if not v.validateFormFields(form, values):
    ctx.render(renderForm(form), app, "Register")
    return

  # Process valid form...
  ctx.redirect("/welcome")
)
```

### Manual Error Setting

```nim
form.setFieldError("email", "Email already taken")
if form.hasErrors():
  # Re-render form with errors
```

---

## API Reference

| Proc | Description |
|------|-------------|
| `newFormDef(action, httpMethod)` | Create form definition |
| `addField(name, label, kind, value, required, attrs, options)` | Add field |
| `renderFormField(field)` | Render single field to HtmlNode |
| `renderForm(form)` | Render complete form |
| `getFieldValues(ctx, form)` | Extract POST values |
| `populateForm(form, ctx)` | Fill form from POST data |
| `setFieldError(form, fieldName, error)` | Add error to field |
| `hasErrors(form)` | Check if form has errors |

---

## TableRef Workaround

`forms/table_helper.nim` works around a nimmax bug where `TableRef[string, string]` operations cause infinite recursion. Uses `newFormData`, `lookupValue`, `formDataLen` helpers.

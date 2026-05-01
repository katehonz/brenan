# Forms & Validation

NimLeptos provides declarative form rendering and integration with NimMax's validation system.

## Form Definition

```nim
import nimleptos/forms/form

let form = newFormDef("/register")
form.addField("name", "Full Name", required = true)
form.addField("email", "Email Address", kind = "email", required = true)
form.addField("age", "Age", kind = "number")
form.addField("password", "Password", kind = "password", required = true)
```

### FormDef

| Proc | Description |
|------|-------------|
| `newFormDef(action, httpMethod)` | Creates a form with action URL and method |
| `addField(name, label, kind, value, required, attrs)` | Adds a form field |
| `renderForm(form)` | Renders the form as `HtmlNode` |
| `renderFormField(field)` | Renders a single field |
| `getFieldValues(ctx, form)` | Extracts POST values as `seq[(string, string)]` |
| `populateForm(form, ctx)` | Fills field values from POST data |
| `setFieldError(form, field, error)` | Adds an error to a field |
| `hasErrors(form)` | Returns true if any field has errors |

### Field Types

The `kind` parameter maps to HTML input types:

```nim
form.addField("name", "Name", kind = "text")
form.addField("email", "Email", kind = "email")
form.addField("age", "Age", kind = "number")
form.addField("password", "Password", kind = "password")
form.addField("bio", "Bio", kind = "textarea")
form.addField("country", "Country", kind = "select")
form.addField("agree", "I agree", kind = "checkbox")
```

### Custom Attributes

```nim
form.addField("phone", "Phone",
  kind = "tel",
  attrs = @[("pattern", "[0-9]+"), ("placeholder", "+359...")]
)
```

## Rendering Forms

```nim
let html = renderForm(form)
echo renderToHtml(html)
```

Output:
```html
<div class="form-field">
  <label for="name">Full Name</label>
  <input type="text" name="name" id="name" required="required">
</div>
<div class="form-field">
  <label for="email">Email Address</label>
  <input type="email" name="email" id="email" required="required">
</div>
...
<button type="submit">Submit</button>
```

### With Errors

After validation fails, fields display errors:

```html
<div class="form-field">
  <label for="email">Email</label>
  <input type="email" name="email" id="email">
  <span class="field-error">Must be a valid email address</span>
</div>
```

## Validation

NimLeptos wraps NimMax's `FormValidator`:

```nim
import nimleptos/forms/validation

let v = newNimLeptosValidator()
v.addRequired("name", "Name")
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
  form.addField("name", "Name")
  form.addField("email", "Email")
  form.addField("password", "Password")

  let values = getFieldValues(ctx, form)

  if not v.validateFormFields(form, values):
    # Re-render form with errors
    let html = renderForm(form)
    ctx.render(html, app, "Register - Error")
    return

  # Success
  ctx.redirect("/welcome")
)
```

### Available Validators

| Validator | Description |
|-----------|-------------|
| `addRequired(field, label)` | Field must not be empty |
| `addEmail(field, label)` | Must be valid email |
| `addMinLen(field, n, label)` | Minimum string length |
| `addMaxLen(field, n, label)` | Maximum string length |
| `addIntRange(field, min, max, label)` | Integer in range |

### Raw NimMax Validators

Access all NimMax validators directly:

```nim
import nimmax/validater

v.addRule("url", isUrl())
v.addRule("flag", isBool())
v.addRule("code", matchPattern(r"^[A-Z]{3}$"))
v.addRule("role", oneOf(@["admin", "user", "guest"]))
v.addRule("confirm", equals(passwordValue))
```

## Complete Example

```nim
import nimleptos
import nimmax

let v = newNimLeptosValidator()
v.addRequired("username", "Username")
v.addMinLen("username", 3, "Username")
v.addRequired("email", "Email")
v.addEmail("email", "Email")
v.addRequired("password", "Password")
v.addMinLen("password", 8, "Password")

proc registerForm(): HtmlNode =
  let form = newFormDef("/register")
  form.addField("username", "Username", required = true)
  form.addField("email", "Email", kind = "email", required = true)
  form.addField("password", "Password", kind = "password", required = true)
  renderForm(form)

proc main() =
  let app = newNimLeptosApp(title = "Register")

  app.get("/register", proc(ctx: Context) {.async.} =
    ctx.render(registerForm(), app, "Register")
  )

  app.post("/register", proc(ctx: Context) {.async.} =
    let form = newFormDef("/register")
    form.addField("username", "Username")
    form.addField("email", "Email")
    form.addField("password", "Password")

    let values = getFieldValues(ctx, form)

    if not v.validateFormFields(form, values):
      ctx.render(renderForm(form), app, "Register - Error")
      return

    ctx.redirect("/login")
  )

  app.run()

main()
```

## TableRef Workaround

NimLeptos uses `forms/table_helper.nim` to work around a nimmax bug where `TableRef[string, string]` operations (`[]`, `[]=`, `hasKey`) cause infinite recursion. The `newFormData` proc creates the table in a scope where nimmax's overrides are not active.

This is transparent to users — just use `getFieldValues` and `validateFormFields`.

# NimMax Integration

NimLeptos uses [NimMax](https://github.com/katehonz/nimmax) as its HTTP backend.

---

## NimLeptosApp

Wraps NimMax's `Application` with SSR context:

```nim
let app = newNimLeptosApp(
  title = "My App",
  clientScript = "/app.js",
  clientStyle = "/app.css"
)
```

### Constructor Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `settings` | `newSettings()` | NimMax server settings |
| `title` | `"NimLeptos App"` | Default page title |
| `clientScript` | `""` | Client JS bundle path |
| `clientStyle` | `""` | Client CSS path |

---

## Routing

```nim
app.get("/about", aboutHandler)
app.post("/submit", submitHandler)
app.put("/api/users/{id}", updateUser)
app.delete("/api/users/{id}", deleteUser)
app.patch("/api/users/{id}", patchUser)
app.all("/catch-all", handler)
```

### Route Components

```nim
app.route("/home", homePage, layout = mainLayout())
```

### Groups

```nim
let api = app.newGroup("/api/v1")
api.get("/users", listUsers)
api.post("/users", createUser)
```

---

## Rendering

| Proc | Description |
|------|-------------|
| `ctx.render(node, app, title)` | Full page with hydration markers. Creates a **fresh SSRContext per request** (thread-safe). Reads `__title__`, `__client_script__`, `__client_style__` from context. |
| `ctx.render(node, title)` | Full page via low-level adapter (also thread-safe, but ignores middleware context values). |
| `ctx.renderFragment(node)` | Raw HTML, no wrapper |
| `ctx.json(data)` | JSON response |
| `ctx.html(str)` | Raw HTML string |

---

## Middleware

NimLeptos provides functional middleware that integrates with the SSR pipeline:

### titleMiddleware

Sets a default page title via context. `render(ctx, node, app)` reads this value:

```nim
app.use(titleMiddleware("My App"))
```

### clientAssetsMiddleware

Injects client-side scripts and styles into the rendered page via context:

```nim
app.use(clientAssetsMiddleware(script = "/app.js", style = "/app.css"))
```

### hydrationMiddleware

Sets `__hydration_enabled__` context flag (available for custom handlers to check):

```nim
app.use(hydrationMiddleware())
```

### NimMax Middleware

All NimMax middleware works directly:

```nim
import nimmax/middleware/logging
import nimmax/middleware/cors

app.use(loggingMiddleware())
app.use(corsMiddleware(allowOrigin = "*"))
```

---

## Context Data

### Path Parameters

```nim
let id = ctx.getPathParam("id")
let idInt = ctx.getInt("id")
```

### Query Parameters

```nim
let page = ctx.getQueryParam("page", "1")
```

### POST Data

```nim
let email = ctx.getPostParam("email")
```

### Cookies

```nim
let session = ctx.getCookie("session_id")
ctx.setCookie("session_id", "abc123")
```

---

## Sessions

```nim
import nimmax/middleware/session

app.use(sessionMiddleware("secret-key"))

# In handler:
ctx.setSession("user_id", "42")
let userId = ctx.getSession("user_id")
```

---

## Error Handling

```nim
app.registerErrorHandler(Http404, proc(ctx: Context) {.async.} =
  ctx.html("<h1>404 Not Found</h1>")
)
```

---

## Testing

```nim
import nimmax/mocking

let testApp = mockApp()
testApp.get("/", handler)
let ctx = testApp.runOnce(HttpGet, "/")
doAssert ctx.response.code == Http200
```

---

## Static Files

```nim
import nimmax/middleware/static

app.use(staticFiles("public"))
```

---

## Lifecycle Events

```nim
app.onStart(proc() =
  echo "Server starting..."
)

app.onStop(proc() =
  echo "Server stopping..."
)
```

---

## Running

```nim
app.run(address = "0.0.0.0", port = Port(8080), debug = true)
```

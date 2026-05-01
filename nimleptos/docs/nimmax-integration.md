# NimMax Integration

NimLeptos uses [NimMax](https://github.com/katehonz/nimmax) as its HTTP backend. This document covers how the two frameworks connect.

## Quick Start

```nim
import nimleptos
import nimmax

proc main() =
  let app = newNimLeptosApp(
    settings = newSettings(address = "0.0.0.0", port = Port(8080)),
    title = "My App"
  )

  app.use(loggingMiddleware())

  app.get("/", proc(ctx: Context) {.async.} =
    let node = elDiv([("class", "app")],
      elH1([], text("Hello NimLeptos!"))
    )
    ctx.render(node, app, "Home")
  )

  app.run()

main()
```

## NimLeptosApp

`NimLeptosApp` wraps NimMax's `Application` and adds SSR context:

```nim
let app = newNimLeptosApp(
  settings = newSettings(port = Port(3000)),
  title = "Default Title",
  clientScript = "/assets/app.js",
  clientStyle = "/assets/app.css"
)
```

### Routing

All NimMax routing features are available:

```nim
# Basic routes
app.get("/about", handler)
app.post("/submit", handler)
app.put("/update", handler)
app.delete("/remove", handler)

# Route groups
let api = app.newGroup("/api/v1")
api.get("/users", listUsers)
api.post("/users", createUser)
api.get("/users/{id}", getUser)

# Named routes
app.get("/user/{id}", handler, name = "user_detail")
let url = ctx.urlFor("user_detail", @[("id", "42")])
```

### Middleware

Use NimMax middleware directly:

```nim
import nimmax/middlewares

app.use(loggingMiddleware())
app.use(corsMiddleware())
app.use(csrfMiddleware())
app.use(sessionMiddleware(backend = sbMemory))
app.use(rateLimitMiddleware(limiter))
```

## Rendering

### Full Page Render

```nim
proc handler(ctx: Context) {.async.} =
  let node = elDiv([], text("Hello"))
  ctx.render(node, app, "Page Title")
```

### Fragment Render (no hydration)

```nim
proc handler(ctx: Context) {.async.} =
  let node = elSpan([("id", "status")], text("Updated"))
  ctx.renderFragment(node)  # sends raw HTML, no wrapper
```

### JSON Response

```nim
proc apiHandler(ctx: Context) {.async.} =
  ctx.json(%*{"status": "ok"})
```

### HTML String Response

```nim
proc handler(ctx: Context) {.async.} =
  ctx.html("<h1>Raw HTML</h1>")
```

## Route Components

Define components that return `HtmlNode`:

```nim
proc homePage(ctx: Context): Future[HtmlNode] {.gcsafe.} =
  result = newFuture[HtmlNode]()
  complete(result, elDiv([("class", "home")],
    elH1([], text("Welcome")),
    elP([], text("This is the home page"))
  ))
```

Use with `route`:

```nim
app.route("/", homePage)

# With layout
app.route("/dashboard", dashboardPage, layout = mainLayout())
```

## Context Data

NimMax's `Context` carries request data:

```nim
proc handler(ctx: Context) {.async.} =
  let id = ctx.getPathParam("id")           # /user/{id}
  let page = ctx.getQueryParam("page")      # ?page=2
  let name = ctx.getPostParam("name")       # form POST
  let token = ctx.getCookie("session")      # cookie
  let auth = ctx.request.headers["Authorization"]  # header
```

### Typed Parameters

```nim
let userId = ctx.getInt("id")         # Option[int]
let price = ctx.getFloat("price")     # Option[float]
let active = ctx.getBool("active")    # Option[bool]
```

## Sessions

```nim
app.use(sessionMiddleware(backend = sbMemory, maxAge = 86400))

proc login(ctx: Context) {.async.} =
  ctx.session["user"] = "alice"
  ctx.session["role"] = "admin"

proc profile(ctx: Context) {.async.} =
  let user = ctx.session["user"]
  ctx.render(elDiv([], text("Hello, " & user)), app)
```

## Error Handling

```nim
app.registerErrorHandler(Http404, proc(ctx: Context) {.async.} =
  ctx.render(elDiv([], text("404 Not Found")), app, "404")
)

app.registerErrorHandler(Http500, proc(ctx: Context) {.async.} =
  ctx.render(elDiv([], text("Server Error")), app, "500")
)
```

## Testing with NimMax Mocking

```nim
import nimmax/mocking

let app = mockApp()
app.get("/", proc(ctx: Context) {.async.} =
  ctx.render(elDiv([], text("Hello")))
)

let ctx = app.runOnce(HttpGet, "/")
assert ctx.response.code == Http200
assert ctx.response.body.contains("Hello")
```

## Startup/Shutdown Events

```nim
app.onStart(proc() =
  echo "Server starting..."
)

app.onStop(proc() =
  echo "Server shutting down..."
)
```

## Static Files

```nim
app.use(staticFileMiddleware("public"))
```

## NimMax Modules Used

| Module | Purpose |
|--------|---------|
| `nimmax` | Core types, routing, context, application |
| `nimmax/middlewares` | CSRF, CORS, sessions, logging, compression |
| `nimmax/validater` | Form validation (15+ validators) |
| `nimmax/websocket` | WebSocket support |
| `nimmax/mocking` | Testing utilities |
| `nimmax/security` | Signing, password hashing |
| `nimmax/cache` | LRU/LFU caching |
| `nimmax/configure` | .env, JSON config |

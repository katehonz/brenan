# Routing & Layouts

NimLeptos provides declarative route components and layout composition on top of NimMax's routing engine.

## Basic Routing

```nim
import nimleptos
import nimmax

# Direct handler approach
app.get("/", proc(ctx: Context) {.async.} =
  let node = elDiv([], text("Home"))
  ctx.render(node, app)
)
```

## Route Components

A route component is a proc that returns `HtmlNode`:

```nim
proc homePage(ctx: Context): Future[HtmlNode] {.gcsafe.} =
  result = newFuture[HtmlNode]()
  complete(result,
    elDiv([("class", "home")],
      elH1([], text("Welcome")),
      elP([], text("Hello, NimLeptos!"))
    )
  )
```

Register it with `route`:

```nim
app.route("/", homePage)
```

## Route with Layout

Layouts wrap page content in a common structure:

```nim
proc dashboardPage(ctx: Context): Future[HtmlNode] {.gcsafe.} =
  result = newFuture[HtmlNode]()
  complete(result, elDiv([], text("Dashboard content")))

let lyt: LayoutComponent = proc(ctx: Context, children: HtmlNode): Future[HtmlNode] {.gcsafe.} =
  result = newFuture[HtmlNode]()
  complete(result,
    elDiv([("class", "layout")],
      elNav([], text("Navigation")),
      elDiv([("class", "content")], children),
      elFooter([], text("Footer"))
    )
  )

app.route("/dashboard", dashboardPage, layout = lyt)
```

## Built-in Layouts

### Main Layout

```nim
let nav = elNav([], text("Nav bar"))
let footer = elFooter([], text("Footer"))
let lyt = mainLayout(navHtml = nav, footerHtml = footer)
```

### Sidebar Layout

```nim
let sidebar = elDiv([], text("Sidebar"))
let lyt = sidebarLayout(sidebar)
```

Result structure:
```html
<div class="sidebar-layout">
  <div class="sidebar">Sidebar</div>
  <div class="main-content">{page content}</div>
</div>
```

## LayoutComponent Type

```nim
type
  LayoutComponent* = proc(ctx: Context, children: HtmlNode): Future[HtmlNode] {.gcsafe.}
```

A layout receives the NimMax `Context` and the page's `HtmlNode` as children, and returns a wrapped `HtmlNode`.

## Route Groups

Group routes with shared prefix and middleware:

```nim
let api = app.newGroup("/api/v1")
api.get("/users", listUsers)
api.post("/users", createUser)
api.get("/users/{id}", getUser)
```

With middleware:

```nim
let admin = app.newGroup("/admin", middlewares = @[authMiddleware()])
admin.get("/dashboard", adminDashboard)
```

## Named Routes

```nim
app.get("/user/{id}", userHandler, name = "user_detail")

# Build URL
let url = ctx.urlFor("user_detail", @[("id", "42")])
# Returns: "/user/42"
```

## Route Parameters

```nim
proc userHandler(ctx: Context) {.async.} =
  let id = ctx.getPathParam("id")
  let node = elDiv([], text("User: " & id))
  ctx.render(node, app)
```

### Typed Parameters

```nim
proc productHandler(ctx: Context) {.async.} =
  let id = ctx.getInt("id")           # Option[int]
  let price = ctx.getFloat("price")   # Option[float]

  if id.isSome:
    ctx.render(elDiv([], text("Product " & $id.get)), app)
  else:
    ctx.abortRequest(Http400, "Invalid ID")
```

## POST Routes

```nim
app.routePost("/submit", proc(ctx: Context): Future[HtmlNode] {.gcsafe.} =
  result = newFuture[HtmlNode]()
  let name = ctx.getPostParam("name")
  complete(result, elDiv([], text("Hello, " & name)))
)
```

## HTTP Methods

| Proc | Method |
|------|--------|
| `app.get` | GET |
| `app.post` | POST |
| `app.put` | PUT |
| `app.delete` | DELETE |
| `app.patch` | PATCH |
| `app.all` | All methods |

## Wildcard Routes

```nim
app.get("/files/*", proc(ctx: Context) {.async.} =
  let filePath = ctx.getPathParam("*")
  ctx.text("File: " & filePath)
)
```

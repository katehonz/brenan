# Routing & Layouts

Declarative route components and layout composition on top of NimMax's routing.

---

## Route Components

A route component is a proc returning `Future[HtmlNode]`:

```nim
proc homePage(ctx: Context): Future[HtmlNode] {.gcsafe.} =
  result = newFuture[HtmlNode]()
  complete(result, elDiv([], text("Welcome")))

app.route("/home", homePage)
```

### With Layout

```nim
app.route("/dashboard", dashboardPage, layout = mainLayout())
```

### POST Routes

```nim
app.routePost("/login", loginHandler)
```

---

## Layouts

`LayoutComponent = proc(ctx: Context, children: HtmlNode): Future[HtmlNode]`

Layouts wrap page content with navigation, sidebars, etc.

### Built-in Layouts

#### html5Layout

Generates a proper HTML5 document structure:

```nim
app.route("/", homePage, layout = html5Layout(
  headNodes = @[
    elMeta([("charset", "UTF-8")]),
    elLink([("rel", "stylesheet"), ("href", "/style.css")])
  ],
  bodyClass = "dark-theme"
))
```

Output:
```html
<html>
  <head>
    <meta charset="UTF-8">
    <link rel="stylesheet" href="/style.css">
  </head>
  <body class="dark-theme">
    <!-- page content -->
  </body>
</html>
```

#### mainLayout

Wraps content with optional nav and footer:

```nim
let nav = elNav([], elA([("/"), text("Home")]))
let footer = elFooter([], text("2026"))
app.route("/about", aboutPage, layout = mainLayout(nav, footer))
```

Output: `<div class="layout"><nav>...</nav><!-- content --><footer>...</footer></div>`

#### sidebarLayout

Two-column layout with sidebar:

```nim
let sidebar = elDiv([], text("Sidebar"))
app.route("/settings", settingsPage, layout = sidebarLayout(sidebar))
```

Output: `<div class="sidebar-layout"><div class="sidebar">...</div><div class="main-content">...</div></div>`

---

## Route Groups

Groups share a URL prefix and optional middleware:

```nim
let api = app.newGroup("/api/v1")
api.get("/users", listUsers)
api.get("/users/{id}", getUser)
api.post("/users", createUser)
```

---

## Named Routes

```nim
app.route("/users/{id}", getUser, name = "user.show")
let url = ctx.urlFor("user.show", {"id": "42"})
# → "/users/42"
```

---

## HTTP Methods

| Proc | Method |
|------|--------|
| `app.get(path, handler)` | GET |
| `app.post(path, handler)` | POST |
| `app.put(path, handler)` | PUT |
| `app.delete(path, handler)` | DELETE |
| `app.patch(path, handler)` | PATCH |
| `app.all(path, handler)` | All methods |

---

## Custom Layouts

```nim
proc myLayout*(headNodes: seq[HtmlNode] = @[]): LayoutComponent =
  result = proc(ctx: Context, children: HtmlNode): Future[HtmlNode] {.gcsafe.} =
    result = newFuture[HtmlNode]()
    complete(result, elHtml([],
      elHead([], headNodes),
      elBody([("class", "my-app")],
        elHeader([], text("Header")),
        children,
        elFooter([], text("Footer"))
      )
    ))
```

# Server-Side Rendering (SSR)

Renders HTML on the server with hydration markers for client-side interactivity.

---

## SSRContext

```nim
let ctx = newSSRContext()
```

Tracks hydration IDs, scripts, and styles for the current render.

### Adding Assets

```nim
ctx.addScript("/app.js")
ctx.addStyle("/app.css")
```

---

## Rendering

### Full Page

```nim
let body = elDiv([("class", "app")], text("Hello"))
let html = renderFullPage(ctx, body, "My Page")
```

Output:
```html
<!DOCTYPE html>
<html>
<head>
  <title>My Page</title>
  <script type="application/json" id="__nimleptos_data__">{"nextId":5}</script>
</head>
<body>
  <div class="app" data-nl-id="0">Hello</div>
</body>
</html>
```

### With Hydration IDs

```nim
let root = elDiv([], elSpan([], text("child")))
discard injectHydrationIds(root, ctx)
# root gets data-nl-id="0", child span gets data-nl-id="1"
```

### Render with Hydration

```nim
let html = renderWithHydration(root, ctx)
# Same as renderToHtml but with data-nl-id attributes injected
```

### Full Page with Hydration

```nim
let html = renderPageWithHydration(ctx, body, "Title")
# Combines injectHydrationIds + renderFullPage
```

### Hydration Script

```nim
let script = generateHydrationScript()
# Returns JS that assigns __nimleptos_id to hydrated nodes
```

---

## Integration with NimLeptosApp

```nim
let app = newNimLeptosApp(title = "My App")

app.get("/", proc(ctx: Context) {.async.} =
  let node = elDiv([], text("Hello"))
  ctx.render(node, app, "Home")
)
```

`ctx.render(node, app, title)` internally:
1. Creates SSRContext
2. Injects hydration IDs
3. Renders full HTML page
4. Sends HTML response

### Fragment Rendering

```nim
app.get("/fragment", proc(ctx: Context) {.async.} =
  let node = elSpan([], text("Partial"))
  ctx.renderFragment(node)  # No DOCTYPE/head, just the HTML
)
```

---

## Hydration Data

The `<script id="__nimleptos_data__">` element contains JSON with:
- `nextId` — the next hydration ID to assign

Client-side `hydration_client.nim` reads this on load to track hydrated nodes.

---

## Performance

- No virtual DOM overhead
- Hydration IDs add minimal bytes per element
- Static content can skip hydration with `renderToHtml` or `renderFragment`
- Streaming support via NimMax's async response

# Server-Side Rendering (SSR)

NimLeptos renders HTML on the server and injects hydration markers so the client can attach interactivity without re-rendering.

## SSRContext

The `SSRContext` tracks hydration IDs, scripts, and styles for a render pass:

```nim
import nimleptos/ssr/renderer

let ctx = newSSRContext()
ctx.addScript("/assets/app.js")
ctx.addStyle("body { margin: 0; }")
```

### Rendering a Full Page

```nim
let body = elDiv([("class", "app")],
  elH1([], text("Hello")),
  elP([], text("World"))
)

let html = renderFullPage(ctx, body, "My Page")
# Returns: <!DOCTYPE html><html><head><title>My Page</title>...</head><body>...</body></html>
```

### Rendering with Hydration IDs

```nim
import nimleptos/ssr/hydration

let ctx = newSSRContext()
let root = elDiv([("class", "app")],
  elH1([], text("Title")),
  elP([], text("Content"))
)

let html = renderWithHydration(root, ctx)
# Each element gets data-nl-id="N" attributes
# <div class="app" data-nl-id="0"><h1 data-nl-id="1">Title</h1><p data-nl-id="2">Content</p></div>
```

### Injecting Hydration IDs Manually

```nim
let ctx = newSSRContext()
let root = elDiv([], elSpan([], text("child")))
discard injectHydrationIds(root, ctx)

echo ctx.nextId  # 2 (root=0, span=1)
```

## SSRContext API

| Proc | Description |
|------|-------------|
| `newSSRContext()` | Creates a new SSR context |
| `nextMarkerId(ctx)` | Returns and increments the next hydration ID |
| `addMarker(ctx, marker)` | Registers a hydration marker |
| `addScript(ctx, url)` | Adds a `<script>` tag to the page |
| `addStyle(ctx, css)` | Adds a `<style>` tag to the page |
| `renderHead(ctx, title)` | Renders `<head>` with title, styles |
| `renderHydrationData(ctx)` | Renders `__nimleptos_data__` JSON + scripts |
| `renderFullPage(ctx, body, title)` | Renders complete HTML page |
| `renderPageWithHydration(ctx, body, title)` | Injects IDs then renders full page |

## Hydration Data

The SSR renderer injects a JSON blob that the client reads on load:

```html
<script type="application/json" id="__nimleptos_data__">{"nextId":8}</script>
```

The client reads this to know how many hydration markers exist and to restore state.

## Integration with NimMax

```nim
import nimleptos
import nimmax

proc handler(ctx: Context) {.async.} =
  let node = elDiv([], text("Hello"))
  ctx.render(node, title = "My Page")  # renders full page with hydration
```

The `render` proc on NimMax `Context` creates an `SSRContext`, injects hydration IDs, and sends the HTML response.

## Performance Notes

- SSR renders the full HTML string on the server — no virtual DOM overhead
- Hydration IDs add minimal bytes (`data-nl-id="N"`)
- The `__nimleptos_data__` JSON is typically < 100 bytes
- Static content (no signals) can skip hydration IDs with `renderToHtml`

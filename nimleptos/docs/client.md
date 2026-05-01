# Client-Side Hydration

When compiling to JavaScript (`nim js`), NimLeptos can hydrate server-rendered HTML by attaching event handlers and restoring reactive state without re-rendering the DOM.

## How Hydration Works

1. Server renders HTML with `data-nl-id` attributes on each element
2. Server injects `<script id="__nimleptos_data__">` with state JSON
3. Client JS loads, reads `data-nl-id` attributes, and attaches handlers
4. No full re-render — the existing DOM is reused

## Client Modules

### dom_interop

Low-level DOM access via Nim's `jsffi`:

```nim
when defined(js):
  import nimleptos/client/dom_interop

  let el = getElementById("my-div")
  el.addEventListener("click", proc(e: Event) =
    echo "clicked!"
  )
  el.setInnerHtml("<span>Updated</span>")
```

| Proc | Description |
|------|-------------|
| `getElementById(id)` | Find element by ID |
| `querySelector(sel)` | CSS selector (first match) |
| `querySelectorAll(sel)` | CSS selector (all matches) |
| `addEventListener(el, event, handler)` | Bind event |
| `createElement(tag)` | Create new element |
| `createTextNode(text)` | Create text node |
| `appendChild(parent, child)` | Append child |
| `removeChild(parent, child)` | Remove child |
| `setInnerHtml(el, html)` | Set innerHTML |
| `getInnerHtml(el)` | Get innerHTML |
| `setAttribute(el, name, value)` | Set attribute |
| `getAttribute(el, name)` | Get attribute |
| `setStyle(el, prop, value)` | Set CSS property |

### hydration_client

Hydrates server-rendered HTML:

```nim
when defined(js):
  import nimleptos/client/hydration_client

  # Manual hydration
  let state = loadHydrationData()
  let nodes = hydrateNodes()
  echo "Hydrated " & $nodes.len & " nodes"

  # Auto-hydrate on DOMContentLoaded
  initHydration()
```

| Proc | Description |
|------|-------------|
| `loadHydrationData()` | Reads `__nimleptos_data__` JSON |
| `hydrateNodes()` | Finds all `[data-nl-id]` elements, marks hydrated |
| `hydrateApp()` | Full hydration: load data + hydrate nodes |
| `initHydration()` | Auto-hydrate on DOMContentLoaded |

### event_handlers

Binds events to hydrated elements:

```nim
when defined(js):
  import nimleptos/client/event_handlers

  # Register bindings
  bindClick("#increment-btn", proc(e: Event) =
    echo "Increment!"
  )

  bindSubmit("#my-form", proc(e: Event) =
    e.preventDefault()
    echo "Form submitted"
  )

  bindInput("#search", proc(e: Event) =
    echo "Search: " & $e.target.value
  )

  # Apply all bindings after DOM is ready
  initEventHandlers()
```

| Proc | Description |
|------|-------------|
| `bindEvent(selector, event, handler)` | Generic event binding |
| `bindClick(selector, handler)` | Shorthand for click |
| `bindSubmit(selector, handler)` | Shorthand for submit |
| `bindInput(selector, handler)` | Shorthand for input |
| `applyBindings()` | Apply all registered bindings |
| `initEventHandlers()` | Hydrate + apply bindings on DOMContentLoaded |

## Compilation

### Server (native)

```bash
nim c -r src/myapp.nim
```

### Client (JavaScript)

```bash
nim js -o:public/app.js src/myapp_client.nim
```

### Combined Build

```nim
# src/myapp.nim (server)
import nimleptos
import nimmax

proc main() =
  let app = newNimLeptosApp(clientScript = "/assets/app.js")
  app.get("/", proc(ctx: Context) {.async.} =
    ctx.render(elDiv([("id", "root")], text("Hello")), app)
  )
  app.run()

main()
```

```nim
# src/myapp_client.nim (client)
when defined(js):
  import nimleptos/client/event_handlers

  bindClick("#root", proc(e: Event) =
    echo "Root clicked!"
  )

  initEventHandlers()
```

## Progressive Enhancement

NimLeptos supports progressive enhancement — the page works without JavaScript:

1. **Without JS**: Server-rendered HTML is fully functional (forms submit normally)
2. **With JS**: Client hydration adds interactivity (AJAX, live updates)

```nim
# Server renders a form that works without JS
let form = elForm([("action", "/submit"), ("method", "POST")],
  elInput([("type", "text"), ("name", "query")]),
  elButton([("type", "submit")], text("Search"))
)

# Client enhances it with JS
when defined(js):
  bindSubmit("form", proc(e: Event) =
    e.preventDefault()
    # AJAX submission instead
  )
```

## Limitations

- Client-side hydration requires `nim js` compilation
- `when defined(js)` guards are needed for client-only code
- Server and client must agree on `data-nl-id` numbering
- Event handlers are closures and cannot be serialized

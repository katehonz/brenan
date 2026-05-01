# Client-Side Rendering & Hydration

NimLeptos supports both **Server-Side Rendering (SSR)** with client hydration and **pure Client-Side Rendering (CSR)** via `nim js` compilation.

## Two Modes

| Mode | Compilation | Use Case |
|------|-------------|----------|
| **SSR + Hydration** | `nim c` (server) + `nim js` (client) | SEO, fast first paint, progressive enhancement |
| **Pure CSR** | `nim js` only | SPAs, dashboards, internal tools |

---

## Pure Client-Side Rendering (New)

Mount a reactive app directly to a DOM element:

```nim
import nimleptos/client/reactive_dom
import nimleptos/client/dom_interop
import nimleptos/reactive/signal
import std/dom

when defined(js):
  proc counterApp(): seq[DomElement] =
    let (count, setCount) = createSignal(0)

    let heading = createElement("h1")
    heading.textContent = "Counter"

    let display = createElement("p")
    let textEl = reactiveTextNode(proc(): string = "Count: " & $count())
    display.appendChild(textEl)

    let btnInc = createElement("button")
    btnInc.textContent = "+"
    btnInc.addEventListener("click", proc(e: Event) =
      setCount(count() + 1)
    )

    return @[heading, display, btnInc]

  mountReactiveApp("#app", counterApp)
```

```bash
nim js -p:src -o:app.js app.nim
```

### Mounting

| Proc | Description |
|------|-------------|
| `mountApp(selector, builder)` | Mount an `HtmlNode` tree to a DOM element |
| `mountReactiveApp(selector, builder)` | Mount reactive `DomElement`s directly |

### Reactive DOM Bindings

Fine-grained updates — only the changed text/attribute updates, no full re-render:

```nim
import nimleptos/client/reactive_dom
import nimleptos/reactive/signal
import std/dom

when defined(js):
  let (name, setName) = createSignal("Alice")
  let (active, setActive) = createSignal(true)

  let el = createElement("div")

  # Text updates automatically when `name` changes
  let textNode = reactiveTextNode(proc(): string = "Hello, " & name())
  el.appendChild(textNode)

  # Attribute updates automatically
  reactiveAttr(el, "data-user", proc(): string = name())

  # Class updates automatically
  reactiveClass(el, proc(): string =
    if active(): "user-card active" else: "user-card"
  )

  # Style updates automatically
  reactiveStyle(el, "opacity", proc(): string =
    if active(): "1.0" else: "0.5"
  )
```

| Proc | Description |
|------|-------------|
| `reactiveTextNode(getter)` | Text node bound to a `Getter[string]` |
| `reactiveAttr(el, name, getter)` | Attribute bound to a signal |
| `reactiveClass(el, getter)` | `class` attribute bound to a signal |
| `reactiveStyle(el, prop, getter)` | CSS property bound to a signal |
| `renderDomNode(node)` | Convert `HtmlNode` tree to real DOM elements |
| `clearChildren(el)` | Remove all child nodes |

---

## Hydration (SSR + Client)

When compiling to JavaScript (`nim js`), NimLeptos can hydrate server-rendered HTML by attaching event handlers and restoring reactive state without re-rendering the DOM.

### How Hydration Works

1. Server renders HTML with `data-nl-id` attributes on each element
2. Server injects `<script id="__nimleptos_data__">` with state JSON
3. Client JS loads, reads `data-nl-id` attributes, and attaches handlers
4. No full re-render — the existing DOM is reused

### Client Modules

#### dom_interop

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
| `setTextContent(el, text)` | Set textContent |
| `getTextContent(el)` | Get textContent |
| `setAttribute(el, name, value)` | Set attribute |
| `getAttribute(el, name)` | Get attribute |
| `setStyle(el, prop, value)` | Set CSS property |

#### hydration_client

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

#### event_handlers

Binds events to hydrated elements:

```nim
when defined(js):
  import nimleptos/client/event_handlers

  bindClick("#increment-btn", proc(e: Event) =
    echo "Increment!"
  )

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

---

## Compilation

### Server (native)

```bash
nim c -r src/myapp.nim
```

### Client (JavaScript)

```bash
nim js -o:public/app.js src/myapp_client.nim
```

### CSR Example Build

```bash
nim js -p:src -o:counter_client.js examples/counter_client.nim
```

---

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

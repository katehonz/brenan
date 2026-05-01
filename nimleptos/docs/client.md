# Client-Side Rendering & Hydration

NimLeptos supports both **Server-Side Rendering (SSR)** with client hydration and **pure Client-Side Rendering (CSR)** via `nim js` compilation.

---

## Two Modes

| Mode | Compilation | Use Case |
|------|-------------|----------|
| **SSR + Hydration** | `nim c` (server) + `nim js` (client) | SEO, fast first paint, progressive enhancement |
| **Pure CSR** | `nim js` only | SPAs, dashboards, internal tools |

---

## Pure Client-Side Rendering

### mountReactiveApp

Mount reactive DOM elements directly for fine-grained control:

```nim
when defined(js):
  proc counterApp(): seq[DomElement] =
    let (count, setCount) = createSignal(0)

    let display = createElement("p")
    let textEl = reactiveTextNode(proc(): string = "Count: " & $count())
    display.appendChild(textEl)

    let btn = createElement("button")
    btn.textContent = "+"
    btn.addEventListener("click", proc(e: Event) =
      setCount(count() + 1)
    )

    return @[display, btn]

  mountReactiveApp("#app", counterApp)
```

### mountApp

Mount an `HtmlNode` tree to the DOM (converts to real DOM elements):

```nim
when defined(js):
  proc app(): HtmlNode =
    buildHtml:
      el("div", class="app"):
        el("h1"): text("Hello")
        el("p"): text("World")

  mountApp("#app", app)
```

---

## Reactive DOM Bindings

| Proc | Description |
|------|-------------|
| `reactiveTextNode(getter)` | Text node that auto-updates from a `Getter[string]` signal |
| `reactiveAttr(el, name, getter)` | Attribute bound to a signal |
| `reactiveClass(el, getter)` | CSS class bound to a signal |
| `reactiveStyle(el, prop, getter)` | CSS property bound to a signal |
| `renderDomNode(node)` | Convert `HtmlNode` tree to real DOM elements |
| `clearChildren(el)` | Remove all child nodes |
| `mountApp(selector, builder, afterMount)` | Mount HtmlNode tree to DOM |
| `mountReactiveApp(selector, builder)` | Mount reactive DomElements |

### Example: Reactive Style

```nim
let (progress, setProgress) = createSignal(0)
let bar = createElement("div")
reactiveStyle(bar, "width", proc(): string = $progress() & "%")
```

---

## Hydration (SSR + Client)

Server renders HTML with `data-nl-id` attributes and injects `<script type="application/json" id="__nimleptos_data__">` with state JSON. Client JS reads these markers and attaches handlers without re-rendering.

### HydrationState

```nim
let state = hydrateApp()
# state.nextId — next hydration ID
# state.nodeCount — number of hydrated nodes
# state.hydrated — true after hydration completes
```

### onHydrate Callbacks

Register custom handlers that fire for each hydrated node:

```nim
import nimleptos/client/hydration_client

onHydrate(proc(node: DomElement, nlId: string) =
  echo "Hydrated node: " & nlId
  # Attach reactive bindings, event handlers, etc.
)
```

### attachEvent

Attach an event handler to a specific DOM element:

```nim
attachEvent(element, "click", proc(e: Event) =
  echo "Clicked!"
)
```

---

## Event Handlers

| Proc | Description |
|------|-------------|
| `bindEvent(selector, event, handler)` | Bind event to CSS selector |
| `bindClick(selector, handler)` | Shorthand for click |
| `bindSubmit(selector, handler)` | Shorthand for submit |
| `bindInput(selector, handler)` | Shorthand for input |
| `applyBindings()` | Apply all registered bindings |
| `initEventHandlers()` | Init hydration + bindings on DOMContentLoaded |

### EventHandler Type

```nim
type EventHandler* = proc(e: Event) {.closure.}
```

Same signature on both JS and native targets (native uses stub `Event` type).

---

## DOM Interop

Low-level DOM wrappers in `dom_interop.nim`:

| Proc | Wraps |
|------|-------|
| `getElementById(id)` | `document.getElementById` |
| `querySelector(selector)` | `document.querySelector` |
| `querySelectorAll(selector)` | `document.querySelectorAll` |
| `createElement(tag)` | `document.createElement` |
| `createTextNode(text)` | `document.createTextNode` |
| `appendChild(parent, child)` | `parent.appendChild` |
| `removeChild(parent, child)` | `parent.removeChild` |
| `setAttribute(el, name, value)` | `el.setAttribute` |
| `getAttribute(el, name)` | `el.getAttribute` |
| `addEventListener(el, event, handler)` | `el.addEventListener` |
| `setInnerHtml(el, html)` | `el.innerHTML = ...` |
| `getInnerHtml(el)` | `el.innerHTML` |
| `setTextContent(el, text)` | `el.textContent = ...` |
| `getTextContent(el)` | `el.textContent` |
| `setStyle(el, prop, value)` | `el.style.setProperty` |

---

## Compilation

```bash
# Compile client-side JS
nim js -p:src -o:app.js myapp.nim

# Or use nimble tasks
nimble client      # counter example
nimble timer       # reactive timer
nimble hybrid      # buildHtml + reactive DOM
nimble conditional # reactive if/else
```

---

## Progressive Enhancement

Pages work without JavaScript (server-rendered HTML submits normally) and gain interactivity when JS loads. The hydration system marks SSR-rendered nodes with `data-nl-id` and `data-nl-hydrated` attributes.

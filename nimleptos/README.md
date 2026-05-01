# NimLeptos

A full-stack reactive web framework for Nim, inspired by [Leptos](https://leptos.dev/) (Rust), powered by [NimMax](https://github.com/katehonz/nimmax).

[![Nim](https://img.shields.io/badge/Nim-%3E%3D2.0.0-FFE000?logo=nim&logoColor=white)](https://nim-lang.org/)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

## Features

- **Fine-Grained Reactivity** — Signals, Effects, Memos with automatic dependency tracking (no virtual DOM)
- **HTML Builder DSL** — Type-safe element construction with `elDiv`, `elP`, `text`, etc.
- **Server-Side Rendering** — Full HTML pages rendered on the server with hydration markers
- **NimMax Backend** — Routing, middleware, sessions, CSRF, CORS, validation, WebSocket, caching
- **Route Components** — Declarative `route()` with layout composition
- **Form Handling** — Declarative forms with 15+ validators from NimMax
- **WebSocket Reactivity** — Real-time signal synchronization between server and clients
- **Client Hydration** — `nim js` compilation for progressive enhancement
- **Client-Side Rendering** — Fine-grained reactive DOM updates with `mountApp` and `reactiveTextNode`
- **HTML DSL Macros** — `buildHtml` and `el()` macros for declarative DOM trees
- **Type-Safe** — Full Nim type system, `Option[T]` for safe parameter access

## Quick Start

### Prerequisites

- [Nim](https://nim-lang.org/) >= 2.0.0
- [Nimble](https://github.com/nim-lang/nimble) package manager

### Installation

```bash
nimble install
```

### Hello World

```nim
import nimleptos
import nimmax

proc main() =
  let app = newNimLeptosApp(title = "Hello")

  app.get("/", proc(ctx: Context) {.async.} =
    let node = elDiv([("class", "app")],
      elH1([], text("Hello, NimLeptos!")),
      elP([], text("Powered by NimMax"))
    )
    ctx.render(node, app, "Home")
  )

  app.run()

main()
```

```bash
nim c -r --threads:on -p:src myapp.nim
# Server starts on http://0.0.0.0:8080
```

## Reactivity

```nim
let (count, setCount) = createSignal(0)
let (doubled, _) = createMemo(proc(): int = count() * 2)

discard createEffect(proc() =
  echo "Count: " & $count() & ", Doubled: " & $doubled()
)

setCount(5)      # "Count: 5, Doubled: 10"

batch(proc() =
  setCount(10)
  setCount(20)
)                 # "Count: 20, Doubled: 40" (one re-run)
```

## HTML Builder

### Functional DSL

```nim
let page = elDiv([("class", "container")],
  elH1([], text("Welcome")),
  elP([("class", "subtitle")], text("Hello, NimLeptos!")),
  elButton([("id", "btn")], text("Click me"))
)

echo renderToHtml(page)
```

### Macro DSL (New)

```nim
import nimleptos/macros/html_macros

let page = buildHtml:
  el("div", class="container"):
    el("h1"): text("Welcome")
    el("p", class="subtitle"): text("Hello, NimLeptos!")

echo renderToHtml(page)
```

## Server-Side Rendering

```nim
let ctx = newSSRContext()
let body = elDiv([], text("Hello"))
let html = renderFullPage(ctx, body, "My Page")
# Returns full HTML with hydration markers
```

## Client-Side Rendering

Compile with `nim js` and mount directly to the DOM:

```nim
import nimleptos/client/reactive_dom
import nimleptos/client/dom_interop
import nimleptos/reactive/signal
import std/dom

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

```bash
nim js -p:src -o:app.js app.nim
```

### Reactive DOM Bindings

- `reactiveTextNode(getter)` — Text node that auto-updates from a signal
- `reactiveAttr(el, name, getter)` — Attribute bound to a signal
- `reactiveClass(el, getter)` — CSS class bound to a signal
- `reactiveStyle(el, prop, getter)` — Style property bound to a signal
- `mountApp(selector, builder)` — Mount an HtmlNode tree to the DOM
- `mountReactiveApp(selector, builder)` — Mount reactive DomElements directly

## Routing

```nim
# Direct handlers
app.get("/about", aboutHandler)
app.post("/submit", submitHandler)

# Route components with layouts
app.route("/dashboard", dashboardPage, layout = mainLayout())

# Groups
let api = app.newGroup("/api/v1")
api.get("/users", listUsers)
api.get("/users/{id}", getUser)
```

## Forms & Validation

```nim
let v = newNimLeptosValidator()
v.addRequired("email", "Email")
v.addEmail("email", "Email")
v.addMinLen("password", 8, "Password")

app.post("/register", proc(ctx: Context) {.async.} =
  let form = newFormDef("/register")
  form.addField("email", "Email", kind = "email")
  form.addField("password", "Password", kind = "password")

  let values = getFieldValues(ctx, form)
  if not v.validateFormFields(form, values):
    ctx.render(renderForm(form), app, "Register")
    return
  ctx.redirect("/welcome")
)
```

## WebSocket Realtime

```nim
import nimleptos/realtime/ws_handler

let (onlineCount, setOnlineCount) = createServerSignal("online", 0)

app.get("/ws", wsSignalRoute())

# Push updates to all connected clients
setOnlineCount(42)
```

## Project Structure

```
nimleptos/
├── src/nimleptos/
│   ├── reactive/          # Signal, Effect, Memo, Batch
│   ├── dom/               # HtmlNode, element builders
│   ├── macros/            # Compile-time HTML DSL
│   ├── ssr/               # Server-side rendering
│   ├── server/            # NimMax adapter
│   ├── routing/           # Route components, layouts
│   ├── forms/             # Form handling, validation
│   ├── realtime/          # WebSocket signals
│   └── client/            # JS hydration
├── tests/
├── examples/
├── docs/
└── nimleptos.nimble
```

## Documentation

| Document | Description |
|----------|-------------|
| [Reactive System](docs/reactive.md) | Signals, Effects, Memos, Batching |
| [HTML DSL & DOM](docs/dom.md) | Element builders, rendering |
| [SSR](docs/ssr.md) | Server-side rendering, hydration markers |
| [NimMax Integration](docs/nimmax-integration.md) | Routing, middleware, sessions, context |
| [Routing & Layouts](docs/routing.md) | Route components, layout composition |
| [Forms & Validation](docs/forms.md) | Form rendering, validators |
| [Client Hydration](docs/client.md) | JS compilation, event binding |
| [WebSocket Realtime](docs/realtime.md) | Server signals, live updates |

## Testing

```bash
nimble test
```

## Examples

```bash
# Counter example (SSR only)
nimble example

# Server example (NimMax)
nimble server
```

## Comparison with Leptos (Rust)

| Feature | Leptos | NimLeptos |
|---------|--------|-----------|
| Language | Rust | Nim |
| Reactivity | Signals | Signals (same model) |
| Rendering | Virtual DOM / SSR | HtmlNode tree / SSR |
| Backend | Actix/Axum | NimMax |
| Compilation | WASM + Native | Native (server) + JS (client) |
| Macros | `view!` | `elDiv()`, `text()` builders |
| Hydration | WASM-based | `nim js` + `data-nl-id` |

## License

MIT License. See [LICENSE](LICENSE) for details.

## References

- [Leptos Book](https://leptos.dev/)
- [NimMax](https://github.com/katehonz/nimmax)
- [Nim Language](https://nim-lang.org/)
- [Karax](https://github.com/pragmagic/karax)

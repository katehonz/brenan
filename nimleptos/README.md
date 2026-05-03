# NimLeptos

A full-stack reactive web framework for Nim, inspired by [Leptos](https://leptos.dev/) (Rust), powered by [NimMax](https://github.com/katehonz/nimmax).

[![Nim](https://img.shields.io/badge/Nim-%3E%3D2.0.0-FFE000?logo=nim&logoColor=white)](https://nim-lang.org/)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

## Features

- **Fine-Grained Reactivity** — Signals, Effects, Memos with automatic dependency tracking (no virtual DOM)
- **HTML Builder DSL** — Type-safe element construction with 47 builders + macro DSL with reactive interpolation and event binding
- **Server-Side Rendering** — Full HTML pages rendered on the server with hydration markers
- **NimMax Backend** — Routing, middleware, sessions, CSRF, CORS, validation, WebSocket, caching
- **Route Components** — Declarative `route()` with layout composition
- **Form Handling** — Declarative forms with 15+ validators from NimMax
- **WebSocket Reactivity** — Real-time signal synchronization between server and clients
- **Client Hydration** — `nim js` compilation for progressive enhancement
- **Client-Side Rendering** — Fine-grained reactive DOM updates with `mountApp`, `reactiveTextNode`, and event binding through DSL
- **HTML DSL Macros** — `buildHtml`, `html`, and `el()` macros with reactive interpolation and inline event handlers (`onClick`, `onInput`, etc.)
- **Type-Safe** — Full Nim type system, `Option[T]` for safe parameter access

- **JWT Authentication** — HMAC/RSA/ECDSA signing via BearSSL, Bearer token middleware, refresh tokens, role-based access
- **Component System** — `view` macro with typed props, children/slots, `ComponentChildren`
- **SSR State Handoff** — Server initializes client state via `addInitialState` → `getInitialValue`
- **Context** — Dependency injection for reactive components (key/value provider/consumer)
- **Store** — Global reactive state container with selectors and slices
- **Resource** — Async reactive primitive with loading/error/value states and auto-refetch

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

## Multi-Target Compilation

NimLeptos reactive core compiles to three targets:

| Target | Command | Use Case |
|--------|---------|----------|
| **Native** | `nim c --threads:on -p:src` | Server-side rendering, full-stack |
| **JavaScript** | `nim js -p:src` | Client-side rendering in the browser |
| **WASM** | `nim c --cpu:wasm32 --mm:arc ...` | High-performance reactive core in the browser |

### Native (default)
```bash
nim c -r --threads:on -p:src app.nim
```

### JavaScript (nim js)
```bash
nim js -p:src -o:app.js app.nim
# Reactive signals, effects, and DOM updates work in the browser
```

### WebAssembly (WASM)

**With Nimbling** (recommended):
```bash
nimble nimbling_reactive
# Follow the printed instructions to link with Zig/WASI and post-process
```

The reactive core (`signal`, `effects`, `context`, `store`, `resource`) is fully portable across all three targets. Platform-specific DOM bindings are provided by:
- `client/reactive_dom.nim` — for `nim js`
- `wasm/reactive_wasm.nim` — WASM stub (DOM is handled by JS glue when using Nimbling)

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

### Macro DSL

```nim
import nimleptos

# buildHtml with reactive interpolation and event binding
let (count, setCount) = createSignal(0)

let page = buildHtml:
  el("div", class="container"):
    el("h1"): text("Welcome")
    el("p", class="subtitle"): "Count: " & $count()  # reactive text
    el("button", onClick=proc(e: DomEvent) = setCount(count() + 1)):
      text("Increment")

echo renderToHtml(page)
```

Event attributes (`onClick`, `onInput`, `onSubmit`, etc.) are detected automatically and generate client-side event handlers when compiled with `nim js`. Non-literal expressions in the DSL body become reactive text nodes. All 47 HTML element builders are available: `elDiv`, `elSpan`, `elInput`, `elImg`, etc.

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

## WebAssembly (WASM) — Nimbling Edition

Compile the reactive core to WebAssembly for high-performance signal computation in the browser, controlled from JavaScript via [Nimbling](https://github.com/katehonz/nimbling):

```nim
# examples/nimbling_reactive/counter.nim
import nimbling
import nimleptos/reactive/signal
import nimleptos/reactive/effects

let (count, setCount) = createSignal(0)
let (doubled, _) = createMemo(proc(): int = count() * 2)

proc increment() {.wasmBindgen.} = setCount(count() + 1)
proc decrement() {.wasmBindgen.} = setCount(count() - 1)
proc getCount(): int32 {.wasmBindgen.} = count().int32
proc getDoubled(): int32 {.wasmBindgen.} = doubled().int32

wasmBindgenFinalize()
```

Build with Nimbling:

```bash
nimble nimbling_reactive
# Then link with Zig/WASI and post-process with nimbling CLI
```

Use from JavaScript:

```javascript
import initWasm from './pkg/counter.js';
const wasm = await initWasm();

wasm.increment();
console.log(wasm.getCount());      // 1
console.log(wasm.getDoubled());    // 2
```

Open `examples/nimbling_reactive/index.html` in a browser to see the interactive demo.

### WASM Architecture

| Layer | Technology | Role |
|-------|-----------|------|
| Reactive Core | Nim → WASM (nimbling) | Signals, effects, memos |
| JS Bridge | Nimbling `wasmBindgen` | Type-safe JS ↔ Wasm interop |
| DOM | Plain JS | Render and event handling |

> **Note:** Avoid `echo` inside `createEffect` when compiling to WASM — it can block stdout and cause deadlock in the Emscripten runtime. Use JS-side logging instead.

## Full-Stack Example: Todo App

A complete end-to-end application demonstrating SSR, forms, validation, and REST API:

```bash
nimble todo
# Open http://localhost:8080
```

Features:
- Server-side rendered todo list with hydration markers
- Form validation (required fields)
- Toggle complete / delete tasks
- REST API at `/api/todos`
- Thread-safe in-memory storage

## WebSocket Realtime

```nim
import nimleptos/realtime/ws_handler

let (onlineCount, setOnlineCount) = createServerSignal("online", 0)

app.get("/ws", wsSignalRoute())

# Push updates to all connected clients
setOnlineCount(42)
```

## JWT Authentication

Powered by [jwt-nim-baraba](https://github.com/katehonz/jwt-nim-baraba) (HS256/RS256/ES256 via BearSSL).

```nim
import nimleptos/server/auth

setJwtSecret("your-256-bit-secret")

# Middleware — extracts Bearer token, sets auth context
app.use(jwtAuthMiddleware())

# Protect routes by role/permission
app.get("/admin", adminHandler, middlewares = @[requireAuth(), requireRole("admin")])
app.get("/api/invoices", listInvoices, middlewares = @[requireAuth(), requirePermission("read:invoices")])

# Login endpoint — returns access_token + refresh_token
type LoginChecker = proc(username, password: string): AuthUser {.gcsafe.}
app.post("/api/login", loginHandler(checkCredentials))

# Token refresh
app.post("/api/refresh", refreshHandler())

# Usage in route handler
proc adminHandler(ctx: Context) {.async.} =
  let user = extractAuthUser(ctx)
  ctx.json(%*{"message": "Hello " & user.username})
```

| Feature | Description |
|---------|-------------|
| `jwtAuthMiddleware()` | Bearer token extraction, HMAC verification, context population |
| `loginHandler()` | Credential check → JWT creation with access + refresh tokens |
| `refreshHandler()` | Refresh token validation → new access token |
| `requireAuth()` | Gate middleware: redirects unauthenticated users |
| `requireRole(role)` | Gate middleware: 403 if insufficient role |
| `requirePermission(perm)` | Gate middleware: 403 if insufficient permission |
| `isAuthenticated(ctx)` | Check if user in request context |
| `hasRole(ctx, role)` | Check user role |
| `hasPermission(ctx, perm)` | Check user permission |
| `createAccessToken(user)` | Create JWT with claims (sub, username, role, perms, iat, exp) |
| `verifyToken(token)` | Parse + verify → AuthUser or nil |
| `setJwtConfig()` | Configure secret, access/refresh expiry, issuer |

## Component System

```nim
import nimleptos/macros/view_macros

proc Card(title: string, children: ComponentChildren = noChildren()): HtmlNode =
  buildHtml:
    el("div", class="card"):
      el("h3"): text(title)
      el("div", class="card-body"): renderSlot(children)

# Invoke with children via `view` macro
let page = view Card(title="Invoice #42"):
  el("p"): text("Amount: 1500 BGN")
  el("button", onClick=proc(e: auto) = discard): text("Pay")
```

Helpers: `slot()`, `renderSlot()`, `noChildren()`, `ComponentChildren`

## SSR → Client State Handoff

```nim
# Server: store initial data in SSR context
ctx.ssrCtx.addInitialState("invoices", $invoicesJson)
ctx.ssrCtx.addInitialState("userRole", "accountant")

# Client: read back after hydration
import nimleptos/client/hydration_client
let invoices = getInitialValue("invoices", "[]")
let role = getInitialValue("userRole", "viewer")

## Context — Dependency Injection

```nim
import nimleptos/reactive/context

type UserCtx = ref object of ContextValue
  name: string

provideContext("user", UserCtx(name: "Alice"))
let user = useContextAs[UserCtx]("user")
echo user.name  # "Alice"
```

## Store — Global Reactive State

```nim
import nimleptos/reactive/store

type AppState = object
  count: int
  theme: string

let store = createStore(AppState(count: 0, theme: "dark"))
store.update(proc(s: AppState): AppState =
  result = s
  result.count += 1
)

# Derived selector (memoized, only recalculates when slice changes)
let count = store.select(proc(s: AppState): int = s.count)
echo count()  # 1

# Reactive slice with getter/setter
let countSlice = createSlice(store,
  proc(s: AppState): int = s.count,
  proc(s: AppState, v: int): AppState =
    result = s; result.count = v)
countSlice.set(42)
```

## Resource — Async Reactive Data

```nim
import nimleptos/reactive/resource

# Standalone resource
let data = createResource(proc(): string =
  "Fetched data"
)
echo data.value()     # "Fetched data"
echo data.loading()   # false
echo data.state()     # rsReady

# Source-driven resource (auto-refetch on signal change)
let (userId, setUserId) = createSignal(1)
let user = createResource(userId, proc(id: int): string =
  "User " & $id
)
echo user.value()     # "User 1"
setUserId(2)          # automatically refetches → "User 2"
```

## Project Structure

```
nimleptos/
├── src/nimleptos/
│   ├── reactive/          # Signal, Effect, Memo, Batch (thread-safe)
│   ├── dom/               # HtmlNode, element builders
│   ├── macros/            # Compile-time HTML DSL + component view
│   ├── ssr/               # Server-side rendering + hydration state
│   ├── server/            # NimMax adapter, app wrapper, JWT auth
│   ├── routing/           # Route components, layouts
│   ├── forms/             # Form handling, validation
│   ├── realtime/          # WebSocket signals (thread-safe)
│   └── client/            # JS hydration, reactive DOM, router, HTTP
├── tests/                 # 40 tests across 5 suites
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
| [JWT Authentication](docs/auth.md) | Bearer tokens, login/refresh, role-based access |
| [Component System](docs/components.md) | View macros, slots, typed props |

## Testing

```bash
nimble test   # 40 tests across 5 suites
```

## Examples

```bash
# Counter example (SSR only)
nimble example

# Server example (NimMax)
nimble server

# Client-side counter (CSR, nim js)
nimble client

# Reactive timer (setInterval + signals, nim js)
nimble timer

# Hybrid buildHtml + reactive DOM (nim js)
nimble hybrid

# Reactive if/else conditional (nim js)
nimble conditional

# Blog App (CSR + REST API + client router)
nimble blog

# Full-stack Todo App (SSR + forms + validation)
nimble todo

# Reactive core to WASM (requires Nimbling + Zig/WASI)
nimble nimbling_reactive
```

## Comparison with Leptos (Rust)

| Feature | Leptos | NimLeptos |
|---------|--------|-----------|
| Language | Rust | Nim |
| Reactivity | Signals | Signals (same model) |
| Rendering | Virtual DOM / SSR | HtmlNode tree / SSR |
| Backend | Actix/Axum | NimMax |
| Auth | External (axum-login, etc.) | Built-in JWT (HS256/RS256/ES256) |
| Components | `view!` + `#[component]` | `view` macro + procs |
| Context | `use_context` / `provide_context` | `useContext` / `provideContext` |
| Store | `Store` | `Store[T]` with selectors & slices |
| Resource | `Resource` | `Resource[T]` with auto-refetch |
| Compilation | WASM + Native | Native (server) + JS (client) + WASM (core) |
| Macros | `view!` | `buildHtml`, `el()`, `view` with reactive interpolation & events |
| Hydration | WASM-based | `nim js` + `data-nl-id` |

## License

MIT License. See [LICENSE](LICENSE) for details.

## References

- [Leptos Book](https://leptos.dev/)
- [NimMax](https://github.com/katehonz/nimmax)
- [Nim Language](https://nim-lang.org/)
- [Karax](https://github.com/pragmagic/karax)

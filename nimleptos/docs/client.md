# Client-Side Development with NimLeptos

NimLeptos compiles directly to JavaScript via `nim js`, giving you fine-grained reactive DOM updates without WASM or external toolchains.

## Quick Start

```bash
nim js -p:src -o:app.js myapp.nim
```

Then load `app.js` in an HTML file:

```html
<div id="app"></div>
<script src="app.js"></script>
```

## Compiling to JavaScript

### Basic compilation

```bash
nim js -p:src -o:app.js app.nim
```

### Production build (smaller bundle)

```bash
nim js -d:release --opt:size -p:src -o:app.js app.nim
```

### With source maps

```bash
nim js -g -p:src -o:app.js app.nim
```

### Recommended flags

| Flag | Purpose |
|------|---------|
| `-d:release` | Enable release optimizations |
| `--opt:size` | Optimize for bundle size |
| `-g` | Generate source maps |
| `-d:nimleptosDebug` | Enable debug logging |

## Reactive DOM

### Mounting an app

```nim
import nimleptos/client/reactive_dom
import nimleptos/reactive/signal

when defined(js):
  proc myApp(): seq[DomElement] =
    let (count, setCount) = createSignal(0)

    let display = createElement("p")
    let textEl = reactiveTextNode(proc(): string =
      "Count: " & $count()
    )
    display.appendChild(textEl)

    let btn = createElement("button")
    btn.textContent = "+"
    btn.addEventListener("click", proc(e: Event) =
      setCount(count() + 1)
    )

    return @[display, btn]

  mountReactiveApp("#app", myApp)
```

### Available bindings

- `reactiveTextNode(getter)` — auto-updating text node
- `reactiveAttr(el, name, getter)` — attribute bound to signal
- `reactiveClass(el, getter)` — CSS class bound to signal
- `reactiveStyle(el, prop, getter)` — style property bound to signal
- `mountApp(selector, builder)` — mount HtmlNode tree
- `mountReactiveApp(selector, builder)` — mount reactive DomElements

## DOM Interop

Low-level DOM helpers in `nimleptos/client/dom_interop`:

```nim
import nimleptos/client/dom_interop

let el = createElement("div")
el.setAttribute("class", "container")
el.setTextContent("Hello")

# classList helpers
el.addClass("active")
el.removeClass("hidden")
el.toggleClass("open")
if el.hasClass("active"): ...

# dataset
el.setDataAttr("id", "42")
let id = el.getDataAttr("id")

# focus / scroll
el.focusElement()
el.scrollIntoView()

# animation
let animId = requestAnimationFrame(proc(ts: float) = ...)
cancelAnimationFrame(animId)

# intersection observer (lazy loading)
let observer = createIntersectionObserver(
  proc(entries, obs) = ...,
  threshold = 0.5
)
observeElement(observer, el)
```

## Client-Side Routing

Hash-based or History API routing:

```nim
import nimleptos/client/router

when defined(js):
  initHashRouter()        # or initHistoryRouter()

  # Reactive route getter
  let route = currentRoute()

  # Navigate
  navigate("/about")       # hash mode
  navigateTo("/about")     # history API
  navigateReplace("/about") # replace current entry

  # Use in effects
  discard createEffect(proc() =
    case route():
      of "/": renderHome()
      of "/about": renderAbout()
      else: renderNotFound()
  )
```

## HTTP Client

Fetch JSON from APIs:

```nim
import nimleptos/client/http_client
import std/json

fetchGetJson("/api/posts",
  onSuccess = proc(data: JsonNode) =
    echo data.len, " posts loaded"
  ,
  onError = proc(msg: string) =
    echo "Error: ", msg
)
```

Or use `Resource[T]` for reactive data fetching:

```nim
import nimleptos/reactive/resource

let posts = createResource(proc(): seq[Post] =
  # fetch and return data
)

echo posts.loading()   # true while fetching
echo posts.value()     # fetched data
posts.refetch()        # manually re-fetch
```

## Client-Side Forms

Build forms with reactive validation:

```nim
let (email, setEmail) = createSignal("")
let (errors, setErrors) = createSignal(seq[string](@[]))

proc validate(): seq[string] =
  if email().len == 0 or '@' notin email():
    result.add("Invalid email")

input.addEventListener("input", proc(e: Event) =
  let val = $cast[InputElement](e.target).value
  setEmail(val)
  setErrors(validate())
)
```

## i18n on the Client

```nim
import nimleptos/i18n/i18n
import nimleptos/i18n/catalog

let cat = newMessageCatalog("en")
cat.addTranslation("en", "hello", "Hello")
cat.addTranslation("bg", "hello", "Здравей")

let cfg = createI18n(cat, "en")

# Reactive translation
let hello = cfg.t("hello")   # updates when locale changes

# In buildHtml macro
let node = buildHtml(cfg):
  el("h1"): t"hello"
  el("button", onclick=proc(e: Event) = setLocale(cfg, "bg")):
    text("Switch to BG")
```

## Bundler Integration (Vite)

For a modern dev experience with hot reload:

```bash
cd examples/vite_counter
npm install
nimble dev    # starts hotreload + Vite
```

See `examples/vite_counter/README.md` for details.

## Hot Reload

Watch `.nim` files and auto-recompile:

```bash
nimble hot    # watches src/ and recompiles counter_client.nim
```

Or use `tools/dev.sh` for hot reload + Vite together.

## Hydration

When using SSR, hydrate the client app to attach event listeners without re-rendering:

```nim
import nimleptos/client/hydration_client

# On the server: render with hydration IDs
let ctx = newSSRContext()
let root = elDiv([], ...)
discard injectHydrationIds(root, ctx)

# On the client: hydrate after DOM is ready
initHydration()
```

Read initial state from SSR:

```nim
let theme = getInitialValue("theme", "light")
let user = getInitialValue("user", "guest")
```

## Debugging

Enable debug logging:

```bash
nim js -d:nimleptosDebug -p:src -o:app.js app.nim
```

This routes `debugLog` / `debugWarn` / `debugError` to `console.log` in the browser.

## Bundle Size

Measured for `examples/counter_client.nim` (minimal signals + DOM app):

| Build | Size | Command |
|-------|------|---------|
| Debug | ~220 KB | `nim js -p:src -o:app.js app.nim` |
| Release | ~165 KB | `nim js -d:release --opt:size -p:src -o:app.js app.nim` |
| Danger | ~153 KB | `nim js -d:danger --opt:size -p:src -o:app.js app.nim` |
| Minified (Terser) | ~101 KB | `terser app.js -c -m -o app.min.js` |

Tips for smaller bundles:
- Always use `-d:release --opt:size` for production
- Run through a JS minifier like Terser or UglifyJS
- Import only the modules you need (e.g. `import nimleptos/reactive/signal` instead of `import nimleptos`)

## Cleanup & Disposal

When mounting apps, always keep the dispose function and call it on unmount:

```nim
let dispose = mountReactiveApp("#app", myApp)
# ... later
dispose()  # cleans up all effects, subscriptions, and DOM
```

Effects and memos created inside a `createRoot` are automatically cleaned up when the root is disposed. Event handlers registered via `bindEvent` are cleared on the next `initEventHandlers` call.

## Debug Names (DevTools)

Give names to effects and memos for easier debugging:

```nim
let (count, setCount) = createSignal(0)

# Named effect
discard createEffect(proc() =
  echo "Count: ", count()
, "counterEffect")

# Named memo
let (doubled, _) = createMemo(proc(): int = count() * 2, "doubledMemo")
```

When `-d:nimleptosDebug` is enabled, logs will include these names where available.

## Common Pitfalls

1. **Server-only modules** — `nimleptos.nim` automatically excludes `server/`, `routing/`, `forms/`, and `realtime/` when compiling with `nim js`. Use specific imports if you need only client modules.
2. **Threading** — JS target uses plain globals, not `threadvar`. Never add `{.threadvar.}` unconditionally.
3. **WASM leftovers** — `src/nimleptos/_archive/wasm/` contains archived code. Do not import from there in new projects.

## Examples

| Example | Command | Description |
|---------|---------|-------------|
| Counter | `nimble client` | Basic signals + DOM |
| Router | `nimble routerClient` | Hash-based SPA routing |
| Fetch | `nimble fetchClient` | HTTP client + Resource |
| Form | `nimble formClient` | Client-side validation |
| i18n | `nimble i18nClient` | Reactive translations |
| Vite | `nimble dev` | Bundler + hot reload |

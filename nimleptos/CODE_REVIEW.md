# NimLeptos — Code Review & Progress Log

**Date**: 2026-05-01
**Status**: Phase 1-10 Complete
**Tests**: All passing (28 tests across 4 test suites)

---

## What Was Delivered in This Session

### 1. Reactive DOM Binding (`src/nimleptos/client/reactive_dom.nim`)

Implements fine-grained client-side DOM updates without Virtual DOM. When a signal changes, only the specific text node or attribute updates — not the entire component.

| Proc | Purpose |
|------|---------|
| `renderDomNode(node)` | Converts `HtmlNode` tree → real DOM `Element`s |
| `reactiveTextNode(getter)` | Text node auto-updates from a `Getter[string]` signal |
| `reactiveAttr(el, name, getter)` | Attribute bound to signal |
| `reactiveClass(el, getter)` | `class` attribute bound to signal |
| `reactiveStyle(el, prop, getter)` | CSS property bound to signal |
| `mountApp(selector, builder)` | Mount `HtmlNode` tree to DOM element |
| `mountReactiveApp(selector, builder)` | Mount reactive `DomElement`s directly |
| `clearChildren(el)` | Remove all child nodes |

**Key design decision**: `reactiveTextNode` returns a `DomElement` (text node) that is appended to a parent. The `createEffect` inside it automatically updates `textContent` when the signal changes. This is the Solid/Leptos "fine-grained" approach.

**Type safety fix**: `createTextNode` in `dom_interop.nim` now correctly casts `Node` → `DomElement` (`cast[DomElement](document.createTextNode(...))`), fixing a Nim JS backend type mismatch.

**CString warnings fixed**: All DOM wrapper procs in `dom_interop.nim` now explicitly cast strings to `cstring` before passing to `std/dom`, eliminating Nim 2.2 conversion warnings.

### 2. Improved HTML Macro DSL (`src/nimleptos/macros/html_macros.nim`)

The macro DSL was rewritten to support:
- **`buildHtml:`** block macro that transforms declarative HTML-like syntax into `HtmlNode` construction code at compile time
- **`el("tag", attr="value"):`** element macro with inline attributes
- **Nested elements** with arbitrary depth
- **Text nodes** via `text("content")` command
- **Attribute propagation** to nested calls

Example:
```nim
let node = buildHtml:
  el("div", class="app", id="main"):
    el("h1"): text("Title")
    el("p"): text("Hello")
```

**Bug fixed**: Earlier versions generated `<text></text>` elements instead of actual text nodes. The `nnkCall` branch now detects `text("...")` calls and routes them to `textNode(...)` instead of `elementNode("text")`.

### 3. Client-Side Counter Example

`examples/counter_client.nim` + `examples/counter_client.html`

A complete standalone client-side app that:
- Creates signals (`createSignal(0)`)
- Creates a memo (`createMemo(proc(): int = count() * 2)`)
- Binds reactive text to DOM via `reactiveTextNode`
- Handles click events via `addEventListener`
- Mounts to `#app` via `mountReactiveApp`

Build:
```bash
nimble client   # compiles to examples/counter_client.js
```

### 4. Architecture Fixes

**Cyclic dependency resolved**: `hydration_client.nim` imported `event_handlers.nim` and vice versa. `mountApp` / `mountReactiveApp` were moved to `reactive_dom.nim`, breaking the cycle:
```
reactive_dom.nim → event_handlers.nim → hydration_client.nim → dom_interop.nim
```

**Nimble task added**: `nimble client` compiles the CSR example.

**Documentation updated**:
- `docs/client.md` — Added full CSR section with reactive binding examples
- `docs/dom.md` — Replaced "experimental" macro note with full `buildHtml` / `el` documentation
- `README.md` — Added CSR, reactive DOM, and macro DSL sections
- `PLAN.md` — Updated to Phase 1-10, 23 files, new example listed

### 5. NimMax Bugs File Removed

`docs/nimmax-bugs.md` was deleted because all reported NimMax bugs have been fixed upstream and merged into the NimMax repository.

---

## Current File Inventory (23 files)

```
src/nimleptos/
├── reactive/
│   ├── subscriber.nim      # Signal[T], dependency tracking, scheduler, batch
│   ├── signal.nim          # createSignal, Getter/Setter types
│   └── effects.nim         # createEffect, createMemo
├── dom/
│   ├── node.nim            # HtmlNode type, renderToHtml, escapeHtml
│   └── elements.nim        # elDiv, elSpan, elP, elButton, text, etc.
├── macros/
│   └── html_macros.nim     # buildHtml, el, html macros (compile-time DSL)
├── ssr/
│   ├── renderer.nim        # SSRContext, renderFullPage, renderHead
│   └── hydration.nim       # data-nl-id injection, hydration script
├── client/
│   ├── dom_interop.nim     # DOM manipulation wrappers for JS backend
│   ├── reactive_dom.nim    # Fine-grained reactive DOM binding (NEW)
│   ├── hydration_client.nim # Client-side hydration
│   └── event_handlers.nim  # Event binding system
├── server/
│   ├── adapter.nim         # Bridge between NimLeptos HtmlNode and NimMax Context
│   ├── app.nim             # NimLeptosApp wrapper around nimmax Application
│   └── middleware.nim      # hydrationMiddleware, titleMiddleware, clientAssetsMiddleware
├── routing/
│   ├── route.nim           # Declarative route components with layouts
│   └── layout.nim          # mainLayout, sidebarLayout, html5Layout
├── forms/
│   ├── form.nim            # FormDef, FormField, renderForm
│   ├── validation.nim      # Validators wrapping nimmax/validater
│   └── table_helper.nim    # Workaround for nimmax TableRef bug
└── realtime/
    ├── ws_bridge.nim       # ServerSignal[T], SignalRegistry
    └── ws_handler.nim      # WebSocket signal routes
```

---

## Test Results

| Suite | Tests | Status |
|-------|-------|--------|
| `tests/signal_test.nim` | 5 | ✅ PASS |
| `tests/macros_test.nim` | 9 | ✅ PASS (includes new buildHtml + el tests) |
| `tests/ssr_test.nim` | 5 | ✅ PASS |
| `tests/server_test.nim` | 9 | ✅ PASS |
| **Total** | **28** | **✅ All passing** |

### Compilation Checks

| Target | Command | Status |
|--------|---------|--------|
| Native (server) | `nimble test` | ✅ Success |
| JS (client CSR) | `nimble client` | ✅ Success |
| JS (reactive DOM) | `nim js -p:src ...` | ✅ Success |

---

## Known Limitations & Next Steps

### Current Limitations

1. **No reactive interpolation in `buildHtml` macro**: If you write `text("Count: " & $count())` inside `buildHtml`, the signal is read once at compile time, not auto-wrapped in `createEffect`. For reactive text, use `reactiveTextNode` outside the macro or build DOM manually.

2. **`renderDomNode` does not preserve reactive bindings**: `mountApp` converts a static `HtmlNode` tree to DOM. Any signals used while building the `HtmlNode` are evaluated once. For reactive CSR, use `mountReactiveApp` with direct DOM construction.

3. **Event handlers in macros not yet supported**: The `buildHtml` / `el` macros do not yet generate `addEventListener` calls. Use `event_handlers.nim` (`bindClick`, etc.) or manual DOM manipulation.

4. **No component composition in macros**: The `view` macro exists but is basic. It generates `proc(name: RootObj): HtmlNode` which is not ergonomic for real use.

### Recommended Next Steps

1. **Component macro with props**: Rewrite `view` macro to accept typed props (like `proc(props: MyProps): HtmlNode`) instead of `RootObj`.

2. **Reactive macro interpolation**: Enhance `buildHtml` to detect signal getters (`count()`, `name()`) inside `text()` and automatically wrap them in `reactiveTextNode` calls when compiling for JS.

3. **Event binding in DSL**: Add `onClick`, `onInput`, etc. as special attributes in `el` macro that generate `addEventListener` calls.

4. **CSS-in-Nim / scoped styles**: Add a `style` macro or template that generates scoped CSS for components.

5. **WASM backend exploration**: The user expressed interest in WASM. Current `nim js` is the proven path. A future experiment could compile the reactive core to WASM and keep DOM manipulation in JS via a thin bridge.

6. **Dev server / HMR**: Add a `nimble dev` task that watches `.nim` files and recompiles both server and client automatically.

---

## How to Continue

To pick up from here:

```bash
cd nimleptos
nimble test          # verify all tests pass
nimble client        # compile CSR example
nimble server        # run server example
```

The most impactful next feature would be **reactive interpolation in the `buildHtml` macro** — enabling:
```nim
buildHtml:
  el("p"): text($count())   # auto-wraps in createEffect + reactiveTextNode
```

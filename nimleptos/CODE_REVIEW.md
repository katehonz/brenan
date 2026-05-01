# NimLeptos — Code Review & Progress Log

**Date**: 2026-05-02
**Status**: Phase 1-12 Complete
**Tests**: All passing (40 tests across 5 test suites)

---

## Phase 12 Session — Quality & DX Improvements

### Debug Output Cleanup
- All `echo` statements in `subscriber.nim` and `effects.nim` are now gated behind `when defined(nimleptosDebug)`. Production builds no longer spew debug output.
- To enable: compile with `-d:nimleptosDebug`

### Reactive Interpolation in buildHtml Macro
- Non-literal inline expressions in `buildHtml` / `html` macro bodies now automatically generate reactive text nodes (e.g., `p: "Count: " & $count()` or `p: count()` now update reactively on JS target).
- Previously only `text(expr)` with non-string-literal args was reactive. Now `nnkInfix`, `nnkPrefix`, `nnkIdent`, `nnkDotExpr`, `nnkBracketExpr`, `nnkPar`, `nnkLambda` etc. in the DSL body all produce reactive text nodes.

### Event Binding in DSL (NEW)
- The `buildHtml`, `html`, and `el` macros now detect event attributes: `onClick`, `onInput`, `onSubmit`, `onChange`, `onFocus`, `onBlur`, `onKeyDown`, `onKeyUp`, `onMouseEnter`, `onMouseLeave`, `onMouseOver`, `onDblClick`.
- In JS mode, generates `addDomEvent(node, "click", handler)` calls that store the handler closure on the `HtmlNode`.
- `renderDomNode` attaches stored `domEventHandlers` to the created DOM elements.
- Added `DomEventHandler` type (cross-backend compatible via `when defined(js)`).

### Element Builder Generation via Templates
- Replaced 35 nearly-identical element builder procs with two templates: `defineElement` and `defineVoidElement`.
- Reduced `elements.nim` from 283 lines to 74 lines.
- Added missing elements: `elH3`-`elH6`, `elOl`, `elThead`, `elTbody`, `elBr`, `elHr`, `elLink`, `elMeta`.

### Other Improvements
- `parseAttrs` helper function eliminates duplicated attribute parsing logic in the macro module.
- Added `addDomEvent` proc to `node.nim` for storing client-side event handlers.

---

## Phase 11 Session — Bug Fixes & Improvements

### Critical Bugs Fixed

1. **`ws_bridge.nim` type mismatch (runtime crash)**: `ServerSignal[T]` did not inherit from `ServerSignalBase`. The `SignalRegistry` stored `ServerSignalBase` but `handleSignalMessage` tried to access `.subscribers` on it — field didn't exist. Fixed by making `ServerSignal[T] = ref object of ServerSignalBase` with `name` and `subscribers` on the base type.

2. **`ws_handler.nim` `signalUpdateEndpoint`**: Cleared `sig.subscribers = @[]` instead of broadcasting the new value. Fixed to parse the JSON value and call `broadcastToSubscribers(rawValue)`.

3. **`forms/form.nim` invalid HTML**: `textarea`, `select`, `checkbox` field types rendered as `<input type="textarea">` etc. (invalid HTML). Fixed with proper `case` dispatch: `textarea` → `<textarea>`, `select` → `<select>` with `<option>` children, `checkbox` → `<input type="checkbox">` with `checked` support. Added `options: seq[(string, string)]` field to `FormField`.

### Medium Priority Fixes

4. **`layout.nim` `html5Layout` ignored parameters**: `headNodes` and `bodyClass` were accepted but never used. Fixed to generate proper `<html><head>...</head><body class="...">...</body></html>` structure.

5. **`middleware.nim` were no-ops**: All three middlewares just called `switch(ctx)`. Fixed `hydrationMiddleware` to set `__hydration_enabled__` context flag, removed unused imports.

6. **`event_handlers.nim` type incompatibility**: JS branch defined `EventHandler = proc(e: Event)` while native branch defined `EventHandler = proc()` — incompatible types. Fixed native branch to define a stub `Event` type and use `proc(e: Event)`.

7. **`node.nim` `renderToHtmlRaw` missing condition handling**: Didn't evaluate `condition` nodes like `renderToHtml` does — rendered raw `<conditional>` tag instead. Fixed to check `node.condition` and evaluate branches.

8. **`effects.nim` `Memo[T].value` dead data**: `memo.value` was never updated after construction; `cachedValue` closure variable was used instead. Fixed to sync `memo.value = cachedValue` on every recomputation.

9. **`hydration_client.nim` improved**: Now returns `HydrationState` from `hydrateApp`, supports `onHydrate` callbacks for registering custom hydration handlers, and properly handles `DOMContentLoaded` timing.

### New Element Builders

Added 19 missing HTML element builders to `elements.nim`:
`elTextarea`, `elSelect`, `elOption`, `elTable`, `elTr`, `elTd`, `elTh`, `elImg`, `elMain`, `elArticle`, `elAside`, `elPre`, `elCode`, `elHead`, `elBody`, `elHtml`, `elScript`, `elStyle`, `elTitle`

---

## Previous Sessions Summary

### Phase 1-10 (Original Development)
- Reactive core (signals, effects, memos, batching)
- DOM types and element builders
- SSR rendering and hydration markers
- NimMax server adapter
- Routing and layout components
- Form handling and validation
- WebSocket realtime signals
- Client-side hydration framework
- Event handler binding system
- Reactive DOM bindings + improved macro DSL

### Phase 11 (WASM)
- WebAssembly compilation of reactive core via Emscripten
- `nimble wasm` task with Emscripten SDK detection

---

## Current File Inventory (23 files)

```
src/nimleptos/
├── reactive/
│   ├── subscriber.nim      # Signal[T], dependency tracking, scheduler, batch
│   ├── signal.nim          # createSignal, Getter/Setter types
│   └── effects.nim         # createEffect, createMemo (fixed memo.value sync)
├── dom/
│   ├── node.nim            # HtmlNode type, renderToHtml, renderToHtmlRaw (fixed), escapeHtml
│   └── elements.nim        # 35 element builders (19 new)
├── macros/
│   └── html_macros.nim     # buildHtml, el, html macros (compile-time DSL)
├── ssr/
│   ├── renderer.nim        # SSRContext, renderFullPage, renderHead
│   └── hydration.nim       # data-nl-id injection, hydration script
├── client/
│   ├── dom_interop.nim     # DOM manipulation wrappers for JS backend
│   ├── reactive_dom.nim    # Fine-grained reactive DOM binding
│   ├── hydration_client.nim # Client-side hydration (improved with callbacks)
│   └── event_handlers.nim  # Event binding system (fixed type compat)
├── server/
│   ├── adapter.nim         # Bridge between NimLeptos HtmlNode and NimMax Context
│   ├── app.nim             # NimLeptosApp wrapper around nimmax Application
│   └── middleware.nim      # Functional middlewares (hydration, title, assets)
├── routing/
│   ├── route.nim           # Declarative route components with layouts
│   └── layout.nim          # mainLayout, sidebarLayout, html5Layout (fixed)
├── forms/
│   ├── form.nim            # FormDef, FormField (fixed textarea/select/checkbox)
│   ├── validation.nim      # Validators wrapping nimmax/validater
│   └── table_helper.nim    # Workaround for nimmax TableRef bug
└── realtime/
    ├── ws_bridge.nim       # ServerSignal[T] (fixed type hierarchy + broadcast)
    └── ws_handler.nim      # WebSocket signal routes (fixed update endpoint)
```

---

## Test Results

| Suite | Tests | Status |
|-------|-------|--------|
| `tests/signal_test.nim` | 5 | ✅ PASS |
| `tests/macros_test.nim` | 12 | ✅ PASS |
| `tests/ssr_test.nim` | 5 | ✅ PASS |
| `tests/server_test.nim` | 9 | ✅ PASS |
| `tests/all_test.nim` | 9 | ✅ PASS |
| **Total** | **40** | **✅ All passing** |

### Compilation Checks

| Target | Command | Status |
|--------|---------|--------|
| Native (server) | `nimble test` | ✅ Success |
| JS (client CSR) | `nimble client` | ✅ Success |
| JS (reactive timer) | `nimble timer` | ✅ Success |
| JS (hybrid DSL + DOM) | `nimble hybrid` | ✅ Success |
| JS (conditional) | `nimble conditional` | ✅ Success |
| WASM | `nimble wasm` | ✅ Success (requires Emscripten) |

---

## Known Limitations & Next Steps

### Current Limitations

1. ~~**No reactive interpolation in `buildHtml` macro**~~ → ✅ FIXED in Phase 12. Non-literal expressions in DSL body now automatically produce reactive text nodes on JS target.

2. **`renderDomNode` conditional nodes use display toggling**: Both branches are always in the DOM (hidden via `display: none`). This wastes DOM nodes and could cause issues with event handlers on hidden elements.

3. ~~**Event handlers in macros not yet supported**~~ → ✅ FIXED in Phase 12. `onClick`, `onInput`, etc. are detected by DSL macros and generate `addDomEvent` calls for CSR.

4. **No component composition in macros**: The `view` macro exists but is basic. It generates `proc(name: RootObj): HtmlNode` which is not ergonomic for real use.

5. **Thread safety**: Global mutable state in `subscriber.nim` (`currentComputation`, `globalScheduler`) is not thread-safe. Fine for single-threaded JS but problematic for multi-threaded native servers.

### Recommended Next Steps

1. **Component macro with props**: Rewrite `view` macro to accept typed props (like `proc(props: MyProps): HtmlNode`) instead of `RootObj`.

2. **Reactive macro interpolation**: Enhance `buildHtml` to detect signal getters (`count()`, `name()`) inside `text()` and automatically wrap them in `reactiveTextNode` calls when compiling for JS.

3. **Event binding in DSL**: Add `onClick`, `onInput`, etc. as special attributes in `el` macro that generate `addEventListener` calls.

4. **CSS-in-Nim / scoped styles**: Add a `style` macro or template that generates scoped CSS for components.

5. **Server-side signal state persistence**: Add ability to serialize/deserialize `ServerSignal` values for SSR → client hydration handoff.

6. **Dev server / HMR**: Add a `nimble dev` task that watches `.nim` files and recompiles both server and client automatically.

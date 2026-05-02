# NimLeptos — Code Review & Progress Log

**Date**: 2026-05-02
**Status**: Phase 1-14 Complete (Universal Frontend Fixes + Backend Recommendations)
**Tests**: All passing (40 tests across 5 test suites + all_test)
**New files**: 1 (`NIMMAX_BACKEND_RECOMMENDATIONS.md` in repo root)

---

## Phase 14 Session — Universal Bug Fixes & API Hardening

### SSRContext Race Condition (Critical)
- `app.nim`: `render(ctx, node, app, title)` now creates a **fresh `SSRContext` per HTTP request** instead of reusing `app.ssrCtx`
- Previously: shared `SSRContext` across all requests caused race conditions in multi-threaded servers (`nextId` unbounded growth, mixed `initialState`)
- Now: each request gets isolated hydration IDs and clean state

### NimLeptosApp Route Overloads (Critical)
- `route.nim`: added `route`, `routePost`, `routeGroup` overloads for `NimLeptosApp` (in addition to existing `Application` overloads)
- `NimLeptosApp` route handlers are auto-wrapped with `wrapHandler` → `withReactiveContext` → thread-safe per request
- `Application` (raw nimmax) overloads preserved for backward compatibility and testing
- `wrapHandler` exported (`*`) from `app.nim` so `route.nim` can use it

### Middleware Connected to Render Pipeline (Medium)
- `app.nim` `render` now reads `__title__`, `__client_script__`, `__client_style__` from NimMax context (set by `titleMiddleware`, `clientAssetsMiddleware`)
- Middleware is no longer "dead code" — values actually flow into the rendered page

### JSON Body Auth Support (Medium)
- `auth.nim`: `loginHandler` and `refreshHandler` now accept **JSON request bodies** in addition to form POST params
- Checks `Content-Type: application/json` before parsing; falls back to form params
- Enables API-first frontends (SPA / mobile) to use the built-in JWT handlers

### Missing Import Fix (Medium)
- `client/router.nim`: added `import std/strutils` — was missing despite using `startsWith`
- This would break `nim js` compilation of any app using the hash router

### Test Suite Completeness (Minor)
- `nimleptos.nimble`: added `tests/all_test.nim` to the `test` task

---

## Phase 13 Session — Production Hardening for Accounting App

### Thread Safety (Critical)
- `subscriber.nim`: `currentComputation` and `globalScheduler` converted to `{.threadvar.}` — each thread gets its own reactive context, eliminating race conditions in multi-threaded async servers
- `getScheduler()` provides lazy initialization for thread-local schedulers (needed because Nim doesn't allow explicit init of threadvar)
- `ReactiveContext` type added with `newReactiveContext()` / `release()` for per-request isolation
- `withReactiveContext` template wraps handler code in a fresh reactive context (clean dependency tracking per HTTP request)
- `resetThreadContext()` for full cleanup
- `app.nim`: all route handlers auto-wrapped via `wrapHandler()` → each request gets `withReactiveContext`
- `ws_bridge.nim`: `globalRegistry` protected with `Lock` (thread-safe signal registry for WebSocket realtime)

### Conditional Rendering (Fixed)
- `reactive_dom.nim` line 52-65: replaced `display: none` toggling with proper DOM `replaceChild` swap
- Previously: both branches always in DOM (hidden/shown via CSS) — wasted DOM nodes, screen reader leakage
- Now: only the active branch is in the DOM; uses `replaceChild` for real add/remove

### Component System (New)
- New file: `src/nimleptos/macros/view_macros.nim`
- `ComponentChildren` type and helpers: `slot()`, `noChildren()`, `renderSlot()`
- `view` macro: ergonomic component invocation with children DSL
  ```nim
  view Card(title="Hello"):
    el("p"): text("Card content")
  # Expands to: Card(title="Hello", children=@[buildHtml: ...])
  ```

### SSR → Client Signal State Persistence (New)
- `SSRContext.initialState` table for server-side state serialization
- `addInitialState(key, value)` — server sets initial data during SSR render
- `renderHydrationData()` serializes initialState as JSON in `__nimleptos_data__`
- Client: `getInitialState()` and `getInitialValue(key, default)` to read back state after hydration
- Hydration script passes `info.initialState` to `window.__nimleptos`

### Authentication & Authorization (JWT — New)
- New file: `src/nimleptos/server/auth.nim`
- Powered by [jwt-nim-baraba](https://github.com/katehonz/jwt-nim-baraba) (HS256/RS256/ES256 via BearSSL)
- `AuthUser` type with id, username, email, role, permissions
- JWT token-based: `createAccessToken()`, `createRefreshToken()`, `verifyToken()`, `verifyRefreshToken()`
- `jwtAuthMiddleware()` — Bearer token extraction + verification + context population
- `setContextAuthUser()` / `extractAuthUser()` — user storage in NimMax context (JSON-based)
- `isAuthenticated()`, `hasRole()`, `hasPermission()` — access checks
- Middleware: `requireAuth()`, `requireRole()`, `requirePermission()`
- Handlers: `loginHandler(checkCreds)` returns `{access_token, refresh_token, user}`, `refreshHandler()`
- `setJwtConfig()` / `setJwtSecret()` — global configuration (secret, expiry, issuer)
- `decodeToken()` — decode JWT payload without verification (debug)
- `JwtConfig` is value-type (not ref) for gcsafe closure compatibility
- Replaced SHA-1 session auth with Bearer-token JWT auth

### Minor Fixes
- `router.nim`: removed unused `strutils` import

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

## Current File Inventory (25 files)

```
src/nimleptos/
├── reactive/
│   ├── subscriber.nim      # Signal[T], dependency tracking, scheduler, batch, ReactiveContext
│   ├── signal.nim          # createSignal, Getter/Setter types
│   └── effects.nim         # createEffect, createMemo (fixed memo.value sync)
├── dom/
│   ├── node.nim            # HtmlNode type, renderToHtml, renderToHtmlRaw (fixed), escapeHtml
│   └── elements.nim        # 47 element builders via templates
├── macros/
│   ├── html_macros.nim     # buildHtml, el, html macros (compile-time DSL)
│   └── view_macros.nim     # view macro, ComponentChildren, slot/renderSlot helpers (NEW)
├── ssr/
│   ├── renderer.nim        # SSRContext (added initialState), renderFullPage, renderHead
│   └── hydration.nim       # data-nl-id injection, hydration script (added initialState)
├── client/
│   ├── dom_interop.nim     # DOM manipulation wrappers for JS backend
│   ├── reactive_dom.nim    # Fine-grained reactive DOM binding (fixed conditional render)
│   ├── hydration_client.nim # Client-side hydration (added getInitialState/getInitialValue)
│   ├── event_handlers.nim  # Event binding system (fixed type compat)
│   ├── http_client.nim     # fetchGetJson/fetchPostJson wrappers
│   └── router.nim          # Hash-based client router
├── server/
│   ├── adapter.nim         # Bridge between NimLeptos HtmlNode and NimMax Context
│   ├── app.nim             # NimLeptosApp with per-request reactive context (wrapHandler)
│   ├── middleware.nim      # Functional middlewares (hydration, title, assets)
│   └── auth.nim            # JWT authentication (jwt-nim-baraba), middleware, token management (NEW)
├── routing/
│   ├── route.nim           # Declarative route components with layouts
│   └── layout.nim          # mainLayout, sidebarLayout, html5Layout (fixed)
├── forms/
│   ├── form.nim            # FormDef, FormField (fixed textarea/select/checkbox)
│   └── validation.nim      # Validators wrapping nimmax/validater
└── realtime/
    ├── ws_bridge.nim       # ServerSignal[T] (fixed type hierarchy + broadcast + lock)
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

### Resolved (Phase 13)
1. ~~**Thread safety**~~ → ✅ FIXED. `threadvar` + per-request `withReactiveContext` + `Lock` on signal registry.
2. ~~**`renderDomNode` conditional nodes use display toggling**~~ → ✅ FIXED. Uses `replaceChild` for real DOM add/remove.
3. ~~**No component composition in macros**~~ → ✅ FIXED. `view` macro with children support.
4. ~~**Server-side signal state persistence**~~ → ✅ FIXED. `addInitialState` / `getInitialValue` SSR handoff.

### Current Limitations
1. **Thread safety in shared global state**: `subscriber.nim` globals are now per-thread, but there's still `globalRegistry` in `ws_bridge.nim` protected by a lock. Heavy WebSocket usage may contend on this lock.
2. **Password hashing**: Auth uses JWT (stateless) — actual password hashing is delegated to the user's `CredentialChecker` callback. For production accounting, use bcrypt/argon2 in the checker.
3. **`renderDomNode` conditional swap recreates nodes on each toggle**: Both branches exist in memory; `replaceChild` re-attaches them. Reactive bindings on children persist correctly.
4. **No component lifecycle hooks**: No `onMount` / `onDestroy` / `onUpdate` — Leptos-style lifecycle not yet implemented.
5. **CSR examples not tested automatically**: Client-side rendering tests require a browser; only native/server tests are automated.

### Recommended Next Steps
1. **Replace SHA-1 with bcrypt**: Add `bcrypt` nimble dependency for proper password hashing.
2. **CSR client test harness**: Add Playwright/Puppeteer-based tests for client-side examples.
3. **Component lifecycle**: `onMount`, `onDestroy`, `onUpdate` hooks for resource management.
4. **CSV/PDF export middleware**: Essential for accounting apps — report generation.
5. **Database integration**: Add SQLite/PostgreSQL session store + ORM helpers.

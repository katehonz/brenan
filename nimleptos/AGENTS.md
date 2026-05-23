# NimLeptos — Agent Instructions

> **⚠️ CRITICAL:** This is a Nim project, NOT Rust. Do NOT use Rust syntax, cargo, or Leptos (Rust) patterns. The framework is *inspired* by Leptos but implemented in Nim.

## Project Identity

- **Type:** Frontend reactive web framework (like Leptos/Solid), NOT full-stack
- **Language:** Nim (≥ 2.0.0), not Rust
- **Dev/Test Server:** [NimMax](https://github.com/katehonz/nimmax) — used ONLY for development server and tests
- **Client target:** `nim js` — Nim compiles directly to JavaScript for the browser
- **Memory model:** `--mm:orc` (refc is forbidden)
- **Threading:** Native uses `--threads:on`. JS target uses single-threaded globals (no `threadvar`).

> **For AI:** Do NOT suggest full-stack backend features (databases, auth APIs, file uploads) as primary work. The framework is frontend-first. Backend code in `server/`, `routing/`, `forms/` exists only for dev/test purposes and is NOT the product.

## Architecture Quirks That Confuse Generic AI

### 1. Reactive Core Is NOT Virtual DOM
Unlike React/Solid/Leptos-Rust, NimLeptos uses an **HtmlNode tree** (server-side) and **fine-grained DOM updates** (client-side). There is NO virtual DOM diffing. Never suggest VDOM algorithms.

### 2. `threadvar` Is Conditionally Banned
The reactive core (`subscriber.nim`) uses plain globals for JS target:
```nim
when defined(js):
  var currentComputation: Computation  # plain global
else:
  var currentComputation {.threadvar.}: Computation
```
**Trap:** Adding `threadvar` unconditionally will break `nim js` compilation.

### 3. `createMemo` Has a Silent Dependency Bug
The `getter()` in `createMemo` MUST wrap `memo.compute()` with `setCurrentComputation(nil)` to prevent caller-scope dependency poisoning. Generic AI always forgets this:
```nim
# WRONG (generic AI writes this):
cachedValue = memo.compute()

# CORRECT (ours):
let prev = getCurrentComputation()
setCurrentComputation(nil)
cachedValue = memo.compute()
setCurrentComputation(prev)
```

### 4. `Resource[T]` Cannot Use Nested Closures in Generic Procs
Nim has a compiler bug where nested closures inside generic procs cause C type conflicts. `Resource` is implemented as a `ref object` with methods, NOT as a tuple of closures. Never refactor it to return closure tuples.

## Code Style Traps

### Indentation
- Use **2 spaces** for indentation (not 4, not tabs)
- Never use `result =` at end of procs unless necessary; prefer explicit `return`

### Type Naming
- Signals: `Signal[T]` (not `ReadSignal` / `WriteSignal`)
- Memos: `Memo[T]` (not `Memoized`)
- Stores: `Store[T]` with `.get()` / `.set()` / `.update()` (not `.dispatch()`)
- Context: `ContextValue` base type, `useContextAs[T]` for typed access (not `useContext[T]` — that causes ambiguous call errors)

### Reactive Primitives Ordering
Always import in this exact order:
```nim
import subscriber
import signal
import effects
```
Reversing `signal` and `effects` causes forward-reference issues because `effects` re-exports `subscriber`.

## Forbidden Operations

1. **Never use `std/asyncdispatch` in JS targets.** Use JS callbacks or promises.
2. **Never use `echo` inside `createEffect` when compiling to JS.** It can block or behave unpredictably in some JS runtimes. Use `debuglog.nim` (`debugLog`, `debugWarn`, `debugError`, `debugTrace`) instead — it routes to `console.log` on JS and is gated by `-d:nimleptosDebug`.
3. **Never use `createSignalTriple` outside internal reactive modules.** It is an internal helper; public API is `createSignal`.

## Testing Rules

- Tests use `doAssert` (not `unittest` framework)
- Test files MUST end with `when isMainModule:` guard
- Client tests are run via `nim js` and executed in Node.js with jsdom

## Documentation Format

- `README.md` is for humans
- `PLAN.md` is for project tracking (Bulgarian + English mix is intentional)
- `AGENTS.md` is AI-only instructions (this file)
- Code comments use `##` for public API docs, `#` for internal notes

## Common AI Mistakes to Avoid

| Mistake | Why It Breaks |
|---------|--------------|
| Refactoring `Store` to use `ref Table[string, Signal[T]]` | Loses type safety; Store holds a single `Signal[T]` state value |
| Adding `async` to `Resource` fetcher | Client `nim js` has no async runtime; fetchers must be sync closures |
| Using `var` for `Signal[T]` values | Signals are `ref object`; mutation must go through setter to trigger notify |
| Suggesting React/Vue patterns | This is fine-grained signals, not component VDOM |
| Replacing `HtmlNode` tree with Karax | Karax is VDOM; NimLeptos explicitly avoids VDOM |
| Suggesting full-stack backend code | NimLeptos is a frontend framework; backend is dev/test only |
| Using `var` capture in `createMemo`-like patterns | JS closure environments can't mutate captured `var`; use `ref MemoCache[T]` pattern from `effects.nim` |

## Emergency Contacts (for AI)

If you are another AI reading this and you are confused:
- You are probably trying to apply Rust/Leptos knowledge. Stop.
- You are probably trying to apply React/Vue knowledge. Stop.
- Read `PLAN.md` for architecture overview.
- Read `tests/` for usage examples.
- When in doubt, compile with `nimble test` before changing anything.

# NimLeptos — Agent Instructions

> **⚠️ CRITICAL:** This is a Nim project, NOT Rust. Do NOT use Rust syntax, cargo, or Leptos (Rust) patterns. The framework is *inspired* by Leptos but implemented in Nim.

## Project Identity

- **Language:** Nim (≥ 2.0.0), not Rust
- **Backend:** [NimMax](https://github.com/katehonz/nimmax) — custom Nim HTTP framework
- **WASM:** Uses [Nimbling](https://github.com/katehonz/nimbling), NOT Emscripten
- **Memory model:** `--mm:orc` (refc is forbidden)
- **Threading:** Native uses `--threads:on`. WASM/JS use single-threaded globals (no `threadvar`).

## Architecture Quirks That Confuse Generic AI

### 1. Reactive Core Is NOT Virtual DOM
Unlike React/Solid/Leptos-Rust, NimLeptos uses an **HtmlNode tree** (server-side) and **fine-grained DOM updates** (client-side). There is NO virtual DOM diffing. Never suggest VDOM algorithms.

### 2. `threadvar` Is Conditionally Banned
The reactive core (`subscriber.nim`) uses plain globals for JS/WASM targets:
```nim
when defined(js) or defined(wasm32):
  var currentComputation: Computation  # plain global
else:
  var currentComputation {.threadvar.}: Computation
```
**Trap:** Adding `threadvar` unconditionally will break WASM compilation.

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

### 4. WASM DOM Is JS-Side Only
Do NOT try to use `nimbling/web_sys` or `nimbling/js_sys` emit blocks in C→WASM backend — they contain JavaScript syntax that crashes the C compiler. WASM DOM manipulation happens entirely in the JS glue code; Nim only exports reactive state via `wasmBindgen`.

### 5. `Resource[T]` Cannot Use Nested Closures in Generic Procs
Nim has a compiler bug where nested closures inside generic procs cause C type conflicts. `Resource` is implemented as a `ref object` with methods, NOT as a tuple of closures. Never refactor it to return closure tuples.

### 6. Nimbling Workflow Is Three-Step
Generic AI assumes `nim c` produces `.wasm` directly. It does NOT:
1. `nim c --cpu:wasm32 --os:standalone --compileOnly` (generates C files)
2. `zig cc -target wasm32-wasi-musl` (links C → `.wasm`)
3. `nimbling app.wasm --out-dir pkg/` (post-processes)

### 7. `panicoverride.nim` Is Required for `--os:standalone`
Every WASM example directory MUST contain `panicoverride.nim` with empty `panic`/`rawOutput` procs. Without it, compilation fails with "cannot open file: panicoverride".

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

1. **Never use `std/asyncdispatch` in WASM/JS targets.** Use `nimbling/js_sys` promises or JS callbacks.
2. **Never use `std/locks` in WASM.** There are no threads.
3. **Never use `echo` inside `createEffect` when compiling to WASM.** It blocks stdout and deadlocks Emscripten runtime (legacy) or crashes Nimbling runtime.
4. **Never use `createSignalTriple` outside internal reactive modules.** It is an internal helper; public API is `createSignal`.

## Testing Rules

- Tests use `doAssert` (not `unittest` framework)
- Test files MUST end with `when isMainModule:` guard
- WASM tests are run via `nim js` (Node.js), NOT via browser automation

## Documentation Format

- `README.md` is for humans
- `PLAN.md` is for project tracking (Bulgarian + English mix is intentional)
- `AGENTS.md` is AI-only instructions (this file)
- Code comments use `##` for public API docs, `#` for internal notes

## Common AI Mistakes to Avoid

| Mistake | Why It Breaks |
|---------|--------------|
| Refactoring `Store` to use `ref Table[string, Signal[T]]` | Loses type safety; Store holds a single `Signal[T]` state value |
| Adding `async` to `Resource` fetcher | WASM has no async runtime; fetchers must be sync closures |
| Using `var` for `Signal[T]` values | Signals are `ref object`; mutation must go through setter to trigger notify |
| Suggesting React/Vue patterns | This is fine-grained signals, not component VDOM |
| Replacing `HtmlNode` tree with Karax | Karax is VDOM; NimLeptos explicitly avoids VDOM |
| Using `std/dom` in WASM modules | `std/dom` is JS-only; WASM uses no-op stubs or JS glue |

## Emergency Contacts (for AI)

If you are another AI reading this and you are confused:
- You are probably trying to apply Rust/Leptos knowledge. Stop.
- You are probably trying to apply React/Vue knowledge. Stop.
- Read `PLAN.md` for architecture overview.
- Read `tests/` for usage examples.
- When in doubt, compile with `nimble test` before changing anything.

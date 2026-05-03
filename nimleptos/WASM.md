## NimLeptos WASM Support — Integration Guide
## ===========================================

### Overview

NimLeptos reactive core (signals, effects, scheduler) compiles to WebAssembly via
Emscripten (`emcc`). DOM manipulation is done through `EM_ASM` blocks that call
vanilla JS DOM APIs.

### Quick Start

```bash
cd nimleptos
source ~/emsdk/emsdk_env.sh    # activate Emscripten

# Simple counter with signals + effects
nimble wasm
firefox examples/wasm_counter/index.html  # or index for wasm_reactive

# Counter with reactive DOM updates
nimble wasmCounter
firefox examples/wasm_counter/index.html

# Full demo (signals, memos, conditional)
nimble wasmDemo
firefox examples/wasm_counter/index_demo.html
```

### Architecture

```
Nim Source (.nim)
  │
  ├─ Reactive Core (signal.nim, effects.nim, subscriber.nim)
  │   └─ Works on ALL targets: native C, JS, WASM
  │
  ├─ EM_ASM DOM Bridge (in example files)
  │   └─ {.emit: "EM_ASM({...})".} blocks call browser DOM APIs
  │
  └─ Emscripten Pipeline
      └─ nim c --cpu:wasm32 --cc:clang --clang.exe:emcc ...
          └─ Produces: .js (glue) + .wasm (binary)
```

### Build Pattern

Every WASM build MUST include `_main` in `-sEXPORTED_FUNCTIONS`:

```bash
nim c --cpu:wasm32 --mm:arc --threads:on \
  --cc:clang --clang.exe:emcc --clang.linkerexe:emcc \
  --passC:"-sWASM=1" \
  --passL:"-sWASM=1 -sMODULARIZE=1 -sEXPORT_NAME='ModuleName' \
    -sEXPORTED_FUNCTIONS=['_main','_yourFunc1','_yourFunc2'] \
    -sEXPORTED_RUNTIME_METHODS=['ccall','cwrap']" \
  -p:src -o:output.js source.nim
```

The `_main` export is **critical** — without it, `NimMain()` is not called during
module init, and signal closures fail with "null function or function signature mismatch".

### Known Limitations

| Issue | Status | Workaround |
|-------|--------|------------|
| `createMemo` closure fails in wasm32 | Known Nim bug | Use `var` + `createEffect` instead |
| `buildHtml` generates static nodes in WASM | By design (function table limits) | Use explicit `createEffect` + `emSetText` for reactivity |
| `html_macros` import + module-level signals | Heisenbug (function table layout) | Avoid importing heavy modules in WASM files |
| No closure-based event handlers | nimbling web_sys not Emscripten-compatible yet | Wire buttons via JS `onclick` calling `Module.ccall(...)` |
| DOM manipulation only via EM_ASM | nimbling emit blocks are raw JS | Bridge layer in progress (`src/nimleptos/wasm/`) |

### nimbling Integration Status

We attempted to integrate nimbling's `web_sys` directly but found 3 blocking bugs:

1. **Bug #1 (P0)**: `__nbg_describe` undeclared in C code — `importc, nodecl.` generates code without C declaration for the descriptor function
2. **Bug #2 (P0)**: `web_sys.nim` emit blocks contain raw JavaScript — not valid C, fails Emscripten compilation  
3. **Bug #3 (P1)**: `=destroy` hook member access generates `v.idx` instead of `v->idx` in C

These are documented in `nimbling-bugs-for-kimi.md`.

Once nimbling fixes these, we can replace the EM_ASM approach with nimbling's:
- JsValue-based type safety
- Automatic TypeScript declarations  
- Full web-sys API coverage (722 types, 3266 procs)
- Closure support for event handlers

### Reactive Core in WASM — Example Pattern

```nim
import nimleptos/reactive/signal
import nimleptos/reactive/effects

when defined(wasm32):
  {.passC: "-include emscripten.h".}

# EM_ASM DOM helper
proc updateElement(id: cstring, text: cstring) {.inline.} =
  when defined(wasm32):
    {.emit: "EM_ASM({ document.getElementById(UTF8ToString($0)).innerText = UTF8ToString($1); }, `id`, `text`);".}

# Module-level signals (OK with _main export)
let (count, setCount) = createSignal(0)

# Exported to JS
proc increment() {.exportc, cdecl.} = setCount(count() + 1)

# Initial setup + reactive effects
proc render() {.exportc, cdecl.} =
  updateElement("display", "Count: 0")
  discard createEffect(proc() =
    updateElement("display", cstring("Count: " & $count()))
  )
```

### File Structure

```
nimleptos/
├── examples/
│   ├── wasm_reactive.nim          # Basic signals in WASM (no DOM)
│   └── wasm_counter/
│       ├── build.sh               # Build script
│       ├── wasm_counter.nim        # Counter with EM_ASM DOM
│       ├── wasm_app.nim            # Full app with reactive effects
│       ├── wasm_demo.nim           # Signals + memos + conditional demo
│       ├── index.html              # HTML for wasm_counter
│       ├── index_app.html          # HTML for wasm_app
│       ├── index_demo.html         # HTML for wasm_demo
│       └── test_nimbling_macro.nim # nimbling integration test
├── src/
│   └── nimleptos/
│       └── wasm/
│           ├── dom_bridge.nim      # Low-level EM_ASM DOM primitives
│           └── render.nim          # HtmlNode → WASM DOM renderer
└── nimleptos.nimble               # nim c --cpu:wasm32 tasks
```

### Nimble Tasks

| Task | Command | Output |
|------|---------|--------|
| `wasm` | Basic signals in WASM | `examples/wasm_reactive.js` |
| `wasmCounter` | Counter with EM_ASM DOM | `examples/wasm_counter/wasm_counter.js` |
| `wasmApp` | Full reactive app | `examples/wasm_counter/wasm_app.js` |
| `wasmDemo` | Signals + memos + conditional | `examples/wasm_counter/wasm_demo.js` |
| `test` | Run all native tests | — |

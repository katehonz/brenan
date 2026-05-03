# NimLeptos + Nimbling Reactive Example

Reactive counter running in WebAssembly via [Nimbling](https://github.com/katehonz/nimbling).

## Architecture

```
┌─────────────┐     ┌──────────────┐     ┌─────────────┐
│   Nim Code   │ ──▶ │   WASM       │ ──▶ │  JS Glue    │
│  (signals)   │     │  (reactive   │     │  (DOM +     │
│  (effects)   │     │   core)      │     │   callbacks)│
└─────────────┘     └──────────────┘     └─────────────┘
```

- **WASM side**: Signals, effects, memos, batching (pure Nim reactive core)
- **JS side**: DOM manipulation, event handling, calling WASM exports

## Prerequisites

- [Nim](https://nim-lang.org/) >= 2.0.0
- [Nimbling](https://github.com/katehonz/nimbling) (`nimble install nimbling`)
- WASI SDK or [Zig](https://ziglang.org/) (for WASM compilation with libc)

## Build

### 1. Compile Nim to C (WASM target)

```bash
nim c --cc:clang --cpu:wasm32 --os:standalone --mm:orc -d:wasm32 \
  -p:src --compileOnly --nimcache:nimcache counter.nim
```

### 2. Link to WASM (using Zig)

```bash
zig cc -target wasm32-wasi-musl \
  -nostdlib -Wl,--no-entry -Wl,--export-all \
  -I/usr/local/lib/nim/lib \
  -o counter.wasm nimcache/*.c
```

Or with WASI SDK:

```bash
wasm32-wasi-clang -nostdlib -Wl,--no-entry -Wl,--export-all \
  -I/usr/local/lib/nim/lib \
  -o counter.wasm nimcache/*.c
```

### 3. Post-process with Nimbling CLI

```bash
nimbling counter.wasm --out-dir pkg/ --target bundler
```

### 4. Serve

Open `index.html` in a browser (requires a local server for ES modules).

```bash
python3 -m http.server 8080
# Open http://localhost:8080/examples/nimbling_reactive/
```

## Exported Functions

| Function | Signature | Description |
|----------|-----------|-------------|
| `initCounter` | `(start: int32) → void` | Initialize reactive state |
| `increment` | `() → void` | +1 |
| `decrement` | `() → void` | -1 |
| `getCount` | `() → int32` | Current count |
| `getDoubled` | `() → int32` | Memoized count × 2 |
| `reset` | `(value: int32) → void` | Reset to value |
| `registerOnChange` | `(callback: Closure) → void` | Register JS effect callback |
| `getEffectRuns` | `() → int32` | Debug: effect run count |
| `batchUpdate` | `(delta: int32) → void` | Batched update demo |

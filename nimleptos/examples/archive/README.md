# Archived Examples

These examples are archived and no longer actively maintained.

## Why?

The NimLeptos project has shifted focus to the **`nim js` client target** and
**server-side rendering (SSR)**. The WebAssembly (WASM) pipeline required
external tooling (Nimbling CLI, WASI SDK, Zig) and was fragile compared to
Nim's built-in `nim js` backend.

## Contents

| Directory | Description |
|-----------|-------------|
| `nimbling_counter/` | Reactive counter compiled to WASM via Nimbling |
| `nimbling_reactive/` | Reactive core signals + effects exported via `wasmBindgen` |
| `nimbling_i18n/` | i18n bridge with locale switching via WASM |

## Can I still use them?

Yes, but you will need to install the dependencies manually:

```bash
nimble install nimbling
# Plus: WASI SDK or Zig for linking
```

The source code remains in the Git history if you need to restore full WASM
support in the future.

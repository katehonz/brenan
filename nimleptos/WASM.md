# ARCHIVED: NimLeptos WASM Support — Nimbling Integration Guide

> **⚠️ This document is archived. WASM support is no longer actively developed.**
>
> NimLeptos now focuses on the **`nim js` client target** and **server-side rendering (SSR)**.
> The `nim js` backend is mature, produces smaller bundles, and requires no external
> toolchain (WASI SDK, Zig, or Nimbling CLI).
>
> If you need WASM, the old source code is preserved in `src/nimleptos/_archive/wasm/`
> and `examples/archive/nimbling_*`. You will need to install `nimbling` manually and
> handle linking yourself.

---

## Historical Overview

NimLeptos reactive core (signals, effects, scheduler) used to compile to WebAssembly via
**nimbling** — Nim's equivalent of Rust's wasm-bindgen. DOM manipulation used
nimbling's `web_sys` bindings which emit raw JavaScript via `{.emit.}` blocks.

### Quick Start (Archived)

```bash
cd nimleptos

# Reactive counter with nimbling WASM
nimble nimblingReactive

# i18n bridge with nimbling WASM
nimble nimblingI18n

# Then link with WASI SDK and run nimbling CLI:
cd examples/archive/nimbling_reactive
export WASI_SDK_PATH=/path/to/wasi-sdk
clang --target=wasm32-wasi --sysroot=$WASI_SDK_PATH/share/wasi-sysroot \
  -nostartfiles -O3 -Wno-implicit-function-declaration \
  -Wl,--no-entry -Wl,--export-all -Wl,--allow-undefined -Wl,--no-gc-sections \
  -o counter.wasm nimcache/*.c

nimbling counter.wasm --out-dir pkg/ --target bundler
firefox index.html
```

### Architecture

```
Nim Source (.nim)
  │
  ├─ Reactive Core (signal.nim, effects.nim, subscriber.nim)
  │   └─ Works on ALL targets: native C, JS, WASM
  │
  ├─ Nimbling web_sys bindings
  │   └─ {.emit: "...".} blocks call browser DOM APIs
  │
  └─ Standalone WASM Pipeline (WASI SDK or Zig)
      └─ nim c --cpu:wasm32 --os:standalone --cc:clang ...
          └─ Produces: .wasm (binary) + .nbg (sidecar metadata)
             nimbling CLI → JS glue + TypeScript declarations
```

### Build Pattern

```bash
nim c --cpu:wasm32 --os:standalone --mm:orc -d:wasm32 \
  --compileOnly --nimcache:./nimcache \
  -p:src source.nim

# Link to WASM
clang --target=wasm32-wasi --sysroot=$WASI_SDK/share/wasi-sysroot \
  -nostartfiles -O3 -Wno-implicit-function-declaration \
  -Wl,--no-entry -Wl,--export-all -Wl,--allow-undefined -Wl,--no-gc-sections \
  -o output.wasm nimcache/*.c

# Post-process with nimbling CLI
nimbling output.wasm --out-dir pkg/ --target bundler
```

### Known Limitations

| Issue | Status | Workaround |
|-------|--------|------------|
| `createMemo` closure fails in wasm32 | Known Nim bug | Use `var` + `createEffect` instead |
| `buildHtml` generates static nodes in WASM | By design (function table limits) | Use explicit `createEffect` + web_sys for reactivity |
| `html_macros` import + module-level signals | Heisenbug (function table layout) | Avoid importing heavy modules in WASM files |

### Nimble Tasks (Removed)

The following tasks have been removed from `nimleptos.nimble`:

| Task | Command | Output |
|------|---------|--------|
| `nimblingReactive` | Reactive core via nimbling | `examples/archive/nimbling_reactive/nimcache/` |
| `nimblingI18n` | i18n bridge via nimbling | `examples/archive/nimbling_i18n/nimcache/` |

### WASM i18n Bridge

The i18n module (`src/nimleptos/_archive/wasm/i18n_wasm.nim`) exports translation functions via `wasmBindgen`:

```nim
proc initI18n*(defaultLocale: string, fallbackLocale: string) {.wasmBindgen.}
proc addTranslation*(locale: string, key: string, message: string) {.wasmBindgen.}
proc setLocale*(locale: string) {.wasmBindgen.}
proc getLocale*(): string {.wasmBindgen.}
proc translate*(key: string): string {.wasmBindgen.}
proc translateWithParams*(key: string, params: string): string {.wasmBindgen.}
proc registerOnLocaleChange*(callback: Closure[void]) {.wasmBindgen.}
```

**JS usage:**
```javascript
import initWasm from './pkg/i18n.js';
const wasm = await initWasm();

wasm.initI18n('en', 'en');
wasm.addTranslation('en', 'hello', 'Hello');
wasm.addTranslation('bg', 'hello', 'Здравей');

wasm.registerOnLocaleChange(() => {
  document.getElementById('hello').textContent = wasm.translate('hello');
});

wasm.setLocale('bg');  // JS callback updates DOM
```

See `examples/archive/nimbling_i18n/index.html` for a complete demo with locale switcher and interpolated translations.

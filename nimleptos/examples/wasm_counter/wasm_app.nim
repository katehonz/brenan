## NimLeptos WASM Counter — using buildHtml + explicit reactive effects
## =========================================================================
## Demonstrates the NimLeptos HTML DSL compiled to WASM.
## buildHtml generates STATIC HtmlNode trees in WASM (function table limitation).
## Reactive updates use explicit createEffect + EM_ASM calls.
##
## Build: source ~/emsdk/emsdk_env.sh && nimble wasmApp

import nimleptos/reactive/signal
import nimleptos/reactive/effects

when defined(wasm32):
  {.passC: "-include emscripten.h".}

proc emSetText(id: cstring, text: cstring) {.inline.} =
  when defined(wasm32):
    {.emit: "EM_ASM({ document.getElementById(UTF8ToString($0)).innerText = UTF8ToString($1); }, `id`, `text`);".}

proc emSetClass(id: cstring, cls: cstring) {.inline.} =
  when defined(wasm32):
    {.emit: "EM_ASM({ document.getElementById(UTF8ToString($0)).className = UTF8ToString($1); }, `id`, `cls`);".}

let (count, setCount) = createSignal(0)
let (doubled, _) = createMemo(proc(): int = count() * 2)

proc increment() {.exportc, cdecl.} = setCount(count() + 1)
proc decrement() {.exportc, cdecl.} = setCount(count() - 1)
proc getCount(): int32 {.exportc, cdecl.} = int32(count())

proc render() {.exportc, cdecl.} =
  # Set initial values
  emSetText("count-display", "Count: 0")
  emSetText("doubled-display", "Doubled: 0")

  # Reactive effects update the DOM
  discard createEffect(proc() =
    emSetText("count-display", cstring("Count: " & $count()))
  )
  discard createEffect(proc() =
    emSetText("doubled-display", cstring("Doubled: " & $doubled()))
  )
  discard createEffect(proc() =
    let c = count()
    if c >= 10:
      emSetClass("count-display", "count-display hot")
    else:
      emSetClass("count-display", "count-display")
  )

## NimLeptos WASM Counter — Emscripten + EM_ASM approach
## =========================================================
## Demonstrates NimLeptos reactive core running in WASM with
## DOM manipulation via Emscripten's EM_ASM blocks.
##
## Build:
##   source ~/emsdk/emsdk_env.sh
##   nim c --cpu:wasm32 --mm:arc --cc:clang --clang.exe:emcc --clang.linkerexe:emcc \
##     --passC:"-sWASM=1" \
##     --passL:"-sWASM=1 -sMODULARIZE=1 -sEXPORT_NAME='NimLeptosWasm' \
##       -sEXPORTED_FUNCTIONS=['_main','_render','_increment','_decrement','_getCount'] \
##       -sEXPORTED_RUNTIME_METHODS=['ccall','cwrap']" \
##     -p:src -o:wasm_counter.js examples/wasm_counter/wasm_counter.nim

import nimleptos/reactive/signal
import nimleptos/reactive/effects

when defined(wasm32):
  {.passC: "-include emscripten.h".}

# ─── EM_ASM DOM helpers ───

proc emSetTextById(id: cstring, text: cstring) {.inline.} =
  when defined(wasm32):
    {.emit: "EM_ASM({ document.getElementById(UTF8ToString($0)).innerText = UTF8ToString($1); }, `id`, `text`);".}

proc emSetClass(id: cstring, cls: cstring) {.inline.} =
  when defined(wasm32):
    {.emit: "EM_ASM({ document.getElementById(UTF8ToString($0)).className = UTF8ToString($1); }, `id`, `cls`);".}

# ─── Application State ───

let (count, setCount) = createSignal(0)
let (doubled, _) = createMemo(proc(): int = count() * 2)

# ─── Exports (called from JS via Module.ccall) ───

proc increment() {.exportc, cdecl.} =
  setCount(count() + 1)

proc decrement() {.exportc, cdecl.} =
  setCount(count() - 1)

proc getCount(): int32 {.exportc, cdecl.} =
  int32(count())

# ─── Render (called by JS after Module init) ───

proc render() {.exportc, cdecl.} =
  emSetTextById("count-display", "Count: 0")
  emSetTextById("doubled-display", "Doubled: 0")

  discard createEffect(proc() =
    let text = "Count: " & $count()
    emSetTextById("count-display", cstring(text))
  )

  discard createEffect(proc() =
    let text = "Doubled: " & $doubled()
    emSetTextById("doubled-display", cstring(text))
  )

  discard createEffect(proc() =
    let c = count()
    if c >= 10:
      emSetClass("count-display", "count-display hot")
    else:
      emSetClass("count-display", "count-display")
  )

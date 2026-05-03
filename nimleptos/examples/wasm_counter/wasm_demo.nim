## NimLeptos WASM Demo — explicit EM_ASM reactive DOM
## =====================================================
## Signals, memos, conditional rendering with direct EM_ASM DOM updates.
## Avoids buildHtml for wasm32 (function table limitation with closures).
##
## Build: source ~/emsdk/emsdk_env.sh && nim c --cpu:wasm32 --mm:arc --threads:on \
##   --cc:clang --clang.exe:emcc --clang.linkerexe:emcc \
##   --passC:"-sWASM=1" \
##   --passL:"-sWASM=1 -sMODULARIZE=1 -sEXPORT_NAME='WasmDemo' \
##     -sEXPORTED_FUNCTIONS=['_increment','_decrement','_reset','_render'] \
##     -sEXPORTED_RUNTIME_METHODS=['ccall','cwrap']" \
##   -p:src -o:wasm_demo.js examples/wasm_counter/wasm_demo.nim

import nimleptos/reactive/signal
import nimleptos/reactive/effects

when defined(wasm32):
  {.passC: "-include emscripten.h".}

# EM_ASM helpers
proc emSetText(id: cstring, text: cstring) {.inline.} =
  when defined(wasm32):
    {.emit: "EM_ASM({ document.getElementById(UTF8ToString($0)).innerText = UTF8ToString($1); }, `id`, `text`);".}

proc emSetHtml(id: cstring, html: cstring) {.inline.} =
  when defined(wasm32):
    {.emit: "EM_ASM({ document.getElementById(UTF8ToString($0)).innerHTML = UTF8ToString($1); }, `id`, `html`);".}

let (count, setCount) = createSignal(0)
let (doubled, _) = createMemo(proc(): int = count() * 2)

proc increment() {.exportc, cdecl.} = setCount(count() + 1)
proc decrement() {.exportc, cdecl.} = setCount(count() - 1)
proc reset() {.exportc, cdecl.} = setCount(0)

proc render() {.exportc, cdecl.} =
  # Count display
  emSetText("count", "0")

  # Memo display
  emSetHtml("memo-area", "Doubled: 0<br>Status: <span class='cool-badge'>cool</span>")

  discard createEffect(proc() =
    emSetText("count", cstring($count()))
  )

  discard createEffect(proc() =
    let d = doubled()
    let c = count()
    var status = ""
    if c >= 10:
      status = "Doubled: " & $d & "<br>Status: <span class='hot-badge'>HOT 🔥</span>"
    else:
      status = "Doubled: " & $d & "<br>Status: <span class='cool-badge'>cool</span>"
    emSetHtml("memo-area", cstring(status))
  )

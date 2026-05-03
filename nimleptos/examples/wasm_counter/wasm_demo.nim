## NimLeptos WASM Reactive Demo — Full buildHtml + wasmRender
## ==============================================================
## Demonstrates: signals, memos, conditional rendering, reactive attributes
## all compiled to WebAssembly via Emscripten.
##
## Build:
##   source ~/emsdk/emsdk_env.sh  
##   nim c --cpu:wasm32 --mm:arc --threads:on --cc:clang --clang.exe:emcc \
##     --clang.linkerexe:emcc --passC:"-sWASM=1" \
##     --passL:"-sWASM=1 -sMODULARIZE=1 -sEXPORT_NAME='WasmDemo' \
##       -sEXPORTED_FUNCTIONS=['_increment','_decrement','_reset','_mount'] \
##       -sEXPORTED_RUNTIME_METHODS=['ccall','cwrap']" \
##     -p:src -o:wasm_demo.js examples/wasm_counter/wasm_demo.nim

import nimleptos/reactive/signal
import nimleptos/reactive/effects
import nimleptos/macros/html_macros
import nimleptos/wasm/render

let (count, setCount) = createSignal(0)
let (doubled, _) = createMemo(proc(): int = count() * 2)
let (isHot, _) = createMemo(proc(): bool = count() >= 10)

proc increment() {.exportc, cdecl.} = setCount(count() + 1)
proc decrement() {.exportc, cdecl.} = setCount(count() - 1)
proc reset() {.exportc, cdecl.} = setCount(0)

proc demoApp(): HtmlNode =
  result = buildHtml:
    el("div", class="app"):
      el("h1", class="title"): text("NimLeptos WASM Demo")
      el("p", class="subtitle"):
        text("buildHtml + reactive signals in WebAssembly")

      el("div", class="counter-area"):
        el("div", class="count", id="count"):
          text($count())
        el("div", class="label"): text("clicks")

      el("div", class="memo-info"):
        text("Doubled: " & $doubled())
        el("br")
        text("Status: ")
        if isHot():
          el("span", class="hot-badge"): text("HOT")
        else:
          el("span", class="cool-badge"): text("cool")

      el("div", class="buttons"):
        el("button", id="btn-dec", class="btn btn-dec"): text("-")
        el("button", id="btn-reset", class="btn btn-reset"): text("0")
        el("button", id="btn-inc", class="btn btn-inc"): text("+")

proc mount() {.exportc, cdecl.} =
  wasmMountApp("app", demoApp)

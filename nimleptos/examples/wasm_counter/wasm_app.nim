## NimLeptos WASM Counter — using buildHtml macro + wasmRender
## ==============================================================
## Demonstrates the full NimLeptos HTML DSL compiled to WASM.
## Uses buildHtml macro to define the UI declaratively, then
## wasmRender converts the HtmlNode tree to real DOM via EM_ASM.
##
## Build:
##   source ~/emsdk/emsdk_env.sh
##   nimble wasmApp
##
## Then open index.html in a browser.

import nimleptos/reactive/signal
import nimleptos/reactive/effects
import nimleptos/macros/html_macros
import nimleptos/wasm/render

# ─── Application State ───

let (count, setCount) = createSignal(0)
let (doubled, _) = createMemo(proc(): int = count() * 2)

# ─── Exports (called from JS) ───

proc increment() {.exportc, cdecl.} =
  setCount(count() + 1)

proc decrement() {.exportc, cdecl.} =
  setCount(count() - 1)

proc getCount(): int32 {.exportc, cdecl.} =
  int32(count())

# ─── App Component ───

proc counterApp(): HtmlNode =
  result = buildHtml:
    el("div", class="counter-app"):
      el("h1", class="title"): text("NimLeptos WASM Counter")
      el("p", class="subtitle"): text("Reactive UI via buildHtml macro")
      el("div", class="count-display"):
        text("Count: " & $count())
      el("div", class="doubled-display"):
        text("Doubled: " & $doubled())
      el("div", class="buttons"):
        el("button", id="btn-dec", class="btn btn-dec"): text("-")
        el("button", id="btn-inc", class="btn btn-inc"): text("+")
      el("p", class="info"): text("NimLeptos reactive core + buildHtml in WASM")

proc mount() {.exportc, cdecl.} =
  wasmMountApp("app", counterApp)

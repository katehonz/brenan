## NimLeptos Reactive Counter — Nimbling WASM Edition
## ===================================================
## A reactive counter compiled to WASM via nimbling.
##
## Build:
##   nim c --cc:clang --os:standalone --mm:orc -d:wasm32 -p:src counter.nim
##   nimbling counter.wasm --out-dir pkg/ --target bundler
##
## Or use the nimble task:
##   nimble nimbling_counter

import nimbling
import nimleptos/reactive/signal
import nimleptos/reactive/effects
import nimleptos/wasm/dom_bridge

# ─── Reactive State ───

var countSig: Signal[int]
var countGetter: Getter[int]
var countSetter: Setter[int]

proc initCounter*(start: int32) {.wasmBindgen.} =
  ## Initialize the reactive counter with a starting value.
  let (g, s) = createSignal(start.int)
  countGetter = g
  countSetter = s

proc increment*() {.wasmBindgen.} =
  ## Increment the counter by 1.
  countSetter(countGetter() + 1)

proc decrement*() {.wasmBindgen.} =
  ## Decrement the counter by 1.
  countSetter(countGetter() - 1)

proc getCount*(): int32 {.wasmBindgen.} =
  ## Get the current count value.
  countGetter().int32

# ─── DOM Rendering ───

proc renderCounter*(targetId: string) {.wasmBindgen.} =
  ## Render the counter UI into the target DOM element.
  let doc = wasmGetDocument()
  let body = jsDocumentBody(doc)

  # Create container
  let container = wasmCreateElement("div")
  wasmSetAttribute(container, "id", targetId)
  wasmSetAttribute(container, "style", "font-family: sans-serif; padding: 20px;")

  # Create title
  let title = wasmCreateElement("h2")
  wasmSetInnerHTML(title, "Nimbling Reactive Counter")
  wasmAppendChild(container, JsNode(JsValue(idx: cast[JsValue](title).idx)))

  # Create display
  let display = wasmCreateElement("p")
  let displayIdx = cast[JsValue](display).idx
  wasmSetInnerHTML(display, "Count: " & $countGetter())
  wasmAppendChild(container, JsNode(JsValue(idx: displayIdx)))

  # Create increment button
  let incBtn = wasmCreateElement("button")
  wasmSetInnerHTML(incBtn, "+")
  wasmSetAttribute(incBtn, "style", "font-size: 18px; padding: 8px 16px; margin: 4px;")
  wasmAppendChild(container, JsNode(JsValue(idx: cast[JsValue](incBtn).idx)))

  # Create decrement button
  let decBtn = wasmCreateElement("button")
  wasmSetInnerHTML(decBtn, "-")
  wasmSetAttribute(decBtn, "style", "font-size: 18px; padding: 8px 16px; margin: 4px;")
  wasmAppendChild(container, JsNode(JsValue(idx: cast[JsValue](decBtn).idx)))

  # Attach reactive effect to update display
  discard createEffect(proc() =
    let d = JsElement(JsValue(idx: displayIdx))
    wasmSetInnerHTML(d, "Count: " & $countGetter())
  )

  # Append container to body
  wasmAppendChild(body, JsNode(JsValue(idx: cast[JsValue](container).idx)))

# ─── Finalize nimbling bindings ───
wasmBindgenFinalize()

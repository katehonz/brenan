## NimLeptos Reactive WASM DOM — Nimbling Edition
## ================================================
## Placeholder for WASM reactive DOM bindings.
##
## For Nimbling workflow, reactive core (signals, effects, store, resource)
## is exported via wasmBindgen and JS glue code handles DOM updates.
##
## See examples/nimbling_reactive/ for a full working example.

import ../reactive/signal
import ../reactive/effects
import ../dom/node
import ./dom_bridge

type
  WasmElement* = ref object
    ## Placeholder type for WASM DOM elements.
    ## In real Nimbling apps, DOM is manipulated from JS side.
    discard

proc reactiveTextNode*(getter: Getter[string]): WasmElement =
  discard

proc reactiveAttr*(el: WasmElement, name: string, getter: Getter[string]) =
  discard

proc reactiveClass*(el: WasmElement, getter: Getter[string]) =
  discard

proc reactiveStyle*(el: WasmElement, prop: string, getter: Getter[string]) =
  discard

proc renderDomNode*(node: HtmlNode): WasmElement =
  discard

proc clearChildren*(el: WasmElement) =
  discard

proc mountApp*(selector: string, builder: proc(): HtmlNode) =
  discard

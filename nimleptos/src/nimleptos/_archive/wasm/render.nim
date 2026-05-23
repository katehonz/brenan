## NimLeptos WASM Renderer — Nimbling Edition
## ===========================================
## Placeholder for WASM DOM renderer.
##
## For Nimbling workflow, reactive core is exported via wasmBindgen
## and JS glue code handles the actual DOM rendering.
##
## See examples/nimbling_reactive/ for a full working example.

import ../reactive/effects
import ../dom/node
import ./dom_bridge

proc wasmRender*(node: HtmlNode, targetId: string) =
  discard

proc wasmMountApp*(selector: string, builder: proc(): HtmlNode) {.exportc, cdecl.} =
  discard

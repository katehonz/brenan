## NimLeptos WASM DOM Bridge — Nimbling Edition
## ==============================================
## Placeholder module for WASM DOM bindings.
##
## For Nimbling workflow, reactive core is exported via wasmBindgen
## and JS glue code handles the actual DOM manipulation.
##
## See examples/nimbling_reactive/ for a full working example.

type
  DomId* = distinct int32
  JsValue* = object
    idx*: uint32

when defined(wasm32):
  ## WASM target: types are compatible with nimbling runtime
  discard
else:
  ## Native target: no-op stubs
  template domCreateElement*(tag: cstring): DomId = DomId(0)
  template domGetById*(id: cstring): DomId = DomId(0)
  template domSetText*(elId: DomId, text: cstring) = discard
  template domSetTextById*(id: cstring, text: cstring) = discard
  template domSetHtml*(elId: DomId, html: cstring) = discard
  template domSetAttribute*(elId: DomId, name: cstring, value: cstring) = discard
  template domSetClass*(elId: DomId, cls: cstring) = discard
  template domSetClassById*(id: cstring, cls: cstring) = discard
  template domSetStyle*(elId: DomId, prop: cstring, value: cstring) = discard
  template domAppendChild*(parentId: DomId, childId: DomId) = discard
  template domRemoveChild*(parentId: DomId, childId: DomId) = discard
  template domAddEventListener*(elId: DomId, event: cstring, handlerId: int32) = discard
  template domClearChildren*(elId: DomId) = discard

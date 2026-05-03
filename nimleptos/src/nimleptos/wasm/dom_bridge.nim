## NimLeptos WASM DOM Bridge
## ===========================
## Low-level DOM manipulation for WASM targets via Emscripten's EM_ASM.
##
## Provides a JsValue-based type system (compatible with nimbling's types)
## but uses EM_ASM for the actual DOM calls, which works with Emscripten's
## C→WASM compilation pipeline.
##
## When nimbling's web_sys is updated to support EM_ASM, switch the
## implementation to use nimbling/web_sys directly.

when defined(wasm32):
  {.passC: "-include emscripten.h".}

  type
    DomId* = distinct int32
    JsValue* = object
      idx*: uint32

  {.push inline.}

  proc domCreateElement*(tag: cstring): DomId {.discardable.} =
    {.emit: "`result` = (int)EM_ASM_INT({ var el = document.createElement(UTF8ToString($0)); el.id = 'nl-' + (__nbgNextId++); document.body.appendChild(el); return (int)el; }, `tag`);".}

  proc domGetById*(id: cstring): DomId {.discardable.} =
    {.emit: "`result` = (int)EM_ASM_INT({ var el = document.getElementById(UTF8ToString($0)); return el ? (int)el : 0; }, `id`);".}

  proc domSetText*(elId: DomId, text: cstring) =
    {.emit: "EM_ASM({ ((int)$0).textContent = UTF8ToString($1); }, `elId`, `text`);".}

  proc domSetTextById*(id: cstring, text: cstring) =
    {.emit: "EM_ASM({ document.getElementById(UTF8ToString($0)).innerText = UTF8ToString($1); }, `id`, `text`);".}

  proc domSetHtml*(elId: DomId, html: cstring) =
    {.emit: "EM_ASM({ ((int)$0).innerHTML = UTF8ToString($1); }, `elId`, `html`);".}

  proc domSetAttribute*(elId: DomId, name: cstring, value: cstring) =
    {.emit: "EM_ASM({ ((int)$0).setAttribute(UTF8ToString($1), UTF8ToString($2)); }, `elId`, `name`, `value`);".}

  proc domSetClass*(elId: DomId, cls: cstring) =
    {.emit: "EM_ASM({ ((int)$0).className = UTF8ToString($1); }, `elId`, `cls`);".}

  proc domSetClassById*(id: cstring, cls: cstring) =
    {.emit: "EM_ASM({ document.getElementById(UTF8ToString($0)).className = UTF8ToString($1); }, `id`, `cls`);".}

  proc domSetStyle*(elId: DomId, prop: cstring, value: cstring) =
    {.emit: "EM_ASM({ ((int)$0).style[UTF8ToString($1)] = UTF8ToString($2); }, `elId`, `prop`, `value`);".}

  proc domAppendChild*(parentId: DomId, childId: DomId) =
    {.emit: "EM_ASM({ ((int)$0).appendChild(((int)$1)); }, `parentId`, `childId`);".}

  proc domRemoveChild*(parentId: DomId, childId: DomId) =
    {.emit: "EM_ASM({ ((int)$0).removeChild(((int)$1)); }, `parentId`, `childId`);".}

  proc domAddEventListener*(elId: DomId, event: cstring, handlerId: int32) =
    {.emit: "EM_ASM({ ((int)$0).addEventListener(UTF8ToString($1), function(e) { Module.ccall('onEvent', 'void', ['number', 'number'], [$2, (int)e.target]); }); }, `elId`, `event`, `handlerId`);".}

  proc domClearChildren*(elId: DomId) =
    {.emit: "EM_ASM({ var el = ((int)$0); while (el.firstChild) el.removeChild(el.firstChild); }, `elId`);".}

  {.pop.}

  var nbgNextId {.exportc: "__nbgNextId".}: int32 = 0

else:
  type
    DomId* = distinct int32
    JsValue* = object
      idx*: uint32

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

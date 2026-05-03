## NimLeptos WASM DOM Renderer — v2 (with JS-side element registry)
## =====================================================================
## Converts HtmlNode tree to real DOM elements via EM_ASM.
## Uses __nbgEls (JS-side Map) to map integer handles to DOM nodes.
##
## Compile with:
##   source ~/emsdk/emsdk_env.sh
##   nim c --cpu:wasm32 --mm:arc --cc:clang --clang.exe:emcc --clang.linkerexe:emcc \
##     --passC:"-sWASM=1" --passL:"-sWASM=1 -sMODULARIZE=1 ..." \
##     -p:src -o:out.js file.nim
##
## The HTML must define __nbgEls before loading the WASM module:
##   <script>var __nbgEls = {};</script>

import ../reactive/effects
import ../dom/node

when defined(wasm32):
  {.passC: "-include emscripten.h".}

# ─── EM_ASM DOM primitives ───
# All DOM operations go through __nbgEls[handle] for element lookup.
# __nbgEls is a JS global Map/Object from int handle → DOM node.

proc nbgCreateElement(tag: cstring): int32 {.inline.} =
  when defined(wasm32):
    {.emit: "`result` = (int)EM_ASM_INT({ var el = document.createElement(UTF8ToString($0)); var h = __nbgNextHandle++; __nbgEls[h] = el; return h; }, `tag`);".}
  else:
    result = 0

proc nbgCreateTextNode(text: cstring): int32 {.inline.} =
  when defined(wasm32):
    {.emit: "`result` = (int)EM_ASM_INT({ var tn = document.createTextNode(UTF8ToString($0)); var h = __nbgNextHandle++; __nbgEls[h] = tn; return h; }, `text`);".}
  else:
    result = 0

proc nbgSetAttribute(elHandle: int32, name: cstring, value: cstring) {.inline.} =
  when defined(wasm32):
    {.emit: "EM_ASM({ __nbgEls[$0].setAttribute(UTF8ToString($1), UTF8ToString($2)); }, `elHandle`, `name`, `value`);".}

proc nbgSetTextContent(nodeHandle: int32, text: cstring) {.inline.} =
  when defined(wasm32):
    {.emit: "EM_ASM({ __nbgEls[$0].textContent = UTF8ToString($1); }, `nodeHandle`, `text`);".}

proc nbgAppendChild(parentHandle: int32, childHandle: int32) {.inline.} =
  when defined(wasm32):
    {.emit: "EM_ASM({ __nbgEls[$0].appendChild(__nbgEls[$1]); }, `parentHandle`, `childHandle`);".}

proc nbgRemoveAllChildren(parentHandle: int32) {.inline.} =
  when defined(wasm32):
    {.emit: "EM_ASM({ var el = __nbgEls[$0]; while (el.firstChild) el.removeChild(el.firstChild); }, `parentHandle`);".}

proc nbgGetElementById(id: cstring): int32 {.inline.} =
  when defined(wasm32):
    {.emit: "`result` = (int)EM_ASM_INT({ var el = document.getElementById(UTF8ToString($0)); if (!el) return 0; var h = __nbgNextHandle++; __nbgEls[h] = el; return h; }, `id`);".}
  else:
    result = 0

proc nbgReplaceChild(parentHandle: int32, newHandle: int32, oldHandle: int32) {.inline.} =
  when defined(wasm32):
    {.emit: "EM_ASM({ __nbgEls[$0].replaceChild(__nbgEls[$1], __nbgEls[$2]); }, `parentHandle`, `newHandle`, `oldHandle`);".}

proc nbgSetStyle(handle: int32, prop: cstring, value: cstring) {.inline.} =
  when defined(wasm32):
    {.emit: "EM_ASM({ __nbgEls[$0].style[UTF8ToString($1)] = UTF8ToString($2); }, `handle`, `prop`, `value`);".}

# ─── Render HtmlNode → DOM ───

proc renderNode(node: HtmlNode): int32 =
  if node.isText:
    if node.reactiveText != nil:
      let initialText = node.reactiveText()
      let handle = nbgCreateTextNode(cstring(initialText))
      discard createEffect(proc() =
        let newText = node.reactiveText()
        nbgSetTextContent(handle, cstring(newText))
      )
      return handle
    else:
      return nbgCreateTextNode(cstring(node.text))

  if node.condition != nil:
    let wrapper = nbgCreateElement("div")
    nbgSetStyle(wrapper, "display", "contents")

    let thenEl = renderNode(node.thenBranch)
    let elseEl = renderNode(node.elseBranch)

    if node.condition():
      nbgAppendChild(wrapper, thenEl)
    else:
      nbgAppendChild(wrapper, elseEl)

    discard createEffect(proc() =
      if node.condition():
        nbgRemoveAllChildren(wrapper)
        nbgAppendChild(wrapper, thenEl)
      else:
        nbgRemoveAllChildren(wrapper)
        nbgAppendChild(wrapper, elseEl)
    )
    return wrapper

  let el = nbgCreateElement(cstring(node.tag))

  for (key, value) in node.attributes:
    nbgSetAttribute(el, cstring(key), cstring(value))

  for (name, getter) in node.reactiveAttrs:
    let attrName = name
    let attrGetter = getter
    nbgSetAttribute(el, cstring(attrName), cstring(attrGetter()))
    discard createEffect(proc() =
      nbgSetAttribute(el, cstring(attrName), cstring(attrGetter()))
    )

  for child in node.children:
    let childHandle = renderNode(child)
    nbgAppendChild(el, childHandle)

  return el

# ─── Mount to DOM ───

proc wasmRender*(node: HtmlNode, targetId: string) =
  when defined(wasm32):
    let target = nbgGetElementById(cstring(targetId))
    if target == 0:
      return
    nbgRemoveAllChildren(target)
    let rootHandle = renderNode(node)
    nbgAppendChild(target, rootHandle)

proc wasmMountApp*(selector: string, builder: proc(): HtmlNode) {.exportc, cdecl.} =
  when defined(wasm32):
    let node = builder()
    wasmRender(node, selector)

when defined(js):
  import std/dom
  import std/jsffi

  type
    DomElement* = Element

  proc getElementById*(id: string): DomElement =
    document.getElementById(id)

  proc querySelector*(selector: string): DomElement =
    document.querySelector(cstring(selector))

  proc querySelector*(el: DomElement, selector: string): DomElement =
    el.querySelector(cstring(selector))

  proc querySelectorAll*(selector: string): seq[DomElement] =
    let nodeList = document.querySelectorAll(selector)
    result = @[]
    for i in 0 ..< nodeList.len:
      result.add(nodeList[i])

  proc setAttribute*(el: DomElement, name: string, value: string) =
    el.setAttribute(cstring(name), cstring(value))

  proc getAttribute*(el: DomElement, name: string): string =
    $el.getAttribute(cstring(name))

  proc removeAttribute*(el: DomElement, name: string) =
    el.removeAttribute(cstring(name))

  proc setInnerHtml*(el: DomElement, html: string) =
    el.innerHTML = cstring(html)

  proc getInnerHtml*(el: DomElement): string =
    $el.innerHTML

  proc setTextContent*(el: DomElement, text: string) =
    el.textContent = cstring(text)

  proc getTextContent*(el: DomElement): string =
    $el.textContent

  proc stdAddEventListener(el: DomElement, event: cstring,
      handler: proc(e: Event) {.closure.}) {.importcpp: "addEventListener".}

  proc stdRemoveEventListener(el: DomElement, event: cstring,
      handler: proc(e: Event) {.closure.}) {.importcpp: "removeEventListener".}

  proc addEventListener*(el: DomElement, event: string,
      handler: proc(e: Event) {.closure.}) =
    stdAddEventListener(el, cstring(event), handler)

  proc removeEventListener*(el: DomElement, event: string,
      handler: proc(e: Event) {.closure.}) =
    stdRemoveEventListener(el, cstring(event), handler)

  proc createElement*(tag: string): DomElement =
    document.createElement(cstring(tag))

  proc createTextNode*(text: string): DomElement =
    cast[DomElement](document.createTextNode(cstring(text)))

  proc stdAppendChild(parent, child: Node): Node {.importcpp: "#.appendChild(#)".}
  proc stdRemoveChild(parent, child: Node): Node {.importcpp: "#.removeChild(#)".}

  proc appendChild*(parent, child: DomElement) =
    discard stdAppendChild(parent, child)

  proc removeChild*(parent, child: DomElement) =
    discard stdRemoveChild(parent, child)

  proc setStyle*(el: DomElement, prop: string, value: string) =
    el.style.setProperty(cstring(prop), cstring(value))

  # ─── classList helpers ───

  proc classListAdd(el: DomElement, cls: cstring) {.importcpp: "#.classList.add(#)".}
  proc classListRemove(el: DomElement, cls: cstring) {.importcpp: "#.classList.remove(#)".}
  proc classListToggle(el: DomElement, cls: cstring) {.importcpp: "#.classList.toggle(#)".}
  proc classListContains(el: DomElement, cls: cstring): bool {.importcpp: "#.classList.contains(#)".}

  proc addClass*(el: DomElement, cls: string) =
    classListAdd(el, cstring(cls))

  proc removeClass*(el: DomElement, cls: string) =
    classListRemove(el, cstring(cls))

  proc toggleClass*(el: DomElement, cls: string) =
    classListToggle(el, cstring(cls))

  proc hasClass*(el: DomElement, cls: string): bool =
    classListContains(el, cstring(cls))

  # ─── dataset helper ───

  proc datasetSet(el: DomElement, name: cstring, value: cstring) {.importcpp: "#.dataset[#] = #".}
  proc datasetGet(el: DomElement, name: cstring): cstring {.importcpp: "#.dataset[#] || ''".}

  proc setDataAttr*(el: DomElement, name: string, value: string) =
    datasetSet(el, cstring(name), cstring(value))

  proc getDataAttr*(el: DomElement, name: string): string =
    $datasetGet(el, cstring(name))

  # ─── focus / blur / scroll ───

  proc focusElement*(el: DomElement) =
    {.emit: ["", el, ".focus();"].}

  proc blurElement*(el: DomElement) =
    {.emit: ["", el, ".blur();"].}

  proc scrollIntoView*(el: DomElement) =
    {.emit: ["", el, ".scrollIntoView({ behavior: 'smooth' });"].}

  # ─── requestAnimationFrame ───

  proc requestAnimationFrame*(callback: proc(timestamp: float) {.closure.}): int =
    dom.window.requestAnimationFrame(callback)

  proc cancelAnimationFrame*(id: int) =
    dom.window.cancelAnimationFrame(id)

  # ─── IntersectionObserver helper ───

  type
    IntersectionObserverCallback* = proc(entries: seq[DomElement], observer: JsObject) {.closure.}

  proc observeElement*(observer: JsObject, el: DomElement) =
    {.emit: ["", observer, ".observe(", el, ");"].}

  proc unobserveElement*(observer: JsObject, el: DomElement) =
    {.emit: ["", observer, ".unobserve(", el, ");"].}

  proc disconnectObserver*(observer: JsObject) =
    {.emit: ["", observer, ".disconnect();"].}

  proc createIntersectionObserver*(
    callback: IntersectionObserverCallback,
    root: DomElement = nil,
    rootMargin: string = "0px",
    threshold: float = 0.0
  ): JsObject =
    {.emit: [
      "var __root = ", (if root == nil: "null" else: ""),
      "; if (", (if root == nil: "false" else: "true"), ") { __root = ", root, "; }",
      "var __tmp = new IntersectionObserver(function(entries) {",
      "  var mapped = entries.map(function(e) { return e.target; });",
      "  ", callback, "(mapped, result);",
      "}, {",
      "  root: __root,",
      "  rootMargin: '", rootMargin, "',",
      "  threshold: ", threshold,
      "});",
      "result = __tmp;"
    ].}

else:
  type
    DomElement* = ref object
      discard

when defined(js):
  import std/dom

  type
    DomElement* = Element

  proc getElementById*(id: string): DomElement =
    document.getElementById(id)

  proc querySelector*(selector: string): DomElement =
    document.querySelector(selector)

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
    $el.getAttribute(name)

  proc setInnerHtml*(el: DomElement, html: string) =
    el.innerHTML = cstring(html)

  proc getInnerHtml*(el: DomElement): string =
    $el.innerHTML

  proc setTextContent*(el: DomElement, text: string) =
    el.textContent = cstring(text)

  proc getTextContent*(el: DomElement): string =
    $el.textContent

  proc addEventListener*(el: DomElement, event: string,
      handler: proc(e: Event) {.closure.}) =
    el.addEventListener(event, handler)

  proc createElement*(tag: string): DomElement =
    document.createElement(cstring(tag))

  proc createTextNode*(text: string): DomElement =
    cast[DomElement](document.createTextNode(cstring(text)))

  proc appendChild*(parent, child: DomElement) =
    parent.appendChild(child)

  proc removeChild*(parent, child: DomElement) =
    parent.removeChild(child)

  proc setStyle*(el: DomElement, prop: string, value: string) =
    el.style.setProperty(cstring(prop), cstring(value))
else:
  type
    DomElement* = ref object
      discard

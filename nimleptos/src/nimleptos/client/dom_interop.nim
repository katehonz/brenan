when defined(js):
  import std/dom

  type
    DomElement* = Element

  proc getElementById*(id: string): DomElement =
    document.getElementById(id)

  proc querySelector*(selector: string): DomElement =
    document.querySelector(selector)

  proc querySelectorAll*(selector: string): seq[DomElement] =
    let nodeList = document.querySelectorAll(selector)
    result = @[]
    for i in 0 ..< nodeList.length:
      result.add(nodeList[i])

  proc setAttribute*(el: DomElement, name: string, value: string) =
    el.setAttribute(name, value)

  proc getAttribute*(el: DomElement, name: string): string =
    $el.getAttribute(name)

  proc setInnerHtml*(el: DomElement, html: string) =
    el.innerHTML = html

  proc getInnerHtml*(el: DomElement): string =
    $el.innerHTML

  proc addEventListener*(el: DomElement, event: string,
      handler: proc(e: Event) {.closure.}) =
    el.addEventListener(event, handler)

  proc createElement*(tag: string): DomElement =
    document.createElement(tag)

  proc createTextNode*(text: string): DomElement =
    document.createTextNode(text)

  proc appendChild*(parent, child: DomElement) =
    parent.appendChild(child)

  proc removeChild*(parent, child: DomElement) =
    parent.removeChild(child)

  proc setStyle*(el: DomElement, prop: string, value: string) =
    el.style.setProperty(prop, value)
else:
  type
    DomElement* = ref object
      discard

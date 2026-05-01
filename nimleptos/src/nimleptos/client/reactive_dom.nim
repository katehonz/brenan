import ../reactive/signal
import ../dom/node

when defined(js):
  import std/dom
  import ../reactive/effects
  import ./dom_interop
  import ./event_handlers

  proc renderDomNode*(node: HtmlNode): DomElement =
    ## Convert HtmlNode tree to real DOM elements
    if node.isText:
      return createTextNode(node.text)
    result = createElement(node.tag)
    for (key, value) in node.attributes:
      result.setAttribute(key, value)
    for child in node.children:
      result.appendChild(renderDomNode(child))

  proc reactiveTextNode*(getter: Getter[string]): DomElement =
    ## Create a text node that automatically updates when the signal changes.
    ## Usage:
    ##   let (count, setCount) = createSignal(0)
    ##   let textEl = reactiveTextNode(proc(): string = $count())
    ##   appendChild(parent, textEl)
    let textNode = createTextNode(getter())
    discard createEffect(proc() =
      setTextContent(textNode, getter())
    )
    return textNode

  proc reactiveAttr*(el: DomElement, name: string, getter: Getter[string]) =
    ## Bind a DOM attribute to a signal so it updates automatically.
    el.setAttribute(name, getter())
    discard createEffect(proc() =
      el.setAttribute(name, getter())
    )

  proc reactiveClass*(el: DomElement, getter: Getter[string]) =
    ## Bind the 'class' attribute to a signal.
    el.setAttribute("class", getter())
    discard createEffect(proc() =
      el.setAttribute("class", getter())
    )

  proc reactiveStyle*(el: DomElement, prop: string, getter: Getter[string]) =
    ## Bind a CSS style property to a signal.
    setStyle(el, prop, getter())
    discard createEffect(proc() =
      setStyle(el, prop, getter())
    )

  proc clearChildren*(el: DomElement) =
    ## Remove all child nodes from an element.
    while el.firstChild != nil:
      el.removeChild(el.firstChild)

  proc mountApp*(selector: string, builder: proc(): HtmlNode) =
    ## Mount a NimLeptos app to a DOM element (client-side rendering).
    ## Clears the target element and renders the app inside it.
    let root = querySelector(selector)
    if root == nil:
      echo "mountApp: selector not found: " & selector
      return
    clearChildren(root)
    let node = builder()
    root.appendChild(renderDomNode(node))
    initEventHandlers()

  proc mountReactiveApp*(selector: string, builder: proc(): seq[DomElement]) =
    ## Mount reactive DOM elements directly (fine-grained control).
    let root = querySelector(selector)
    if root == nil:
      echo "mountReactiveApp: selector not found: " & selector
      return
    clearChildren(root)
    for el in builder():
      root.appendChild(el)
    initEventHandlers()

else:
  type
    DomElement* = ref object
      discard

  proc renderDomNode*(node: HtmlNode): DomElement =
    discard

  proc reactiveTextNode*(getter: Getter[string]): DomElement =
    discard

  proc reactiveAttr*(el: DomElement, name: string, getter: Getter[string]) =
    discard

  proc reactiveClass*(el: DomElement, getter: Getter[string]) =
    discard

  proc reactiveStyle*(el: DomElement, prop: string, getter: Getter[string]) =
    discard

  proc clearChildren*(el: DomElement) =
    discard

  proc mountApp*(selector: string, builder: proc(): HtmlNode) =
    discard

  proc mountReactiveApp*(selector: string, builder: proc(): seq[DomElement]) =
    discard

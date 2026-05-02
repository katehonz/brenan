import ../reactive/signal
import ../dom/node

when defined(js):
  import std/dom
  import ../reactive/effects
  import ./dom_interop
  import ./event_handlers

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

  proc renderDomNode*(node: HtmlNode): DomElement =
    ## Convert HtmlNode tree to real DOM elements.
    ## If a text node has `reactiveText`, it becomes a live-updating text node.
    ## If an element has `reactiveAttrs`, they are bound to the DOM element.
    ## If a node has `condition`, it becomes a reactive if/else block.
    if node.isText:
      if node.reactiveText != nil:
        return reactiveTextNode(node.reactiveText)
      return createTextNode(node.text)
    if node.condition != nil:
      let wrapper = createElement("div")
      wrapper.style.setProperty("display", "contents")
      let thenEl = renderDomNode(node.thenBranch)
      let elseEl = renderDomNode(node.elseBranch)
      var currentIsThen = node.condition()
      if currentIsThen:
        wrapper.appendChild(thenEl)
      else:
        wrapper.appendChild(elseEl)
      discard createEffect(proc() =
        let cond = node.condition()
        if cond != currentIsThen:
          if cond:
            if wrapper.firstChild != nil:
              wrapper.replaceChild(thenEl, wrapper.firstChild)
            else:
              wrapper.appendChild(thenEl)
          else:
            if wrapper.firstChild != nil:
              wrapper.replaceChild(elseEl, wrapper.firstChild)
            else:
              wrapper.appendChild(elseEl)
          currentIsThen = cond
      )
      return wrapper
    result = createElement(node.tag)
    for (key, value) in node.attributes:
      result.setAttribute(key, value)
    for (name, getter) in node.reactiveAttrs:
      reactiveAttr(result, name, getter)
    for (eventName, handler) in node.domEventHandlers:
      result.addEventListener(eventName, handler)
    for child in node.children:
      result.appendChild(renderDomNode(child))

  proc clearChildren*(el: DomElement) =
    ## Remove all child nodes from an element.
    while el.firstChild != nil:
      el.removeChild(el.firstChild)

  proc mountApp*(selector: string, builder: proc(): HtmlNode,
      afterMount: proc(root: DomElement) = nil) =
    ## Mount a NimLeptos app to a DOM element (client-side rendering).
    ## Clears the target element and renders the app inside it.
    ## Optional `afterMount` callback receives the rendered root DomElement.
    let mountRoot = querySelector(selector)
    if mountRoot == nil:
      echo "mountApp: selector not found: " & selector
      return
    clearChildren(mountRoot)
    let node = builder()
    let root = renderDomNode(node)
    mountRoot.appendChild(root)
    if afterMount != nil:
      afterMount(root)
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

  proc mountApp*(selector: string, builder: proc(): HtmlNode,
      afterMount: proc(root: DomElement) = nil) =
    discard

  proc mountReactiveApp*(selector: string, builder: proc(): seq[DomElement]) =
    discard

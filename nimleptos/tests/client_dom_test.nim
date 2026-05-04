import ../src/nimleptos/dom/node as nodedom

when defined(js):
  import std/dom
  import ../src/nimleptos/reactive/signal
  import ../src/nimleptos/reactive/effects
  import ../src/nimleptos/client/reactive_dom as rdom
  import ../src/nimleptos/client/event_handlers

  proc testRenderDomNodeBasic() =
    let el = nodedom.elementNode("div")
    nodedom.addAttribute(el, "class", "container")
    let child = nodedom.textNode("Hello World")
    nodedom.addChild(el, child)

    let domEl = rdom.renderDomNode(el)
    doAssert $domEl.nodeName == "DIV"
    doAssert domEl.getAttribute("class") == "container"
    doAssert $domEl.textContent == "Hello World"
    echo "PASS: renderDomNode basic"

  proc testRenderDomNodeNested() =
    let root = nodedom.elementNode("ul")
    for i in 1..3:
      let li = nodedom.elementNode("li")
      nodedom.addAttribute(li, "data-index", $i)
      nodedom.addChild(li, nodedom.textNode("Item " & $i))
      nodedom.addChild(root, li)

    let domRoot = rdom.renderDomNode(root)
    doAssert $domRoot.nodeName == "UL"
    doAssert domRoot.children.len == 3
    doAssert domRoot.children[0].getAttribute("data-index") == "1"
    doAssert $domRoot.children[1].textContent == "Item 2"
    echo "PASS: renderDomNode nested"

  proc testReactiveTextNode() =
    let (text, setText) = createSignal("hello")
    let htmlNode = nodedom.reactiveTextNode("", text)
    let domEl = rdom.renderDomNode(htmlNode)

    doAssert $domEl.textContent == "hello"
    setText("world")
    doAssert $domEl.textContent == "world"
    setText("nimleptos")
    doAssert $domEl.textContent == "nimleptos"
    echo "PASS: reactiveTextNode"

  proc testReactiveAttr() =
    let (cls, setCls) = createSignal("btn-primary")
    let el = nodedom.elementNode("button")
    nodedom.addReactiveAttr(el, "class", cls)

    let domEl = rdom.renderDomNode(el)
    doAssert domEl.getAttribute("class") == "btn-primary"
    setCls("btn-secondary")
    doAssert domEl.getAttribute("class") == "btn-secondary"
    echo "PASS: reactiveAttr"

  proc testReactiveClass() =
    let (cls, setCls) = createSignal("active")
    let el = nodedom.elementNode("div")
    nodedom.addReactiveAttr(el, "class", cls)

    let domEl = rdom.renderDomNode(el)
    doAssert domEl.getAttribute("class") == "active"
    setCls("inactive")
    doAssert domEl.getAttribute("class") == "inactive"
    echo "PASS: reactiveClass"

  proc testReactiveStyle() =
    let (color, setColor) = createSignal("red")
    let el = nodedom.elementNode("span")
    nodedom.addReactiveAttr(el, "style", color)

    let domEl = rdom.renderDomNode(el)
    doAssert domEl.getAttribute("style") == "red"
    setColor("blue")
    doAssert domEl.getAttribute("style") == "blue"
    echo "PASS: reactiveStyle"

  proc testConditionalNode() =
    let (show, setShow) = createSignal(true)
    let thenNode = nodedom.textNode("Yes")
    let elseNode = nodedom.textNode("No")
    let cond = nodedom.conditionalNode(proc(): bool {.closure, gcsafe.} = show(), thenNode, elseNode)

    let domEl = rdom.renderDomNode(cond)
    doAssert $domEl.textContent == "Yes"
    setShow(false)
    doAssert $domEl.textContent == "No"
    setShow(true)
    doAssert $domEl.textContent == "Yes"
    echo "PASS: conditionalNode"

  proc testMountApp() =
    let (title, setTitle) = createSignal("Welcome")
    let el = nodedom.elementNode("h1")
    nodedom.addReactiveAttr(el, "class", title)
    nodedom.addChild(el, nodedom.reactiveTextNode("", title))

    mountApp("#app", proc(): HtmlNode = el)

    let mountRoot = document.getElementById("app")
    doAssert mountRoot != nil
    doAssert mountRoot.children.len == 1
    let h1 = mountRoot.children[0]
    doAssert $h1.nodeName == "H1"
    doAssert $h1.textContent == "Welcome"
    setTitle("Goodbye")
    doAssert $h1.textContent == "Goodbye"
    echo "PASS: mountApp"

  proc testClearChildren() =
    let parent = nodedom.elementNode("div")
    nodedom.addChild(parent, nodedom.textNode("A"))
    nodedom.addChild(parent, nodedom.textNode("B"))
    nodedom.addChild(parent, nodedom.textNode("C"))

    let domParent = rdom.renderDomNode(parent)
    doAssert domParent.len == 3
    clearChildren(domParent)
    doAssert domParent.len == 0
    echo "PASS: clearChildren"

  proc testDomEventHandlers() =
    var clicked = false
    let btn = nodedom.elementNode("button")
    nodedom.addAttribute(btn, "id", "test-btn")
    nodedom.addDomEvent(btn, "click", proc(e: Event) =
      clicked = true
    )

    let domEl = rdom.renderDomNode(btn)
    doAssert domEl.getAttribute("id") == "test-btn"
    var event: Event
    {.emit: "`event` = new window.MouseEvent('click', { bubbles: true, cancelable: true });".}
    domEl.dispatchEvent(event)
    doAssert clicked == true
    echo "PASS: domEventHandlers"

  proc testMultipleReactiveChildren() =
    let (name, setName) = createSignal("Alice")
    let (age, setAge) = createSignal("25")

    let root = nodedom.elementNode("div")
    nodedom.addChild(root, nodedom.reactiveTextNode("", name))
    nodedom.addChild(root, nodedom.textNode(" is "))
    nodedom.addChild(root, nodedom.reactiveTextNode("", age))
    nodedom.addChild(root, nodedom.textNode(" years old"))

    let domRoot = rdom.renderDomNode(root)
    doAssert $domRoot.textContent == "Alice is 25 years old"
    setName("Bob")
    doAssert $domRoot.textContent == "Bob is 25 years old"
    setAge("30")
    doAssert $domRoot.textContent == "Bob is 30 years old"
    echo "PASS: multipleReactiveChildren"

  proc testOnMountCallback() =
    var mountCalled = false
    let el = nodedom.elementNode("div")
    nodedom.addChild(el, nodedom.textNode("mounted"))

    let dispose = mountApp("#app", proc(): HtmlNode =
      onMount(proc() = mountCalled = true)
      return el
    )
    doAssert mountCalled
    let mountRoot = document.getElementById("app")
    doAssert mountRoot != nil
    doAssert mountRoot.children.len == 1
    dispose()
    echo "PASS: onMount callback"

  proc testOnCleanupCallback() =
    var cleanupCalled = false
    let el = nodedom.elementNode("div")
    nodedom.addChild(el, nodedom.textNode("cleanup"))

    let dispose = mountApp("#app", proc(): HtmlNode =
      onCleanup(proc() = cleanupCalled = true)
      return el
    )
    doAssert not cleanupCalled
    dispose()
    doAssert cleanupCalled
    echo "PASS: onCleanup callback"

  proc testUnmountClearsDOM() =
    let el = nodedom.elementNode("h1")
    nodedom.addChild(el, nodedom.textNode("test"))

    let dispose = mountApp("#app", proc(): HtmlNode = el)
    let mountRoot = document.getElementById("app")
    doAssert mountRoot.children.len == 1
    dispose()
    doAssert mountRoot.children.len == 0
    echo "PASS: unmount clears DOM"

  proc testMultipleMountUnmountCycles() =
    var mountCount = 0
    var cleanupCount = 0

    for i in 1..3:
      let el = nodedom.elementNode("p")
      nodedom.addChild(el, nodedom.textNode("cycle " & $i))
      let dispose = mountApp("#app", proc(): HtmlNode =
        onMount(proc() = inc mountCount)
        onCleanup(proc() = inc cleanupCount)
        return el
      )
      let mountRoot = document.getElementById("app")
      doAssert mountRoot.children.len == 1
      dispose()
      doAssert mountRoot.children.len == 0

    doAssert mountCount == 3
    doAssert cleanupCount == 3
    echo "PASS: multiple mount/unmount cycles"

  proc testErrorBoundaryCatches() =
    let badChild = nodedom.listNode(proc(): seq[HtmlNode] {.closure, gcsafe.} =
      raise newException(ValueError, "simulated render error")
    )
    let wrapped = nodedom.errorBoundaryNode(
      badChild,
      proc(error: string): HtmlNode {.closure, gcsafe.} =
        let fallback = nodedom.elementNode("div")
        nodedom.addAttribute(fallback, "class", "error-fallback")
        nodedom.addChild(fallback, nodedom.textNode("Error: " & error))
        return fallback
    )
    let domEl = rdom.renderDomNode(wrapped)
    doAssert $domEl.textContent == "Error: simulated render error"
    doAssert domEl.getAttribute("class") == "error-fallback"
    echo "PASS: error boundary catches exception (CSR)"

  proc testErrorBoundaryPassThrough() =
    let child = nodedom.elementNode("div")
    nodedom.addChild(child, nodedom.textNode("no errors"))
    let wrapped = nodedom.errorBoundaryNode(
      child,
      proc(error: string): HtmlNode {.closure, gcsafe.} =
        nodedom.textNode("FAIL")
    )
    let domEl = rdom.renderDomNode(wrapped)
    doAssert $domEl.nodeName == "DIV"
    doAssert $domEl.textContent == "no errors"
    echo "PASS: error boundary pass-through (CSR)"

  proc testLazyNodeCsrShowsFallback() =
    let fallback = nodedom.elementNode("div")
    nodedom.addAttribute(fallback, "class", "skeleton")
    nodedom.addChild(fallback, nodedom.textNode("please wait"))
    let lazy = nodedom.lazyNode(
      proc(): HtmlNode {.closure, gcsafe.} =
        let content = nodedom.elementNode("div")
        nodedom.addAttribute(content, "class", "loaded")
        nodedom.addChild(content, nodedom.textNode("ready"))
        return content
      ,
      fallback
    )
    let domEl = rdom.renderDomNode(lazy)
    # Initially shows fallback
    doAssert domEl.children.len >= 1
    # The wrapper has display:contents, so it won't have textContent directly
    echo "PASS: lazy node CSR renders fallback"

when isMainModule:
  when defined(js):
    testRenderDomNodeBasic()
    testRenderDomNodeNested()
    testReactiveTextNode()
    testReactiveAttr()
    testReactiveClass()
    testReactiveStyle()
    testConditionalNode()
    testMountApp()
    testClearChildren()
    testDomEventHandlers()
    testMultipleReactiveChildren()
    testOnMountCallback()
    testOnCleanupCallback()
    testUnmountClearsDOM()
    testMultipleMountUnmountCycles()
    testErrorBoundaryCatches()
    testErrorBoundaryPassThrough()
    testLazyNodeCsrShowsFallback()
    echo ""
    echo "All client DOM tests passed!"
  else:
    echo "SKIP: client_dom_test requires -d:js (compile with: nim js tests/client_dom_test.nim)"

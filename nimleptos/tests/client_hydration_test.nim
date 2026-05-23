## Client Hydration Tests — SSR → hydration cycle
## Compile: nim js -p:src tests/client_hydration_test.nim
## Run:     node --require ./tests/jsdom_setup.js tests/client_hydration_test.js

when defined(js):
  import std/dom
  import std/json
  import ../src/nimleptos/client/hydration_client as hydr
  import ../src/nimleptos/client/dom_interop as domi

  proc testLoadHydrationDataMissing() =
    # Remove data element if exists
    let existing = domi.getElementById("__nimleptos_data__")
    if existing != nil:
      existing.parentNode.removeChild(existing)
    let state = hydr.loadHydrationData()
    doAssert state.nextId == 0
    doAssert state.nodeCount == 0
    doAssert not state.hydrated
    echo "PASS: loadHydrationData missing element"

  proc testLoadHydrationDataValid() =
    let dataEl = domi.createElement("script")
    dataEl.setAttribute("id", "__nimleptos_data__")
    dataEl.setAttribute("type", "application/json")
    dataEl.textContent = "{\"nextId\": 5, \"initialState\": {\"user\": \"alice\"}}"
    document.body.appendChild(dataEl)

    let state = hydr.loadHydrationData()
    doAssert state.nextId == 5
    doAssert state.initialState.kind == JObject

    # Cleanup
    document.body.removeChild(dataEl)
    echo "PASS: loadHydrationData valid JSON"

  proc testHydrateNodesFindsElements() =
    let container = domi.createElement("div")
    container.setAttribute("id", "hydration-test-container")
    let child1 = domi.createElement("span")
    child1.setAttribute("data-nl-id", "1")
    let child2 = domi.createElement("span")
    child2.setAttribute("data-nl-id", "2")
    container.appendChild(child1)
    container.appendChild(child2)
    document.body.appendChild(container)

    let nodes = hydr.hydrateNodes()
    doAssert nodes.len == 2
    doAssert domi.hasClass(nodes[0], "data-nl-hydrated") or nodes[0].getAttribute("data-nl-hydrated") == "true"

    # Cleanup
    document.body.removeChild(container)
    echo "PASS: hydrateNodes finds elements"

  proc testOnHydrateCallback() =
    var called = false
    var receivedId = ""
    hydr.onHydrate(proc(node: DomElement, nlId: string) =
      called = true
      receivedId = nlId
    )

    let el = domi.createElement("div")
    el.setAttribute("data-nl-id", "99")
    document.body.appendChild(el)

    discard hydr.hydrateNodes()
    doAssert called
    doAssert receivedId == "99"

    # Cleanup
    document.body.removeChild(el)
    # Reset callbacks (not exposed, but next tests will add more)
    echo "PASS: onHydrate callback invoked"

  proc testGetInitialValue() =
    let dataEl = domi.createElement("script")
    dataEl.setAttribute("id", "__nimleptos_data__")
    dataEl.setAttribute("type", "application/json")
    dataEl.textContent = "{\"initialState\": {\"theme\": \"dark\", \"count\": \"42\"}}"
    document.body.appendChild(dataEl)

    doAssert hydr.getInitialValue("theme", "light") == "dark"
    doAssert hydr.getInitialValue("count", "0") == "42"
    doAssert hydr.getInitialValue("missing", "default") == "default"

    document.body.removeChild(dataEl)
    echo "PASS: getInitialValue reads SSR state"

  proc testHydrateAppReturnsState() =
    let el = domi.createElement("div")
    el.setAttribute("data-nl-id", "1")
    document.body.appendChild(el)

    let state = hydr.hydrateApp()
    doAssert state.hydrated
    doAssert state.nodeCount >= 1

    document.body.removeChild(el)
    echo "PASS: hydrateApp returns hydrated state"

when isMainModule:
  when defined(js):
    testLoadHydrationDataMissing()
    testLoadHydrationDataValid()
    testHydrateNodesFindsElements()
    testOnHydrateCallback()
    testGetInitialValue()
    testHydrateAppReturnsState()
    echo ""
    echo "All client hydration tests passed!"
  else:
    echo "SKIP: client_hydration_test requires -d:js"

when defined(js):
  import std/dom
  import std/json
  import ./dom_interop

  type
    HydrationState* = ref object
      nextId*: int
      nodeCount*: int

  proc loadHydrationData*(): HydrationState =
    let dataEl = getElementById("__nimleptos_data__")
    if dataEl == nil:
      return HydrationState(nextId: 0, nodeCount: 0)
    try:
      let data = parseJson($dataEl.textContent)
      result = HydrationState(
        nextId: data{"nextId"}.getInt(0),
        nodeCount: 0
      )
    except:
      result = HydrationState(nextId: 0, nodeCount: 0)

  proc hydrateNodes*(): seq[DomElement] =
    let nodes = querySelectorAll("[data-nl-id]")
    result = nodes
    for node in nodes:
      let id = getAttribute(node, "data-nl-id")
      node.setAttribute("data-nl-hydrated", "true")

  proc attachEvent*(node: DomElement, event: string,
      handler: proc(e: Event) {.closure.}) =
    node.addEventListener(event, handler)

  proc hydrateApp*() =
    let state = loadHydrationData()
    let nodes = hydrateNodes()
    echo "Hydrated " & $nodes.len & " nodes (nextId=" & $state.nextId & ")"

  proc onDOMContentLoaded*(callback: proc() {.closure.}) =
    document.addEventListener("DOMContentLoaded", proc(e: Event) =
      callback()
    )

  proc initHydration*() =
    onDOMContentLoaded(proc() =
      hydrateApp()
    )
else:
  proc hydrateApp*() =
    discard

  proc initHydration*() =
    discard

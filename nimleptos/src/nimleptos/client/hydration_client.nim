when defined(js):
  import std/dom
  import std/json
  import ./dom_interop

  type
    HydrationState* = ref object
      nextId*: int
      nodeCount*: int
      hydrated: bool

    HydrationCallback* = proc(node: DomElement, nlId: string) {.closure.}

  var hydrationCallbacks: seq[HydrationCallback] = @[]

  proc onHydrate*(callback: HydrationCallback) =
    hydrationCallbacks.add(callback)

  proc loadHydrationData*(): HydrationState =
    let dataEl = getElementById("__nimleptos_data__")
    if dataEl == nil:
      return HydrationState(nextId: 0, nodeCount: 0, hydrated: false)
    try:
      let data = parseJson($dataEl.textContent)
      result = HydrationState(
        nextId: data{"nextId"}.getInt(0),
        nodeCount: 0,
        hydrated: false
      )
    except:
      result = HydrationState(nextId: 0, nodeCount: 0, hydrated: false)

  proc hydrateNodes*(): seq[DomElement] =
    let nodes = querySelectorAll("[data-nl-id]")
    result = nodes
    for node in nodes:
      let nlId = getAttribute(node, "data-nl-id")
      node.setAttribute("data-nl-hydrated", "true")
      for cb in hydrationCallbacks:
        cb(node, nlId)

  proc attachEvent*(node: DomElement, event: string,
      handler: proc(e: Event) {.closure.}) =
    node.addEventListener(event, handler)

  proc hydrateApp*(): HydrationState =
    let state = loadHydrationData()
    let nodes = hydrateNodes()
    state.nodeCount = nodes.len
    state.hydrated = true
    return state

  proc onDOMContentLoaded*(callback: proc() {.closure.}) =
    document.addEventListener("DOMContentLoaded", proc(e: Event) =
      callback()
    )

  proc initHydration*() =
    onDOMContentLoaded(proc() =
      discard hydrateApp()
    )

else:
  type
    HydrationState* = ref object
      nextId*: int
      nodeCount*: int
      hydrated: bool

  proc hydrateApp*(): HydrationState =
    HydrationState(nextId: 0, nodeCount: 0, hydrated: false)

  proc initHydration*() =
    discard



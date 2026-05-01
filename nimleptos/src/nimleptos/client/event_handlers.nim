when defined(js):
  import std/dom
  import ./dom_interop
  import ./hydration_client

  type
    EventHandler* = proc(e: Event) {.closure.}
    EventBinding* = object
      selector*: string
      event*: string
      handler*: EventHandler

  var bindings: seq[EventBinding] = @[]

  proc bindEvent*(selector, event: string, handler: EventHandler) =
    bindings.add(EventBinding(selector: selector, event: event, handler: handler))

  proc bindClick*(selector: string, handler: EventHandler) =
    bindEvent(selector, "click", handler)

  proc bindSubmit*(selector: string, handler: EventHandler) =
    bindEvent(selector, "submit", handler)

  proc bindInput*(selector: string, handler: EventHandler) =
    bindEvent(selector, "input", handler)

  proc applyBindings*() =
    for binding in bindings:
      let nodes = querySelectorAll(binding.selector)
      for node in nodes:
        node.addEventListener(binding.event, binding.handler)

  proc initEventHandlers*() =
    onDOMContentLoaded(proc() =
      hydrateApp()
      applyBindings()
    )
else:
  type
    EventHandler* = proc() {.closure.}

  proc bindEvent*(selector, event: string, handler: EventHandler) =
    discard

  proc bindClick*(selector: string, handler: EventHandler) =
    discard

  proc bindSubmit*(selector: string, handler: EventHandler) =
    discard

  proc bindInput*(selector: string, handler: EventHandler) =
    discard

  proc applyBindings*() =
    discard

  proc initEventHandlers*() =
    discard

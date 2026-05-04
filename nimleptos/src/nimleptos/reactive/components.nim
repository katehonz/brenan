import signal
import effects
import resource
import ../dom/node

## Suspense — shows fallback while a resource/signal is in loading state.
## Transition — defers signal updates to allow CSS animations.
## Animation — CSS class-based enter/exit transitions for conditional nodes.

proc suspenseNode*(loading: proc(): bool {.closure, gcsafe.}, fallback: HtmlNode, content: HtmlNode): HtmlNode =
  ## Create a Suspense node that shows `fallback` while `loading` returns true,
  ## and `content` when loading is complete.
  ##
  ## Usage:
  ##   let posts = createResource(fetchPosts)
  ##   let node = suspenseNode(
  ##     proc(): bool = posts.loading(),
  ##     fallback = buildHtml: div(class="skeleton"): text("Loading..."),
  ##     content = buildHtml: div: text(posts.value())
  ##   )
  conditionalNode(
    proc(): bool {.closure, gcsafe.} = not loading(),
    content,
    fallback
  )

proc suspenseNode*[T](resource: Resource[T], fallback: HtmlNode, content: HtmlNode): HtmlNode =
  ## Convenience overload that derives the loading condition from a Resource[T].
  suspenseNode(proc(): bool {.closure, gcsafe.} = resource.loading(), fallback, content)

proc animateNode*(show: proc(): bool {.closure, gcsafe.}, content: HtmlNode,
    enterClass: string = "enter", exitClass: string = "exit"): HtmlNode =
  ## Create an animated conditional node. Wraps a conditional node with CSS class info
  ## for enter/exit transitions. Works with CSS animations/transitions.
  ##
  ## Usage:
  ##   let (visible, setVisible) = createSignal(false)
  ##   let node = animateNode(visible, buildHtml: div(class="modal"): text("Hello"))
  ##   # CSS: .enter { animation: fadeIn 0.3s; } .exit { animation: fadeOut 0.3s; }
  let wrapper = elementNode("div")
  addAttribute(wrapper, "style", "display: contents")
  let inner = conditionalNode(show, content, textNode(""))
  addChild(wrapper, inner)
  return wrapper

when defined(js):
  import std/dom

  proc clearTimeout(timeoutId: int) {.importc: "clearTimeout".}

  proc createTransition*[T](getter: Getter[T], setter: Setter[T], durationMs: int = 0): (proc(): T, proc(newVal: T)) =
    ## Creates a transition wrapper around a signal getter/setter pair.
    ## When `durationMs` is 0, updates are deferred to the next JS event loop tick,
    ## allowing CSS transitions to play. When > 0, updates are delayed by `durationMs`.
    ##
    ## Usage:
    ##   let (visible, setVisible) = createSignal(false)
    ##   let (tVisible, tSetVisible) = createTransition(visible, setVisible, 300)
    ##   # tVisible lags behind visible by 300ms, enabling CSS transitions
    var (transValue, setTransValue) = createSignal(getter())
    var timeoutId: int = -1

    proc apply(newVal: T) =
      if timeoutId >= 0:
        clearTimeout(timeoutId)
      timeoutId = setTimeout(proc() =
        setTransValue(newVal)
        timeoutId = -1
      , durationMs)

    let transGetter = proc(): T =
      addDependency(transValue)
      return transValue.value

    let transSetter = proc(newVal: T) =
      setter(newVal)  # apply to original signal immediately
      apply(newVal)   # defer transition signal update

    return (transGetter, transSetter)

else:
  # Non-JS stubs — transition is a no-op without browser animations
  proc createTransition*[T](getter: Getter[T], setter: Setter[T], durationMs: int = 0): (proc(): T, proc(newVal: T)) =
    ## Non-JS: transition is a pass-through (no DOM animations on server).
    return (getter, setter)

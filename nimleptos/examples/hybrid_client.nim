## Fully Automatic Reactive Counter
## The buildHtml macro auto-wraps non-string text() in reactiveTextNode()
## when compiled with nim js.
##
## Compile: nim js -p:src -o:examples/hybrid_client.js examples/hybrid_client.nim

import std/dom
import nimleptos/client/reactive_dom
import nimleptos/client/dom_interop
import nimleptos/macros/html_macros
import nimleptos/reactive/signal
import nimleptos/reactive/effects

when defined(js):
  # Signals at module level so both builder and afterMount can use them
  let (count, setCount) = createSignal(0)

  proc hybridApp(): HtmlNode =
    # MAGIC: text($count()) is automatically reactive when compiled with nim js!
    # The macro generates: when defined(js): reactiveTextNode(...) else: textNode(...)
    result = buildHtml:
      el("div", class="app"):
        el("h1"): text("Auto-Reactive Counter")
        el("p", class="display"): text("Count: " & $count())
        el("div", class="bar-container"):
          el("div", class="bar"): text("")
        el("div", class="buttons"):
          el("button", class="btn btn-dec"): text("-")
          el("button", class="btn btn-inc"): text("+")

  proc afterMount(root: DomElement) =
    # Bind buttons
    let btnDec = querySelector(root, ".btn-dec")
    if btnDec != nil:
      btnDec.addEventListener("click", proc(e: Event) = setCount(count() - 1))

    let btnInc = querySelector(root, ".btn-inc")
    if btnInc != nil:
      btnInc.addEventListener("click", proc(e: Event) = setCount(count() + 1))

    # Reactive bar width
    let bar = querySelector(root, ".bar")
    if bar != nil:
      reactiveStyle(bar, "width", proc(): string =
        let pct = min(count() * 10, 100)
        $pct & "%"
      )

  mountApp("#app", hybridApp, afterMount)

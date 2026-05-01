## Fully Automatic Reactive Counter
## The buildHtml macro auto-detects reactive expressions in BOTH text() and attributes!
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
  let (active, setActive) = createSignal(true)

  proc hybridApp(): HtmlNode =
    # MAGIC: Both text($count()) and class=$active() are automatically reactive!
    # The macro generates when defined(js): reactiveTextNode/reactiveAttr
    result = buildHtml:
      el("div", class="app"):
        el("h1"): text("Auto-Reactive Counter")
        el("p", class=$active()): text($count())
        el("div", class="bar-container"):
          el("div", class=$active()): text("")
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

    # Toggle active state every 5 clicks (just for demo)
    let display = querySelector(root, "p")
    if display != nil:
      display.addEventListener("click", proc(e: Event) = setActive(not active()))

  mountApp("#app", hybridApp, afterMount)

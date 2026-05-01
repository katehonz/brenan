## Reactive Conditional Demo — if/else in buildHtml
## The if/else blocks automatically show/hide DOM elements when signals change.
##
## Compile: nim js -p:src -o:examples/conditional_client.js examples/conditional_client.nim

import std/dom
import nimleptos/client/reactive_dom
import nimleptos/client/dom_interop
import nimleptos/macros/html_macros
import nimleptos/reactive/signal
import nimleptos/reactive/effects

when defined(js):
  let (showName, setShowName) = createSignal(true)
  let (name, setName) = createSignal("Alice")

  proc conditionalApp(): HtmlNode =
    result = buildHtml:
      el("div", class="app"):
        el("h1"): text("Conditional Rendering")
        if showName():
          el("p", class="greeting"): text("Hello, " & $name() & "!")
          el("p"): text("Welcome back.")
        else:
          el("p", class="greeting"): text("Hello, Anonymous!")
          el("p"): text("Please sign in.")
        el("div", class="buttons"):
          el("button", class="btn"): text("Toggle")
          el("button", class="btn"): text("Change Name")

  proc afterMount(root: DomElement) =
    let btnToggle = querySelector(root, ".btn")
    if btnToggle != nil:
      btnToggle.addEventListener("click", proc(e: Event) = setShowName(not showName()))

    let btns = querySelectorAll(root, ".btn")
    if btns.len >= 2:
      btns[1].addEventListener("click", proc(e: Event) =
        if name() == "Alice":
          setName("Bob")
        else:
          setName("Alice")
      )

  mountApp("#app", conditionalApp, afterMount)

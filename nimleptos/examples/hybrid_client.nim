## Hybrid CSR Demo: buildHtml + reactive DOM binding
## This shows how static structure (buildHtml) mixes with fine-grained reactivity.
## Compile: nim js -p:src -o:examples/hybrid_client.js examples/hybrid_client.nim

import std/dom
import nimleptos/client/reactive_dom
import nimleptos/client/dom_interop
import nimleptos/macros/html_macros
import nimleptos/reactive/signal
import nimleptos/reactive/effects

when defined(js):
  proc hybridApp(): seq[DomElement] =
    let (count, setCount) = createSignal(0)

    # 1. Build static structure with the macro DSL
    let staticNode = buildHtml:
      el("div", class="app"):
        el("h1"): text("Hybrid Counter")
        el("p", id="display", class="display"): text("Count: 0")
        el("div", class="bar-container"):
          el("div", id="bar", class="bar")
        el("div", class="buttons"):
          el("button", id="btn-dec", class="btn"): text("-")
          el("button", id="btn-inc", class="btn"): text("+")

    # 2. Render HtmlNode tree to real DOM
    let root = renderDomNode(staticNode)

    # 3. Find elements inside the rendered tree and attach REACTIVITY
    #    This is the magic: createEffect runs automatically when signals change,
    #    updating ONLY the changed DOM node. No virtual DOM. No re-render.

    let displayEl = querySelector(root, "#display")
    clearChildren(displayEl)
    displayEl.appendChild(
      reactiveTextNode(proc(): string = "Count: " & $count())
    )

    let barEl = querySelector(root, "#bar")
    reactiveStyle(barEl, "width", proc(): string =
      let pct = min(count() * 10, 100)
      $pct & "%"
    )

    let btnDec = querySelector(root, "#btn-dec")
    btnDec.addEventListener("click", proc(e: Event) =
      setCount(count() - 1)
    )

    let btnInc = querySelector(root, "#btn-inc")
    btnInc.addEventListener("click", proc(e: Event) =
      setCount(count() + 1)
    )

    return @[root]

  mountReactiveApp("#app", hybridApp)

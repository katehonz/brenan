## Vite + NimLeptos Counter Example
## Compile: nim js -p:src -o:dist/counter.js counter.nim
## Dev:    nim js -p:src -o:dist/counter.js counter.nim && npx vite

import nimleptos
import nimleptos/client/reactive_dom
import nimleptos/client/dom_interop
import std/dom

when defined(js):
  proc counterApp(): seq[DomElement] =
    let (count, setCount) = createSignal(0)
    let (doubled, _) = createMemo(proc(): int = count() * 2)

    # Heading
    let heading = createElement("h1")
    heading.setAttribute("class", "counter-title")
    heading.textContent = "Vite + NimLeptos Counter"

    # Display with reactive text binding
    let display = createElement("p")
    display.setAttribute("class", "counter-display")
    let textEl = reactiveTextNode(proc(): string =
      "Count: " & $count()
    )
    display.appendChild(textEl)

    # Doubled value
    let doubledDisplay = createElement("p")
    doubledDisplay.setAttribute("class", "counter-doubled")
    let doubledText = reactiveTextNode(proc(): string =
      "Doubled: " & $doubled()
    )
    doubledDisplay.appendChild(doubledText)

    # Buttons
    let btnInc = createElement("button")
    btnInc.setAttribute("class", "btn btn-inc")
    btnInc.textContent = "+"
    btnInc.addEventListener("click", proc(e: Event) =
      setCount(count() + 1)
    )

    let btnDec = createElement("button")
    btnDec.setAttribute("class", "btn btn-dec")
    btnDec.textContent = "-"
    btnDec.addEventListener("click", proc(e: Event) =
      setCount(count() - 1)
    )

    return @[heading, display, doubledDisplay, btnDec, btnInc]

  mountReactiveApp("#app", counterApp)

## Client-Side Reactive Counter Example
## Compile with: nim js -p:src examples/counter_client.nim
## Then open examples/counter_client.html in a browser.

import std/dom
import nimleptos/client/reactive_dom
import nimleptos/client/dom_interop
import nimleptos/reactive/signal
import nimleptos/reactive/effects

when defined(js):
  proc counterApp(): seq[DomElement] =
    let (count, setCount) = createSignal(0)

    # Heading
    let heading = createElement("h1")
    heading.setAttribute("class", "counter-title")
    heading.textContent = "NimLeptos Counter"

    # Display with reactive text binding
    let display = createElement("p")
    display.setAttribute("class", "counter-display")
    let textEl = reactiveTextNode(proc(): string = "Count: " & $count())
    display.appendChild(textEl)

    # Doubled value (memo demo)
    let (doubled, _) = createMemo(proc(): int = count() * 2)
    let doubledDisplay = createElement("p")
    doubledDisplay.setAttribute("class", "counter-doubled")
    let doubledText = reactiveTextNode(proc(): string = "Doubled: " & $doubled())
    doubledDisplay.appendChild(doubledText)

    # Increment button
    let btnInc = createElement("button")
    btnInc.setAttribute("class", "btn btn-inc")
    btnInc.textContent = "+"
    btnInc.addEventListener("click", proc(e: Event) =
      setCount(count() + 1)
    )

    # Decrement button
    let btnDec = createElement("button")
    btnDec.setAttribute("class", "btn btn-dec")
    btnDec.textContent = "-"
    btnDec.addEventListener("click", proc(e: Event) =
      setCount(count() - 1)
    )

    return @[heading, display, doubledDisplay, btnDec, btnInc]

  mountReactiveApp("#app", counterApp)

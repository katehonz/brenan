## Reactive Timer Demo — CSR Proof of Concept
## Compile: nim js -p:src -o:examples/timer_client.js examples/timer_client.nim
## This proves that dependency tracking works end-to-end in the browser.

import std/dom
import nimleptos/client/reactive_dom
import nimleptos/client/dom_interop
import nimleptos/reactive/signal
import nimleptos/reactive/effects

when defined(js):
  proc timerApp(): seq[DomElement] =
    let (seconds, setSeconds) = createSignal(0)

    # Heading
    let heading = createElement("h1")
    heading.textContent = "Reactive Timer"

    # Status label
    let status = createElement("p")
    status.setAttribute("class", "status")
    let statusText = reactiveTextNode(proc(): string =
      "Running for " & $seconds() & " seconds"
    )
    status.appendChild(statusText)

    # Even/odd indicator — demonstrates memo-like derived state
    let parity = createElement("p")
    parity.setAttribute("class", "parity")
    let parityText = reactiveTextNode(proc(): string =
      if seconds() mod 2 == 0: "Even second ✓" else: "Odd second ✗"
    )
    parity.appendChild(parityText)

    # Visual bar width bound to signal (reactiveStyle demo)
    let barContainer = createElement("div")
    barContainer.setAttribute("class", "bar-container")
    let bar = createElement("div")
    bar.setAttribute("class", "bar")
    reactiveStyle(bar, "width", proc(): string =
      let pct = (seconds() mod 10) * 10
      $pct & "%"
    )
    barContainer.appendChild(bar)

    # Start timer — this is the MAGIC: setSeconds triggers createEffect,
    # which updates the DOM automatically. No manual update() call!
    discard window.setInterval(proc() =
      setSeconds(seconds() + 1)
    , 1000)

    return @[heading, status, parity, barContainer]

  mountReactiveApp("#app", timerApp)

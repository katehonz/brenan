import ../../src/nimleptos/reactive/signal
import ../../src/nimleptos/reactive/effects
import ../../src/nimleptos/dom/node
import ../../src/nimleptos/dom/elements
import ../../src/nimleptos/ssr/renderer
import ../../src/nimleptos/ssr/hydration

proc counterApp(): HtmlNode =
  let (count, setCount) = createSignal(0)
  let (doubled, _) = createMemo(proc(): int = count() * 2)

  var countText: string
  var doubledText: string

  discard createEffect(proc() =
    countText = $count()
    doubledText = $doubled()
  )

  result = elDiv([("class", "counter-app")],
    elH1([], text("NimLeptos Counter")),
    elDiv([("class", "counter-display")],
      elP([], text("Count: " & countText)),
      elP([], text("Doubled: " & doubledText))
    ),
    elDiv([("class", "buttons")],
      elButton([("class", "btn-dec")], text("-")),
      elButton([("class", "btn-inc")], text("+"))
    )
  )

when isMainModule:
  let ctx = newSSRContext()
  let app = counterApp()

  echo "=== Counter App (SSR) ==="
  echo ""
  echo renderPageWithHydration(ctx, app, "NimLeptos Counter Example")
  echo ""
  echo "=== Reactive Demo ==="

  let (count, setCount) = createSignal(0)
  var display = ""

  discard createEffect(proc() =
    display = "Count is: " & $count()
  )

  echo display
  setCount(1)
  echo display
  setCount(5)
  echo display

  batch(proc() =
    setCount(10)
    setCount(20)
    setCount(30)
  )
  echo display

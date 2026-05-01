import ../src/nimleptos
import ../src/nimleptos/dom/node as nl_node

proc testCreateSignal() =
  let (count, setCount) = createSignal(0)
  doAssert count() == 0
  setCount(5)
  doAssert count() == 5
  echo "PASS: createSignal basic"

proc testSignalReactivity() =
  let (count, setCount) = createSignal(0)
  var effectRuns = 0
  var lastValue = -1

  discard createEffect(proc() =
    inc effectRuns
    lastValue = count()
  )

  doAssert effectRuns == 1
  doAssert lastValue == 0
  setCount(10)
  doAssert effectRuns == 2
  doAssert lastValue == 10
  echo "PASS: signal reactivity"

proc testCreateMemo() =
  let (a, setA) = createSignal(2)
  let (b, setB) = createSignal(3)
  let (sum, _) = createMemo(proc(): int = a() + b())

  doAssert sum() == 5
  setA(10)
  doAssert sum() == 13
  echo "PASS: createMemo"

proc testBatch() =
  let (a, setA) = createSignal(0)
  let (b, setB) = createSignal(0)
  var effectRuns = 0

  discard createEffect(proc() =
    inc effectRuns
    discard a()
    discard b()
  )

  let runsBefore = effectRuns
  batch(proc() =
    setA(1)
    setB(2)
  )

  doAssert effectRuns == runsBefore + 1
  doAssert a() == 1
  doAssert b() == 2
  echo "PASS: batch"

proc testHtmlRendering() =
  let node = elDiv([("class", "test")],
    elH1([], text("Title")),
    elP([], text("Content"))
  )
  let html = renderToHtml(node)
  doAssert html.contains("<div class=\"test\">")
  doAssert html.contains("<h1>Title</h1>")
  doAssert html.contains("<p>Content</p>")
  echo "PASS: HTML rendering"

proc testSSR() =
  let ctx = newSSRContext()
  let node = elDiv([("class", "app")], text("Hello"))
  let page = renderFullPage(ctx, node, "Test")
  doAssert page.contains("<!DOCTYPE html>")
  doAssert page.contains("<title>Test</title>")
  doAssert page.contains("__nimleptos_data__")
  echo "PASS: SSR"

proc testHydration() =
  let ctx = newSSRContext()
  let root = elDiv([], elSpan([], text("child")))
  discard injectHydrationIds(root, ctx)
  doAssert root.attributes.len > 0
  echo "PASS: hydration IDs"

proc testEscapeHtml() =
  doAssert nl_node.escapeHtml("<script>") == "&lt;script&gt;"
  doAssert nl_node.escapeHtml("a & b") == "a &amp; b"
  echo "PASS: escapeHtml"

proc testDependencyTracking() =
  let (showName, setShowName) = createSignal(true)
  let (name, setName) = createSignal("Alice")
  var rendered = ""

  discard createEffect(proc() =
    if showName():
      rendered = "Hello " & name()
    else:
      rendered = "Hello"
  )

  doAssert rendered == "Hello Alice"
  setName("Bob")
  doAssert rendered == "Hello Bob"
  setShowName(false)
  doAssert rendered == "Hello"
  echo "PASS: dependency tracking"

when isMainModule:
  testCreateSignal()
  testSignalReactivity()
  testCreateMemo()
  testBatch()
  testHtmlRendering()
  testSSR()
  testHydration()
  testEscapeHtml()
  testDependencyTracking()
  echo ""
  echo "All tests passed!"

import ../src/nimleptos/dom/node
import ../src/nimleptos/dom/elements
import ../src/nimleptos/ssr/renderer
import ../src/nimleptos/ssr/hydration
import std/strutils
import std/sequtils

proc testSSRContext() =
  let ctx = newSSRContext()
  doAssert ctx.nextId == 0
  doAssert ctx.markers.len == 0
  echo "PASS: SSRContext creation"

proc testRenderFullPage() =
  let ctx = newSSRContext()
  let body = elDiv([("class", "app")], text("Hello"))
  let page = renderFullPage(ctx, body, "Test Page")
  doAssert page.contains("<!DOCTYPE html>")
  doAssert page.contains("<title>Test Page</title>")
  doAssert page.contains("<div class=\"app\">Hello</div>")
  doAssert page.contains("__nimleptos_data__")
  echo "PASS: renderFullPage"

proc testHydrationIds() =
  let ctx = newSSRContext()
  let root = elDiv([("class", "root")],
    elSpan([], text("child1")),
    elP([], text("child2"))
  )
  discard injectHydrationIds(root, ctx)
  doAssert root.attributes.anyIt(it[0] == "data-nl-id")
  echo "PASS: hydration ID injection"

proc testRenderWithHydration() =
  let ctx = newSSRContext()
  let root = elDiv([("class", "app")],
    elH1([], text("Title")),
    elP([], text("Content"))
  )
  let html = renderWithHydration(root, ctx)
  doAssert html.contains("data-nl-id")
  doAssert html.contains("Title")
  doAssert html.contains("Content")
  echo "PASS: renderWithHydration"

proc testHydrationScript() =
  let ctx = newSSRContext()
  let script = generateHydrationScript(ctx)
  doAssert script.contains("<script>")
  doAssert script.contains("__nimleptos")
  echo "PASS: hydrationScript"

when isMainModule:
  testSSRContext()
  testRenderFullPage()
  testHydrationIds()
  testRenderWithHydration()
  testHydrationScript()
  echo ""
  echo "All SSR tests passed!"

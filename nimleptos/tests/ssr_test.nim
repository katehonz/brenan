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

proc testErrorBoundaryCatches() =
  let badChild = listNode(proc(): seq[HtmlNode] {.closure, gcsafe.} =
    raise newException(ValueError, "simulated render error")
  )
  let wrapped = errorBoundaryNode(
    badChild,
    proc(error: string): HtmlNode {.closure, gcsafe.} =
      let fallback = elementNode("div")
      addAttribute(fallback, "class", "error-boundary")
      addChild(fallback, textNode("Error: " & error))
      return fallback
  )
  let result = renderToHtml(wrapped)
  doAssert result.contains("error-boundary")
  doAssert result.contains("simulated render error")
  echo "PASS: error boundary catches exception"

proc testErrorBoundaryPassThrough() =
  let child = elementNode("div")
  addChild(child, textNode("all good"))
  let wrapped = errorBoundaryNode(
    child,
    proc(error: string): HtmlNode {.closure, gcsafe.} =
      textNode("should not reach")
  )
  let result = renderToHtml(wrapped)
  doAssert result.contains("all good")
  doAssert not result.contains("should not reach")
  echo "PASS: error boundary pass-through"

proc testNestedErrorBoundaries() =
  # Inner boundary catches inner child's error
  let innerBad = listNode(proc(): seq[HtmlNode] {.closure, gcsafe.} =
    raise newException(ValueError, "inner error")
  )
  let inner = errorBoundaryNode(
    innerBad,
    proc(error: string): HtmlNode {.closure, gcsafe.} =
      textNode("inner fallback: " & error)
  )
  let outer = errorBoundaryNode(
    inner,
    proc(error: string): HtmlNode {.closure, gcsafe.} =
      textNode("outer fallback")
  )
  let result = renderToHtml(outer)
  doAssert result.contains("inner fallback: inner error")
  doAssert not result.contains("outer fallback")
  echo "PASS: nested error boundaries"

proc testLazyNodeSsrShowsFallback() =
  let fallback = elDiv([("class", "skeleton")], text("loading..."))
  let lazy = lazyNode(
    proc(): HtmlNode {.closure, gcsafe.} = textNode("loaded"),
    fallback
  )
  let result = renderToHtml(lazy)
  doAssert result.contains("skeleton")
  doAssert result.contains("loading...")
  doAssert not result.contains("loaded")
  echo "PASS: lazy node SSR shows fallback"

when isMainModule:
  testSSRContext()
  testRenderFullPage()
  testHydrationIds()
  testRenderWithHydration()
  testHydrationScript()
  testErrorBoundaryCatches()
  testErrorBoundaryPassThrough()
  testNestedErrorBoundaries()
  testLazyNodeSsrShowsFallback()
  echo ""
  echo "All SSR tests passed!"

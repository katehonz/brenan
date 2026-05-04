## NimLeptos DOM Render Benchmark
##
## Measures HtmlNode tree construction and rendering throughput.
## Compares: raw element creation, renderToHtml, renderToHtmlRaw.

import times, strformat
import nimleptos/dom/node
import nimleptos/dom/elements

proc buildFlatList(count: int): HtmlNode =
  result = elDiv([("id", "root")])
  for i in 1 .. count:
    let item = elDiv([("class", "item")],
      elSpan([], text("Item " & $i)),
      elButton([("data-id", $i)], text("Click"))
    )
    result.addChild(item)

proc buildNestedTree(depth: int, branching: int): HtmlNode =
  proc rec(d: int): HtmlNode =
    if d == 0:
      return text("leaf")
    result = elDiv([("class", "depth-" & $d)])
    for i in 1 .. branching:
      result.addChild(rec(d - 1))
  rec(depth)

proc measureFlatListBuild(count: int): float =
  let start = cpuTime()
  let tree = buildFlatList(count)
  result = cpuTime() - start
  doAssert tree.children.len == count

proc measureNestedTree(depth: int, branching: int): float =
  let start = cpuTime()
  let tree = buildNestedTree(depth, branching)
  let elapsed = cpuTime() - start
  discard tree
  result = elapsed

when isMainModule:
  echo "NimLeptos DOM Render Benchmark"
  echo "=============================="
  echo ""

  # Warmup
  discard measureFlatListBuild(100)

  const LIST_COUNT = 1000
  const RENDER_ITERATIONS = 1000

  let buildTime = measureFlatListBuild(LIST_COUNT)
  echo fmt"Flat list ({LIST_COUNT} items) — build: {buildTime*1000:.2f} ms"

  # Render the tree 1000 times for measurable timing
  let tree = buildFlatList(LIST_COUNT)
  let startRender = cpuTime()
  for i in 1 .. RENDER_ITERATIONS:
    discard tree.renderToHtml()
  let renderTime = (cpuTime() - startRender) / RENDER_ITERATIONS.float
  echo fmt"Flat list ({LIST_COUNT} items) — renderToHtml: {renderTime*1000:.3f} ms avg"

  let startRenderRaw = cpuTime()
  for i in 1 .. RENDER_ITERATIONS:
    discard tree.renderToHtmlRaw()
  let renderRawTime = (cpuTime() - startRenderRaw) / RENDER_ITERATIONS.float
  echo fmt"Flat list ({LIST_COUNT} items) — renderToHtmlRaw: {renderRawTime*1000:.3f} ms avg"
  echo fmt"Speedup: {(renderTime / renderRawTime):.1f}x"

  echo ""

  const DEPTH = 5
  const BRANCHING = 3
  var powCalc = 1
  for j in 1 .. DEPTH + 1:
    powCalc *= BRANCHING
  let totalNodes = (powCalc - 1) div (BRANCHING - 1)
  let nestedTime = measureNestedTree(DEPTH, BRANCHING)
  echo fmt"Nested tree (depth={DEPTH}, branching={BRANCHING}, ~{totalNodes} nodes) — build: {nestedTime*1000:.2f} ms"
  echo ""

  let nestedTree = buildNestedTree(DEPTH, BRANCHING)
  let start = cpuTime()
  let nestedHtml = nestedTree.renderToHtmlRaw()
  let nestedRenderTime = cpuTime() - start
  echo fmt"Nested tree — renderToHtmlRaw: {nestedRenderTime*1000:.2f} ms"
  echo fmt"Nested tree — HTML size: {nestedHtml.len} chars"
  echo ""

  echo "Benchmark complete."

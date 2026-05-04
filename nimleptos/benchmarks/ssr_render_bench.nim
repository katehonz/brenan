## NimLeptos SSR Render Benchmark
##
## Measures renderFullPage throughput with realistic page sizes.

import times, strformat
import nimleptos/dom/node
import nimleptos/dom/elements
import nimleptos/ssr/renderer

proc buildTypicalPage(contentItems: int): HtmlNode =
  let contentDiv = elDiv([("class", "content-list")])
  for i in 1 .. contentItems:
    let item = elDiv([("class", "content-item")],
      elH3([], text("Item " & $i)),
      elP([], text("Description for item " & $i & ". This is some sample text to make the HTML larger.")),
      elA([("href", "/item/" & $i)], text("Read more"))
    )
    contentDiv.addChild(item)
  let sidebarUl = elUl([])
  for i in 1 .. 5:
    sidebarUl.addChild(elLi([], elA([("href", "#")], text("Sidebar link " & $i))))
  result = elHtml([("lang", "en")],
    elHead([],
      elMeta([("charset", "UTF-8")]),
      elTitle([], text("Benchmark Page")),
      elLink([("rel", "stylesheet"), ("href", "/styles.css")])
    ),
    elBody([],
      elHeader([],
        elNav([],
          elA([("href", "/")], text("Home")),
          elA([("href", "/about")], text("About")),
          elA([("href", "/contact")], text("Contact"))
        )
      ),
      elMain([],
        elH1([], text("Welcome")),
        elSection([],
          elH2([], text("Content")),
          contentDiv
        ),
        elAside([],
          elH3([], text("Sidebar")),
          sidebarUl
        )
      ),
      elFooter([],
        elP([], text("© 2026 NimLeptos"))
      )
    )
  )

when isMainModule:
  echo "NimLeptos SSR Render Benchmark"
  echo "==============================="
  echo ""

  # Warmup
  let warmNode = buildTypicalPage(10)
  discard warmNode.renderToHtml()

  const ITERATIONS = 1000

  let page = buildTypicalPage(20)
  let pageNodes = 20

  let startTotal = cpuTime()
  var totalChars = 0
  for i in 1 .. ITERATIONS:
    let html = page.renderToHtml()
    totalChars += html.len
  let elapsedTotal = cpuTime() - startTotal

  echo fmt"Typical page (~{pageNodes} nodes) — {ITERATIONS} renders:"
  echo fmt"  Total time: {elapsedTotal*1000:.2f} ms"
  echo fmt"  Avg per render: {elapsedTotal*1000/ITERATIONS.float:.3f} ms"
  echo fmt"  Avg HTML size: {totalChars div ITERATIONS} chars"
  echo fmt"  Renders/sec: {(ITERATIONS.float / elapsedTotal).int}"
  echo ""

  # renderToHtmlRaw benchmark
  let startRaw = cpuTime()
  for i in 1 .. ITERATIONS:
    discard page.renderToHtmlRaw()
  let elapsedRaw = cpuTime() - startRaw

  echo fmt"Typical page (~{pageNodes} nodes) — renderToHtmlRaw:"
  echo fmt"  Total time: {elapsedRaw*1000:.2f} ms"
  echo fmt"  Avg per render: {elapsedRaw*1000/ITERATIONS.float:.3f} ms"
  echo fmt"  Speedup vs renderToHtml: {(elapsedTotal / elapsedRaw):.1f}x"
  echo ""

  # Large page benchmark
  let largePage = buildTypicalPage(200)
  let startLarge = cpuTime()
  let largeHtml = largePage.renderToHtml()
  let elapsedLarge = cpuTime() - startLarge

  echo fmt"Large page (~200 nodes):"
  echo fmt"  Render time: {elapsedLarge*1000:.2f} ms"
  echo fmt"  HTML size: {largeHtml.len} chars"
  echo ""

  echo "Benchmark complete."

import std/strutils
import ../src/nimleptos/dom/node
import ../src/nimleptos/dom/elements
import ../src/nimleptos/macros/html_macros

proc testTextNode() =
  let node = textNode("Hello")
  doAssert node.isText
  doAssert node.text == "Hello"
  doAssert renderToHtml(node) == "Hello"
  echo "PASS: textNode"

proc testElementNode() =
  let node = elementNode("div")
  doAssert not node.isText
  doAssert node.tag == "div"
  doAssert renderToHtml(node) == "<div></div>"
  echo "PASS: elementNode"

proc testAttributes() =
  let node = elementNode("div")
  node.addAttribute("class", "container")
  node.addAttribute("id", "main")
  doAssert renderToHtml(node) == "<div class=\"container\" id=\"main\"></div>"
  echo "PASS: attributes"

proc testNestedElements() =
  let parent = elementNode("div")
  let child1 = elementNode("span")
  let child2 = elementNode("p")
  parent.addChild(child1)
  parent.addChild(child2)
  doAssert renderToHtml(parent) == "<div><span></span><p></p></div>"
  echo "PASS: nested elements"

proc testEscapeHtml() =
  doAssert escapeHtml("<script>") == "&lt;script&gt;"
  doAssert escapeHtml("a & b") == "a &amp; b"
  doAssert escapeHtml("\"hello\"") == "&quot;hello&quot;"
  echo "PASS: escapeHtml"

proc testDomBuilders() =
  let node = elDiv([("class", "wrapper")],
    elSpan([], text("Hello")),
    elP([], text("World"))
  )
  doAssert renderToHtml(node) == "<div class=\"wrapper\"><span>Hello</span><p>World</p></div>"
  echo "PASS: DOM builders"

proc testRenderToHtmlRaw() =
  let node = elDiv([("class", "test")],
    text("<b>raw</b>")
  )
  doAssert renderToHtmlRaw(node) == "<div class=\"test\"><b>raw</b></div>"
  echo "PASS: renderToHtmlRaw"

proc testBuildHtmlMacro() =
  let node = buildHtml:
    el("div", class="app", id="main"):
      el("h1"): text("Title")
      el("p"): text("Hello")
  let html = renderToHtml(node)
  doAssert html.contains("<div class=\"app\" id=\"main\">")
  doAssert html.contains("<h1>Title</h1>")
  doAssert html.contains("<p>Hello</p>")
  echo "PASS: buildHtml macro"

proc testElMacro() =
  let node = el("section", class="content"):
    el("article"):
      el("h2"): text("Article")
  let html = renderToHtml(node)
  doAssert html.contains("<section class=\"content\">")
  doAssert html.contains("<article>")
  doAssert html.contains("<h2>Article</h2>")
  echo "PASS: el macro"

proc testReactiveAttrMacro() =
  let active = true
  let node = buildHtml:
    el("div", class=$active):
      el("span", id="test"): text("hello")
  let html = renderToHtml(node)
  # On native backend, reactive attrs evaluate to static values
  doAssert html.contains("<div class=\"true\">")
  doAssert html.contains("<span id=\"test\">hello</span>")
  echo "PASS: reactive attr macro (native fallback)"

when isMainModule:
  testTextNode()
  testElementNode()
  testAttributes()
  testNestedElements()
  testEscapeHtml()
  testDomBuilders()
  testRenderToHtmlRaw()
  testBuildHtmlMacro()
  testElMacro()
  testReactiveAttrMacro()
  echo ""
  echo "All HTML DSL tests passed!"

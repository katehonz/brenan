import ../src/nimleptos/dom/node
import ../src/nimleptos/dom/elements

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

when isMainModule:
  testTextNode()
  testElementNode()
  testAttributes()
  testNestedElements()
  testEscapeHtml()
  testDomBuilders()
  testRenderToHtmlRaw()
  echo ""
  echo "All HTML DSL tests passed!"

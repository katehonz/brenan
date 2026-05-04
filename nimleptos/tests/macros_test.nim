import std/strutils
import std/tables
import ../src/nimleptos/dom/node
import ../src/nimleptos/dom/elements
import ../src/nimleptos/macros/html_macros
import ../src/nimleptos/i18n/catalog
import ../src/nimleptos/i18n/interpolate
import ../src/nimleptos/i18n/i18n

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

proc testConditionalMacro() =
  let showName = true
  let name = "Alice"
  let node = buildHtml:
    el("div"):
      if showName:
        el("p"): text("Hello " & name)
      else:
        el("p"): text("Anonymous")
  let html = renderToHtml(node)
  doAssert html.contains("<p>Hello Alice</p>")
  echo "PASS: conditional macro (if/else)"

  let showName2 = false
  let node2 = buildHtml:
    el("div"):
      if showName2:
        el("p"): text("Hello " & name)
      else:
        el("p"): text("Anonymous")
  let html2 = renderToHtml(node2)
  doAssert html2.contains("<p>Anonymous</p>")
  echo "PASS: conditional macro (else branch)"

proc testI18nBuildHtmlWithCfgMacro() =
  let cat = newMessageCatalog("en", "en")
  cat.addTranslation("en", "hello", "Hello")
  cat.addTranslation("en", "home", "Home")
  let cfg = createI18n(cat, "en")

  let node = buildHtml(cfg):
    el("div", class="app"):
      el("h1"): t"hello"
      el("p"): t"home"

  let html = renderToHtml(node)
  doAssert html.contains("<h1>Hello</h1>")
  doAssert html.contains("<p>Home</p>")
  echo "PASS: buildHtml i18n with cfg macro"

proc testI18nBuildHtmlCallSyntax() =
  let cat = newMessageCatalog("en", "en")
  cat.addTranslation("en", "hello", "Hello")
  cat.addTranslation("en", "greeting", "Hello {name}")
  let cfg = createI18n(cat, "en")

  let node = buildHtml:
    el("div"):
      el("h1"): t(cfg, "hello")
      el("p"): tp(cfg, "greeting", proc(): InterpParams =
        result = initTable[string, InterpValue]()
        result["name"] = str("World")
      )

  let html = renderToHtml(node)
  doAssert html.contains("<h1>Hello</h1>")
  doAssert html.contains("<p>Hello World</p>")
  echo "PASS: buildHtml i18n call syntax"

proc testI18nRegisterCatalogMacro() =
  registerI18nCatalog("../locales/app.json")
  let cat = newMessageCatalog("en", "en")
  cat.addTranslation("en", "hello", "Hello")
  cat.addTranslation("en", "about", "About")
  let cfg = createI18n(cat, "en")

  let node = buildHtml(cfg):
    el("div"):
      el("h1"): t"hello"
      el("p"): t"about"

  let html = renderToHtml(node)
  echo "HTML: ", html
  doAssert html.contains("<h1>Hello</h1>")
  doAssert html.contains("<p>About</p>")
  echo "PASS: registerI18nCatalog macro"

proc testForMacro() =
  let items = @["Alice", "Bob", "Charlie"]
  let node = buildHtml:
    el("ul"):
      for name in items:
        el("li"): text(name)
  let html = renderToHtml(node)
  doAssert html.contains("<li>Alice</li>")
  doAssert html.contains("<li>Bob</li>")
  doAssert html.contains("<li>Charlie</li>")
  echo "PASS: for macro"

proc testForMacroNested() =
  let items = @[("a", "A"), ("b", "B")]
  let node = buildHtml:
    el("dl"):
      for (key, val) in items:
        el("dt"): text(key)
        el("dd"): text(val)
  let html = renderToHtml(node)
  doAssert html.contains("<dt>a</dt>")
  doAssert html.contains("<dd>A</dd>")
  doAssert html.contains("<dt>b</dt>")
  doAssert html.contains("<dd>B</dd>")
  echo "PASS: for macro nested"

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
  testConditionalMacro()
  testI18nBuildHtmlWithCfgMacro()
  testI18nBuildHtmlCallSyntax()
  testI18nRegisterCatalogMacro()
  testForMacro()
  testForMacroNested()
  echo ""
  echo "All HTML DSL tests passed!"

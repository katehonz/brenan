import ../dom/node

export node

type
  ElementBuilder* = proc(): HtmlNode

proc elDiv*(attrs: openArray[(string, string)] = [],
    children: varargs[HtmlNode]): HtmlNode =
  result = elementNode("div")
  for (k, v) in attrs:
    result.addAttribute(k, v)
  for child in children:
    result.addChild(child)

proc elSpan*(attrs: openArray[(string, string)] = [],
    children: varargs[HtmlNode]): HtmlNode =
  result = elementNode("span")
  for (k, v) in attrs:
    result.addAttribute(k, v)
  for child in children:
    result.addChild(child)

proc elP*(attrs: openArray[(string, string)] = [],
    children: varargs[HtmlNode]): HtmlNode =
  result = elementNode("p")
  for (k, v) in attrs:
    result.addAttribute(k, v)
  for child in children:
    result.addChild(child)

proc elH1*(attrs: openArray[(string, string)] = [],
    children: varargs[HtmlNode]): HtmlNode =
  result = elementNode("h1")
  for (k, v) in attrs:
    result.addAttribute(k, v)
  for child in children:
    result.addChild(child)

proc elH2*(attrs: openArray[(string, string)] = [],
    children: varargs[HtmlNode]): HtmlNode =
  result = elementNode("h2")
  for (k, v) in attrs:
    result.addAttribute(k, v)
  for child in children:
    result.addChild(child)

proc elButton*(attrs: openArray[(string, string)] = [],
    children: varargs[HtmlNode]): HtmlNode =
  result = elementNode("button")
  for (k, v) in attrs:
    result.addAttribute(k, v)
  for child in children:
    result.addChild(child)

proc elInput*(attrs: openArray[(string, string)] = []): HtmlNode =
  result = elementNode("input")
  for (k, v) in attrs:
    result.addAttribute(k, v)

proc elLabel*(attrs: openArray[(string, string)] = [],
    children: varargs[HtmlNode]): HtmlNode =
  result = elementNode("label")
  for (k, v) in attrs:
    result.addAttribute(k, v)
  for child in children:
    result.addChild(child)

proc elForm*(attrs: openArray[(string, string)] = [],
    children: varargs[HtmlNode]): HtmlNode =
  result = elementNode("form")
  for (k, v) in attrs:
    result.addAttribute(k, v)
  for child in children:
    result.addChild(child)

proc elA*(attrs: openArray[(string, string)] = [],
    children: varargs[HtmlNode]): HtmlNode =
  result = elementNode("a")
  for (k, v) in attrs:
    result.addAttribute(k, v)
  for child in children:
    result.addChild(child)

proc elNav*(attrs: openArray[(string, string)] = [],
    children: varargs[HtmlNode]): HtmlNode =
  result = elementNode("nav")
  for (k, v) in attrs:
    result.addAttribute(k, v)
  for child in children:
    result.addChild(child)

proc elUl*(attrs: openArray[(string, string)] = [],
    children: varargs[HtmlNode]): HtmlNode =
  result = elementNode("ul")
  for (k, v) in attrs:
    result.addAttribute(k, v)
  for child in children:
    result.addChild(child)

proc elLi*(attrs: openArray[(string, string)] = [],
    children: varargs[HtmlNode]): HtmlNode =
  result = elementNode("li")
  for (k, v) in attrs:
    result.addAttribute(k, v)
  for child in children:
    result.addChild(child)

proc elSection*(attrs: openArray[(string, string)] = [],
    children: varargs[HtmlNode]): HtmlNode =
  result = elementNode("section")
  for (k, v) in attrs:
    result.addAttribute(k, v)
  for child in children:
    result.addChild(child)

proc elHeader*(attrs: openArray[(string, string)] = [],
    children: varargs[HtmlNode]): HtmlNode =
  result = elementNode("header")
  for (k, v) in attrs:
    result.addAttribute(k, v)
  for child in children:
    result.addChild(child)

proc elFooter*(attrs: openArray[(string, string)] = [],
    children: varargs[HtmlNode]): HtmlNode =
  result = elementNode("footer")
  for (k, v) in attrs:
    result.addAttribute(k, v)
  for child in children:
    result.addChild(child)

proc elTextarea*(attrs: openArray[(string, string)] = [],
    children: varargs[HtmlNode]): HtmlNode =
  result = elementNode("textarea")
  for (k, v) in attrs:
    result.addAttribute(k, v)
  for child in children:
    result.addChild(child)

proc elSelect*(attrs: openArray[(string, string)] = [],
    children: varargs[HtmlNode]): HtmlNode =
  result = elementNode("select")
  for (k, v) in attrs:
    result.addAttribute(k, v)
  for child in children:
    result.addChild(child)

proc elOption*(attrs: openArray[(string, string)] = [],
    children: varargs[HtmlNode]): HtmlNode =
  result = elementNode("option")
  for (k, v) in attrs:
    result.addAttribute(k, v)
  for child in children:
    result.addChild(child)

proc elTable*(attrs: openArray[(string, string)] = [],
    children: varargs[HtmlNode]): HtmlNode =
  result = elementNode("table")
  for (k, v) in attrs:
    result.addAttribute(k, v)
  for child in children:
    result.addChild(child)

proc elTr*(attrs: openArray[(string, string)] = [],
    children: varargs[HtmlNode]): HtmlNode =
  result = elementNode("tr")
  for (k, v) in attrs:
    result.addAttribute(k, v)
  for child in children:
    result.addChild(child)

proc elTd*(attrs: openArray[(string, string)] = [],
    children: varargs[HtmlNode]): HtmlNode =
  result = elementNode("td")
  for (k, v) in attrs:
    result.addAttribute(k, v)
  for child in children:
    result.addChild(child)

proc elTh*(attrs: openArray[(string, string)] = [],
    children: varargs[HtmlNode]): HtmlNode =
  result = elementNode("th")
  for (k, v) in attrs:
    result.addAttribute(k, v)
  for child in children:
    result.addChild(child)

proc elImg*(attrs: openArray[(string, string)] = []): HtmlNode =
  result = elementNode("img")
  for (k, v) in attrs:
    result.addAttribute(k, v)

proc elMain*(attrs: openArray[(string, string)] = [],
    children: varargs[HtmlNode]): HtmlNode =
  result = elementNode("main")
  for (k, v) in attrs:
    result.addAttribute(k, v)
  for child in children:
    result.addChild(child)

proc elArticle*(attrs: openArray[(string, string)] = [],
    children: varargs[HtmlNode]): HtmlNode =
  result = elementNode("article")
  for (k, v) in attrs:
    result.addAttribute(k, v)
  for child in children:
    result.addChild(child)

proc elAside*(attrs: openArray[(string, string)] = [],
    children: varargs[HtmlNode]): HtmlNode =
  result = elementNode("aside")
  for (k, v) in attrs:
    result.addAttribute(k, v)
  for child in children:
    result.addChild(child)

proc elPre*(attrs: openArray[(string, string)] = [],
    children: varargs[HtmlNode]): HtmlNode =
  result = elementNode("pre")
  for (k, v) in attrs:
    result.addAttribute(k, v)
  for child in children:
    result.addChild(child)

proc elCode*(attrs: openArray[(string, string)] = [],
    children: varargs[HtmlNode]): HtmlNode =
  result = elementNode("code")
  for (k, v) in attrs:
    result.addAttribute(k, v)
  for child in children:
    result.addChild(child)

proc elHead*(attrs: openArray[(string, string)] = [],
    children: varargs[HtmlNode]): HtmlNode =
  result = elementNode("head")
  for (k, v) in attrs:
    result.addAttribute(k, v)
  for child in children:
    result.addChild(child)

proc elBody*(attrs: openArray[(string, string)] = [],
    children: varargs[HtmlNode]): HtmlNode =
  result = elementNode("body")
  for (k, v) in attrs:
    result.addAttribute(k, v)
  for child in children:
    result.addChild(child)

proc elHtml*(attrs: openArray[(string, string)] = [],
    children: varargs[HtmlNode]): HtmlNode =
  result = elementNode("html")
  for (k, v) in attrs:
    result.addAttribute(k, v)
  for child in children:
    result.addChild(child)

proc elScript*(attrs: openArray[(string, string)] = [],
    children: varargs[HtmlNode]): HtmlNode =
  result = elementNode("script")
  for (k, v) in attrs:
    result.addAttribute(k, v)
  for child in children:
    result.addChild(child)

proc elStyle*(attrs: openArray[(string, string)] = [],
    children: varargs[HtmlNode]): HtmlNode =
  result = elementNode("style")
  for (k, v) in attrs:
    result.addAttribute(k, v)
  for child in children:
    result.addChild(child)

proc elTitle*(attrs: openArray[(string, string)] = [],
    children: varargs[HtmlNode]): HtmlNode =
  result = elementNode("title")
  for (k, v) in attrs:
    result.addAttribute(k, v)
  for child in children:
    result.addChild(child)

proc text*(content: string): HtmlNode =
  textNode(content)

import ../dom/node

export node

type
  ElementBuilder* = proc(): HtmlNode

template defineElement(name: untyped, tag: string) =
  proc name*(attrs: openArray[(string, string)] = [],
      children: varargs[HtmlNode]): HtmlNode =
    result = elementNode(tag)
    for (k, v) in attrs:
      result.addAttribute(k, v)
    for child in children:
      result.addChild(child)

template defineVoidElement(name: untyped, tag: string) =
  proc name*(attrs: openArray[(string, string)] = []): HtmlNode =
    result = elementNode(tag)
    for (k, v) in attrs:
      result.addAttribute(k, v)

# Regular elements (with children)
defineElement(elDiv, "div")
defineElement(elSpan, "span")
defineElement(elP, "p")
defineElement(elH1, "h1")
defineElement(elH2, "h2")
defineElement(elH3, "h3")
defineElement(elH4, "h4")
defineElement(elH5, "h5")
defineElement(elH6, "h6")
defineElement(elButton, "button")
defineElement(elLabel, "label")
defineElement(elForm, "form")
defineElement(elA, "a")
defineElement(elNav, "nav")
defineElement(elUl, "ul")
defineElement(elOl, "ol")
defineElement(elLi, "li")
defineElement(elSection, "section")
defineElement(elHeader, "header")
defineElement(elFooter, "footer")
defineElement(elTextarea, "textarea")
defineElement(elSelect, "select")
defineElement(elOption, "option")
defineElement(elTable, "table")
defineElement(elThead, "thead")
defineElement(elTbody, "tbody")
defineElement(elTr, "tr")
defineElement(elTd, "td")
defineElement(elTh, "th")
defineElement(elMain, "main")
defineElement(elArticle, "article")
defineElement(elAside, "aside")
defineElement(elPre, "pre")
defineElement(elCode, "code")
defineElement(elHead, "head")
defineElement(elBody, "body")
defineElement(elHtml, "html")
defineElement(elScript, "script")
defineElement(elStyle, "style")
defineElement(elTitle, "title")

# Void elements (no children)
defineVoidElement(elInput, "input")
defineVoidElement(elImg, "img")
defineVoidElement(elBr, "br")
defineVoidElement(elHr, "hr")
defineVoidElement(elLink, "link")
defineVoidElement(elMeta, "meta")

proc text*(content: string): HtmlNode =
  textNode(content)

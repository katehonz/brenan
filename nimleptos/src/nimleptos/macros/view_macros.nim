import std/macros
import ../dom/node

export node

type
  ComponentChildren* = seq[HtmlNode]

proc slot*(children: ComponentChildren, name: string = "default"): HtmlNode =
  if children.len == 0:
    return textNode("")
  if children.len == 1:
    return children[0]
  var wrapper = elementNode("div")
  wrapper.addAttribute("style", "display: contents")
  for child in children:
    wrapper.addChild(child)
  return wrapper

proc noChildren*(): ComponentChildren = @[]

proc renderSlot*(children: ComponentChildren, placeholder: HtmlNode = nil): HtmlNode =
  if children.len > 0:
    return slot(children)
  if placeholder != nil:
    return placeholder
  return textNode("")

macro view*(callNode: untyped, body: untyped = nil): untyped =
  ## Call a component with props and optional child content.
  ## Children are wrapped in `buildHtml` automatically.
  result = copyNimTree(callNode)
  if body != nil and body.kind != nnkEmpty:
    let childrenExpr = newCall("@", newCall("buildHtml", body))
    result.add(newNimNode(nnkExprEqExpr).add(ident("children")).add(childrenExpr))

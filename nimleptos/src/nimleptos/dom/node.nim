import std/strutils

type
  ReactiveAttr* = tuple[name: string, getter: proc(): string {.closure.}]

  HtmlNode* = ref object
    tag*: string
    attributes*: seq[(string, string)]
    events*: seq[(string, string)]
    children*: seq[HtmlNode]
    text*: string
    isText*: bool
    reactiveText*: proc(): string {.closure.}  ## If set, this text node auto-updates in the browser
    reactiveAttrs*: seq[ReactiveAttr]  ## Attributes that auto-update in the browser
    condition*: proc(): bool {.closure, gcsafe.}  ## For conditional nodes (if/else)
    thenBranch*: HtmlNode  ## Shown when condition is true
    elseBranch*: HtmlNode  ## Shown when condition is false

proc escapeHtml*(s: string): string =
  result = s
  result = result.replace("&", "&amp;")
  result = result.replace("<", "&lt;")
  result = result.replace(">", "&gt;")
  result = result.replace("\"", "&quot;")

proc textNode*(content: string): HtmlNode =
  HtmlNode(text: content, isText: true)

proc reactiveTextNode*(content: string, getter: proc(): string {.closure.}): HtmlNode =
  ## Create a text node with reactive binding for CSR.
  ## The getter is called automatically when the node is rendered to DOM via `renderDomNode`.
  HtmlNode(text: content, isText: true, reactiveText: getter)

proc elementNode*(tag: string): HtmlNode =
  HtmlNode(tag: tag, isText: false)

proc addAttribute*(node: HtmlNode, key: string, value: string) =
  node.attributes.add((key, value))

proc addReactiveAttr*(node: HtmlNode, name: string, getter: proc(): string {.closure.}) =
  ## Add an attribute that automatically updates when the signal changes.
  ## Used by the buildHtml macro for reactive attribute interpolation.
  node.reactiveAttrs.add((name, getter))

proc conditionalNode*(condition: proc(): bool {.closure, gcsafe.}, thenBranch, elseBranch: HtmlNode): HtmlNode =
  ## Create a conditional node that shows/hides branches based on a signal.
  ## Used by the buildHtml macro for reactive if/else control flow.
  result = elementNode("conditional")
  result.condition = condition
  result.thenBranch = thenBranch
  result.elseBranch = elseBranch

proc addEvent*(node: HtmlNode, event: string, handlerId: string) =
  node.events.add((event, handlerId))

proc addChild*(node: HtmlNode, child: HtmlNode) =
  node.children.add(child)

proc renderToHtml*(node: HtmlNode): string =
  if node.isText:
    return escapeHtml(node.text)
  if node.condition != nil:
    if node.condition():
      return renderToHtml(node.thenBranch)
    else:
      return renderToHtml(node.elseBranch)

  result = "<" & node.tag
  for (key, value) in node.attributes:
    result &= " " & key & "=\"" & escapeHtml(value) & "\""
  result &= ">"

  for child in node.children:
    result &= renderToHtml(child)

  result &= "</" & node.tag & ">"

proc renderToHtmlRaw*(node: HtmlNode): string =
  if node.isText:
    return node.text

  result = "<" & node.tag
  for (key, value) in node.attributes:
    result &= " " & key & "=\"" & value & "\""
  result &= ">"

  for child in node.children:
    result &= renderToHtmlRaw(child)

  result &= "</" & node.tag & ">"

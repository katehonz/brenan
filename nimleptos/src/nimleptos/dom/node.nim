import std/strutils

type
  HtmlNode* = ref object
    tag*: string
    attributes*: seq[(string, string)]
    events*: seq[(string, string)]
    children*: seq[HtmlNode]
    text*: string
    isText*: bool

proc escapeHtml*(s: string): string =
  result = s
  result = result.replace("&", "&amp;")
  result = result.replace("<", "&lt;")
  result = result.replace(">", "&gt;")
  result = result.replace("\"", "&quot;")

proc textNode*(content: string): HtmlNode =
  HtmlNode(text: content, isText: true)

proc elementNode*(tag: string): HtmlNode =
  HtmlNode(tag: tag, isText: false)

proc addAttribute*(node: HtmlNode, key: string, value: string) =
  node.attributes.add((key, value))

proc addEvent*(node: HtmlNode, event: string, handlerId: string) =
  node.events.add((event, handlerId))

proc addChild*(node: HtmlNode, child: HtmlNode) =
  node.children.add(child)

proc renderToHtml*(node: HtmlNode): string =
  if node.isText:
    return escapeHtml(node.text)

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

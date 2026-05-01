import nimmax
import ../dom/node
import ../dom/elements
import ./route

proc html5Layout*(headNodes: seq[HtmlNode] = @[], bodyClass = ""): LayoutComponent =
  result = proc(ctx: Context, children: HtmlNode): Future[HtmlNode] {.gcsafe.} =
    result = newFuture[HtmlNode]()
    var bodyAttrs: seq[(string, string)] = @[]
    if bodyClass.len > 0:
      bodyAttrs.add(("class", bodyClass))
    var headChildren: seq[HtmlNode] = @[]
    for node in headNodes:
      headChildren.add(node)
    let head = elHead([], headChildren)
    let body = elBody(bodyAttrs, children)
    complete(result, elHtml([], head, body))

proc mainLayout*(navHtml: HtmlNode = nil, footerHtml: HtmlNode = nil): LayoutComponent =
  result = proc(ctx: Context, children: HtmlNode): Future[HtmlNode] {.gcsafe.} =
    result = newFuture[HtmlNode]()
    var parts: seq[HtmlNode] = @[]
    if navHtml != nil:
      parts.add(navHtml)
    parts.add(children)
    if footerHtml != nil:
      parts.add(footerHtml)
    complete(result, elDiv([("class", "layout")], parts))

proc sidebarLayout*(sidebar: HtmlNode): LayoutComponent =
  result = proc(ctx: Context, children: HtmlNode): Future[HtmlNode] {.gcsafe.} =
    result = newFuture[HtmlNode]()
    complete(result, elDiv([("class", "sidebar-layout")],
      elDiv([("class", "sidebar")], sidebar),
      elDiv([("class", "main-content")], children)
    ))

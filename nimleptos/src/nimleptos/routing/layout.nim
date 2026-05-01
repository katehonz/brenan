import nimmax
import ../dom/node
import ../dom/elements
import ./route

proc html5Layout*(headNodes: seq[HtmlNode] = @[], bodyClass = ""): LayoutComponent =
  result = proc(ctx: Context, children: HtmlNode): Future[HtmlNode] {.gcsafe.} =
    result = newFuture[HtmlNode]()
    complete(result, elDiv([], children))

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

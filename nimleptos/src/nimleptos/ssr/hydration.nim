import ../dom/node
import renderer

type
  HydrationNode* = ref object
    id*: int
    tag*: string
    signalValues*: seq[(string, string)]

proc injectHydrationIds*(node: HtmlNode, ctx: SSRContext, parentId: int = -1): int =
  let markerId = ctx.nextMarkerId()
  node.addAttribute("data-nl-id", $markerId)

  for child in node.children:
    if not child.isText:
      discard injectHydrationIds(child, ctx, markerId)

  return markerId

proc renderWithHydration*(node: HtmlNode, ctx: SSRContext): string =
  discard injectHydrationIds(node, ctx)
  return renderToHtml(node)

proc renderPageWithHydration*(ctx: SSRContext, body: HtmlNode,
    title: string = "NimLeptos App"): string =
  let hydratedHtml = renderWithHydration(body, ctx)
  return renderFullPage(ctx, hydratedHtml, title)

proc generateHydrationScript*(ctx: SSRContext): string =
  result = "<script>"
  result &= """
(function() {
  var data = document.getElementById('__nimleptos_data__');
  if (!data) return;
  var info = JSON.parse(data.textContent);
  var nodes = document.querySelectorAll('[data-nl-id]');
  nodes.forEach(function(node) {
    var id = parseInt(node.getAttribute('data-nl-id'));
    node.__nimleptos_id = id;
  });
  window.__nimleptos = { nextId: info.nextId, nodes: nodes, initialState: info.initialState || {} };
})();
"""
  result &= "</script>"

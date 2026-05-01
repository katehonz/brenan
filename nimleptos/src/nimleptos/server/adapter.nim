import nimmax
import ../dom/node
import ../ssr/renderer
import ../ssr/hydration

export nimmax
export node
export renderer
export hydration

type
  NimLeptosContext* = ref object
    ssrCtx*: SSRContext
    nimmaxCtx*: Context
    title*: string

proc newNimLeptosContext*(ctx: Context, title: string = "NimLeptos App"): NimLeptosContext =
  NimLeptosContext(
    ssrCtx: newSSRContext(),
    nimmaxCtx: ctx,
    title: title
  )

proc render*(ctx: NimLeptosContext, node: HtmlNode, title: string = "") =
  let t = if title.len > 0: title else: ctx.title
  let html = renderPageWithHydration(ctx.ssrCtx, node, t)
  ctx.nimmaxCtx.html(html)

proc render*(nimmaxCtx: Context, node: HtmlNode, title: string = "NimLeptos App") =
  let ssrCtx = newSSRContext()
  let html = renderPageWithHydration(ssrCtx, node, title)
  nimmaxCtx.html(html)

proc renderRaw*(nimmaxCtx: Context, node: HtmlNode) =
  nimmaxCtx.html(renderToHtml(node))

proc renderJson*(nimmaxCtx: Context, node: HtmlNode) =
  nimmaxCtx.json(%*{"html": renderToHtml(node)})

proc renderFragment*(nimmaxCtx: Context, node: HtmlNode) =
  nimmaxCtx.html(renderToHtml(node))

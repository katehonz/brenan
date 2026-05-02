import nimmax
import ../dom/node
import ../server/adapter
import ../server/app

type
  RouteComponent* = proc(ctx: Context): Future[HtmlNode] {.gcsafe.}
  LayoutComponent* = proc(ctx: Context, children: HtmlNode): Future[HtmlNode] {.gcsafe.}

  RouteDef* = object
    path*: string
    component*: RouteComponent
    layout*: LayoutComponent
    name*: string
    httpMethod*: HttpMethod

# -----------------------------------------------------------------------------
# NimMax Application (raw) — handlers are NOT wrapped with reactive context
# -----------------------------------------------------------------------------
proc route*(app: Application, path: string, component: RouteComponent,
            layout: LayoutComponent = nil, name = "") =
  proc handler(ctx: Context) {.async.} =
    let node = await component(ctx)
    if layout != nil:
      let wrapped = await layout(ctx, node)
      ctx.render(wrapped)
    else:
      ctx.render(node)
  app.get(path, handler, name = name)

proc routePost*(app: Application, path: string, component: RouteComponent,
                layout: LayoutComponent = nil, name = "") =
  proc handler(ctx: Context) {.async.} =
    let node = await component(ctx)
    if layout != nil:
      let wrapped = await layout(ctx, node)
      ctx.render(wrapped)
    else:
      ctx.render(node)
  app.post(path, handler, name = name)

proc routeGroup*(app: Application, prefix: string, routes: seq[RouteDef],
                 middlewares: seq[HandlerAsync] = @[]) =
  let group = app.newGroup(prefix, middlewares)
  for r in routes:
    proc handler(ctx: Context) {.async.} =
      let node = await r.component(ctx)
      if r.layout != nil:
        let wrapped = await r.layout(ctx, node)
        ctx.render(wrapped)
      else:
        ctx.render(node)
    case r.httpMethod
    of HttpGet: group.get(r.path, handler, name = r.name)
    of HttpPost: group.post(r.path, handler, name = r.name)
    of HttpPut: group.put(r.path, handler, name = r.name)
    of HttpDelete: group.delete(r.path, handler, name = r.name)
    else: group.get(r.path, handler, name = r.name)

# -----------------------------------------------------------------------------
# NimLeptosApp — handlers ARE wrapped with per-request reactive context
# -----------------------------------------------------------------------------
proc route*(app: NimLeptosApp, path: string, component: RouteComponent,
            layout: LayoutComponent = nil, name = "") =
  proc handler(ctx: Context) {.async.} =
    let node = await component(ctx)
    if layout != nil:
      let wrapped = await layout(ctx, node)
      ctx.render(wrapped, app)
    else:
      ctx.render(node, app)
  app.nimmaxApp.get(path, wrapHandler(handler), name = name)

proc routePost*(app: NimLeptosApp, path: string, component: RouteComponent,
                layout: LayoutComponent = nil, name = "") =
  proc handler(ctx: Context) {.async.} =
    let node = await component(ctx)
    if layout != nil:
      let wrapped = await layout(ctx, node)
      ctx.render(wrapped, app)
    else:
      ctx.render(node, app)
  app.nimmaxApp.post(path, wrapHandler(handler), name = name)

proc routeGroup*(app: NimLeptosApp, prefix: string, routes: seq[RouteDef],
                 middlewares: seq[HandlerAsync] = @[]) =
  let group = app.nimmaxApp.newGroup(prefix, middlewares)
  for r in routes:
    proc handler(ctx: Context) {.async.} =
      let node = await r.component(ctx)
      if r.layout != nil:
        let wrapped = await r.layout(ctx, node)
        ctx.render(wrapped, app)
      else:
        ctx.render(node, app)
    case r.httpMethod
    of HttpGet: group.get(r.path, wrapHandler(handler), name = r.name)
    of HttpPost: group.post(r.path, wrapHandler(handler), name = r.name)
    of HttpPut: group.put(r.path, wrapHandler(handler), name = r.name)
    of HttpDelete: group.delete(r.path, wrapHandler(handler), name = r.name)
    else: group.get(r.path, wrapHandler(handler), name = r.name)

proc page*(component: RouteComponent, layout: LayoutComponent = nil): RouteDef =
  RouteDef(path: "", component: component, layout: layout, httpMethod: HttpGet)

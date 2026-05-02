import nimmax
import ../dom/node
import ../ssr/renderer
import ../ssr/hydration
import ../reactive/subscriber
import ./adapter

export adapter
export subscriber

type
  NimLeptosApp* = ref object
    nimmaxApp*: Application
    ssrCtx*: SSRContext
    defaultTitle*: string
    clientScript*: string
    clientStyle*: string

proc newNimLeptosApp*(
  settings: Settings = newSettings(),
  title: string = "NimLeptos App",
  clientScript: string = "",
  clientStyle: string = ""
): NimLeptosApp =
  result = NimLeptosApp(
    nimmaxApp: newApp(settings = settings),
    ssrCtx: newSSRContext(),
    defaultTitle: title,
    clientScript: clientScript,
    clientStyle: clientStyle
  )
  if clientScript.len > 0:
    result.ssrCtx.addScript(clientScript)
  if clientStyle.len > 0:
    result.ssrCtx.addStyle(clientStyle)

proc wrapHandler(handler: HandlerAsync): HandlerAsync =
  return proc(ctx: Context) {.async.} =
    withReactiveContext:
      await handler(ctx)

template get*(app: NimLeptosApp, path: string, handler: HandlerAsync,
              middlewares: seq[HandlerAsync] = @[], name = "") =
  app.nimmaxApp.get(path, wrapHandler(handler), middlewares, name)

template post*(app: NimLeptosApp, path: string, handler: HandlerAsync,
               middlewares: seq[HandlerAsync] = @[], name = "") =
  app.nimmaxApp.post(path, wrapHandler(handler), middlewares, name)

template put*(app: NimLeptosApp, path: string, handler: HandlerAsync,
              middlewares: seq[HandlerAsync] = @[], name = "") =
  app.nimmaxApp.put(path, wrapHandler(handler), middlewares, name)

template delete*(app: NimLeptosApp, path: string, handler: HandlerAsync,
                 middlewares: seq[HandlerAsync] = @[], name = "") =
  app.nimmaxApp.delete(path, wrapHandler(handler), middlewares, name)

template patch*(app: NimLeptosApp, path: string, handler: HandlerAsync,
                middlewares: seq[HandlerAsync] = @[], name = "") =
  app.nimmaxApp.patch(path, wrapHandler(handler), middlewares, name)

template all*(app: NimLeptosApp, path: string, handler: HandlerAsync,
              middlewares: seq[HandlerAsync] = @[], name = "") =
  app.nimmaxApp.all(path, wrapHandler(handler), middlewares, name)

proc use*(app: NimLeptosApp, middlewares: varargs[HandlerAsync]) =
  app.nimmaxApp.use(middlewares)

proc newGroup*(app: NimLeptosApp, prefix: string,
               middlewares: seq[HandlerAsync] = @[]): Group =
  app.nimmaxApp.newGroup(prefix, middlewares)

proc registerErrorHandler*(app: NimLeptosApp, code: HttpCode, handler: ErrorHandler) =
  app.nimmaxApp.registerErrorHandler(code, handler)

proc onStart*(app: NimLeptosApp, handler: Event) =
  app.nimmaxApp.onStart(handler)

proc onStop*(app: NimLeptosApp, handler: Event) =
  app.nimmaxApp.onStop(handler)

proc render*(ctx: Context, node: HtmlNode, app: NimLeptosApp, title: string = "") =
  let t = if title.len > 0: title else: app.defaultTitle
  let html = renderPageWithHydration(app.ssrCtx, node, t)
  ctx.html(html)

proc run*(app: NimLeptosApp, address = "", port: Port = Port(0), debug = true) =
  app.nimmaxApp.run(address, port, debug)

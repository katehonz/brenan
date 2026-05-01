import nimmax
import ../../src/nimleptos

proc homePage(ctx: Context): Future[HtmlNode] {.gcsafe.} =
  result = newFuture[HtmlNode]()
  let (count, setCount) = createSignal(0)
  var countText: string
  discard createEffect(proc() =
    countText = $count()
  )
  let node = elDiv([("class", "home")],
    elH1([], text("NimLeptos + NimMax")),
    elP([], text("Count: " & countText)),
    elDiv([("class", "actions")],
      elButton([("onclick", "fetch('/api/count', {method:'POST'})")],
        text("Increment"))
    )
  )
  complete(result, node)

proc aboutPage(ctx: Context): Future[HtmlNode] {.gcsafe.} =
  result = newFuture[HtmlNode]()
  complete(result, elDiv([("class", "about")],
    elH1([], text("About")),
    elP([], text("NimLeptos is a reactive web framework for Nim."))
  ))

proc apiCountHandler(ctx: Context) {.async.} =
  ctx.json(%*{"status": "ok"})

proc main() =
  let settings = newSettings(
    address = "0.0.0.0",
    port = Port(8080),
    debug = true,
    appName = "NimLeptos Server"
  )

  let app = newNimLeptosApp(settings = settings, title = "NimLeptos")

  app.use(loggingMiddleware())

  app.get("/", proc(ctx: Context) {.async.} =
    let node = await homePage(ctx)
    ctx.render(node, app, "Home")
  , name = "home")

  app.get("/about", proc(ctx: Context) {.async.} =
    let node = await aboutPage(ctx)
    ctx.render(node, app, "About")
  , name = "about")

  app.post("/api/count", apiCountHandler, name = "api_count")

  app.get("/api/html", proc(ctx: Context) {.async.} =
    let node = elDiv([], text("Dynamic content"))
    ctx.renderFragment(node)
  , name = "api_html")

  echo "Starting NimLeptos server on http://0.0.0.0:8080"
  app.run()

main()

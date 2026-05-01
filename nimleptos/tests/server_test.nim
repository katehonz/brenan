import ../src/nimleptos
import nimmax
import nimmax/mocking

proc testNimLeptosAppCreation() =
  let app = newNimLeptosApp(title = "Test App")
  doAssert app != nil
  doAssert app.defaultTitle == "Test App"
  echo "PASS: NimLeptosApp creation"

proc testRenderToContext() =
  let nimmaxApp = mockApp()
  nimmaxApp.get("/", proc(ctx: Context) {.async.} =
    let node = elDiv([("class", "test")], text("Hello"))
    ctx.render(node)
  )
  let ctx = nimmaxApp.runOnce(HttpGet, "/")
  doAssert ctx.response.code == Http200
  doAssert ctx.response.body.contains("class=\"test\"")
  doAssert ctx.response.body.contains("Hello")
  doAssert ctx.response.body.contains("__nimleptos_data__")
  echo "PASS: render to context"

proc testRenderWithCustomTitle() =
  let nimmaxApp = mockApp()
  nimmaxApp.get("/", proc(ctx: Context) {.async.} =
    let node = elDiv([], text("Page"))
    ctx.render(node, title = "Custom Title")
  )
  let ctx = nimmaxApp.runOnce(HttpGet, "/")
  doAssert ctx.response.body.contains("<title>Custom Title</title>")
  echo "PASS: render with custom title"

proc testRenderFragment() =
  let nimmaxApp = mockApp()
  nimmaxApp.get("/frag", proc(ctx: Context) {.async.} =
    let node = elSpan([("id", "s1")], text("Fragment"))
    ctx.renderFragment(node)
  )
  let ctx = nimmaxApp.runOnce(HttpGet, "/frag")
  doAssert ctx.response.code == Http200
  doAssert ctx.response.body.contains("<span")
  doAssert ctx.response.body.contains("Fragment")
  doAssert not ctx.response.body.contains("__nimleptos_data__")
  echo "PASS: render fragment"

proc testRouteComponent() =
  let nimmaxApp = mockApp()
  nimmaxApp.route("/hello", proc(ctx: Context): Future[HtmlNode] {.gcsafe.} =
    result = newFuture[HtmlNode]()
    complete(result, elDiv([], text("Hello World")))
  )
  let ctx = nimmaxApp.runOnce(HttpGet, "/hello")
  doAssert ctx.response.code == Http200
  doAssert ctx.response.body.contains("Hello World")
  echo "PASS: route component"

proc testRouteWithLayout() =
  let nimmaxApp = mockApp()
  let lyt: LayoutComponent = proc(ctx: Context, children: HtmlNode): Future[HtmlNode] {.gcsafe.} =
    result = newFuture[HtmlNode]()
    complete(result, elDiv([("class", "layout")], children))

  nimmaxApp.route("/wrapped", proc(ctx: Context): Future[HtmlNode] {.gcsafe.} =
    result = newFuture[HtmlNode]()
    complete(result, elP([], text("Inner content")))
  , layout = lyt)
  let ctx = nimmaxApp.runOnce(HttpGet, "/wrapped")
  doAssert ctx.response.body.contains("class=\"layout\"")
  doAssert ctx.response.body.contains("Inner content")
  echo "PASS: route with layout"

proc testFormRendering() =
  let form = newFormDef("/submit")
  form.addField("name", "Your Name", required = true)
  form.addField("email", "Email", kind = "email", required = true)
  let html = renderForm(form)
  let rendered = renderToHtml(html)
  doAssert rendered.contains("Your Name")
  doAssert rendered.contains("Email")
  doAssert rendered.contains("type=\"email\"")
  doAssert rendered.contains("required")
  echo "PASS: form rendering"

proc testFormValidation() =
  let v = newNimLeptosValidator()
  v.addRequired("name", "Name")
  v.addEmail("email", "Email")
  let form = newFormDef("/register")
  form.addField("name", "Name")
  form.addField("email", "Email")

  let values = @[("name", ""), ("email", "invalid")]
  doAssert not v.validateFormFields(form, values)
  doAssert form.hasErrors()
  echo "PASS: form validation"

proc testRouteGroup() =
  let nimmaxApp = mockApp()
  let api = nimmaxApp.newGroup("/api")
  api.get("/users", proc(ctx: Context) {.async.} =
    ctx.json(%*{"users": @["Alice", "Bob"]})
  )
  api.get("/users/{id}", proc(ctx: Context) {.async.} =
    let id = ctx.getPathParam("id")
    ctx.json(%*{"user_id": id})
  )

  let ctx1 = nimmaxApp.runOnce(HttpGet, "/api/users")
  doAssert ctx1.response.code == Http200
  doAssert ctx1.response.body.contains("Alice")

  let ctx2 = nimmaxApp.runOnce(HttpGet, "/api/users/42")
  doAssert ctx2.response.code == Http200
  doAssert ctx2.response.body.contains("42")
  echo "PASS: route group"

when isMainModule:
  testNimLeptosAppCreation()
  testRenderToContext()
  testRenderWithCustomTitle()
  testRenderFragment()
  testRouteComponent()
  testRouteWithLayout()
  testFormRendering()
  testFormValidation()
  testRouteGroup()
  echo ""
  echo "All server tests passed!"

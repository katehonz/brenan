## i18n Demo App — SSR with Accept-Language detection + client-side language switcher
##
## Run server:
##   nim c -r --threads:on -p:src examples/i18n_app.nim
##
## Compile client JS (optional, for full interactivity):
##   nim js -p:src -o:examples/i18n_client.js examples/i18n_client.nim
##
## Open http://localhost:8080

import nimmax
import nimleptos
import nimleptos/i18n/locale_middleware
import nimleptos/i18n/catalog
import nimleptos/i18n/i18n
import nimleptos/i18n/interpolate
import std/strutils
import std/json

const clientJsContent = staticRead("i18n_client.js")

proc main() =
  let settings = newSettings(
    address = "0.0.0.0",
    port = Port(8080),
    debug = true
  )

  let inlineCss = """
body { font-family: system-ui,-apple-system,sans-serif; margin:0; padding:0; background:#f5f5f5; }
.app { max-width:800px; margin:0 auto; background:#fff; min-height:100vh; }
.site-header { background:#2c3e50; color:#fff; padding:1rem 2rem; display:flex; justify-content:space-between; align-items:center; }
.site-header h1 { margin:0; font-size:1.5rem; }
.lang-nav { display:flex; gap:.5rem; }
.lang-link { color:#fff; text-decoration:none; padding:.25rem .75rem; border-radius:4px; }
.lang-link:hover { background:rgba(255,255,255,.2); }
.main-content { padding:2rem; }
.greeting { font-size:1.25rem; color:#34495e; }
.client-mount { margin-top:2rem; padding:1.5rem; border:2px dashed #bdc3c7; border-radius:8px; }
.site-footer { text-align:center; padding:1rem; color:#7f8c8d; border-top:1px solid #ecf0f1; }
.client-app { text-align:center; }
.locale-info { font-size:.875rem; color:#7f8c8d; margin-bottom:1rem; }
.lang-switcher { display:flex; justify-content:center; gap:.5rem; margin-bottom:1.5rem; }
.btn { padding:.5rem 1rem; border:none; border-radius:4px; cursor:pointer; font-size:1rem; }
.btn-lang { background:#3498db; color:#fff; }
.btn-lang:hover { background:#2980b9; }
.btn-dec { background:#e74c3c; color:#fff; }
.btn-inc { background:#2ecc71; color:#fff; }
.counter-controls { display:flex; justify-content:center; align-items:center; gap:1rem; margin:1rem 0; }
.count-display { font-size:1.5rem; font-weight:bold; min-width:2rem; }
.plural-result { font-size:1.125rem; color:#2c3e50; font-weight:500; }
"""

  let app = newNimLeptosApp(
    settings = settings,
    title = "i18n Demo",
    clientScript = "/i18n_client.js",
    clientStyle = inlineCss
  )

  # Locale detection from Accept-Language header, cookie, or URL query
  app.use(localeMiddleware(newLocaleDetection("en", @["en", "bg", "fr"])))

  let catalog = loadCatalog("locales/app.json")

  app.get("/", proc(ctx: Context) {.async, gcsafe.} =
    let locale = ctx["locale"].getStr("en")
    let cfg = createI18n(catalog, locale)

    # Prepare interpolation params outside buildHtml for GC safety in async proc
    var greetingParams = initTable[string, InterpValue]()
    greetingParams["name"] = str("NimLeptos")

    let node = buildHtml:
      el("div", class="app"):
        el("header", class="site-header"):
          el("h1"): text(translate(cfg, "hello"))
          el("nav", class="lang-nav"):
            el("a", href="/?locale=en", class="lang-link"): text("EN")
            el("a", href="/?locale=bg", class="lang-link"): text("BG")
            el("a", href="/?locale=fr", class="lang-link"): text("FR")
        el("main", class="main-content"):
          el("p", class="greeting"): text(translate(cfg, "greeting", greetingParams))
          el("div", class="plural-intro"):
            el("p"): text(translate(cfg, "language"))
          el("div", id="client-app", class="client-mount"):
            text("")
        el("footer", class="site-footer"):
          el("p"): text(translate(cfg, "home"))

    ctx.render(node, app, "i18n Demo")
  )

  # Serve client JS (embedded at compile-time if available)
  app.get("/i18n_client.js", proc(ctx: Context) {.async.} =
    {.gcsafe.}:
      ctx.response.headers["Content-Type"] = "application/javascript"
      ctx.response.body = clientJsContent
  )

  # API endpoint to set locale cookie
  app.post("/api/locale", proc(ctx: Context) {.async, gcsafe.} =
    let body = ctx.request.body
    var newLocale = "en"
    if body.contains("locale="):
      newLocale = body.split("locale=")[1].split("&")[0]
    ctx.response.headers.add("Set-Cookie", "locale=" & newLocale & "; Path=/; Max-Age=31536000")
    ctx.json(%*{"status": "ok", "locale": newLocale})
  )

  echo "i18n Demo server running at http://localhost:8080"
  echo "Supported locales: en, bg, fr"
  echo ""
  echo "To enable client-side interactivity, compile the client JS:"
  echo "  nim js -p:src -o:examples/i18n_client.js examples/i18n_client.nim"
  app.run()

main()

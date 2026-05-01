## NimMax Blog Backend
## Serves JSON API + static files for the NimLeptos frontend
##
## Run:
##   nim c -r --threads:on -p:src examples/blog/backend.nim
##   # Open http://localhost:8080

import nimmax
import nimmax/middlewares/cors
import std/json
import std/strutils
import std/os

type
  Post = object
    id: int
    title: string
    content: string
    date: string

var posts = @[
  Post(id: 1, title: "Hello NimLeptos",
       content: "Welcome to the first post on this blog. NimLeptos is a reactive web framework for Nim inspired by Leptos. It compiles to JavaScript for fine-grained DOM updates without a virtual DOM.",
       date: "2026-05-01"),
  Post(id: 2, title: "Reactive Signals",
       content: "Signals are the core of reactivity. They track dependencies and automatically update the DOM when values change. This is more efficient than diffing a virtual DOM tree.",
       date: "2026-05-01"),
  Post(id: 3, title: "Why Not Dioxus",
       content: "Dioxus is great but WASM-heavy. NimLeptos compiles to JavaScript with fine-grained reactive updates. This means smaller bundle sizes and better interoperability with the existing JS ecosystem.",
       date: "2026-05-01"),
]

proc apiPosts(ctx: Context) {.async, gcsafe.} =
  {.gcsafe.}:
    ctx.json(%*{"posts": posts})

proc apiPost(ctx: Context) {.async, gcsafe.} =
  {.gcsafe.}:
    let idOpt = ctx.getInt("id")
    if idOpt.isSome:
      let id = idOpt.get
      for p in posts:
        if p.id == id:
          ctx.json(%*p)
          return
    ctx.json(%*{"error": "not found"}, Http404)

proc main() =
  let settings = newSettings(
    address = "0.0.0.0",
    port = Port(8080),
    debug = true
  )
  let app = newApp(settings)

  # CORS for local dev
  app.use(corsMiddleware())

  # API routes
  app.get("/api/posts", apiPosts)
  app.get("/api/posts/{id}", apiPost)

  let publicDir = currentSourcePath().parentDir / "public"

  # Static files — manual serving to avoid staticFileMiddleware expandFilename issues
  app.get("/", proc(ctx: Context) {.async, gcsafe.} =
    ctx.html(readFile(publicDir / "index.html"))
  )

  app.get("/app.js", proc(ctx: Context) {.async, gcsafe.} =
    let content = readFile(publicDir / "app.js")
    ctx.response.headers["Content-Type"] = "application/javascript"
    ctx.response.body = content
  )

  app.get("/style.css", proc(ctx: Context) {.async, gcsafe.} =
    let content = readFile(publicDir / "style.css")
    ctx.response.headers["Content-Type"] = "text/css"
    ctx.response.body = content
  )

  # SPA fallback — serve index.html for all unmatched routes
  app.get("/**", proc(ctx: Context) {.async, gcsafe.} =
    ctx.html(readFile(publicDir / "index.html"))
  )

  echo "Blog server running at http://localhost:8080"
  echo "API: http://localhost:8080/api/posts"
  app.run()

main()

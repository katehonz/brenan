## Blog Frontend — NimLeptos client-side reactive app
## Compile: nim js -p:src -o:examples/blog/public/app.js examples/blog/frontend.nim
## Then open http://localhost:8080

import nimleptos/client/reactive_dom
import nimleptos/client/dom_interop
import nimleptos/client/http_client
import nimleptos/client/router
import nimleptos/reactive/signal
import nimleptos/reactive/effects
import std/dom
import std/json
import std/strutils

when defined(js):
  type Post = object
    id: int
    title: string
    content: string
    date: string

  let (posts, setPosts) = createSignal[seq[Post]](@[])
  let (currentPost, setCurrentPost) = createSignal[Post](Post())

  proc loadPosts() =
    fetchGetJson("/api/posts", proc(data: JsonNode) =
      if data.hasKey("posts"):
        var loaded: seq[Post] = @[]
        for p in data["posts"]:
          loaded.add(Post(
            id: p["id"].getInt,
            title: p["title"].getStr,
            content: p["content"].getStr,
            date: p["date"].getStr
          ))
        setPosts(loaded)
    )

  proc loadPost(id: int) =
    fetchGetJson("/api/posts/" & $id, proc(data: JsonNode) =
      if data.hasKey("id"):
        setCurrentPost(Post(
          id: data["id"].getInt,
          title: data["title"].getStr,
          content: data["content"].getStr,
          date: data["date"].getStr
        ))
    )

  # Auto-load post when route changes to /post/{id}
  discard createEffect(proc() =
    let r = hashRoute()()
    if r.startsWith("/post/"):
      let idStr = routeParam(r, "/post/")
      if idStr.len > 0:
        try:
          let id = parseInt(idStr)
          loadPost(id)
        except ValueError:
          discard
    else:
      setCurrentPost(Post())
  )

  proc postCardDom(post: Post): DomElement =
    let article = createElement("article")
    article.setAttribute("class", "post-card")

    let h2 = createElement("h2")
    h2.textContent = post.title.cstring
    article.appendChild(h2)

    let date = createElement("p")
    date.setAttribute("class", "date")
    date.textContent = post.date.cstring
    article.appendChild(date)

    let excerpt = if post.content.len > 120: post.content[0..119] & "..." else: post.content
    let excerptP = createElement("p")
    excerptP.setAttribute("class", "excerpt")
    excerptP.textContent = excerpt.cstring
    article.appendChild(excerptP)

    let a = createElement("a")
    a.setAttribute("href", ("#/post/" & $post.id))
    a.setAttribute("class", "read-more")
    a.textContent = "Read more →"
    article.appendChild(a)

    return article

  proc postListDom(): DomElement =
    let container = createElement("div")
    container.setAttribute("class", "posts-grid")
    discard createEffect(proc() =
      clearChildren(container)
      for p in posts():
        let card = postCardDom(p)
        container.appendChild(card)
    )
    return container

  proc postDetailDom(): DomElement =
    let container = createElement("article")
    container.setAttribute("class", "post-full")
    discard createEffect(proc() =
      clearChildren(container)
      let p = currentPost()
      if p.id == 0:
        container.appendChild(createTextNode("Loading..."))
        return
      let title = createElement("h1")
      title.textContent = p.title.cstring
      let date = createElement("p")
      date.setAttribute("class", "date")
      date.textContent = p.date.cstring
      let content = createElement("div")
      content.setAttribute("class", "content")
      content.textContent = p.content.cstring
      let back = createElement("a")
      back.setAttribute("href", "#/")
      back.setAttribute("class", "back-link")
      back.textContent = "← Back to posts".cstring
      container.appendChild(title)
      container.appendChild(date)
      container.appendChild(content)
      container.appendChild(back)
    )
    return container

  proc app(): seq[DomElement] =
    let appDiv = createElement("div")
    appDiv.setAttribute("class", "app")

    # Header
    let header = createElement("header")
    header.setAttribute("class", "site-header")
    let logo = createElement("a")
    logo.setAttribute("href", "#/")
    logo.setAttribute("class", "logo")
    logo.textContent = "NimLeptos Blog"
    header.appendChild(logo)
    let nav = createElement("nav")
    let homeLink = createElement("a")
    homeLink.setAttribute("href", "#/")
    homeLink.textContent = "Home"
    nav.appendChild(homeLink)
    header.appendChild(nav)
    appDiv.appendChild(header)

    # Main content
    let mainContent = createElement("div")
    mainContent.setAttribute("class", "main-content")
    discard createEffect(proc() =
      let r = hashRoute()()
      echo "mainContent effect, route=" & r
      clearChildren(mainContent)
      if r == "/":
        echo "  showing postList"
        mainContent.appendChild(postListDom())
      elif r.startsWith("/post/"):
        echo "  showing postDetail"
        mainContent.appendChild(postDetailDom())
      else:
        echo "  showing 404"
        let notFound = createElement("div")
        notFound.setAttribute("class", "not-found")
        notFound.textContent = "404 — Page not found"
        mainContent.appendChild(notFound)
    )
    appDiv.appendChild(mainContent)

    # Footer
    let footer = createElement("footer")
    footer.setAttribute("class", "site-footer")
    footer.textContent = "Built with NimLeptos + NimMax"
    appDiv.appendChild(footer)

    return @[appDiv]

  mountReactiveApp("#app", app)
  echo "window.hash=" & $window.location.hash
  initHashRouter()
  echo "after init, route=" & hashRoute()()
  loadPosts()

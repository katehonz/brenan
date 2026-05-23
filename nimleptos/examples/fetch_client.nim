## HTTP Client + Resource Demo — Fetch JSON from API
## Compile: nim js -p:src -o:examples/fetch_client.js examples/fetch_client.nim

import nimleptos
import nimleptos/client/reactive_dom
import nimleptos/client/dom_interop
import nimleptos/client/http_client
import nimleptos/reactive/signal
import nimleptos/reactive/resource
import std/dom
import std/json

when defined(js):
  # Simulated fetcher for demo (in real app, use a real endpoint)
  var demoPosts: seq[JsonNode] = @[]
  demoPosts.add(%*{ "id": 1, "title": "Hello NimLeptos", "body": "Reactive web framework for Nim." })
  demoPosts.add(%*{ "id": 2, "title": "Signals are great", "body": "Fine-grained reactivity without VDOM." })
  demoPosts.add(%*{ "id": 3, "title": "Client-side rendering", "body": "Compile to JS and mount to DOM." })

  proc fetchPosts(): seq[JsonNode] =
    # In a real app, this would be an async fetch.
    # For demo purposes we return mock data after a small delay simulation.
    return demoPosts

  let postsRes = createResource(fetchPosts)

  proc fetchApp(): seq[DomElement] =
    let heading = createElement("h1")
    heading.textContent = "Fetch + Resource Demo"

    let statusEl = createElement("p")
    statusEl.setAttribute("class", "fetch-status")
    let statusText = reactiveTextNode(proc(): string =
      if postsRes.loading(): "Loading..."
      elif postsRes.error().len > 0: "Error: " & postsRes.error()
      else: "Loaded " & $postsRes.value().len & " posts"
    )
    statusEl.appendChild(statusText)

    let list = createElement("ul")
    list.setAttribute("class", "post-list")

    discard createEffect(proc() =
      let posts = postsRes.value()
      clearChildren(list)
      for post in posts:
        let li = createElement("li")
        li.setAttribute("class", "post-item")
        let title = createElement("strong")
        title.textContent = post["title"].getStr()
        let body = createElement("p")
        body.textContent = post["body"].getStr()
        li.appendChild(title)
        li.appendChild(body)
        list.appendChild(li)
    )

    let btn = createElement("button")
    btn.textContent = "Refetch"
    btn.setAttribute("class", "btn")
    btn.addEventListener("click", proc(e: Event) =
      postsRes.refetch()
    )

    return @[heading, statusEl, list, btn]

  mountReactiveApp("#app", fetchApp)

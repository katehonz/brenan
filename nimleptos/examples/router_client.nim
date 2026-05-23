## Client-Side Router Demo — Hash-based SPA
## Compile: nim js -p:src -o:examples/router_client.js examples/router_client.nim

import nimleptos
import nimleptos/client/router
import nimleptos/client/reactive_dom
import nimleptos/client/dom_interop
import std/dom

when defined(js):
  proc homePage(): seq[DomElement] =
    let heading = createElement("h1")
    heading.textContent = "Home"
    let desc = createElement("p")
    desc.textContent = "Welcome to the NimLeptos router demo."
    return @[heading, desc]

  proc aboutPage(): seq[DomElement] =
    let heading = createElement("h1")
    heading.textContent = "About"
    let desc = createElement("p")
    desc.textContent = "This demo shows hash-based client-side routing."
    return @[heading, desc]

  proc contactPage(): seq[DomElement] =
    let heading = createElement("h1")
    heading.textContent = "Contact"
    let desc = createElement("p")
    desc.textContent = "Reach us at hello@nimleptos.dev"
    return @[heading, desc]

  proc notFoundPage(): seq[DomElement] =
    let heading = createElement("h1")
    heading.textContent = "404"
    let desc = createElement("p")
    desc.textContent = "Page not found."
    return @[heading, desc]

  proc navLink(label: string, path: string): DomElement =
    let a = createElement("a")
    a.setAttribute("href", "#" & path)
    a.setAttribute("class", "nav-link")
    a.textContent = label
    return a

  proc routerApp(): seq[DomElement] =
    let nav = createElement("nav")
    nav.setAttribute("class", "router-nav")
    nav.appendChild(navLink("Home", "/"))
    nav.appendChild(navLink("About", "/about"))
    nav.appendChild(navLink("Contact", "/contact"))

    let content = createElement("div")
    content.setAttribute("class", "router-content")
    content.setAttribute("id", "router-content")

    let routeText = reactiveTextNode(proc(): string =
      "Current route: " & currentRoute()()
    )
    let routeDisplay = createElement("p")
    routeDisplay.setAttribute("class", "route-display")
    routeDisplay.appendChild(routeText)

    # Render page based on route
    discard createEffect(proc() =
      let route = currentRoute()()
      clearChildren(content)
      let page =
        if route == "/" or route == "": homePage()
        elif route == "/about": aboutPage()
        elif route == "/contact": contactPage()
        else: notFoundPage()
      for el in page:
        content.appendChild(el)
    )

    return @[nav, routeDisplay, content]

  initHashRouter()
  mountReactiveApp("#app", routerApp)

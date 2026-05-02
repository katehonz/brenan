## Hash-based client-side router for NimLeptos

import ../reactive/signal
export signal

when defined(js):
  import std/dom
  import std/strutils

  let (currentHashRoute, setCurrentHashRoute) = createSignal("/")

  proc getHashRoute*(): string =
    ## Get current route from window.location.hash
    let hash = $window.location.hash
    if hash.len > 0 and hash[0] == '#':
      result = hash[1..^1]
    else:
      result = "/"

  proc navigate*(path: string) =
    ## Navigate to a new route by setting window.location.hash
    window.location.hash = path.cstring

  proc initHashRouter*() =
    ## Initialize hash router. Call once on app startup.
    ## Sets up hashchange listener and initial route signal.
    setCurrentHashRoute(getHashRoute())
    window.addEventListener("hashchange", proc(e: Event) =
      setCurrentHashRoute(getHashRoute())
    )

  proc hashRoute*(): Getter[string] =
    ## Returns the current route getter (for use in effects/buildHtml)
    currentHashRoute

  proc routeParam*(route: string, prefix: string): string =
    ## Extract parameter after prefix, e.g. routeParam("/post/5", "/post/") == "5"
    if route.startsWith(prefix):
      result = route[prefix.len..^1]
    else:
      result = ""

else:
  proc getHashRoute*(): string = "/"
  proc navigate*(path: string) = discard
  proc initHashRouter*() = discard
  proc hashRoute*(): Getter[string] =
    let (sig, _) = createSignal("/")
    sig
  proc routeParam*(route: string, prefix: string): string = ""

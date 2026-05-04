## Client-side router for NimLeptos
## Supports both hash-based and History API modes.

import ../reactive/signal
export signal

when defined(js):
  import std/dom
  import std/strutils

  type
    RouterMode* = enum
      rmHash     ## Hash-based routing (#/path)
      rmHistory  ## History API routing (/path)

  let (currentRouteSignal, setCurrentRouteSignal) = createSignal("/")
  var routerMode = rmHash

  proc getPathFromUrl*(): string =
    ## Extract path from current URL (works for both hash and history modes).
    if routerMode == rmHash:
      let hash = $window.location.hash
      if hash.len > 0 and hash[0] == '#':
        return hash[1..^1]
      return "/"
    else:
      return $window.location.pathname

  proc getHashRoute*(): string =
    ## Get current route from window.location.hash
    let hash = $window.location.hash
    if hash.len > 0 and hash[0] == '#':
      result = hash[1..^1]
    else:
      result = "/"

  proc navigate*(path: string) =
    ## Navigate via hash change (legacy).
    window.location.hash = path.cstring

  proc navigateTo*(path: string) =
    ## Navigate using History API pushState.
    ## Updates the route signal directly and provides a new history entry.
    let url = cstring(path)
    {.emit: "window.history.pushState({}, '', `url`);".}
    setCurrentRouteSignal(path)

  proc navigateReplace*(path: string) =
    ## Replace current history entry (no new entry).
    let url = cstring(path)
    {.emit: "window.history.replaceState({}, '', `url`);".}
    setCurrentRouteSignal(path)

  proc initHashRouter*() =
    ## Initialize hash router. Call once on app startup.
    routerMode = rmHash
    setCurrentRouteSignal(getHashRoute())
    window.addEventListener("hashchange", proc(e: Event) =
      setCurrentRouteSignal(getHashRoute())
    )

  proc initHistoryRouter*() =
    ## Initialize History API router. Call once on app startup.
    ## Uses pushState/popstate for navigation.
    routerMode = rmHistory
    setCurrentRouteSignal(getPathFromUrl())
    window.addEventListener("popstate", proc(e: Event) =
      setCurrentRouteSignal(getPathFromUrl())
    )

  proc initRouter*(mode: RouterMode = rmHash) =
    ## Initialize router with given mode.
    if mode == rmHistory:
      initHistoryRouter()
    else:
      initHashRouter()

  proc currentRoute*(): Getter[string] =
    ## Returns the current route getter (for use in effects/buildHtml).
    ## Works with both hash and history modes.
    currentRouteSignal

  proc hashRoute*(): Getter[string] =
    ## Returns the current hash route getter (legacy).
    currentRouteSignal

  proc routeParam*(route: string, prefix: string): string =
    ## Extract parameter after prefix, e.g. routeParam("/post/5", "/post/") == "5"
    if route.startsWith(prefix):
      result = route[prefix.len..^1]
    else:
      result = ""

else:
  type
    RouterMode* = enum
      rmHash, rmHistory

  proc getPathFromUrl*(): string = "/"
  proc getHashRoute*(): string = "/"
  proc navigate*(path: string) = discard
  proc navigateTo*(path: string) = discard
  proc navigateReplace*(path: string) = discard
  proc initHashRouter*() = discard
  proc initHistoryRouter*() = discard
  proc initRouter*(mode: RouterMode = rmHash) = discard
  proc currentRoute*(): Getter[string] =
    let (sig, _) = createSignal("/")
    sig
  proc hashRoute*(): Getter[string] =
    let (sig, _) = createSignal("/")
    sig
  proc routeParam*(route: string, prefix: string): string = ""

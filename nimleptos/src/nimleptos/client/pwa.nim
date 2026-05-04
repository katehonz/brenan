## PWA / Service Worker support for NimLeptos
## Provides manifest.json generation, service worker registration, and offline support.

when defined(js):
  import std/dom

  proc registerServiceWorker*(swPath: string = "/sw.js") =
    ## Register a service worker for offline support and caching.
    ## The service worker file must be served by the server.
    ##
    ## Usage:
    ##   registerServiceWorker("/sw.js")
    if navigator.serviceWorker.getNil() == nil:
      {.emit: "console.warn('Service Worker not supported');".}
      return
    {.emit: ["navigator.serviceWorker.register('", swPath, "').then(function(reg) {",
      "  console.log('SW registered:', reg.scope);",
      "}).catch(function(err) {",
      "  console.error('SW registration failed:', err);",
      "]);"].}

  proc unregisterServiceWorkers*() =
    ## Unregister all service workers.
    if navigator.serviceWorker.getNil() == nil:
      return
    {.emit: """
      navigator.serviceWorker.getRegistrations().then(function(registrations) {
        for (let reg of registrations) {
          reg.unregister();
        }
      });
    """.}
else:
  proc registerServiceWorker*(swPath: string = "/sw.js") = discard
  proc unregisterServiceWorkers*() = discard
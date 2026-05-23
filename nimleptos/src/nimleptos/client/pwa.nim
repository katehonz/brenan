## PWA / Service Worker support for NimLeptos
## Provides manifest.json generation, service worker registration, and offline support.

when defined(js):
  proc registerServiceWorker*(swPath: string = "/sw.js") =
    ## Register a service worker for offline support and caching.
    ## The service worker file must be served by the server.
    ##
    ## Usage:
    ##   registerServiceWorker("/sw.js")
    {.emit: ["if ('serviceWorker' in navigator) {",
      "  navigator.serviceWorker.register('", swPath, "').then(function(reg) {",
      "    console.log('SW registered:', reg.scope);",
      "  }).catch(function(err) {",
      "    console.error('SW registration failed:', err);",
      "  });",
      "} else {",
      "  console.warn('Service Worker not supported');",
      "}"].}

  proc unregisterServiceWorkers*() =
    ## Unregister all service workers.
    {.emit: """
      if ('serviceWorker' in navigator) {
        navigator.serviceWorker.getRegistrations().then(function(registrations) {
          for (let reg of registrations) {
            reg.unregister();
          }
        });
      }
    """.}
else:
  proc registerServiceWorker*(swPath: string = "/sw.js") = discard
  proc unregisterServiceWorkers*() = discard

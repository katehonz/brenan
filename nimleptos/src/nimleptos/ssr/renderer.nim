import ../dom/node
import std/strformat
import std/tables
import std/json

export node

type
  HydrationMarker* = ref object
    id*: int
    signalIds*: seq[string]

  SSRContext* = ref object
    nextId*: int
    markers*: seq[HydrationMarker]
    head*: string
    scripts*: seq[string]
    styles*: seq[string]
    initialState*: Table[string, string]

proc newSSRContext*(): SSRContext =
  SSRContext(nextId: 0, markers: @[], head: "", scripts: @[], styles: @[],
             initialState: initTable[string, string]())

proc addInitialState*(ctx: SSRContext, key: string, value: string) =
  ctx.initialState[key] = value

proc nextMarkerId*(ctx: SSRContext): int =
  result = ctx.nextId
  inc ctx.nextId

proc addMarker*(ctx: SSRContext, marker: HydrationMarker) =
  ctx.markers.add(marker)

proc addScript*(ctx: SSRContext, script: string) =
  ctx.scripts.add(script)

proc addStyle*(ctx: SSRContext, style: string) =
  ctx.styles.add(style)

proc renderHead*(ctx: SSRContext, title: string = ""): string =
  result = "<head>"
  if title.len > 0:
    result &= &"<title>{escapeHtml(title)}</title>"
  result &= ctx.head
  for style in ctx.styles:
    result &= &"<style>{style}</style>"
  result &= "</head>"

proc renderHydrationData*(ctx: SSRContext): string =
  result = "<script type=\"application/json\" id=\"__nimleptos_data__\">"
  var data = newJObject()
  data["nextId"] = %ctx.nextId
  if ctx.initialState.len > 0:
    var stateObj = newJObject()
    for key, value in ctx.initialState:
      stateObj[key] = %value
    data["initialState"] = stateObj
  result &= $data
  result &= "</script>"
  for script in ctx.scripts:
    result &= &"<script src=\"{script}\"></script>"

proc renderFullPage*(ctx: SSRContext, body: HtmlNode, title: string = "NimLeptos App"): string =
  result = "<!DOCTYPE html>"
  result &= "<html>"
  result &= renderHead(ctx, title)
  result &= "<body>"
  result &= renderToHtml(body)
  result &= renderHydrationData(ctx)
  result &= "</body>"
  result &= "</html>"

proc renderFullPage*(ctx: SSRContext, bodyHtml: string, title: string = "NimLeptos App"): string =
  result = "<!DOCTYPE html>"
  result &= "<html>"
  result &= "<head>"
  result &= &"<title>{escapeHtml(title)}</title>"
  result &= ctx.head
  for style in ctx.styles:
    result &= &"<style>{style}</style>"
  result &= "</head>"
  result &= "<body>"
  result &= bodyHtml
  result &= renderHydrationData(ctx)
  result &= "</body>"
  result &= "</html>"

# ========== PWA / Service Worker Helpers ==========

proc generatePwaManifest*(name: string, shortName: string = "",
    description: string = "", startUrl: string = "/", display: string = "standalone",
    backgroundColor: string = "#ffffff", themeColor: string = "#000000",
    iconPath: string = "/icon.png"): string =
  ## Generate a PWA manifest.json file content.
  ## Serve at `/manifest.json` for PWA installability.
  result = "{"
  result &= &"\"name\": \"{name}\""
  if shortName.len > 0:
    result &= &", \"short_name\": \"{shortName}\""
  else:
    result &= &", \"short_name\": \"{name}\""
  result &= &", \"start_url\": \"{startUrl}\""
  result &= &", \"display\": \"{display}\""
  result &= &", \"background_color\": \"{backgroundColor}\""
  result &= &", \"theme_color\": \"{themeColor}\""
  if description.len > 0:
    result &= &", \"description\": \"{description}\""
  result &= &", \"icons\": [{{\"src\": \"{iconPath}\", \"sizes\": \"192x192\", \"type\": \"image/png\"}}]"
  result &= "}"

proc generateServiceWorkerJs*(cacheName: string = "nimleptos-v1",
    urlsToCache: seq[string] = @["/"]): string =
  ## Generate a basic service worker JS file content for offline caching.
  ## Serve at `/sw.js`.
  result = "const CACHE_NAME = '" & cacheName & "';\n"
  result &= "const urlsToCache = [\n"
  for i, url in urlsToCache:
    if i > 0: result &= ",\n"
    result &= "  '" & url & "'"
  result &= "\n];\n"
  result &= """
self.addEventListener('install', function(event) {
  event.waitUntil(
    caches.open(CACHE_NAME).then(function(cache) {
      return cache.addAll(urlsToCache);
    })
  );
});

self.addEventListener('fetch', function(event) {
  event.respondWith(
    caches.match(event.request).then(function(response) {
      return response || fetch(event.request);
    })
  );
});

self.addEventListener('activate', function(event) {
  event.waitUntil(
    caches.keys().then(function(keys) {
      return Promise.all(
        keys.filter(function(key) { return key !== CACHE_NAME; })
            .map(function(key) { return caches.delete(key); })
      );
    })
  );
});
"""

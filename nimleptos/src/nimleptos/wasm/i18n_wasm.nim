## NimLeptos WASM i18n Bridge — Nimbling Edition
## ==============================================
## Exports i18n functionality via wasmBindgen for use in WASM apps.
##
## The JS side is responsible for:
##   1. Creating an empty catalog via initI18n()
##   2. Populating it with addTranslation() calls (one per message)
##   3. Calling setLocale() when the user switches languages
##   4. Updating DOM text nodes after locale changes (either by polling
##      getLocale() or using the registerOnLocaleChange callback)
##
## Build:
##   nim c --cc:clang --cpu:wasm32 --os:standalone --mm:orc -d:wasm32 \
##     -p:src --compileOnly --nimcache:examples/nimbling_i18n/nimcache \
##     examples/nimbling_i18n/i18n.nim
##   nimbling i18n.wasm --out-dir pkg/ --target bundler

import nimbling
import std/tables
import std/strutils
import ../i18n/catalog
import ../i18n/interpolate
import ../i18n/i18n

# ─── Global i18n state (kept in WASM memory) ───

var i18nConfig: I18nConfig
var localeChangeCallbacks: seq[Closure[void]]

# ─── Internal helpers ───

proc invokeJsClosure(callback: Closure[void]) =
  ## Invoke a JS closure from WASM via the nimbling heap.
  ## Uses {.emit.} to access the JS heap directly.
  when defined(wasm32):
    {.emit: """
    var fn = heap[`callback`.idx];
    if (typeof fn === 'function') {
      fn();
    }
    """.}
  else:
    discard

proc notifyLocaleChanged() =
  for cb in localeChangeCallbacks:
    invokeJsClosure(cb)

# ─── Exported API ───

proc initI18n*(defaultLocale: string, fallbackLocale: string) {.wasmBindgen.} =
  ## Initialize an empty i18n catalog with the given default and fallback
  ## locales. Call addTranslation() repeatedly to populate messages.
  var catalog = emptyCatalog()
  catalog.defaultLocale = defaultLocale
  catalog.fallbackLocale = fallbackLocale
  i18nConfig = createI18n(catalog, defaultLocale)
  localeChangeCallbacks = @[]

proc addTranslation*(locale: string, key: string, message: string) {.wasmBindgen.} =
  ## Add a single translation message to the catalog.
  if i18nConfig == nil:
    return
  i18nConfig.catalog.addTranslation(locale, key, message)

proc setLocale*(locale: string) {.wasmBindgen.} =
  ## Change the current locale and notify all registered JS callbacks.
  if i18nConfig == nil:
    return
  i18nConfig.localeSetter(locale)
  notifyLocaleChanged()

proc getLocale*(): string {.wasmBindgen.} =
  ## Return the current locale string (e.g. "en", "bg").
  if i18nConfig == nil:
    return ""
  return i18nConfig.localeGetter()

proc translate*(key: string): string {.wasmBindgen.} =
  ## Non-reactive single-shot translation for the current locale.
  ## Returns the key itself if no translation is found.
  if i18nConfig == nil:
    return key
  return i18nConfig.catalog.getMessage(i18nConfig.localeGetter(), key)

proc translateWithParams*(key: string, paramsJson: string): string {.wasmBindgen.} =
  ## Translation with interpolation parameters passed as a simple
  ## pipe-delimited string.
  ##
  ## paramsJson format: "name|World|count|42"
  ##   - keys and values alternate, separated by '|'
  ##   - integer values are auto-detected (all digits)
  ##   - float values are auto-detected (contains '.')
  if i18nConfig == nil:
    return key
  let locale = i18nConfig.localeGetter()
  let msg = i18nConfig.catalog.getMessage(locale, key)

  var params: InterpParams
  if paramsJson.len > 0:
    let parts = paramsJson.split('|')
    var i = 0
    while i + 1 < parts.len:
      let k = parts[i]
      let v = parts[i + 1]
      if v.contains('.'):
        try:
          params[k] = floatv(parseFloat(v))
        except:
          params[k] = str(v)
      elif v.allCharsInSet(Digits):
        try:
          params[k] = intv(parseInt(v))
        except:
          params[k] = str(v)
      else:
        params[k] = str(v)
      i += 2

  return interpolate(msg, params)

proc getAvailableLocales*(): string {.wasmBindgen.} =
  ## Return available locales as a pipe-separated string: "en|bg|fr"
  if i18nConfig == nil:
    return ""
  let locales = i18nConfig.catalog.localeNames()
  return locales.join("|")

proc getDefaultLocale*(): string {.wasmBindgen.} =
  ## Return the default locale configured in the catalog.
  if i18nConfig == nil:
    return "en"
  return i18nConfig.catalog.defaultLocale

proc getFallbackLocale*(): string {.wasmBindgen.} =
  ## Return the fallback locale configured in the catalog.
  if i18nConfig == nil:
    return "en"
  return i18nConfig.catalog.fallbackLocale

proc registerOnLocaleChange*(callback: Closure[void]) {.wasmBindgen.} =
  ## Register a JS callback that gets called whenever the locale changes.
  ## The callback receives no arguments; call getLocale() from JS to read
  ## the new locale.
  localeChangeCallbacks.add(callback)

proc unregisterOnLocaleChange*(callback: Closure[void]) {.wasmBindgen.} =
  ## Remove a previously registered locale change callback.
  var newCallbacks: seq[Closure[void]] = @[]
  for cb in localeChangeCallbacks:
    if cb.idx != callback.idx:
      newCallbacks.add(cb)
  localeChangeCallbacks = newCallbacks

# ─── Finalize nimbling bindings ───
wasmBindgenFinalize()

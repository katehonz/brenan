import nimmax
import std/strutils
import std/json

type
  LocaleDetectionConfig* = ref object
    defaultLocale*: string
    supportedLocales*: seq[string]
    detectFromUrl*: bool
    detectFromCookie*: bool
    detectFromHeader*: bool

proc newLocaleDetection*(defaultLocale: string = "en",
    supportedLocales: seq[string] = @["en", "bg", "ru", "fr", "es", "de", "it", "ar"]): LocaleDetectionConfig =
  LocaleDetectionConfig(
    defaultLocale: defaultLocale,
    supportedLocales: supportedLocales,
    detectFromUrl: true,
    detectFromCookie: true,
    detectFromHeader: true,
  )

proc extractLocaleFromUrl(path: string, supported: seq[string]): string =
  let parts = path.split('/')
  if parts.len > 0 and parts[0].len in {2, 3, 5}:
    let candidate = parts[0].toLowerAscii()
    if candidate in supported:
      return candidate
  return ""

proc extractLocaleFromAccept(header: string, supported: seq[string]): string =
  if header.len == 0:
    return ""
  for part in header.split(','):
    let lang = part.split(';')[0].strip().toLowerAscii()
    let short = if lang.contains('-'): lang[0..lang.find('-')-1] else: lang
    if short in supported:
      return short
    if short.len == 2 and lang in supported:
      return lang
  return ""

proc localeMiddleware*(config: LocaleDetectionConfig): HandlerAsync =
  result = proc(ctx: Context): Future[void] {.async, gcsafe.} =
    var detectedLocale = ""

    if config.detectFromUrl:
      let path = ctx.request.url.path
      let fromUrl = extractLocaleFromUrl(path, config.supportedLocales)
      if fromUrl.len > 0:
        detectedLocale = fromUrl

    if detectedLocale.len == 0 and config.detectFromCookie:
      let rawCookies = ctx.request.headers.getHeader("Cookie")
      if rawCookies.len > 0:
        for cookie in rawCookies.split(';'):
          let parts = cookie.strip().split('=')
          if parts.len == 2 and parts[0].strip() == "locale":
            let cookieLocale = parts[1].strip().toLowerAscii()
            if cookieLocale in config.supportedLocales:
              detectedLocale = cookieLocale

    if detectedLocale.len == 0 and config.detectFromHeader:
      let acceptLang = ctx.request.headers.getHeader("Accept-Language")
      if acceptLang.len > 0:
        let fromHeader = extractLocaleFromAccept(acceptLang, config.supportedLocales)
        if fromHeader.len > 0:
          detectedLocale = fromHeader

    if detectedLocale.len == 0:
      detectedLocale = config.defaultLocale

    ctx["locale"] = %detectedLocale
    await switch(ctx)

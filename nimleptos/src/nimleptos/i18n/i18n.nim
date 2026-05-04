import catalog
import interpolate
import ../reactive/signal

type
  I18nConfig* = ref object
    catalog*: MessageCatalog
    localeGetter*: Getter[string]
    localeSetter*: Setter[string]
    fallback*: string

  TranslationFn* = ref object
    key*: string
    config*: I18nConfig
    paramsFn*: proc(): InterpParams {.closure.}

proc locale*(cfg: I18nConfig): string =
  cfg.localeGetter()

proc `locale=`*(cfg: I18nConfig, value: string) =
  cfg.localeSetter(value)

proc `$`*(fn: TranslationFn): string =
  let locale = fn.config.localeGetter()
  let msg = fn.config.catalog.getMessage(locale, fn.key)
  if fn.paramsFn != nil:
    return interpolate(msg, fn.paramsFn())
  return msg

proc useLocale*(cfg: I18nConfig): Getter[string] =
  cfg.localeGetter

proc setLocale*(cfg: I18nConfig, locale: string) =
  cfg.localeSetter(locale)

proc createI18n*(catalog: MessageCatalog, initialLocale: string = ""): I18nConfig =
  let locale = if initialLocale.len > 0: initialLocale else: catalog.defaultLocale
  let (getLocale, setLocale) = createSignal(locale)
  result = I18nConfig(catalog: catalog, localeGetter: getLocale, localeSetter: setLocale, fallback: catalog.fallbackLocale)

proc createI18n*(catalog: MessageCatalog, getLocale: Getter[string], setLocale: Setter[string]): I18nConfig =
  ## Create I18nConfig with an existing signal pair. Use when you already have
  ## a locale signal managed elsewhere (e.g., from a Context/Store).
  result = I18nConfig(catalog: catalog, localeGetter: getLocale, localeSetter: setLocale, fallback: catalog.fallbackLocale)

proc t*(cfg: I18nConfig, key: string): proc(): string {.closure.} =
  ## Returns a reactive translation getter. When locale changes, the value
  ## updates automatically in reactive contexts (createEffect, reactiveTextNode).
  ##
  ## Usage:
  ##   let hello = cfg.t("hello")
  ##   echo hello()  # "Hello" in English, "Здравей" in Bulgarian
  result = proc(): string {.closure.} =
    let locale = cfg.localeGetter()
    return cfg.catalog.getMessage(locale, key)

proc tp*(cfg: I18nConfig, key: string, paramsFn: proc(): InterpParams {.closure.}): proc(): string {.closure.} =
  ## Reactive translation with interpolation parameters.
  ##
  ## Usage:
  ##   let (count, _) = createSignal(5)
  ##   let items = cfg.tp("items_count", proc(): InterpParams =
  ##     {"count": interp.intv(count())}.toTable
  ##   )
  result = proc(): string {.closure.} =
    let locale = cfg.localeGetter()
    let msg = cfg.catalog.getMessage(locale, key)
    return interpolate(msg, paramsFn())

proc translate*(cfg: I18nConfig, key: string): string =
  ## Non-reactive single-shot translation (for SSR).
  let locale = cfg.localeGetter()
  return cfg.catalog.getMessage(locale, key)

proc translate*(cfg: I18nConfig, key: string, params: InterpParams): string =
  let locale = cfg.localeGetter()
  let msg = cfg.catalog.getMessage(locale, key)
  return interpolate(msg, params)

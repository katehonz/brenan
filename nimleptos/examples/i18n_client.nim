## i18n Client-Side Demo — Language switcher + reactive pluralization
## Compile: nim js -p:src -o:examples/i18n_client.js examples/i18n_client.nim

import nimleptos/client/reactive_dom
import nimleptos/client/dom_interop
import nimleptos/client/event_handlers
import nimleptos/macros/html_macros
import nimleptos/reactive/signal
import nimleptos/reactive/effects
import nimleptos/i18n/catalog
import nimleptos/i18n/i18n
import nimleptos/i18n/plural
import nimleptos/i18n/interpolate
import std/dom
import std/tables
import std/strutils

when defined(js):
  # Inline catalog for client-side (synced with locales/app.json)
  let cat = newMessageCatalog("en", "en")
  cat.addTranslation("en", "hello", "Hello")
  cat.addTranslation("en", "greeting", "Hello, {name}!")
  cat.addTranslation("en", "language", "Language")
  cat.addTranslation("en", "home", "Home")
  cat.addTranslation("en", "about", "About")
  cat.addTranslation("en", "items_count", "one#1 item|other#{count} items")
  cat.addTranslation("en", "click_me", "Click me")
  cat.addTranslation("en", "current_locale", "Current locale: {locale}")
  cat.addTranslation("bg", "hello", "Здравей")
  cat.addTranslation("bg", "greeting", "Здравей, {name}!")
  cat.addTranslation("bg", "language", "Език")
  cat.addTranslation("bg", "home", "Начало")
  cat.addTranslation("bg", "about", "За нас")
  cat.addTranslation("bg", "items_count", "one#1 артикул|other#{count} артикула")
  cat.addTranslation("bg", "click_me", "Кликни")
  cat.addTranslation("bg", "current_locale", "Текущ език: {locale}")
  cat.addTranslation("fr", "hello", "Bonjour")
  cat.addTranslation("fr", "greeting", "Bonjour {name}!")
  cat.addTranslation("fr", "language", "Langue")
  cat.addTranslation("fr", "home", "Accueil")
  cat.addTranslation("fr", "about", "À propos")
  cat.addTranslation("fr", "items_count", "one#1 article|other#{count} articles")
  cat.addTranslation("fr", "click_me", "Cliquez-moi")
  cat.addTranslation("fr", "current_locale", "Langue actuelle: {locale}")

  let cfg = createI18n(cat, "en")
  let (count, setCount) = createSignal(1)

  proc pluralText(cfg: I18nConfig, key: string, count: int): string =
    let locale = cfg.locale
    let raw = cfg.catalog.getMessage(locale, key)
    let parts = parsePluralMessage(raw)
    let cat = resolvePlural(locale, float(count))
    let templateStr = if cat in parts: parts[cat] else: parts.getOrDefault(pcOther, raw)
    return templateStr.replace("{count}", $count)

  proc i18nApp(): HtmlNode =
    result = buildHtml(cfg):
      el("div", class="client-app"):
        el("div", class="locale-info"):
          el("p"): tp(cfg, "current_locale", proc(): InterpParams =
            result = initTable[string, InterpValue]()
            result["locale"] = str(cfg.locale)
          )
        el("div", class="lang-switcher"):
          el("button", class="btn btn-lang", onclick=proc(e: Event) = setLocale(cfg, "en")):
            text("English")
          el("button", class="btn btn-lang", onclick=proc(e: Event) = setLocale(cfg, "bg")):
            text("Български")
          el("button", class="btn btn-lang", onclick=proc(e: Event) = setLocale(cfg, "fr")):
            text("Français")
        el("h2"): t"hello"
        el("p", class="greeting-text"): tp(cfg, "greeting", proc(): InterpParams =
          result = initTable[string, InterpValue]()
          result["name"] = str("NimLeptos")
        )
        el("div", class="plural-demo"):
          el("p", class="demo-title"): t"click_me"
          el("div", class="counter-controls"):
            el("button", class="btn btn-dec", onclick=proc(e: Event) = setCount(count() - 1)):
              text("-")
            el("span", class="count-display"): text($count())
            el("button", class="btn btn-inc", onclick=proc(e: Event) = setCount(count() + 1)):
              text("+")
          el("p", class="plural-result", id="plural-text"):
            text("")

  proc afterMount(root: DomElement) =
    # Bind plural text reactively
    let pluralEl = querySelector(root, "#plural-text")
    if pluralEl != nil:
      discard createEffect(proc() =
        let txt = pluralText(cfg, "items_count", count())
        setTextContent(pluralEl, txt)
      )

  mountApp("#client-app", i18nApp, afterMount)

import std/tables
import ../src/nimleptos/i18n/catalog
import ../src/nimleptos/i18n/i18n
import ../src/nimleptos/i18n/plural
import ../src/nimleptos/i18n/interpolate
import ../src/nimleptos/reactive/signal
import ../src/nimleptos/reactive/effects

proc testCatalogAddTranslation() =
  let cat = newMessageCatalog("en", "en")
  cat.addTranslation("en", "hello", "Hello")
  cat.addTranslation("bg", "hello", "Здравей")

  doAssert cat.getMessage("en", "hello") == "Hello"
  doAssert cat.getMessage("bg", "hello") == "Здравей"
  echo "PASS: catalog add translation"

proc testCatalogMissingKey() =
  let cat = newMessageCatalog("en", "en")
  doAssert cat.getMessage("en", "missing") == "missing"
  echo "PASS: catalog missing key returns key"

proc testCatalogFallback() =
  let cat = newMessageCatalog("en", "en")
  cat.addTranslation("en", "hello", "Hello")
  doAssert cat.getMessage("bg", "hello") == "Hello"
  echo "PASS: catalog fallback locale"

proc testCatalogHasKey() =
  let cat = newMessageCatalog()
  cat.addTranslation("en", "hello", "Hello")
  doAssert cat.hasKey("en", "hello") == true
  doAssert cat.hasKey("en", "missing") == false
  doAssert cat.hasKey("bg", "hello") == false
  echo "PASS: catalog hasKey"

proc testCatalogLocaleNames() =
  let cat = newMessageCatalog()
  cat.addTranslation("en", "hello", "Hello")
  cat.addTranslation("bg", "hello", "Здравей")
  cat.addTranslation("fr", "hello", "Bonjour")
  let names = cat.localeNames()
  doAssert names.len == 3
  doAssert "en" in names
  doAssert "bg" in names
  doAssert "fr" in names
  echo "PASS: catalog locale names"

proc testMergeCatalogs() =
  let cat1 = newMessageCatalog("en", "en")
  cat1.addTranslation("en", "hello", "Hello")
  cat1.addTranslation("bg", "hello", "Здравей")

  let cat2 = newMessageCatalog("en", "en")
  cat2.addTranslation("fr", "hello", "Bonjour")
  cat2.addTranslation("en", "goodbye", "Goodbye")

  let merged = mergeCatalogs(cat1, cat2)
  doAssert merged.getMessage("en", "hello") == "Hello"
  doAssert merged.getMessage("bg", "hello") == "Здравей"
  doAssert merged.getMessage("fr", "hello") == "Bonjour"
  doAssert merged.getMessage("en", "goodbye") == "Goodbye"
  echo "PASS: merge catalogs"

proc testPluralEn() =
  doAssert resolvePlural("en", 1.0) == pcOne
  doAssert resolvePlural("en", 2.0) == pcOther
  doAssert resolvePlural("en", 0.0) == pcOther
  doAssert resolvePlural("en", 100.0) == pcOther
  echo "PASS: plural EN"

proc testPluralBg() =
  doAssert resolvePlural("bg", 1.0) == pcOne
  doAssert resolvePlural("bg", 2.0) == pcOther
  doAssert resolvePlural("bg", 5.0) == pcOther
  echo "PASS: plural BG"

proc testPluralRu() =
  doAssert resolvePlural("ru", 1.0) == pcOne
  doAssert resolvePlural("ru", 2.0) == pcFew
  doAssert resolvePlural("ru", 5.0) == pcMany
  doAssert resolvePlural("ru", 21.0) == pcOne
  doAssert resolvePlural("ru", 22.0) == pcFew
  echo "PASS: plural RU"

proc testPluralAr() =
  doAssert resolvePlural("ar", 0.0) == pcZero
  doAssert resolvePlural("ar", 1.0) == pcOne
  doAssert resolvePlural("ar", 2.0) == pcTwo
  doAssert resolvePlural("ar", 3.0) == pcFew
  doAssert resolvePlural("ar", 11.0) == pcMany
  echo "PASS: plural AR"

proc testParsePluralMessage() =
  let tbl = parsePluralMessage("one#1 item|other#5 items")
  doAssert tbl[pcOne] == "1 item"
  doAssert tbl[pcOther] == "5 items"
  echo "PASS: parse plural message"

proc testParsePluralMessageOtherOnly() =
  let tbl = parsePluralMessage("no items")
  doAssert tbl[pcOther] == "no items"
  echo "PASS: parse plural other only"

proc testInterpolation() =
  var params: InterpParams
  params["name"] = str("Alice")
  params["count"] = intv(42)
  params["price"] = floatv(9.99)
  let result = interpolate("Hello {name}, you have {count} items at ${price}", params)
  doAssert result == "Hello Alice, you have 42 items at $9.99"
  echo "PASS: interpolation"

proc testInterpolationMissing() =
  var params: InterpParams
  params["name"] = str("Bob")
  let result = interpolate("Hello {name}, age: {age}", params)
  doAssert result == "Hello Bob, age: {age}"
  echo "PASS: interpolation missing key"

proc testTranslationSignal() =
  let cat = newMessageCatalog("en", "en")
  cat.addTranslation("en", "hello", "Hello")
  cat.addTranslation("bg", "hello", "Здравей")
  cat.addTranslation("en", "greeting", "Hello {name}")
  cat.addTranslation("bg", "greeting", "Здравей, {name}")

  let (getLocale, setLocale) = createSignal("en")
  let i18n = createI18n(cat, getLocale, setLocale)

  let t = i18n.t("hello")
  doAssert t() == "Hello"

  setLocale("bg")
  doAssert t() == "Здравей"

  setLocale("en")
  doAssert t() == "Hello"
  echo "PASS: translation signal"

proc testTranslationWithParams() =
  let cat = newMessageCatalog("en", "en")
  cat.addTranslation("en", "greeting", "Hello {name}")

  let (getLocale, setLocale) = createSignal("en")
  let i18n = createI18n(cat, getLocale, setLocale)

  let (name, setName) = createSignal("Alice")
  let greeting = i18n.tp("greeting", proc(): InterpParams =
    {"name": str(name())}.toTable
  )

  doAssert greeting() == "Hello Alice"
  setName("Bob")
  doAssert greeting() == "Hello Bob"
  echo "PASS: translation with params"

proc testSetLocale() =
  let cat = newMessageCatalog("en", "en")
  let i18n = createI18n(cat, "en")

  doAssert i18n.locale == "en"
  i18n.setLocale("bg")
  doAssert i18n.locale == "bg"
  echo "PASS: setLocale"

proc testUseLocale() =
  let cat = newMessageCatalog("en", "en")
  let i18n = createI18n(cat, "fr")

  let getter = i18n.useLocale()
  doAssert getter() == "fr"
  echo "PASS: useLocale"

when isMainModule:
  testCatalogAddTranslation()
  testCatalogMissingKey()
  testCatalogFallback()
  testCatalogHasKey()
  testCatalogLocaleNames()
  testMergeCatalogs()
  testPluralEn()
  testPluralBg()
  testPluralRu()
  testPluralAr()
  testParsePluralMessage()
  testParsePluralMessageOtherOnly()
  testInterpolation()
  testInterpolationMissing()
  testTranslationSignal()
  testTranslationWithParams()
  testSetLocale()
  testUseLocale()
  echo ""
  echo "All i18n tests passed!"

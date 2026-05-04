import std/json
import std/tables
import std/os

type
  MessageKey* = string
  LocaleStr* = string
  MessageCatalog* = ref object
    messages*: Table[LocaleStr, Table[MessageKey, string]]
    defaultLocale*: LocaleStr
    fallbackLocale*: LocaleStr

proc emptyCatalog*(): MessageCatalog =
  MessageCatalog(messages: initTable[LocaleStr, Table[MessageKey, string]](),
    defaultLocale: "en", fallbackLocale: "en")

proc newMessageCatalog*(defaultLocale: LocaleStr = "en",
    fallbackLocale: LocaleStr = "en"): MessageCatalog =
  MessageCatalog(messages: initTable[LocaleStr, Table[MessageKey, string]](),
    defaultLocale: defaultLocale, fallbackLocale: fallbackLocale)

proc addTranslation*(cat: MessageCatalog, locale: LocaleStr,
    key: MessageKey, msg: string) =
  if locale notin cat.messages:
    cat.messages[locale] = initTable[MessageKey, string]()
  cat.messages[locale][key] = msg

proc addTranslations*(cat: MessageCatalog, locale: LocaleStr,
    msgs: openArray[(MessageKey, string)]) =
  if locale notin cat.messages:
    cat.messages[locale] = initTable[MessageKey, string]()
  for (key, msg) in msgs:
    cat.messages[locale][key] = msg

proc hasKey*(cat: MessageCatalog, locale: LocaleStr, key: MessageKey): bool =
  if locale in cat.messages:
    return cat.messages[locale].hasKey(key)
  return false

proc getMessage*(cat: MessageCatalog, locale: LocaleStr, key: MessageKey): string =
  if locale in cat.messages and cat.messages[locale].hasKey(key):
    return cat.messages[locale][key]
  let fb = cat.fallbackLocale
  if fb != locale and fb in cat.messages and cat.messages[fb].hasKey(key):
    return cat.messages[fb][key]
  return key

proc loadCatalog*(filePath: string): MessageCatalog =
  result = emptyCatalog()
  if not fileExists(filePath):
    return
  let jsonNode = parseFile(filePath)
  if jsonNode.kind != JObject:
    return
  result.defaultLocale = jsonNode{"defaultLocale"}.getStr("en")
  result.fallbackLocale = jsonNode{"fallbackLocale"}.getStr(result.defaultLocale)
  let messagesNode = jsonNode{"messages"}
  if messagesNode.kind != JObject:
    return
  for localeKey, localeMsgs in messagesNode.pairs():
    if localeMsgs.kind != JObject:
      continue
    var tbl = initTable[MessageKey, string]()
    for msgKey, msgVal in localeMsgs.pairs():
      tbl[$msgKey] = msgVal.getStr($msgKey)
    result.messages[localeKey] = tbl

proc mergeCatalogs*(a, b: MessageCatalog): MessageCatalog =
  result = emptyCatalog()
  result.defaultLocale = a.defaultLocale
  result.fallbackLocale = a.fallbackLocale
  for locale, tbl in a.messages:
    for k, v in tbl:
      result.addTranslation(locale, k, v)
  for locale, tbl in b.messages:
    for k, v in tbl:
      result.addTranslation(locale, k, v)

proc localeNames*(cat: MessageCatalog): seq[LocaleStr] =
  for locale, _ in cat.messages:
    result.add(locale)

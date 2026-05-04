import std/tables
import std/math
import std/strutils

type
  PluralCategory* = enum
    pcZero
    pcOne
    pcTwo
    pcFew
    pcMany
    pcOther

proc pluralCategoryName*(cat: PluralCategory): string =
  case cat
  of pcZero: "zero"
  of pcOne: "one"
  of pcTwo: "two"
  of pcFew: "few"
  of pcMany: "many"
  of pcOther: "other"

proc pluralCategoryFromName*(name: string): PluralCategory =
  case name.toLowerAscii()
  of "zero": pcZero
  of "one": pcOne
  of "two": pcTwo
  of "few": pcFew
  of "many": pcMany
  else: pcOther

proc enPluralRule*(n: float): PluralCategory =
  let i = int(n)
  if i == 1: pcOne
  else: pcOther

proc bgPluralRule*(n: float): PluralCategory =
  let i = int(n)
  if i == 1: pcOne
  else: pcOther

proc ruPluralRule*(n: float): PluralCategory =
  if n.isNaN: return pcOther
  let i = int(abs(n))
  let i10 = i mod 10
  let i100 = i mod 100
  if i10 == 1 and i100 != 11: pcOne
  elif i10 in {2, 3, 4} and i100 notin {12, 13, 14}: pcFew
  else: pcMany

proc arPluralRule*(n: float): PluralCategory =
  let i = int(n)
  if i == 0: pcZero
  elif i == 1: pcOne
  elif i == 2: pcTwo
  elif i mod 100 >= 3 and i mod 100 <= 10: pcFew
  elif i mod 100 >= 11: pcMany
  else: pcOther

proc frPluralRule*(n: float): PluralCategory =
  let i = int(n)
  if i == 0 or i == 1: pcOne
  else: pcOther

type PluralRuleProc* = proc(n: float): PluralCategory {.closure.}

const defaultPluralRules* = {
  "en": enPluralRule,
  "bg": bgPluralRule,
  "ru": ruPluralRule,
  "ar": arPluralRule,
  "fr": frPluralRule,
  "de": enPluralRule,
  "es": enPluralRule,
  "it": enPluralRule,
}.toTable

proc getPluralRule*(locale: string): PluralRuleProc =
  let short = locale[0..1].toLowerAscii()
  if short in defaultPluralRules:
    return defaultPluralRules[short]

proc resolvePlural*(locale: string, n: float): PluralCategory =
  let rule = getPluralRule(locale)
  return rule(n)

proc parsePluralMessage*(raw: string): Table[PluralCategory, string] =
  result = initTable[PluralCategory, string]()
  var parts: seq[string] = @[]
  var current = ""
  var i = 0
  while i < raw.len:
    if raw[i] == '|' and (i + 1 >= raw.len or raw[i + 1] != '|'):
      parts.add(current)
      current = ""
    elif raw[i] == '|' and i + 1 < raw.len and raw[i + 1] == '|':
      current.add('|')
      inc(i)
    else:
      current.add(raw[i])
    inc(i)
  if current.len > 0:
    parts.add(current)

  for part in parts:
    let hashPos = part.find('#')
    if hashPos >= 0:
      let catName = part[0..<hashPos].strip()
      let text = part[hashPos + 1..^1]
      if catName.len > 0:
        result[pluralCategoryFromName(catName)] = text
    else:
      result[pcOther] = part

  if pcOther notin result:
    result[pcOther] = raw

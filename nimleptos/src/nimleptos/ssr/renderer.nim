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

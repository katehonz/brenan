import nimmax
import nimmax/websocket
import ./ws_bridge
import std/asyncdispatch
import std/json

export ws_bridge

proc wsSignalHandler*(ws: WebSocket) {.async.} =
  await ws.performHandshake()
  while ws.readyState == Open:
    try:
      let msg = await ws.receiveStrPacket()
      handleSignalMessage(msg, ws)
    except:
      break

  for name, sig in globalRegistry.signals:
    var newSubs: seq[WebSocket] = @[]
    for s in sig.subscribers:
      if s != ws:
        newSubs.add(s)
    sig.subscribers = newSubs

proc wsSignalRoute*(): HandlerAsync =
  result = proc(ctx: Context): Future[void] {.async, gcsafe.} =
    let ws = await ctx.request.nativeRequest.newWebSocket()
    if ws.isNil:
      ctx.response.code = Http400
      ctx.response.body = "WebSocket upgrade failed"
      return
    await wsSignalHandler(ws)

proc signalUpdateEndpoint*(signalName: string): HandlerAsync =
  result = proc(ctx: Context): Future[void] {.async, gcsafe.} =
    if not globalRegistry.signals.hasKey(signalName):
      ctx.json(%*{"error": "Signal not found"}, Http404)
      return
    let sig = globalRegistry.signals[signalName]
    let body = ctx.request.body
    try:
      let data = parseJson(body)
      if data.hasKey("value"):
        sig.subscribers = @[]
    except:
      discard
    ctx.json(%*{"status": "ok", "signal": signalName})

proc signalStateEndpoint*(): HandlerAsync =
  result = proc(ctx: Context): Future[void] {.async, gcsafe.} =
    ctx.json(getSignalState())

import nimmax
import nimmax/websocket
import std/tables
import std/asyncdispatch
import std/json

type
  ServerSignal*[T] = ref object
    name*: string
    value*: T
    subscribers*: seq[WebSocket]

  SignalRegistry* = ref object
    signals*: Table[string, ServerSignalBase]

  ServerSignalBase* = ref object of RootObj

var globalRegistry = SignalRegistry(signals: initTable[string, ServerSignalBase]())

proc getRegistry*(): SignalRegistry = globalRegistry

proc createServerSignal*[T](name: string, initial: T): ServerSignal[T] =
  result = ServerSignal[T](name: name, value: initial, subscribers: @[])
  globalRegistry.signals[name] = result

proc getServerValue*[T](signal: ServerSignal[T]): T =
  signal.value

proc setServerValue*[T](signal: ServerSignal[T], value: T) =
  signal.value = value
  let msg = %*{"type": "signal_update", "name": signal.name, "value": $value}
  var toRemove: seq[int] = @[]
  for i, ws in signal.subscribers:
    try:
      waitFor ws.sendText($msg)
    except:
      toRemove.add(i)
  for i in countdown(toRemove.len - 1, 0):
    signal.subscribers.delete(toRemove[i])

proc subscribeWs*[T](signal: ServerSignal[T], ws: WebSocket) =
  signal.subscribers.add(ws)

proc unsubscribeWs*[T](signal: ServerSignal[T], ws: WebSocket) =
  var newSubs: seq[WebSocket] = @[]
  for s in signal.subscribers:
    if s != ws:
      newSubs.add(s)
  signal.subscribers = newSubs

proc handleSignalMessage*(msg: string, ws: WebSocket) =
  let parsed = parseJson(msg)
  let msgType = parsed{"type"}.getStr("")
  if msgType == "subscribe":
    let sigName = parsed{"name"}.getStr("")
    if globalRegistry.signals.hasKey(sigName):
      let sig = globalRegistry.signals[sigName]
      sig.subscribers.add(ws)
  elif msgType == "unsubscribe":
    let sigName = parsed{"name"}.getStr("")
    if globalRegistry.signals.hasKey(sigName):
      let sig = globalRegistry.signals[sigName]
      var newSubs: seq[WebSocket] = @[]
      for s in sig.subscribers:
        if s != ws:
          newSubs.add(s)
      sig.subscribers = newSubs

proc getSignalState*(): JsonNode =
  result = newJObject()
  for name, sig in globalRegistry.signals:
    result[name] = %*{"subscribers": sig.subscribers.len}

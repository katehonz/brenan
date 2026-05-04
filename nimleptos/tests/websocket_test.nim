import ../src/nimleptos/realtime/ws_bridge
import nimmax/websocket
import std/json
import std/tables

proc testCreateServerSignal() =
  let sig = createServerSignal("counter", 0)
  doAssert sig != nil
  doAssert sig.name == "counter"
  doAssert sig.value == 0
  echo "PASS: createServerSignal"

proc testGetServerValue() =
  let sig = createServerSignal("name", "Alice")
  doAssert getServerValue(sig) == "Alice"
  echo "PASS: getServerValue"

proc testSetServerValue() =
  let sig = createServerSignal("toggle", false)
  setServerValue(sig, true)
  doAssert getServerValue(sig) == true
  echo "PASS: setServerValue"

proc testSubscribeAndUnsubscribe() =
  let sig = createServerSignal("temp", 0.0)
  var ws = new(WebSocket)
  ws.readyState = wsClosed

  subscribeWs(sig, ws)
  doAssert sig.subscribers.len == 1

  unsubscribeWs(sig, ws)
  doAssert sig.subscribers.len == 0
  echo "PASS: subscribe and unsubscribe"

proc testBroadcastToClosedSocket() =
  ## broadcastToSubscribers should not crash when socket is closed.
  let sig = createServerSignal("msg", "hello")
  var ws = new(WebSocket)
  ws.readyState = wsClosed
  subscribeWs(sig, ws)
  ## Should not raise even though socket is closed.
  broadcastToSubscribers(sig, "world")
  echo "PASS: broadcast to closed socket"

proc testHandleSignalMessageSubscribe() =
  let sig = createServerSignal("chat", "")
  var ws = new(WebSocket)
  ws.readyState = wsClosed

  let msg = $ %*{"type": "subscribe", "name": "chat"}
  handleSignalMessage(msg, ws)

  doAssert sig.subscribers.len == 1
  echo "PASS: handleSignalMessage subscribe"

proc testHandleSignalMessageUnsubscribe() =
  let sig = createServerSignal("chat", "")
  var ws = new(WebSocket)
  ws.readyState = wsClosed
  subscribeWs(sig, ws)
  doAssert sig.subscribers.len == 1

  let msg = $ %*{"type": "unsubscribe", "name": "chat"}
  handleSignalMessage(msg, ws)

  doAssert sig.subscribers.len == 0
  echo "PASS: handleSignalMessage unsubscribe"

proc testGetSignalState() =
  discard createServerSignal("a", 1)
  discard createServerSignal("b", 2)
  let state = getSignalState()
  doAssert state.hasKey("a")
  doAssert state.hasKey("b")
  doAssert state["a"]["subscribers"].getInt() == 0
  echo "PASS: getSignalState"

proc testSignalRegistry() =
  let reg = getRegistry()
  doAssert reg != nil
  doAssert reg.signals.hasKey("counter")  # from earlier tests
  echo "PASS: getRegistry"

proc testMultipleSubscribers() =
  let sig = createServerSignal("multi", 0)
  var ws1 = new(WebSocket)
  ws1.readyState = wsClosed
  var ws2 = new(WebSocket)
  ws2.readyState = wsClosed

  subscribeWs(sig, ws1)
  subscribeWs(sig, ws2)
  doAssert sig.subscribers.len == 2

  unsubscribeWs(sig, ws1)
  doAssert sig.subscribers.len == 1
  doAssert sig.subscribers[0] == ws2
  echo "PASS: multiple subscribers"

when isMainModule:
  testCreateServerSignal()
  testGetServerValue()
  testSetServerValue()
  testSubscribeAndUnsubscribe()
  testBroadcastToClosedSocket()
  testHandleSignalMessageSubscribe()
  testHandleSignalMessageUnsubscribe()
  testGetSignalState()
  testSignalRegistry()
  testMultipleSubscribers()
  echo ""
  echo "All WebSocket tests passed!"

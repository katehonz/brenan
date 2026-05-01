# WebSocket Realtime

Real-time signal synchronization between server and clients via WebSocket.

---

## ServerSignal

```nim
import nimleptos/realtime/ws_bridge

let (onlineCount, setOnlineCount) = createServerSignal("online", 0)
```

`createServerSignal(name, initial)` creates a reactive value stored in a global `SignalRegistry`. Changes are pushed to all connected WebSocket subscribers.

### Type Hierarchy

```
ServerSignalBase (name, subscribers)
  └── ServerSignal[T] (value: T)
```

The registry stores `ServerSignalBase` — this allows subscribe/unsubscribe operations without knowing the generic type.

---

## Setting Values

```nim
# From server code
setOnlineCount(42)
# Automatically broadcasts {"type":"signal_update","name":"online","value":"42"}
# to all WebSocket subscribers
```

### Low-Level Broadcast

```nim
# Broadcast raw string value to subscribers (for HTTP endpoint integration)
signal.broadcastToSubscribers("42")
```

---

## Message Protocol

### Client → Server

```json
{"type": "subscribe", "name": "online"}
{"type": "unsubscribe", "name": "online"}
```

### Server → Client

```json
{"type": "signal_update", "name": "online", "value": "42"}
```

---

## WebSocket Handler

```nim
import nimleptos/realtime/ws_handler

# Register WebSocket route
app.get("/ws", wsSignalRoute())
```

The `wsSignalHandler` manages the WebSocket lifecycle:
1. Performs handshake
2. Listens for subscribe/unsubscribe messages
3. Cleans up subscriptions on disconnect

---

## HTTP Endpoints

```nim
# Update signal via HTTP POST
app.post("/api/signals/{name}", signalUpdateEndpoint("online"))

# Get signal state
app.get("/api/signals", signalStateEndpoint())
```

`signalUpdateEndpoint` parses JSON body `{"value": "42"}` and broadcasts to all subscribers.

---

## Client-Side JavaScript

```javascript
const ws = new WebSocket("ws://localhost:8080/ws");

ws.onopen = () => {
  ws.send(JSON.stringify({type: "subscribe", name: "online"}));
};

ws.onmessage = (event) => {
  const msg = JSON.parse(event.data);
  if (msg.type === "signal_update") {
    document.getElementById("count").textContent = msg.value;
  }
};
```

---

## API Reference

| Proc | Description |
|------|-------------|
| `createServerSignal[T](name, initial)` | Create server-side signal |
| `getServerValue[T](signal)` | Read current value |
| `setServerValue[T](signal, value)` | Update and broadcast |
| `broadcastToSubscribers(signal, value)` | Broadcast raw string |
| `subscribeWs(signal, ws)` | Add WebSocket subscriber |
| `unsubscribeWs(signal, ws)` | Remove WebSocket subscriber |
| `handleSignalMessage(msg, ws)` | Process incoming WS message |
| `getSignalState()` | Get JSON state of all signals |
| `wsSignalRoute()` | WebSocket route handler |
| `signalUpdateEndpoint(name)` | HTTP POST signal update |
| `signalStateEndpoint()` | HTTP GET signal state |

---

## Limitations

- Values serialized as strings (`$value`) — complex types lose structure
- No built-in WebSocket authentication
- No per-client signal filtering
- In-memory only — signals reset on server restart
- `waitFor` in `setServerValue` blocks the event loop

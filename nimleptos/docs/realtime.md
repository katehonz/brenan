# WebSocket Realtime

NimLeptos supports real-time signal synchronization between server and clients via WebSocket, powered by NimMax's WebSocket module.

## Server Signals

A `ServerSignal[T]` is a reactive value that pushes updates to connected WebSocket clients:

```nim
import nimleptos/realtime/ws_bridge

let (onlineCount, setOnlineCount) = createServerSignal("online_users", 0)

# Update — all subscribed clients receive the change
setOnlineCount(42)
```

### ServerSignal API

| Proc | Description |
|------|-------------|
| `createServerSignal(name, initial)` | Creates a named server signal |
| `getServerValue(signal)` | Read current value |
| `setServerValue(signal, value)` | Update and push to all subscribers |
| `subscribeWs(signal, ws)` | Subscribe a WebSocket client |
| `unsubscribeWs(signal, ws)` | Unsubscribe a WebSocket client |

### Signal Registry

All server signals are stored in a global registry:

```nim
import nimleptos/realtime/ws_bridge

let registry = getRegistry()
let state = getSignalState()  # JSON with signal names and subscriber counts
```

## WebSocket Handler

### Route Setup

```nim
import nimleptos
import nimleptos/realtime/ws_handler
import nimmax/websocket

# Register the WebSocket route
app.get("/ws", wsSignalRoute())
```

### Message Protocol

Clients send JSON messages to subscribe/unsubscribe:

```json
{"type": "subscribe", "name": "online_users"}
```

```json
{"type": "unsubscribe", "name": "online_users"}
```

Server pushes updates:

```json
{"type": "signal_update", "name": "online_users", "value": "42"}
```

### Client-Side JavaScript

```javascript
const ws = new WebSocket('ws://localhost:8080/ws');

ws.onopen = () => {
  ws.send(JSON.stringify({type: 'subscribe', name: 'online_users'}));
};

ws.onmessage = (event) => {
  const msg = JSON.parse(event.data);
  if (msg.type === 'signal_update') {
    document.getElementById('count').textContent = msg.value;
  }
};
```

## API Endpoints

### Signal State

```nim
app.get("/api/signals", signalStateEndpoint())
```

Returns JSON:
```json
{
  "online_users": {"subscribers": 5},
  "notifications": {"subscribers": 3}
}
```

### Signal Update

```nim
app.post("/api/signals/{name}", signalUpdateEndpoint("name"))
```

## Integration with SSR

Combine SSR and WebSocket for full-stack reactivity:

```nim
import nimleptos
import nimleptos/realtime/ws_handler

let (count, setCount) = createServerSignal("counter", 0)

proc counterPage(ctx: Context): Future[HtmlNode] {.gcsafe.} =
  result = newFuture[HtmlNode]()
  let current = getServerValue(count)
  complete(result,
    elDiv([("id", "counter")],
      elP([], text("Count: " & $current)),
      elButton([("id", "inc-btn")], text("+"))
    )
  )

proc main() =
  let app = newNimLeptosApp(clientScript = "/assets/counter.js")

  app.get("/", proc(ctx: Context) {.async.} =
    ctx.render(await counterPage(ctx), app)
  )

  app.get("/ws", wsSignalRoute())

  app.run()
```

## Limitations

- ServerSignal values are serialized as strings in WebSocket messages
- No built-in authentication for WebSocket connections (use NimMax middleware)
- All connected clients receive all updates (no per-client filtering)
- ServerSignal state is in-memory only (lost on server restart)

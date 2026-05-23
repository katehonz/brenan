# NimLeptos Debugging

## Enabling Debug Logging

Enable debug output with the compiler flag `-d:nimleptosDebug`:

```bash
nim c -r -d:nimleptosDebug -p:src your_app.nim
nim js -d:nimleptosDebug -p:src your_client.nim
```

## Debug Log Module (`src/nimleptos/debuglog.nim`)

The `debuglog` module provides safe logging across all targets:

| Function      | Native                   | JS                       |
|---------------|--------------------------|--------------------------|
| `debugLog`    | `echo`                   | `console.log`            |
| `debugWarn`   | `echo "[WARN]"`          | `console.warn`           |
| `debugError`  | `echo "[ERROR]"`         | `console.error`          |
| `debugTrace`  | `echo` with line info    | `console.log` with line  |

All functions are **no-ops** unless compiled with `-d:nimleptosDebug`.

### Usage

```nim
import nimleptos/debuglog

debugLog("Signal updated: ", value)
debugTrace("Effect triggered, deps=", $deps.len)
debugWarn("Slow render detected: ", elapsedMs, "ms")
debugError("Unhandled state: ", state)
```

## Compile-Time Safety

Debug logging is **completely zero-cost** when `nimleptosDebug` is not defined:
- No function calls emitted
- No string concatenation at runtime
- No affect on binary size

## What Gets Logged

When `-d:nimleptosDebug` is enabled, the reactive core logs:
- Signal subscription/unsubscription
- Computation dependency tracking
- Scheduler queue flushes
- Batch depth transitions

## Client-Side Debugging

For `nim js` targets, debug messages appear in the browser's DevTools console (not stdout). Use:
```bash
nim js -d:nimleptosDebug -p:src your_client.nim
```
Then check the browser console for log output.

## Debug Names

Name your effects and memos for easier tracing:

```nim
import nimleptos/reactive/signal
import nimleptos/reactive/effects

let (count, _) = createSignal(0)

discard createEffect(proc() =
  echo count()
, "countWatcher")

let (doubled, _) = createMemo(proc(): int = count() * 2, "doubledMemo")
```

When `-d:nimleptosDebug` is enabled, named computations include their name in trace output.

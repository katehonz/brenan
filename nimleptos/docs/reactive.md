# Reactive System

NimLeptos implements fine-grained reactivity inspired by Leptos (Rust). Unlike virtual DOM frameworks, only the specific computations that depend on changed signals are re-executed.

## Signals

A signal is a reactive container that tracks who reads it and notifies them when its value changes.

### createSignal

```nim
import nimleptos/reactive/signal

let (count, setCount) = createSignal(0)

echo count()      # 0
setCount(5)
echo count()      # 5
```

`createSignal[T]` returns a tuple of:
- `getter: proc(): T` — reads the current value and registers the caller as a dependency
- `setter: proc(val: T)` — updates the value and notifies all subscribers

### Type-Safe Signals

```nim
let (name, setName) = createSignal("Alice")    # Signal[string]
let (price, setPrice) = createSignal(9.99)     # Signal[float]
let (active, setActive) = createSignal(true)   # Signal[bool]
```

## Effects

An effect runs immediately and re-runs whenever any signal it reads changes.

```nim
import nimleptos/reactive/effects

let (count, setCount) = createSignal(0)

discard createEffect(proc() =
  echo "Count is: " & $count()
)
# Output: "Count is: 0"

setCount(5)
# Output: "Count is: 5"

setCount(10)
# Output: "Count is: 10"
```

### Dependency Tracking

Effects automatically track which signals they read. Only signals accessed during execution are tracked:

```nim
let (showName, setShowName) = createSignal(true)
let (name, setName) = createSignal("Alice")
var rendered = ""

discard createEffect(proc() =
  if showName():
    rendered = "Hello " & name()    # tracks both showName AND name
  else:
    rendered = "Hello"              # tracks only showName
)

setName("Bob")     # re-runs because name() was tracked
setShowName(false) # re-runs, now only tracks showName
setName("Charlie") # does NOT re-run (name no longer tracked)
```

## Memos

A memo derives a value from signals and caches it until its dependencies change.

```nim
let (a, setA) = createSignal(2)
let (b, setB) = createSignal(3)
let (sum, _) = createMemo(proc(): int = a() + b())

echo sum()    # 5
setA(10)
echo sum()    # 13
```

The memo recomputes only when `a` or `b` changes. Multiple reads of `sum()` return the cached value without re-computation.

## Batching

Multiple signal updates within a `batch` block trigger only one effect re-run:

```nim
let (a, setA) = createSignal(0)
let (b, setB) = createSignal(0)
var runs = 0

discard createEffect(proc() =
  inc runs
  discard a()
  discard b()
)

# Without batch: runs increases by 2
setA(1)
setB(2)

# With batch: runs increases by 1
batch(proc() =
  setA(10)
  setB(20)
)
```

## API Reference

### Signal Module

| Proc | Signature | Description |
|------|-----------|-------------|
| `createSignal` | `(initial: T): (Getter[T], Setter[T])` | Creates a reactive signal |
| `getSignalValue` | `(signal: Signal[T]): T` | Reads signal value (raw) |
| `setSignalValue` | `(signal: Signal[T], val: T)` | Sets signal value (raw) |

### Effects Module

| Proc | Signature | Description |
|------|-----------|-------------|
| `createEffect` | `(effect: proc()): Computation` | Creates a reactive effect |
| `createMemo` | `(compute: proc(): T): (Getter[T], Computation)` | Creates a cached derived value |

### Scheduler (via subscriber)

| Proc | Signature | Description |
|------|-----------|-------------|
| `batch` | `(fn: proc())` | Groups updates into one notification |
| `getScheduler` | `(): Scheduler` | Returns the global scheduler |

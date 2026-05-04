import subscriber

export subscriber

type
  Getter*[T] = proc(): T {.closure.}
  Setter*[T] = proc(val: T) {.closure.}
  SignalPair*[T] = tuple[getter: Getter[T], setter: Setter[T]]
  SignalTriple*[T] = tuple[sig: Signal[T], getter: Getter[T], setter: Setter[T]]

proc createSignal*[T](initial: T): SignalPair[T] =
  let sig = newSignal[T](initial)

  proc getter(): T =
    addDependency(sig)
    return sig.value

  proc setter(newValue: T) =
    if sig.value != newValue:
      sig.value = newValue
      notify(sig)

  return (getter, setter)

proc getSignalValue*[T](signal: Signal[T]): T =
  addDependency(signal)
  return signal.value

proc setSignalValue*[T](signal: Signal[T], newValue: T) =
  if signal.value != newValue:
    signal.value = newValue
    notify(signal)

proc createSignalTriple*[T](initial: T): SignalTriple[T] =
  ## Like createSignal but also returns the underlying Signal reference.
  ## Used internally by primitives that need direct access to the signal object.
  let sig = newSignal[T](initial)

  proc getter(): T =
    addDependency(sig)
    return sig.value

  proc setter(newValue: T) =
    if sig.value != newValue:
      sig.value = newValue
      notify(sig)

  return (sig, getter, setter)

## ─── Trigger — imperative reactive invalidation ───

type Trigger* = tuple[track: proc() {.closure.}, notify: proc() {.closure.}]

proc createTrigger*(): Trigger =
  ## Returns a trigger pair: `track()` to subscribe in an effect,
  ## `notify()` to invalidate all subscribers imperatively.
  let sig = newSignal[int](0)

  proc track() =
    addDependency(sig)

  proc notifyFn() =
    sig.value = sig.value + 1
    notify(sig)

  return (track: track, notify: notifyFn)

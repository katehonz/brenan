import subscriber

export subscriber

type
  Getter*[T] = proc(): T {.closure.}
  Setter*[T] = proc(val: T) {.closure.}
  SignalPair*[T] = tuple[getter: Getter[T], setter: Setter[T]]

proc createSignal*[T](initial: T): SignalPair[T] =
  let sig = Signal[T](value: initial)

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

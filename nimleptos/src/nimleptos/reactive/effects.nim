import subscriber
import signal

export subscriber
export signal

proc createEffect*(effect: proc() {.closure.}): Computation =
  let comp = Computation(execute: effect)
  trackDependencies(comp)
  return comp

type
  MemoPair*[T] = tuple[getter: Getter[T], computation: Computation]

proc createMemo*[T](compute: proc(): T {.closure.}): MemoPair[T] =
  let memo = Memo[T](compute: compute, dirty: true)
  var cachedValue: T

  proc getter(): T =
    addDependency(memo)
    if memo.dirty:
      # Prevent memo.compute() from registering dependencies in the caller's computation.
      # The memo's own computation (comp) already tracks these dependencies.
      let prev = getCurrentComputation()
      setCurrentComputation(nil)
      cachedValue = memo.compute()
      setCurrentComputation(prev)
      memo.value = cachedValue
      memo.dirty = false
    return cachedValue

  let comp = Computation(
    execute: proc() =
      let newVal = memo.compute()
      if cachedValue != newVal:
        cachedValue = newVal
        memo.value = cachedValue
        memo.dirty = false
        notify(memo)
  )

  trackDependencies(comp)

  return (getter, comp)

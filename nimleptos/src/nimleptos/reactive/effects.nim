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
      cachedValue = memo.compute()
      memo.dirty = false
    return cachedValue

  let comp = Computation(
    execute: proc() =
      let newVal = memo.compute()
      if cachedValue != newVal:
        cachedValue = newVal
        memo.dirty = false
        notify(memo)
  )

  trackDependencies(comp)

  return (getter, comp)

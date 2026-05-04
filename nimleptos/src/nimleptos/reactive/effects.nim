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
  MemoCache[T] = ref object
    value: T

proc createMemo*[T](compute: proc(): T {.closure.}): MemoPair[T] =
  let memo = Memo[T](compute: compute, dirty: true)
  let cache = MemoCache[T](value: default(T))

  proc getter(): T =
    addDependency(memo)
    if memo.dirty:
      # Prevent memo.compute() from registering dependencies in the caller's computation.
      # The memo's own computation (comp) already tracks these dependencies.
      let prev = getCurrentComputation()
      setCurrentComputation(nil)
      cache.value = memo.compute()
      setCurrentComputation(prev)
      memo.value = cache.value
      memo.dirty = false
    return cache.value

  let comp = Computation(
    execute: proc() =
      let newVal = memo.compute()
      if cache.value != newVal:
        cache.value = newVal
        memo.value = cache.value
        memo.dirty = false
        notify(memo)
  )

  trackDependencies(comp)

  return (getter, comp)

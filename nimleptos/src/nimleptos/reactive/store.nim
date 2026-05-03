import std/tables
import subscriber
import signal
import effects

## Store — global reactive state container
##
## A Store holds a single mutable state value and provides actions to mutate it.
## Unlike raw signals, a Store can hold complex objects and supports derived selectors.
##
## Example:
##   type CounterState = object
##     count: int
##     step: int
##
##   let store = createStore(CounterState(count: 0, step: 1))
##   store.update(proc(s: CounterState): CounterState =
##     result = s
##     result.count += s.step
##   )
##   echo store.get().count  # 1
##
##   let count = store.select(proc(s: CounterState): int = s.count)
##   echo count()  # 1

type
  Store*[T] = ref object
    ## Reactive state container with getter/setter and derived selectors.
    getter*: Getter[T]
    setter*: Setter[T]
    signal: Signal[T]

  Action*[T] = proc(state: T): T {.closure.}
    ## An action is a pure function that transforms state: T -> T.

proc createStore*[T](initial: T): Store[T] =
  ## Creates a new Store with the given initial state.
  let sig = Signal[T](value: initial)

  proc getter(): T =
    addDependency(sig)
    return sig.value

  proc setter(newValue: T) =
    if sig.value != newValue:
      sig.value = newValue
      notify(sig)

  Store[T](
    getter: getter,
    setter: setter,
    signal: sig
  )

proc get*[T](store: Store[T]): T =
  ## Reads the current state from the store. Reactive — tracked in effects.
  store.getter()

proc set*[T](store: Store[T], value: T) =
  ## Replaces the entire store state. Notifies subscribers.
  store.setter(value)

proc update*[T](store: Store[T], action: Action[T]) =
  ## Applies an action to transform the current state.
  let next = action(store.getter())
  store.setter(next)

proc select*[T, U](store: Store[T], selector: proc(s: T): U {.closure.}): Getter[U] =
  ## Creates a derived signal that selects a slice of the store state.
  ## The derived signal is memoized — only recalculates when the selected slice changes.
  ##
  ## Example:
  ##   let count = store.select(proc(s: CounterState): int = s.count)
  ##   echo count()  # reactive slice
  let memo = createMemo(proc(): U = selector(store.getter()))
  return memo.getter

type
  ## SliceStore allows binding a Store field to a reactive getter/setter pair.
  SliceStore*[T, F] = ref object
    store: Store[T]
    getter: proc(s: T): F {.closure.}
    setter: proc(s: T, val: F): T {.closure.}

proc createSlice*[T, F](
  store: Store[T],
  getter: proc(s: T): F {.closure.},
  setter: proc(s: T, val: F): T {.closure.}
): SliceStore[T, F] =
  ## Creates a reactive slice into a Store field.
  ##
  ## Example:
  ##   let countSlice = createSlice(store,
  ##     proc(s: CounterState): int = s.count,
  ##     proc(s: CounterState, v: int): CounterState =
  ##       result = s; result.count = v)
  ##   countSlice.set(10)
  SliceStore[T, F](store: store, getter: getter, setter: setter)

proc get*[T, F](slice: SliceStore[T, F]): F =
  ## Reads the current slice value. Reactive.
  slice.getter(slice.store.get())

proc set*[T, F](slice: SliceStore[T, F], value: F) =
  ## Updates the store by setting only this slice.
  slice.store.update(proc(s: T): T =
    result = slice.setter(s, value)
  )

proc selectSlice*[T, F](slice: SliceStore[T, F]): Getter[F] =
  ## Returns a reactive getter for this slice.
  let memo = createMemo(proc(): F = slice.get())
  return memo.getter

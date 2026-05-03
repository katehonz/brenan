import ../src/nimleptos/reactive/signal
import ../src/nimleptos/reactive/effects
import ../src/nimleptos/reactive/context
import ../src/nimleptos/reactive/store
import ../src/nimleptos/reactive/resource

# ========== Context Tests ==========

type
  UserCtx = ref object of ContextValue
    name: string
    age: int

  ThemeCtx = ref object of ContextValue
    darkMode: bool

proc testContextBasic() =
  clearContext()
  let user = UserCtx(name: "Alice", age: 30)
  provideContext("user", user)

  let retrieved = useContext("user")
  doAssert not retrieved.isNil
  doAssert UserCtx(retrieved).name == "Alice"
  doAssert UserCtx(retrieved).age == 30
  echo "PASS: context basic"

proc testContextTyped() =
  clearContext()
  let theme = ThemeCtx(darkMode: true)
  provideContext("theme", theme)

  let t = useContextAs[ThemeCtx]("theme")
  doAssert not t.isNil
  doAssert t.darkMode == true
  echo "PASS: context typed"

proc testContextMissing() =
  clearContext()
  let missing = useContext("nonexistent")
  doAssert missing.isNil
  echo "PASS: context missing"

proc testContextHasKey() =
  clearContext()
  doAssert not hasContext("user")
  provideContext("user", UserCtx(name: "Bob", age: 25))
  doAssert hasContext("user")
  echo "PASS: context has key"

proc testContextRemove() =
  clearContext()
  provideContext("temp", UserCtx(name: "Temp", age: 0))
  doAssert hasContext("temp")
  removeContext("temp")
  doAssert not hasContext("temp")
  echo "PASS: context remove"

proc testContextWithScope() =
  clearContext()
  provideContext("outer", UserCtx(name: "Outer", age: 1))
  doAssert hasContext("outer")

  withContext:
    doAssert not hasContext("outer")  # fresh scope
    provideContext("inner", UserCtx(name: "Inner", age: 2))
    doAssert hasContext("inner")

  doAssert hasContext("outer")       # restored
  doAssert not hasContext("inner")   # inner gone
  echo "PASS: context with scope"

# ========== Store Tests ==========

type
  CounterState = object
    count: int
    step: int

  TodoState = object
    items: seq[string]
    filter: string

proc testStoreBasic() =
  let store = createStore(CounterState(count: 0, step: 1))
  doAssert store.get().count == 0
  doAssert store.get().step == 1

  store.set(CounterState(count: 5, step: 2))
  doAssert store.get().count == 5
  doAssert store.get().step == 2
  echo "PASS: store basic"

proc testStoreUpdate() =
  let store = createStore(CounterState(count: 0, step: 1))
  store.update(proc(s: CounterState): CounterState =
    result = s
    result.count += s.step
  )
  doAssert store.get().count == 1
  echo "PASS: store update"

proc testStoreReactivity() =
  let store = createStore(CounterState(count: 0, step: 1))
  var effectRuns = 0
  var lastCount = -1

  discard createEffect(proc() =
    inc effectRuns
    lastCount = store.get().count
  )

  doAssert effectRuns == 1
  doAssert lastCount == 0

  store.update(proc(s: CounterState): CounterState =
    result = s
    result.count = 10
  )
  doAssert effectRuns == 2
  doAssert lastCount == 10
  echo "PASS: store reactivity"

proc testStoreSelect() =
  let store = createStore(CounterState(count: 0, step: 1))
  let count = store.select(proc(s: CounterState): int = s.count)

  doAssert count() == 0

  store.update(proc(s: CounterState): CounterState =
    result = s
    result.count = 42
  )
  doAssert count() == 42
  echo "PASS: store select"

proc testStoreSelectReactivity() =
  let store = createStore(CounterState(count: 0, step: 1))
  let count = store.select(proc(s: CounterState): int = s.count)
  var effectRuns = 0

  discard createEffect(proc() =
    inc effectRuns
    discard count()
  )

  store.update(proc(s: CounterState): CounterState =
    result = s
    result.step = 5   # changing step, not count
  )
  # Effect should NOT rerun because only step changed
  doAssert effectRuns == 1

  store.update(proc(s: CounterState): CounterState =
    result = s
    result.count = 99  # changing count
  )
  doAssert effectRuns == 2
  echo "PASS: store select reactivity"

proc testStoreSlice() =
  let store = createStore(CounterState(count: 0, step: 1))
  let countSlice = createSlice(store,
    proc(s: CounterState): int = s.count,
    proc(s: CounterState, v: int): CounterState =
      result = s
      result.count = v
  )

  doAssert countSlice.get() == 0
  countSlice.set(7)
  doAssert countSlice.get() == 7
  doAssert store.get().count == 7
  doAssert store.get().step == 1  # step unchanged
  echo "PASS: store slice"

proc testStoreSliceReactivity() =
  let store = createStore(CounterState(count: 0, step: 1))
  let countSlice = createSlice(store,
    proc(s: CounterState): int = s.count,
    proc(s: CounterState, v: int): CounterState =
      result = s
      result.count = v
  )
  var effectRuns = 0

  discard createEffect(proc() =
    inc effectRuns
    discard countSlice.get()
  )

  countSlice.set(5)
  doAssert effectRuns == 2
  echo "PASS: store slice reactivity"

# ========== Resource Tests ==========

proc testResourceBasic() =
  var fetchCount = 0
  let res = createResource(proc(): string =
    inc fetchCount
    "Data-" & $fetchCount
  )

  doAssert res.loading() == false
  doAssert res.state() == rsReady
  doAssert res.value() == "Data-1"
  doAssert res.error() == ""
  echo "PASS: resource basic"

proc testResourceRefetch() =
  var fetchCount = 0
  let res = createResource(proc(): int =
    inc fetchCount
    fetchCount * 10
  )

  doAssert res.value() == 10
  res.refetch()
  doAssert res.value() == 20
  res.refetch()
  doAssert res.value() == 30
  echo "PASS: resource refetch"

proc testResourceWithSource() =
  let (multiplier, setMultiplier) = createSignal(2)
  let res = createResource(multiplier, proc(m: int): int =
    m * 5
  )

  doAssert res.value() == 10   # 2 * 5
  setMultiplier(3)
  doAssert res.value() == 15   # 3 * 5
  setMultiplier(10)
  doAssert res.value() == 50   # 10 * 5
  echo "PASS: resource with source"

proc testResourceReactivity() =
  let (id, setId) = createSignal(1)
  let res = createResource(id, proc(i: int): string =
    "User" & $i
  )

  var effectRuns = 0
  var lastValue = ""

  discard createEffect(proc() =
    inc effectRuns
    lastValue = res.value()
  )

  doAssert effectRuns == 1
  doAssert lastValue == "User1"

  setId(2)
  doAssert effectRuns == 2
  doAssert lastValue == "User2"
  echo "PASS: resource reactivity"

proc testResourceLoadingState() =
  var fetchCount = 0
  let res = createResource(proc(): int =
    inc fetchCount
    fetchCount
  )

  # After initial fetch, loading should be false
  doAssert res.loading() == false
  doAssert res.state() == rsReady

  # Trigger refetch
  res.refetch()
  # Note: with sync fetcher, loading goes true then false immediately
  # so by the time we check, it's already done
  doAssert res.state() == rsReady
  echo "PASS: resource loading state"

# ========== Main ==========

when isMainModule:
  # Context
  testContextBasic()
  testContextTyped()
  testContextMissing()
  testContextHasKey()
  testContextRemove()
  testContextWithScope()

  # Store
  testStoreBasic()
  testStoreUpdate()
  testStoreReactivity()
  testStoreSelect()
  testStoreSelectReactivity()
  testStoreSlice()
  testStoreSliceReactivity()

  # Resource
  testResourceBasic()
  testResourceRefetch()
  testResourceWithSource()
  testResourceReactivity()
  testResourceLoadingState()

  echo ""
  echo "All reactive extension tests passed!"

import ../src/nimleptos/reactive/signal
import ../src/nimleptos/reactive/effects

proc testCreateSignal() =
  let (count, setCount) = createSignal(0)
  doAssert count() == 0
  setCount(5)
  doAssert count() == 5
  echo "PASS: createSignal basic"

proc testSignalReactivity() =
  let (count, setCount) = createSignal(0)
  var effectRuns = 0
  var lastValue = -1

  discard createEffect(proc() =
    inc effectRuns
    lastValue = count()
  )

  doAssert effectRuns == 1
  doAssert lastValue == 0
  setCount(10)
  doAssert effectRuns == 2
  doAssert lastValue == 10
  echo "PASS: signal reactivity"

proc testCreateMemo() =
  let (a, setA) = createSignal(2)
  let (b, setB) = createSignal(3)
  let (sum, _) = createMemo(proc(): int = a() + b())

  doAssert sum() == 5
  setA(10)
  doAssert sum() == 13
  setB(20)
  doAssert sum() == 30
  echo "PASS: createMemo"

proc testBatch() =
  let (a, setA) = createSignal(0)
  let (b, setB) = createSignal(0)
  var effectRuns = 0

  discard createEffect(proc() =
    inc effectRuns
    discard a()
    discard b()
  )

  let runsBefore = effectRuns
  batch(proc() =
    setA(1)
    setB(2)
  )

  doAssert effectRuns == runsBefore + 1
  doAssert a() == 1
  doAssert b() == 2
  echo "PASS: batch"

proc testDependencyTracking() =
  let (showName, setShowName) = createSignal(true)
  let (name, setName) = createSignal("Alice")
  let (greeting, setGreeting) = createSignal("Hello")
  var rendered = ""

  discard createEffect(proc() =
    if showName():
      rendered = greeting() & " " & name()
    else:
      rendered = greeting()
  )

  doAssert rendered == "Hello Alice"
  setName("Bob")
  doAssert rendered == "Hello Bob"
  setShowName(false)
  doAssert rendered == "Hello"
  setGreeting("Hi")
  doAssert rendered == "Hi"
  echo "PASS: dependency tracking"

proc testOwnerTree() =
  var effectRuns = 0
  var cleanupRuns = 0

  let dispose = createRoot(proc() =
    let (count, setCount) = createSignal(0)
    discard createEffect(proc() =
      inc effectRuns
      discard count()
    )
    onCleanup(proc() =
      inc cleanupRuns
    )
    setCount(1)
  )

  doAssert effectRuns == 2  # initial + one update
  doAssert cleanupRuns == 0
  dispose()
  doAssert cleanupRuns == 1
  echo "PASS: owner tree with cleanup"

proc testUntrack() =
  let (count, setCount) = createSignal(0)
  var effectRuns = 0
  var untrackedValue = -1

  discard createEffect(proc() =
    inc effectRuns
    var captured = -1
    untrack(proc() = captured = count())
    untrackedValue = captured
  )

  doAssert effectRuns == 1
  doAssert untrackedValue == 0
  setCount(5)
  # Effect should NOT re-run because untrack() prevents subscription
  doAssert effectRuns == 1
  doAssert untrackedValue == 0
  echo "PASS: untrack prevents subscription"

proc testTrigger() =
  let (count, setCount) = createSignal(0)
  let trig = createTrigger()
  var effectRuns = 0

  discard createEffect(proc() =
    inc effectRuns
    trig.track()
    discard count()
  )

  doAssert effectRuns == 1
  trig.notify()
  doAssert effectRuns == 2
  setCount(1)
  doAssert effectRuns == 3
  echo "PASS: trigger imperatively invalidates effects"

proc testNestedOwners() =
  var innerEffectRuns = 0
  var outerEffectRuns = 0
  var innerCleanup = 0
  var outerCleanup = 0

  let dispose = createRoot(proc() =
    let (x, setX) = createSignal(0)
    discard createEffect(proc() =
      inc outerEffectRuns
      discard x()
    )
    onCleanup(proc() = inc outerCleanup)

    # Nested root
    let disposeInner = createRoot(proc() =
      let (y, setY) = createSignal(0)
      discard createEffect(proc() =
        inc innerEffectRuns
        discard y()
      )
      onCleanup(proc() = inc innerCleanup)
    )

    setX(1)
    disposeInner()
    doAssert innerCleanup == 1
    doAssert innerEffectRuns == 1  # inner disposed, no more runs
  )

  dispose()
  doAssert outerCleanup == 1
  doAssert outerEffectRuns == 2  # initial + setX(1)
  echo "PASS: nested owners dispose independently"

when isMainModule:
  testCreateSignal()
  testSignalReactivity()
  testCreateMemo()
  testBatch()
  testDependencyTracking()
  testOwnerTree()
  testUntrack()
  testTrigger()
  testNestedOwners()
  echo ""
  echo "All reactive core tests passed!"

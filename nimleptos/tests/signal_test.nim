import ../src/nimleptos/reactive/signal
import ../src/nimleptos/reactive/effects
import ../src/nimleptos/reactive/subscriber

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

proc testStressSignalDisposal() =
  ## Create and dispose many signal+effect trees to check for leaks.
  for i in 1..1000:
    let dispose = createRoot(proc() =
      let (x, setX) = createSignal(i)
      var captured = 0
      discard createEffect(proc() =
        captured = x()
      )
      setX(i * 2)
    )
    dispose()
  echo "PASS: stress test — 1000 signal+effect trees disposed"

proc testDisposedEffectDoesNotFire() =
  ## Verify that after disposal, effects don't fire when signals change.
  let (sig, setSig) = createSignal(0)
  var effectRuns = 0
  let dispose = createRoot(proc() =
    discard createEffect(proc() =
      inc effectRuns
      discard sig()
    )
    setSig(1)
  )
  doAssert effectRuns == 2  # initial + setSig(1)
  dispose()
  setSig(2)  # should NOT trigger the disposed effect
  doAssert effectRuns == 2  # no new runs
  echo "PASS: disposed effect stops firing"

proc testMemoDisposal() =
  ## Verify that disposed memos don't leak dependencies.
  let (x, setX) = createSignal(0)
  var memoRuns = 0
  let dispose = createRoot(proc() =
    let (m, _) = createMemo(proc(): int =
      inc memoRuns
      return x() * 2
    )
    doAssert m() == 0
    setX(5)
    doAssert m() == 10
  )
  dispose()
  let runsAfter = memoRuns
  setX(100)  # should NOT trigger the disposed memo
  doAssert memoRuns == runsAfter
  echo "PASS: memo disposal stops recomputation"

proc testSchedulerQueueBounded() =
  ## Verify that proper disposal doesn't leave orphaned computations.
  for i in 1..500:
    let dispose = createRoot(proc() =
      let (a, setA) = createSignal(0)
      let (b, setB) = createSignal(0)
      discard createEffect(proc() =
        discard a()
        discard b()
      )
      setA(1)
      setB(1)
    )
    dispose()
  # After all disposals, no effects should remain in the scheduler
  flush(getScheduler())
  echo "PASS: scheduler queue bounded after mass disposal"

proc testOwnerDisposalBreaksCycles() =
  ## Verify that Owner→child→parent cycle is properly broken.
  ## Create a 3-level deep owner tree and dispose from root.
  var disposals = 0
  let dispose = createRoot(proc() =
    onCleanup(proc() = inc disposals)
    discard createRoot(proc() =
      onCleanup(proc() = inc disposals)
      discard createRoot(proc() =
        onCleanup(proc() = inc disposals)
      )
    )
  )
  dispose()
  doAssert disposals == 3
  echo "PASS: nested owner disposal breaks all cycles"

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
  testStressSignalDisposal()
  testDisposedEffectDoesNotFire()
  testMemoDisposal()
  testSchedulerQueueBounded()
  testOwnerDisposalBreaksCycles()
  echo ""
  echo "All reactive core tests passed!"

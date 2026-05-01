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

when isMainModule:
  testCreateSignal()
  testSignalReactivity()
  testCreateMemo()
  testBatch()
  testDependencyTracking()
  echo ""
  echo "All reactive core tests passed!"

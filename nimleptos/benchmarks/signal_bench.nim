## NimLeptos Signal Update Throughput Benchmark
##
## Measures:
## 1. Raw signal updates per second (10 000 updates)
## 2. Signal updates with createEffect tracking
## 3. Signal updates with createMemo
## 4. Batched signal updates (throughput vs unbatched)

import times, strformat
import nimleptos/reactive/signal
import nimleptos/reactive/effects

proc measureBareSignalUpdate(iterations: int): float =
  let (count, setCount) = createSignal(0)
  let start = cpuTime()
  for i in 1 .. iterations:
    setCount(i)
  let elapsed = cpuTime() - start
  result = elapsed

proc measureSignalWithEffect(iterations: int): float =
  let (count, setCount) = createSignal(0)
  var total: int = 0
  discard createEffect(proc() =
    total += count()
  )
  let start = cpuTime()
  for i in 1 .. iterations:
    setCount(i)
  let elapsed = cpuTime() - start
  result = elapsed

proc measureSignalWithMemo(iterations: int): float =
  let (a, setA) = createSignal(0)
  let (b, setB) = createSignal(0)
  let (sum, _) = createMemo(proc(): int = a() + b())
  var captured: int = 0
  let start = cpuTime()
  for i in 1 .. iterations:
    setA(i)
    setB(i)
    captured += sum()
  let elapsed = cpuTime() - start
  doAssert captured > 0, "memo should produce values"
  result = elapsed

proc measureBatchedSignalUpdate(iterations: int, batchSize: int = 100): float =
  let (count, setCount) = createSignal(0)
  var effectRuns: int = 0
  discard createEffect(proc() =
    discard count()
    inc effectRuns
  )
  let start = cpuTime()
  var i = 0
  while i < iterations:
    batch(proc() =
      for j in 1 .. batchSize:
        inc i
        if i > iterations:
          break
        setCount(i)
    )
  let elapsed = cpuTime() - start
  result = elapsed

when isMainModule:
  const ITERATIONS = 10_000
  const WARMUP = 1_000

  # Warmup
  discard measureBareSignalUpdate(WARMUP)
  discard measureSignalWithEffect(WARMUP)
  discard measureSignalWithMemo(WARMUP)

  echo fmt"╔══════════════════════════════════════════════════╗"
  echo fmt"║   NimLeptos Signal Update Throughput Benchmark    ║"
  echo fmt"╠══════════════════════════════════════════════════╣"
  echo fmt"║ Iterations: {ITERATIONS:>6}                              ║"

  let bareTime = measureBareSignalUpdate(ITERATIONS)
  let bareRate = ITERATIONS.float / bareTime
  echo fmt"╠══════════════════════════════════════════════════╣"
  echo fmt"║ Bare signal update:     {bareTime*1000:>7.2f} ms        ║"
  echo fmt"║ Rate:                   {bareRate.int:>6} updates/s       ║"

  let effectTime = measureSignalWithEffect(ITERATIONS)
  let effectRate = ITERATIONS.float / effectTime
  echo fmt"╠══════════════════════════════════════════════════╣"
  echo fmt"║ Signal + effect:        {effectTime*1000:>7.2f} ms        ║"
  echo fmt"║ Rate:                   {effectRate.int:>6} updates/s       ║"
  echo fmt"║ Overhead vs bare:       {((effectTime/bareTime - 1.0) * 100):>5.1f}%              ║"

  let memoTime = measureSignalWithMemo(ITERATIONS)
  let memoRate = ITERATIONS.float / memoTime
  echo fmt"╠══════════════════════════════════════════════════╣"
  echo fmt"║ Signal + memo (2 src):  {memoTime*1000:>7.2f} ms        ║"
  echo fmt"║ Rate:                   {memoRate.int:>6} updates/s       ║"

  let batchTime = measureBatchedSignalUpdate(ITERATIONS)
  let batchRate = ITERATIONS.float / batchTime
  echo fmt"╠══════════════════════════════════════════════════╣"
  echo fmt"║ Batched (x100):         {batchTime*1000:>7.2f} ms        ║"
  echo fmt"║ Rate:                   {batchRate.int:>6} updates/s       ║"
  echo fmt"║ Speedup vs effect:      {(effectTime/batchTime):>5.1f}x              ║"

  echo fmt"╚══════════════════════════════════════════════════╝"
  echo ""
  echo "Benchmark complete."

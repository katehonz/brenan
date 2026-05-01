import std/sequtils

type
  Subscriber* = ref object of RootObj
    dirty*: bool
    onNotify*: proc() {.closure.}

  Computation* = ref object of Subscriber
    execute*: proc() {.closure.}
    dependencies*: seq[SignalBase]

  SignalBase* = ref object of RootObj
    subscribers: seq[Subscriber]

  Signal*[T] = ref object of SignalBase
    value*: T

  Memo*[T] = ref object of SignalBase
    value*: T
    compute*: proc(): T {.closure.}
    dirty*: bool

  Scheduler* = ref object
    queue: seq[Computation]
    pending: bool
    batchDepth: int

var currentComputation: Computation = nil
var globalScheduler = Scheduler(queue: @[], pending: false, batchDepth: 0)

proc getScheduler*(): Scheduler = globalScheduler

proc getCurrentComputation*(): Computation = currentComputation

proc setCurrentComputation*(c: Computation) =
  currentComputation = c

proc subscribe*(signal: SignalBase, sub: Subscriber) =
  if sub notin signal.subscribers:
    signal.subscribers.add(sub)

proc unsubscribe*(signal: SignalBase, sub: Subscriber) =
  signal.subscribers = signal.subscribers.filterIt(it != sub)

proc cleanup*(comp: Computation) =
  for dep in comp.dependencies:
    dep.unsubscribe(comp)
  comp.dependencies.setLen(0)

proc trackDependencies*(comp: Computation) =
  let prev = currentComputation
  currentComputation = comp
  comp.dirty = false
  cleanup(comp)
  if comp.execute != nil:
    comp.execute()
  currentComputation = prev

proc flush*(sched: Scheduler) =
  while sched.queue.len > 0:
    let batch = sched.queue
    sched.queue.setLen(0)
    for comp in batch:
      if comp.dirty:
        trackDependencies(comp)
  sched.pending = false

proc schedule*(sched: Scheduler, comp: Computation) =
  if comp notin sched.queue:
    sched.queue.add(comp)
  if sched.batchDepth == 0 and not sched.pending:
    sched.pending = true
    flush(sched)

proc notify*(signal: SignalBase) =
  for sub in signal.subscribers:
    sub.dirty = true
    if sub.onNotify != nil:
      sub.onNotify()
    elif sub of Computation:
      globalScheduler.schedule(Computation(sub))

proc batch*(sched: Scheduler, fn: proc() {.closure.}) =
  inc sched.batchDepth
  try:
    fn()
  finally:
    dec sched.batchDepth
    if sched.batchDepth == 0:
      flush(sched)

proc batch*(fn: proc() {.closure.}) =
  globalScheduler.batch(fn)

proc addDependency*(signal: SignalBase) =
  if currentComputation != nil:
    signal.subscribe(currentComputation)
    if signal notin currentComputation.dependencies:
      currentComputation.dependencies.add(signal)

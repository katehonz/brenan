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

when defined(js) or defined(wasm32):
  ## JS and WASM (without pthreads) use plain globals.
  ## Native backend uses thread-local for thread safety.
  var currentComputation: Computation
  var globalScheduler: Scheduler
else:
  var currentComputation {.threadvar.}: Computation
  var globalScheduler {.threadvar.}: Scheduler

proc getScheduler*(): Scheduler =
  if globalScheduler == nil:
    globalScheduler = Scheduler(queue: @[], pending: false, batchDepth: 0)
  return globalScheduler

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
  when defined(nimleptosDebug):
    echo "flush called, queue len=" & $sched.queue.len
  while sched.queue.len > 0:
    let batch = sched.queue
    sched.queue.setLen(0)
    for comp in batch:
      if comp.dirty:
        when defined(nimleptosDebug):
          echo "flushing computation"
        trackDependencies(comp)
  sched.pending = false

proc schedule*(sched: Scheduler, comp: Computation) =
  if comp notin sched.queue:
    sched.queue.add(comp)
  if sched.batchDepth == 0 and not sched.pending:
    sched.pending = true
    flush(sched)

proc notify*(signal: SignalBase) =
  when defined(nimleptosDebug):
    echo "notify called, subscribers=" & $signal.subscribers.len
  let subs = signal.subscribers  # snapshot: cleanup/addDependency mutate the list during flush
  for sub in subs:
    when defined(nimleptosDebug):
      echo "  sub is Computation=" & $(sub of Computation)
    sub.dirty = true
    if sub.onNotify != nil:
      sub.onNotify()
    elif sub of Computation:
      getScheduler().schedule(Computation(sub))

proc batch*(sched: Scheduler, fn: proc() {.closure.}) =
  inc sched.batchDepth
  try:
    fn()
  finally:
    dec sched.batchDepth
    if sched.batchDepth == 0:
      flush(sched)

proc batch*(fn: proc() {.closure.}) =
  getScheduler().batch(fn)

proc newSignal*[T](initial: T): Signal[T] =
  ## Creates a new Signal with the given initial value.
  result = Signal[T](value: initial)
  result.subscribers = newSeq[Subscriber]()

proc addDependency*(signal: SignalBase) =
  if currentComputation != nil:
    when defined(nimleptosDebug):
      echo "addDependency: adding comp to signal subscribers"
    signal.subscribe(currentComputation)
    if signal notin currentComputation.dependencies:
      currentComputation.dependencies.add(signal)

type
  ReactiveContext* = ref object
    savedComputation: Computation
    savedScheduler: Scheduler
    ownedScheduler: Scheduler

proc newReactiveContext*(): ReactiveContext =
  let prevSched = getScheduler()
  let freshSched = Scheduler(queue: @[], pending: false, batchDepth: 0)
  globalScheduler = freshSched
  ReactiveContext(
    savedComputation: currentComputation,
    savedScheduler: prevSched,
    ownedScheduler: freshSched,
  )

proc release*(ctx: ReactiveContext) =
  for comp in ctx.ownedScheduler.queue:
    cleanup(comp)
  currentComputation = ctx.savedComputation
  globalScheduler = ctx.savedScheduler

template withReactiveContext*(body: untyped) =
  var nlReactiveCtx = newReactiveContext()
  try:
    body
  finally:
    release(nlReactiveCtx)

proc resetThreadContext*() =
  currentComputation = nil
  for comp in getScheduler().queue:
    cleanup(comp)
  globalScheduler = Scheduler(queue: @[], pending: false, batchDepth: 0)

import subscriber
import signal
import effects

## Resource — async reactive primitive
##
## A Resource wraps a data fetcher and exposes reactive loading/error/value states.
## When a source signal changes, the resource automatically refetches.
##
## Example:
##   let (userId, setUserId) = createSignal(1)
##   let userRes = createResource(userId, proc(id: int): string =
##     "User " & $id   # in real code: fetch from server
##   )
##
##   echo userRes.loading()   # true while fetching
##   echo userRes.value()     # "User 1" when ready
##
##   setUserId(2)             # triggers automatic refetch

type
  ResourceState* = enum
    rsIdle       ## Resource has not been fetched yet
    rsLoading    ## Fetcher is currently running
    rsReady      ## Fetch completed successfully
    rsError      ## Fetch failed

  Resource*[T] = ref object
    ## Reactive async data container with loading, error, and value states.
    currentValue*: T
    isLoadingSig: Signal[bool]
    valueSig: Signal[T]
    errorSig: Signal[string]
    stateSig: Signal[ResourceState]
    setLoading: Setter[bool]
    setValue: Setter[T]
    setError: Setter[string]
    setState: Setter[ResourceState]
    fetcher: proc(): T {.closure.}
    sourceComp: Computation

proc value*[T](res: Resource[T]): T =
  ## Returns the current value of the resource. Reactive — tracked in effects.
  addDependency(res.valueSig)
  return res.currentValue

proc loading*[T](res: Resource[T]): bool =
  ## Returns true while the resource is fetching. Reactive.
  addDependency(res.isLoadingSig)
  return res.isLoadingSig.value

proc error*[T](res: Resource[T]): string =
  ## Returns the error message if the last fetch failed. Reactive.
  addDependency(res.errorSig)
  return res.errorSig.value

proc state*[T](res: Resource[T]): ResourceState =
  ## Returns the current resource state. Reactive.
  addDependency(res.stateSig)
  return res.stateSig.value

proc refetch*[T](res: Resource[T]) =
  ## Manually triggers a re-fetch.
  res.setState(rsLoading)
  res.setLoading(true)
  when defined(wasm32):
    ## Wasm without full exception support — fetcher errors are fatal.
    let val = res.fetcher()
    res.currentValue = val
    res.setValue(val)
    res.setState(rsReady)
    res.setError("")
    res.setLoading(false)
  else:
    try:
      let val = res.fetcher()
      res.currentValue = val
      res.setValue(val)
      res.setState(rsReady)
      res.setError("")
    except:
      res.setError(getCurrentExceptionMsg())
      res.setState(rsError)
    finally:
      res.setLoading(false)

proc createResource*[T](fetcher: proc(): T {.closure.}): Resource[T] =
  ## Creates a Resource with a synchronous fetcher.
  ##
  ## The fetcher runs immediately. Call `refetch()` to fetch again.
  ## For source-driven resources see `createResource(source, fetcher)`.
  var initialVal: T
  let (ils, _, sl) = createSignalTriple(false)
  let (vs, _, sv) = createSignalTriple(initialVal)
  let (es, _, se) = createSignalTriple("")
  let (ss, _, sst) = createSignalTriple(rsIdle)

  let res = Resource[T](
    currentValue: initialVal,
    isLoadingSig: ils,
    valueSig: vs,
    errorSig: es,
    stateSig: ss,
    setLoading: sl,
    setValue: sv,
    setError: se,
    setState: sst,
    fetcher: fetcher,
  )

  res.refetch()
  return res

proc createResource*[S, T](
  source: Getter[S],
  fetcher: proc(s: S): T {.closure.}
): Resource[T] =
  ## Creates a Resource driven by a source signal.
  ##
  ## Whenever the source signal changes, the resource automatically refetches
  ## by calling fetcher with the new source value.
  ##
  ## Example:
  ##   let (page, setPage) = createSignal(1)
  ##   let posts = createResource(page, proc(p: int): seq[string] =
  ##     @["Post " & $p]
  ##   )
  ##   setPage(2)   # automatically refetches with p=2
  var initialVal: T
  let (ils, _, sl) = createSignalTriple(false)
  let (vs, _, sv) = createSignalTriple(initialVal)
  let (es, _, se) = createSignalTriple("")
  let (ss, _, sst) = createSignalTriple(rsIdle)

  let res = Resource[T](
    currentValue: initialVal,
    isLoadingSig: ils,
    valueSig: vs,
    errorSig: es,
    stateSig: ss,
    setLoading: sl,
    setValue: sv,
    setError: se,
    setState: sst,
    fetcher: proc(): T = fetcher(source()),
  )

  res.refetch()

  # Track source signal and auto-refetch on change
  res.sourceComp = createEffect(proc() =
    discard source()  # track dependency
    res.refetch()
  )

  return res

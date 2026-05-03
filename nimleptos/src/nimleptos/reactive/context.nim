import std/tables

## Context — dependency injection for reactive components
##
## Provides a key-value store accessible anywhere in the reactive tree,
## eliminating prop drilling. Values are stored per-thread.
##
## Example:
##   type UserCtx = ref object of ContextValue
##     username: string
##
##   let user = UserCtx(username: "Alice")
##   provideContext("user", user)
##
##   let ctx = useContext("user", UserCtx)
##   echo ctx.username  # "Alice"

type
  ContextValue* = ref object of RootObj
    ## Base type for all context values. Inherit from this to create typed contexts.

  ContextMap* = ref Table[string, ContextValue]

var globalContext {.threadvar.}: ContextMap

proc getContextMap(): ContextMap =
  ## Returns the thread-local context map, creating it if needed.
  if globalContext.isNil:
    globalContext = ContextMap()
    globalContext[] = initTable[string, ContextValue]()
  return globalContext

proc provideContext*(key: string, value: ContextValue) =
  ## Stores a context value under the given key in the thread-local context.
  runnableExamples:
    type AppTheme = ref object of ContextValue
      darkMode: bool
    provideContext("theme", AppTheme(darkMode: true))
  let ctx = getContextMap()
  ctx[key] = value

proc useContext*(key: string): ContextValue =
  ## Retrieves a context value by key. Returns nil if not found.
  ## Use the typed variant `useContext[T]` for type-safe access.
  let ctx = getContextMap()
  if ctx.hasKey(key):
    result = ctx[key]
  else:
    result = nil

proc useContextAs*[T: ContextValue](key: string): T =
  ## Type-safe context retrieval. Returns nil if key missing or wrong type.
  runnableExamples:
    type UserCtx = ref object of ContextValue
      name: string
    provideContext("user", UserCtx(name: "Bob"))
    let user = useContextAs[UserCtx]("user")
    assert user.name == "Bob"
  let raw = useContext(key)
  if raw.isNil:
    return nil
  if raw of T:
    return T(raw)
  return nil

proc hasContext*(key: string): bool =
  ## Returns true if a context value exists for the given key.
  let ctx = getContextMap()
  return ctx.hasKey(key)

proc removeContext*(key: string) =
  ## Removes a context value from the current thread.
  let ctx = getContextMap()
  ctx.del(key)

proc clearContext*() =
  ## Clears all context values in the current thread.
  globalContext = nil

template withContext*(body: untyped) =
  ## Executes body with a fresh context scope. Changes do not leak outside.
  var savedCtx = getContextMap()
  globalContext = nil
  try:
    body
  finally:
    globalContext = savedCtx

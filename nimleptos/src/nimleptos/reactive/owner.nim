## Owner / Scope Tree — Automatic Cleanup for Reactive Primitives
##
## Every `createEffect`, `createMemo`, and component registers in an Owner tree.
## When a parent Owner is disposed, all child effects and cleanup callbacks
## run automatically. This prevents memory leaks from orphaned subscriptions.

import subscriber

type
  Owner* = ref object
    disposers*: seq[proc() {.closure.}]
    children*: seq[Owner]
    parent*: Owner
    mounted*: bool
    mountCallbacks*: seq[proc() {.closure.}]

when defined(js):
  var currentOwner {.global.}: Owner
else:
  var currentOwner {.threadvar.}: Owner

proc getCurrentOwner*(): Owner = currentOwner

proc setCurrentOwner*(o: Owner) =
  currentOwner = o

proc newOwner*(parent: Owner = nil): Owner =
  Owner(disposers: @[], children: @[], parent: parent, mounted: false, mountCallbacks: @[])

proc dispose*(owner: Owner) =
  ## Recursively dispose all children, then run own disposers.
  if owner == nil: return
  for child in owner.children:
    child.dispose()
  owner.children.setLen(0)
  for fn in owner.disposers:
    fn()
  owner.disposers.setLen(0)
  owner.mountCallbacks.setLen(0)

proc addDisposer*(owner: Owner, fn: proc() {.closure.}) =
  if owner != nil:
    owner.disposers.add(fn)

proc addChild*(parent: Owner, child: Owner) =
  if parent != nil:
    parent.children.add(child)
    child.parent = parent

proc runMount*(owner: Owner) =
  ## Call mount callbacks once, then recursively on children.
  if owner == nil or owner.mounted: return
  owner.mounted = true
  for fn in owner.mountCallbacks:
    fn()
  for child in owner.children:
    child.runMount()

proc onCleanup*(fn: proc() {.closure.}) =
  ## Register a cleanup callback on the current Owner.
  ## It runs when the Owner is disposed.
  let owner = getCurrentOwner()
  if owner != nil:
    owner.disposers.add(fn)

proc onMount*(fn: proc() {.closure.}) =
  ## Register a mount callback on the current Owner.
  ## It runs once when the Owner tree is mounted.
  let owner = getCurrentOwner()
  if owner != nil:
    owner.mountCallbacks.add(fn)
  else:
    # No owner — call immediately (top-level usage)
    fn()

proc createRoot*(fn: proc() {.closure.}): proc() =
  ## Create a new reactive root scope. All effects, memos, and cleanup
  ## registered inside `fn` are owned by this root.
  ## Returns a dispose function that cleans up everything.
  let parent = getCurrentOwner()
  let root = newOwner(parent)
  setCurrentOwner(root)
  try:
    fn()
    root.runMount()
  finally:
    setCurrentOwner(parent)
    if parent != nil:
      parent.addChild(root)

  return proc() = root.dispose()

proc untrack*(fn: proc() {.closure.}) =
  ## Execute `fn` without tracking signal dependencies.
  ## Any signal reads inside `fn` will not subscribe the current effect.
  let prevOwner = getCurrentOwner()
  let prevComp = getCurrentComputation()
  setCurrentOwner(nil)
  setCurrentComputation(nil)
  try:
    fn()
  finally:
    setCurrentOwner(prevOwner)
    setCurrentComputation(prevComp)

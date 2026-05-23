## NimLeptos Reactive Counter — Nimbling WASM Edition
## ===================================================
## Exports reactive core (signals + effects) to WASM via nimbling.
## The JS side calls these functions and updates the DOM directly.
##
## Build:
##   nim c --cc:clang --os:standalone --mm:orc -d:wasm32 -p:src counter.nim
##   nimbling counter.wasm --out-dir pkg/ --target bundler
##
## Or use:
##   nimble nimbling_reactive

import nimbling
import nimleptos/reactive/signal
import nimleptos/reactive/effects

# ─── Reactive State (kept in WASM memory) ───

var countGetter: Getter[int]
var countSetter: Setter[int]
var doubledGetter: Getter[int]
var effectCount: int = 0

proc initCounter*(start: int32) {.wasmBindgen.} =
  ## Initialize reactive signals. Call once before using the counter.
  let (g, s) = createSignal(start.int)
  countGetter = g
  countSetter = s

  let (dg, _) = createMemo(proc(): int = countGetter() * 2)
  doubledGetter = dg

proc increment*() {.wasmBindgen.} =
  countSetter(countGetter() + 1)

proc decrement*() {.wasmBindgen.} =
  countSetter(countGetter() - 1)

proc getCount*(): int32 {.wasmBindgen.} =
  countGetter().int32

proc getDoubled*(): int32 {.wasmBindgen.} =
  doubledGetter().int32

proc reset*(value: int32) {.wasmBindgen.} =
  countSetter(value.int)

# ─── Effect registration (JS provides callback index) ───

import nimbling/runtime

var onChangeCallback: Closure[void]

proc registerOnChange*(callback: Closure[void]) {.wasmBindgen.} =
  ## Register a JS callback that gets called whenever count changes.
  onChangeCallback = callback
  discard createEffect(proc() =
    discard countGetter()  # track dependency
    inc effectCount
    if onChangeCallback.idx != 0:
      ## The JS closure is invoked via the JS heap
      discard
  )

proc getEffectRuns*(): int32 {.wasmBindgen.} =
  ## Returns how many times the effect has run (for debugging).
  effectCount.int32

# ─── Batch update (demonstrates batching) ───

proc batchUpdate*(delta: int32) {.wasmBindgen.} =
  ## Apply multiple updates in a single batch (one effect run).
  batch(proc() =
    countSetter(countGetter() + delta.int)
    countSetter(countGetter() + delta.int)
  )

# ─── Finalize nimbling bindings ───
wasmBindgenFinalize()

## Minimal WASM reactive core module for e2e compile test
import nimbling
import nimleptos/reactive/signal
import nimleptos/reactive/effects

var g: Getter[int]
var s: Setter[int]
var m: Getter[int]

proc initState*(start: int32) {.wasmBindgen.} =
  let (getter, setter) = createSignal(start.int)
  g = getter
  s = setter
  let (memoGetter, _) = createMemo(proc(): int = g() * 2)
  m = memoGetter

proc getValue*(): int32 {.wasmBindgen.} =
  g().int32

proc setValue*(v: int32) {.wasmBindgen.} =
  s(v.int)

proc getMemo*(): int32 {.wasmBindgen.} =
  m().int32

wasmBindgenFinalize()

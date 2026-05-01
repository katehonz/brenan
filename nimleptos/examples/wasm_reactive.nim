## NimLeptos Reactive Core in WebAssembly
## Signals + Effects compiled to WASM, controlled from JavaScript.
##
## Build:
##   source ~/emsdk/emsdk_env.sh
##   nim c --cpu:wasm32 --mm:arc -p:src \
##     --cc:clang --clang.exe:emcc --clang.linkerexe:emcc \
##     --passC:"-sWASM=1" \
##     --passL:"-sWASM=1 -sMODULARIZE=1 -sEXPORT_NAME='NimLeptosWasm' \
##       -sEXPORTED_FUNCTIONS=['_main','_increment','_decrement','_getCount','_getDoubled'] \
##       -sEXPORTED_RUNTIME_METHODS=['ccall','cwrap']" \
##     -o:examples/wasm_reactive.js examples/wasm_reactive.nim

import nimleptos/reactive/signal
import nimleptos/reactive/effects

# Signals
let (count, setCount) = createSignal(0)
let (doubled, _) = createMemo(proc(): int = count() * 2)

# Exported functions called from JS via Module.ccall/_func
proc increment() {.exportc.} =
  setCount(count() + 1)

proc decrement() {.exportc.} =
  setCount(count() - 1)

proc getCount(): int {.exportc.} =
  return count()

proc getDoubled(): int {.exportc.} =
  return doubled()

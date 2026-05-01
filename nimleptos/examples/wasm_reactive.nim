## NimLeptos Reactive Core in WebAssembly
## Signals + Effects compiled to WASM, controlled from JavaScript.
##
## Prerequisites:
##   - Emscripten SDK (https://emscripten.org/docs/getting_started/downloads.html)
##
## Build:
##   source ~/emsdk/emsdk_env.sh   # or ensure emcc is in PATH
##   nimble wasm
##
## Or manually:
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

{.push exportc.}

proc increment() =
  setCount(count() + 1)

proc decrement() =
  setCount(count() - 1)

proc getCount(): int =
  count()

proc getDoubled(): int =
  doubled()

{.pop.}

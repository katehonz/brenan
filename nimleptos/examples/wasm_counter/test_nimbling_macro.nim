## Test nimbling wasmBindgen macro with Emscripten
## Compile:
##   source ~/emsdk/emsdk_env.sh
##   nim c --cpu:wasm32 --mm:arc --threads:on --cc:clang --clang.exe:emcc --clang.linkerexe:emcc \
##     --passC:"-sWASM=1" --passL:"-sWASM=1 -sMODULARIZE=1 -sEXPORT_NAME='TestWasm' \
##     -sEXPORTED_FUNCTIONS=['_main','_greet','_add','_increment'] \
##     -sEXPORTED_RUNTIME_METHODS=['ccall','cwrap']" \
##     -p:src -p:../../nimbling/src -o:test_nbg.js test_nimbling_macro.nim

import nimbling

proc greet(name: string): string {.wasmBindgen.} =
  result = "Hello, " & name & "!"

proc add(a, b: int32): int32 {.wasmBindgen.} =
  result = a + b

var counter: int32 = 0

proc increment(): int32 {.wasmBindgen.} =
  inc counter
  result = counter

wasmBindgenFinalize()

when isMainModule:
  echo greet("World")

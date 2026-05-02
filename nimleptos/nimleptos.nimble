# Package
version       = "0.2.0"
author        = "NimLeptos Contributors"
description   = "A full-stack reactive web framework for Nim inspired by Leptos"
license       = "MIT"
srcDir        = "src"

# Dependencies
requires "nim >= 2.0.0"
requires "nimmax >= 1.0.0"
requires "jwt >= 2.1.0"

import os

task test, "Run all tests":
  exec "nim c -r --threads:on -p:src tests/signal_test.nim"
  exec "nim c -r --threads:on -p:src tests/macros_test.nim"
  exec "nim c -r --threads:on -p:src tests/ssr_test.nim"
  exec "nim c -r --threads:on -p:src tests/server_test.nim"
  exec "nim c -r --threads:on -p:src tests/all_test.nim"

task example, "Run counter example":
  exec "nim c -r --threads:on -p:src examples/counter/main.nim"

task server, "Run server example":
  exec "nim c -r --threads:on -p:src examples/server_app.nim"

task client, "Compile client-side counter example":
  exec "nim js -p:src -o:examples/counter_client.js examples/counter_client.nim"

task timer, "Compile reactive timer example":
  exec "nim js -p:src -o:examples/timer_client.js examples/timer_client.nim"

task hybrid, "Compile hybrid buildHtml + reactive DOM example":
  exec "nim js -p:src -o:examples/hybrid_client.js examples/hybrid_client.nim"

task conditional, "Compile reactive if/else example":
  exec "nim js -p:src -o:examples/conditional_client.js examples/conditional_client.nim"

task todo, "Run full-stack todo app example":
  exec "nim c -r --threads:on -p:src examples/todo_app.nim"

task blog, "Build and run blog example":
  exec "nim js -p:src -o:examples/blog/public/app.js examples/blog/frontend.nim"
  exec "nim c -r --threads:on -p:src examples/blog/backend.nim"

task wasm, "Compile reactive core to WASM":
  var emcc = findExe("emcc")
  if emcc == "":
    let emsdk = getEnv("EMSDK")
    if emsdk != "":
      emcc = emsdk / "upstream" / "emscripten" / "emcc"
    else:
      let home = getEnv("HOME")
      let candidate = home / "emsdk" / "upstream" / "emscripten" / "emcc"
      if fileExists(candidate):
        emcc = candidate
      else:
        echo "Error: emcc not found. Install Emscripten (https://emscripten.org) and ensure it's in your PATH, set EMSDK env var, or install to ~/emsdk."
        quit(1)
  exec "nim c --cpu:wasm32 --mm:arc -p:src " &
    "--cc:clang --clang.exe:" & emcc & " --clang.linkerexe:" & emcc & " " &
    "--passC:\"-sWASM=1\" " &
    "--passL:\"-sWASM=1 -sMODULARIZE=1 -sEXPORT_NAME='NimLeptosWasm' " &
    "-sEXPORTED_FUNCTIONS=['_main','_increment','_decrement','_getCount','_getDoubled'] " &
    "-sEXPORTED_RUNTIME_METHODS=['ccall','cwrap']\" " &
    "-o:examples/wasm_reactive.js examples/wasm_reactive.nim"

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
requires "nimbling >= 0.1.0"

import os

task test, "Run all tests":
  exec "nim c -r --threads:on -p:src tests/signal_test.nim"
  exec "nim c -r --threads:on -p:src tests/macros_test.nim"
  exec "nim c -r --threads:on -p:src tests/ssr_test.nim"
  exec "nim c -r --threads:on -p:src tests/server_test.nim"
  exec "nim c -r --threads:on -p:src tests/reactive_ext_test.nim"
  exec "nim c -r --threads:on -p:src tests/all_test.nim"
  exec "nim c -r --threads:on -p:src tests/i18n_test.nim"
  exec "nim c -r --threads:on -p:src tests/form_test.nim"
  exec "nim c -r --threads:on -p:src tests/websocket_test.nim"
  exec "nim c -r --threads:on -p:src tests/wasm_e2e_test.nim"
  exec "nim js -p:src tests/client_dom_test.nim"
  exec "node --require ./tests/jsdom_setup.js tests/client_dom_test.js"
  exec "nim js -p:src tests/router_test.nim"
  exec "node --require ./tests/jsdom_setup.js tests/router_test.js"

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

task nimblingReactive, "Compile reactive core example for nimbling WASM":
  let outDir = "examples/nimbling_reactive"
  let nimcache = outDir & "/nimcache"
  echo "Building nimbling reactive counter..."
  exec "nim c --cc:clang --cpu:wasm32 --os:standalone --mm:orc -d:wasm32 " &
    "-p:src --compileOnly --nimcache:" & nimcache & " " &
    outDir & "/counter.nim"

  # Copy .nbg sidecar to example dir so CLI can find it
  for file in listFiles("."):
    if file.endsWith(".nbg"):
      let dst = outDir & "/" & extractFilename(file)
      cpFile(file, dst)
      rmFile(file)
      echo "Moved sidecar: " & file & " -> " & dst

  echo ""
  echo "C files generated in " & nimcache
  echo ""
  echo "Next steps:"
  echo "  1. Link to WASM (requires WASI SDK):"
  echo "     export WASI_SDK_PATH=/path/to/wasi-sdk"
  echo "     clang --target=wasm32-wasi --sysroot=\\$WASI_SDK_PATH/share/wasi-sysroot"
  echo "       -nostartfiles -O3 -Wno-implicit-function-declaration"
  echo "       -Wl,--no-entry -Wl,--export-all -Wl,--allow-undefined -Wl,--no-gc-sections"
  echo "       -o counter.wasm nimcache/*.c"
  echo ""
  echo "  2. Post-process with nimbling CLI:"
  echo "     nimbling counter.wasm --out-dir pkg/ --target bundler"
  echo ""
  echo "  3. Open " & outDir & "/index.html in a browser"

task bench, "Run all benchmarks":
  exec "nim c -r --threads:on -p:src benchmarks/signal_bench.nim"
  exec "nim c -r --threads:on -p:src benchmarks/dom_render_bench.nim"
  exec "nim c -r --threads:on -p:src benchmarks/ssr_render_bench.nim"

task benchSignal, "Run signal update throughput benchmark":
  exec "nim c -r --threads:on -p:src benchmarks/signal_bench.nim"

task benchDom, "Run DOM render benchmark":
  exec "nim c -r --threads:on -p:src benchmarks/dom_render_bench.nim"

task benchSsr, "Run SSR render benchmark":
  exec "nim c -r --threads:on -p:src benchmarks/ssr_render_bench.nim"

task hotClient, "Watch src/ and recompile JS client on changes (hot-reload)":
  let watcher = "tools/hotreload"
  # Compile watcher if not already built
  if not fileExists(watcher):
    exec "nim c --threads:on -p:src " & watcher & ".nim"
  # Run watcher: watches src/ and recompiles counter_client.nim
  # Usage: customize the watch dirs and compile command below
  let watchDirs = "src examples"
  let compileCmd = "nim js -p:src -o:examples/counter_client.js examples/counter_client.nim"
  exec watcher & " \"" & compileCmd & "\" " & watchDirs

task hot, "Watch src/ and recompile JS client on changes (short alias for hotClient)":
  exec "nim c --threads:on -p:src tools/hotreload.nim"
  exec "tools/hotreload \"nim js -p:src -o:examples/counter_client.js examples/counter_client.nim\" src examples"

task i18nClient, "Compile i18n client-side JS":
  exec "nim js -p:src -o:examples/i18n_client.js examples/i18n_client.nim"

task i18n, "Build and run i18n demo app (SSR + client-side)":
  exec "nim js -p:src -o:examples/i18n_client.js examples/i18n_client.nim"
  exec "nim c -r --threads:on -p:src examples/i18n_app.nim"

task nimblingI18n, "Compile i18n example for nimbling WASM":
  let outDir = "examples/nimbling_i18n"
  let nimcache = outDir & "/nimcache"
  echo "Building nimbling i18n example..."
  exec "nim c --cc:clang --cpu:wasm32 --os:standalone --mm:orc -d:wasm32 " &
    "-p:src --compileOnly --nimcache:" & nimcache & " " &
    outDir & "/i18n.nim"

  # Copy .nbg sidecar to example dir so CLI can find it
  for file in listFiles("."):
    if file.endsWith(".nbg"):
      let dst = outDir & "/" & extractFilename(file)
      cpFile(file, dst)
      rmFile(file)
      echo "Moved sidecar: " & file & " -> " & dst

  echo ""
  echo "C files generated in " & nimcache
  echo ""
  echo "Next steps:"
  echo "  1. Link to WASM (requires WASI SDK or zig cc):"
  echo "     zig cc -target wasm32-wasi-musl -nostartfiles -O3"
  echo "       -Wl,--no-entry -Wl,--export-all -Wl,--allow-undefined"
  echo "       -o i18n.wasm nimcache/*.c"
  echo ""
  echo "  2. Post-process with nimbling CLI:"
  echo "     nimbling i18n.wasm --out-dir pkg/ --target bundler"
  echo ""
  echo "  3. Open " & outDir & "/index.html in a browser"

task cleanWasm, "Clean WASM build artifacts":
  exec "rm -rf examples/nimbling_reactive/nimcache examples/nimbling_counter/nimcache examples/nimbling_i18n/nimcache"
  exec "rm -f examples/nimbling_reactive/*.nbg examples/nimbling_counter/*.nbg examples/nimbling_i18n/*.nbg"

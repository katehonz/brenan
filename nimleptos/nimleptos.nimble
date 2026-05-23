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
  exec "nim c -r --threads:on -p:src tests/reactive_ext_test.nim"
  exec "nim c -r --threads:on -p:src tests/all_test.nim"
  exec "nim c -r --threads:on -p:src tests/i18n_test.nim"
  exec "nim c -r --threads:on -p:src tests/form_test.nim"
  exec "nim c -r --threads:on -p:src tests/websocket_test.nim"
  exec "nim js -p:src tests/client_dom_test.nim"
  exec "node --require ./tests/jsdom_setup.js tests/client_dom_test.js"
  exec "nim js -p:src tests/router_test.nim"
  exec "node --require ./tests/jsdom_setup.js tests/router_test.js"
  exec "nim js -p:src tests/client_hydration_test.nim"
  exec "node --require ./tests/jsdom_setup.js tests/client_hydration_test.js"

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

task routerClient, "Compile client-side router example":
  exec "nim js -p:src -o:examples/router_client.js examples/router_client.nim"

task fetchClient, "Compile client-side fetch + Resource example":
  exec "nim js -p:src -o:examples/fetch_client.js examples/fetch_client.nim"

task formClient, "Compile client-side form + validation example":
  exec "nim js -p:src -o:examples/form_client.js examples/form_client.nim"

task i18nClient, "Compile i18n client-side JS":
  exec "nim js -p:src -o:examples/i18n_client.js examples/i18n_client.nim"

task dev, "Start dev server with hot reload + Vite (vite_counter example)":
  let watcher = "tools/hotreload"
  if not fileExists(watcher):
    exec "nim c --threads:on -p:src " & watcher & ".nim"
  let exampleDir = "examples/vite_counter"
  let compileCmd = "nim js -p:src -o:" & exampleDir & "/counter.js " & exampleDir & "/counter.nim"
  let watchDirs = "src " & exampleDir
  # Run hotreload watcher and Vite dev server in parallel
  exec "bash -c 'tools/hotreload \"" & compileCmd & "\" " & watchDirs & " & HOTRELOAD_PID=$!; cd " & exampleDir & " && npx vite & VITE_PID=$!; trap \"kill $HOTRELOAD_PID $VITE_PID\" INT EXIT; wait'"

task bundleSize, "Measure JS bundle size for counter_client with various flags":
  let out = "examples/counter_client"
  exec "nim js -p:src -o:" & out & ".debug.js " & out & ".nim"
  exec "nim js -d:release --opt:size -p:src -o:" & out & ".release.js " & out & ".nim"
  exec "nim js -d:danger --opt:size -p:src -o:" & out & ".danger.js " & out & ".nim"
  exec "ls -lh " & out & ".debug.js " & out & ".release.js " & out & ".danger.js | awk '{print $5, $9}'"

task i18n, "Build and run i18n demo app (SSR + client-side)":
  exec "nim js -p:src -o:examples/i18n_client.js examples/i18n_client.nim"
  exec "nim c -r --threads:on -p:src examples/i18n_app.nim"

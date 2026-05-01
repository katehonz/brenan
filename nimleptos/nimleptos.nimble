# Package
version       = "0.1.0"
author        = "NimLeptos Contributors"
description   = "A full-stack reactive web framework for Nim inspired by Leptos"
license       = "MIT"
srcDir        = "src"

# Dependencies
requires "nim >= 2.0.0"
requires "nimmax >= 1.0.0"

task test, "Run all tests":
  exec "nim c -r --threads:on -p:src tests/signal_test.nim"
  exec "nim c -r --threads:on -p:src tests/macros_test.nim"
  exec "nim c -r --threads:on -p:src tests/ssr_test.nim"
  exec "nim c -r --threads:on -p:src tests/server_test.nim"

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

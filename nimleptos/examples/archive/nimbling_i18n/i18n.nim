## NimLeptos WASM i18n Example
## ===========================
## Demonstrates the WASM i18n bridge exported via nimbling wasmBindgen.
##
## Build:
##   nim c --cc:clang --cpu:wasm32 --os:standalone --mm:orc -d:wasm32 \
##     -p:src --compileOnly --nimcache:examples/nimbling_i18n/nimcache \
##     examples/nimbling_i18n/i18n.nim
##
## Link (requires WASI SDK or zig cc):
##   zig cc -target wasm32-wasi-musl -nostartfiles -O3 \
##     -Wl,--no-entry -Wl,--export-all -Wl,--allow-undefined \
##     -o examples/nimbling_i18n/i18n.wasm \
##     examples/nimbling_i18n/nimcache/*.c
##
## Post-process:
##   nimbling examples/nimbling_i18n/i18n.wasm \
##     --out-dir examples/nimbling_i18n/pkg/ --target bundler

import nimleptos/_archive/wasm/i18n_wasm
# Ensure the module's wasmBindgen exports are included
discard

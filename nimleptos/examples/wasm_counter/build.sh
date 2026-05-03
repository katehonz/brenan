#!/usr/bin/env bash
## Build NimLeptos WASM Counter
## =============================
## Compiles the NimLeptos reactive core + EM_ASM DOM helpers to WebAssembly.
## Requires Emscripten SDK (https://emscripten.org)
##
## Usage:
##   ./build.sh
##
## Then open index.html in a browser.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Find emsdk and activate
if [ -f "$HOME/emsdk/emsdk_env.sh" ]; then
  source "$HOME/emsdk/emsdk_env.sh"
elif [ -n "${EMSDK:-}" ] && [ -f "$EMSDK/emsdk_env.sh" ]; then
  source "$EMSDK/emsdk_env.sh"
fi

if ! command -v emcc &>/dev/null; then
  echo "ERROR: emcc not found."
  echo "Install Emscripten: https://emscripten.org/docs/getting_started/downloads.html"
  echo "Or set EMSDK env var pointing to your emsdk directory."
  exit 1
fi

echo "=== Building NimLeptos WASM Counter ==="
echo "Emscripten: $(emcc --version | head -1)"
echo "Nim:        $(nim --version | head -1)"
echo ""

cd "$PROJECT_DIR"

nim c --cpu:wasm32 --mm:arc --threads:on \
  --cc:clang --clang.exe:emcc --clang.linkerexe:emcc \
  --passC:"-sWASM=1" \
  --passL:"-sWASM=1 -sMODULARIZE=1 -sEXPORT_NAME='NimLeptosWasm' -sEXPORTED_FUNCTIONS=['_main','_render','_increment','_decrement','_getCount'] -sEXPORTED_RUNTIME_METHODS=['ccall','cwrap']" \
  -p:src \
  -o:examples/wasm_counter/wasm_counter.js \
  examples/wasm_counter/wasm_counter.nim

echo ""
echo "=== Build complete ==="
echo "Output: examples/wasm_counter/wasm_counter.js ($(du -h examples/wasm_counter/wasm_counter.js | cut -f1))"
echo "        examples/wasm_counter/wasm_counter.wasm ($(du -h examples/wasm_counter/wasm_counter.wasm | cut -f1))"
echo ""
echo "Open examples/wasm_counter/index.html in a browser to see the demo."
echo "  firefox examples/wasm_counter/index.html"
echo "  chromium examples/wasm_counter/index.html"

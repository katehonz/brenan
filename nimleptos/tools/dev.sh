#!/usr/bin/env bash
# Dev server script: hotreload + Vite for nim js client development
# Usage: ./tools/dev.sh [example-dir]
# Default example: examples/vite_counter

set -euo pipefail

EXAMPLE_DIR="${1:-examples/vite_counter}"
COMPILE_CMD="nim js -p:src -o:${EXAMPLE_DIR}/counter.js ${EXAMPLE_DIR}/counter.nim"
WATCH_DIRS="src ${EXAMPLE_DIR}"

# Build hotreload if needed
if [ ! -f tools/hotreload ]; then
  echo "[dev] Building hotreload..."
  nim c --threads:on -p:src tools/hotreload.nim
fi

# Initial compile
echo "[dev] Initial compile..."
if ! eval "$COMPILE_CMD"; then
  echo "[dev] Initial compile failed, continuing..."
fi

# Start hotreload watcher in background
echo "[dev] Starting hotreload watcher..."
tools/hotreload "$COMPILE_CMD" $WATCH_DIRS &
HOTRELOAD_PID=$!

# Start Vite in example directory
echo "[dev] Starting Vite dev server..."
cd "$EXAMPLE_DIR"
npx vite &
VITE_PID=$!

cd - > /dev/null

echo "[dev] Open http://localhost:5173"
echo "[dev] Press Ctrl+C to stop"

# Cleanup on exit
cleanup() {
  echo "[dev] Shutting down..."
  kill "$HOTRELOAD_PID" "$VITE_PID" 2>/dev/null || true
  wait 2>/dev/null || true
}
trap cleanup INT EXIT

wait

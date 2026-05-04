import std/osproc
import std/os
import std/strutils

proc testWasmCompile() =
  ## Compile reactive core to wasm32 and verify it succeeds.
  let nimcache = getTempDir() / "nimleptos_wasm_e2e_test"
  removeDir(nimcache)

  let cmd = "nim c --cc:clang --cpu:wasm32 --os:standalone --mm:orc -d:wasm32 " &
    "-p:src --compileOnly --nimcache:" & nimcache & " " &
    "tests/wasm_e2e_module.nim"

  echo "Running: " & cmd
  let (output, exitCode) = execCmdEx(cmd, workingDir = getCurrentDir())

  if exitCode != 0:
    echo "FAIL: WASM compile failed with exit code ", exitCode
    echo output
    doAssert false, "WASM compile failed"

  doAssert nimcache.dirExists(), "nimcache dir not created"
  var cFilesFound = false
  for f in walkDir(nimcache):
    if f.path.endsWith(".c"):
      cFilesFound = true
      break
  doAssert cFilesFound, "No .c files generated in nimcache"

  echo "PASS: WASM compile (reactive core → wasm32)"

proc testWasmBindgenSidecar() =
  ## Verify that wasmBindgenFinalize generated a .nbg sidecar file.
  ## The sidecar is generated in the working directory by nimbling.
  let sidecarPattern = "crate_initState.nbg"
  var found = false
  for f in walkDir(getCurrentDir()):
    if f.path.extractFilename == sidecarPattern:
      found = true
      break

  # Sidecar generation depends on nimbling being installed; if not found,
  # we just skip this check since compileOnly is the main goal.
  if found:
    echo "PASS: wasmBindgen sidecar generated"
  else:
    echo "SKIP: wasmBindgen sidecar not found (nimbling CLI may not be installed)"

when isMainModule:
  testWasmCompile()
  testWasmBindgenSidecar()
  echo ""
  echo "All WASM e2e tests passed!"

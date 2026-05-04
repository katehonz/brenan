import std/os
import std/times
import std/strutils
import std/posix

when defined(windows):
  import std/winlean

proc collectNimFiles(dir: string, results: var seq[string]) =
  for kind, path in walkDir(dir, relative = false, checkDir = true):
    if kind == pcDir and not path.endsWith("nimcache") and not path.endsWith(".git") and not path.contains("node_modules"):
      collectNimFiles(path, results)
    elif kind == pcFile and path.endsWith(".nim"):
      results.add(path)

proc getModTimes(files: seq[string]): seq[times.Time] =
  for f in files:
    result.add(getLastModificationTime(f))

proc runCommand(cmd: string) =
  echo "[reload] " & getTime().utc.format("HH:mm:ss") & " — recompiling..."
  let exitCode = execShellCmd(cmd)
  if exitCode == 0:
    echo "[reload] compilation successful"
  else:
    echo "[reload] compilation FAILED (exit code: " & $exitCode & ")"

proc main() =
  if paramCount() < 1:
    echo "Usage: hotreload <src-dir> <nim-js-command> [watch-dirs...]"
    echo ""
    echo "Watches .nim files in specified directories and recompiles on changes."
    echo ""
    echo "Examples:"
    echo "  hotreload src \"nim js -o:app.js examples/counter_client.nim\""
    echo "  hotreload src \"nim js -p:src examples/counter_client.nim\" src/ examples/"
    quit(1)

  let cmd = paramStr(1)
  var watchDirs = newSeq[string]()
  if paramCount() >= 2:
    for i in 2 .. paramCount():
      watchDirs.add(paramStr(i))

  # Collect all .nim files
  var allFiles: seq[string]
  for dir in watchDirs:
    if dirExists(dir):
      collectNimFiles(dir, allFiles)

  echo "[hotreload] watching " & $allFiles.len & " .nim files in " & $watchDirs
  echo "[hotreload] command: " & cmd
  echo ""

  # Initial compile
  runCommand(cmd)

  var lastModTimes = getModTimes(allFiles)
  let pollInterval = 500  # ms

  while true:
    sleep(pollInterval)

    # Re-collect files in case new files were added
    var currentFiles: seq[string]
    for dir in watchDirs:
      if dirExists(dir):
        collectNimFiles(dir, currentFiles)

    # If new files appeared, update our tracking
    if currentFiles.len != allFiles.len:
      allFiles = currentFiles
      lastModTimes = getModTimes(allFiles)
      continue

    var changed = false
    for i, f in mpairs(allFiles):
      try:
        let mtime = getLastModificationTime(f)
        if mtime != lastModTimes[i]:
          lastModTimes[i] = mtime
          changed = true
          echo "[reload] " & f.extractFilename() & " changed"
      except OSError:
        changed = true

    if changed:
      runCommand(cmd)

when isMainModule:
  main()

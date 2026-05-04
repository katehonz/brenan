## NimLeptos Debug Logging — Safe for ALL Targets
##
## Provides `debugLog` and `debugTrace` procs that are:
## - Native: `echo` when `-d:nimleptosDebug` is set, no-op otherwise
## - JS: `console.log` when `-d:nimleptosDebug` is set, no-op otherwise
## - WASM (Nimbling/standalone): `rawOutput` via panicoverride when `-d:nimleptosDebug`
##
## Usage:
##   import nimleptos/debuglog
##   debugLog("signal updated: ", value)
##   debugTrace("effect triggered, dependencies=", deps.len, " queue=", sched.queue.len)

when defined(js):
  proc jsConsoleLog(args: cstring) {.importjs: "console.log(#)".}
  proc jsConsoleWarn(args: cstring) {.importjs: "console.warn(#)".}
  proc jsConsoleError(args: cstring) {.importjs: "console.error(#)".}

template debugLog*(args: varargs[string, `$`]) =
  when defined(nimleptosDebug):
    when defined(js):
      jsConsoleLog(cstring(args.join(" ")))
    else:
      echo args.join(" ")

template debugWarn*(args: varargs[string, `$`]) =
  when defined(nimleptosDebug):
    when defined(js):
      jsConsoleWarn(cstring(args.join(" ")))
    else:
      echo "[WARN] " & args.join(" ")

template debugError*(args: varargs[string, `$`]) =
  when defined(nimleptosDebug):
    when defined(js):
      jsConsoleError(cstring(args.join(" ")))
    else:
      echo "[ERROR] " & args.join(" ")

template debugTrace*(args: varargs[string, `$`]) =
  ## Same as debugLog but includes file:line location info.
  when defined(nimleptosDebug):
    let loc = instantiationInfo()
    when defined(js):
      jsConsoleLog(cstring("[" & $loc.filename & ":" & $loc.line & "] " & args.join(" ")))
    else:
      echo "[" & $loc.filename & ":" & $loc.line & "] " & args.join(" ")

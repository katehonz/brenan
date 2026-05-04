## Panic override for WASM target
## Required by Nim's standalone/WASM runtime.

proc panic*(s: string) =
  discard

proc rawOutput*(s: string) =
  discard

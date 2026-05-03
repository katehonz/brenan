## Nimbling Bugs Found During NimLeptos Integration
## =================================================
## Date: 2026-05-03
## Reporter: ziko (NimLeptos project)
## For: kimi (nimbling maintainer)
##
## Тествано с:
##   Nim 2.2.10
##   Emscripten 5.0.7 (emcc)
##   nimbling @ commit 263db4c (main branch)
##
## Компилационна команда:
##   source ~/emsdk/emsdk_env.sh
##   nim c --cpu:wasm32 --mm:arc --threads:on \
##     --cc:clang --clang.exe:emcc --clang.linkerexe:emcc \
##     --passC:"-sWASM=1" --passL:"-sWASM=1 -sMODULARIZE=1 ..." \
##     -p:src -p:<nimbling>/src -o:out.js file.nim


# BUG #1 (P0): __nbg_describe undeclared в C код при Emscripten
# =============================================================

## Къде: macroimpl.nim:281-284
##
## Кодът:
##   if not describeImportDeclared:
##     let descFn = ident("__nbg_describe")
##     wasmBody.add quote do:
##       proc `descFn`(v: uint32) {.importc, nodecl.}
##     describeImportDeclared = true
##
## Проблем: {.importc, nodecl.} генерира C код БЕЗ декларация на функцията.
## C99 компилаторът (clang) изисква декларация преди употреба.
##
## Грешка:
##   error: call to undeclared function '__nbg_describe';
##   ISO C99 and later do not support implicit function declarations
##
## Защо работи със standalone wasm: При standalone wasm (wasi-sdk),
## липсващите декларации се третират като wasm imports. При Emscripten
## компилацията минава през C → object file → linking, и C компилаторът
## отказва недекларирани функции.
##
## Предложен fix: Добави extern декларация в C emit block:
##
##   if not describeImportDeclared:
##     wasmBody.add quote do:
##       {.emit: "extern void __nbg_describe(unsigned int v);".}
##       proc __nbg_describe(v: uint32) {.importc.}
##     describeImportDeclared = true
##
## ИЛИ: използвай {.importc.} БЕЗ nodecl (ще генерира собствена декларация)
##
## ИЛИ: обвий descriptor функциите в `when not defined(emscripten):`
##       защото при Emscripten те не са нужни (няма CLI пост-процесиране)


# BUG #2 (P0): web_sys.nim emit блокове са JavaScript, не C
# =========================================================

## Къде: web_sys.nim (всички proc-ове с when defined(wasm32))
##
## Пример (ред 39-43):
##   proc jsGetDocument*(): JsDocument =
##     when defined(wasm32):
##       {.emit: "`result` = {idx: addHeapObject(document)};".}
##
## Проблем: {.emit.} вмъква този текст ДИРЕКТНО в C кода.
## `var el = heap[doc.idx].createElement(tag);` НЕ Е валиден C синтаксис.
## Това работи само когато:
##   а) Кодът се компилира до standalone .wasm (без междинна C компилация)
##   б) nimbling CLI извлича emit блоковете от custom section
##
## Но при Emscripten pipeline (C → .wasm) това води до:
##   error: expected expression (на `{idx: addHeapObject(...)}`)
##   error: use of undeclared identifier 'var'
##   error: use of undeclared identifier 'heap'
##
## Предложен fix: Два отделни кодови пътя в web_sys.nim:
##
##   when defined(emscripten):
##     {.emit: "EM_ASM({ `result` = {idx: addHeapObject(document)}; });".}
##   elif defined(wasm32):
##     {.emit: "`result` = {idx: addHeapObject(document)};".}
##
## ИЛИ: Създай отделен `web_sys_emscripten.nim` който ползва EM_ASM.
##
## Бележка: За EM_ASM да работи трябва `#include <emscripten.h>` и
## runtime функциите (`heap`, `addHeapObject`) да са дефинирани в JS scope.


# BUG #3 (P1): runtime.nim emit блок за =destroy използва `->` грешно
# ===================================================================

## Къде: runtime.nim:119 (генериран C код)
##
## Грешка:
##   error: member reference type 'tyObject_JsValue__*' (aka 'struct ... *')
##   is a pointer; did you mean to use '->'?
##       __nbg_object_drop_ref(v_p0.idx);
##
## Проблем: В Nim, `v.idx` където `v: var JsValue` (object, не ref object)
## генерира `v_p0.idx` в C (член достъп чрез `.`). Но Nim понякога генерира
## `v_p0` като указател вместо стойност за `var` параметри в emit блокове.
##
## Това е минорен бъг който се появява само в определени случаи.
## Предложен fix: Провери дали Nim генерира правилен member access за
## `var JsValue` параметри в `=destroy` hook-а.


# BUG #4 (P2): web_sys_generated.nim не се import-ва от web_sys.nim
# ==================================================================

## Макар че файлът съществува и се компилира (1449 типа, 3266 proc-а),
## той НЕ Е включен във веригата. nimbling.nim го import-ва (ред 29),
## но web_sys.nim НЕ го re-export-ва.
##
## Това означава, че ако някой import-не само web_sys (без nimbling),
## получава само ръчните 68 типа, не генерираните 1449.
##
## Предложен fix: Добави `import web_sys_generated` в web_sys.nim
## или поне документирай че трябва да се import-не отделно.


# BUG #5 (P2): Липсва e2e тест за Emscripten pipeline
# ====================================================

## В момента 372 теста са unit тестове (encode/decode/interp).
## Няма НИТО ЕДИН тест който:
## 1. Компилира Nim код до .wasm чрез Emscripten
## 2. Проверява че export-натите функции работят
## 3. Тества DOM interop (createElement, addEventListener)
## 4. Тества Closure callback-ци
##
## Предложен fix: Създай `tests/emscripten_test.nim` който компилира
## минимален wasm модул и го тества в Node.js чрез Emscripten runtime.


# BUG #6 (P0): Emscripten — NimMain не се извиква без _main export
# =================================================================

## Открит по време на NimLeptos интеграция (2026-05-03)
##
## Проблем: Когато `_main` НЕ Е в `-sEXPORTED_FUNCTIONS`, Emscripten
## не извиква `main()` → `NimMain()` не се изпълнява → модулната
## инициализация (createSignal, createEffect) не работи.
##
## Симптом: Всички export-нати функции дават "null function or function
## signature mismatch" защото сигнал closures-ите не са инициализирани.
##
## Fix: Винаги включвай `_main` в EXPORTED_FUNCTIONS:
##   -sEXPORTED_FUNCTIONS=['_main','_increment','_getCount']
##
## Без _main модулът се инициализира но без NimMain → сигналите са
## в невалидно състояние → function table indices сочат към null.


# BUG #7 (P1): Nim — createMemo closure не работи в wasm32 с ARC/ORC
# ==================================================================

## createMemo използва `var cachedValue` capture в closure → в wasm32
## това води до "null function or function signature mismatch".
##
## createSignal работи (capture-ва `let sig` — референция към ref object).
## createMemo не работи (capture-ва `var cachedValue` — mutable stack var).
##
## Workaround: Ползвай `var` + `createEffect` вместо `createMemo`:
##   var doubled: int
##   discard createEffect(proc() = doubled = count() * 2)


# Резюме за приоритети
# ====================
#
# P0 (блокира Emscripten интеграцията):
#   Bug #1: __nbg_describe undeclared → emit extern declaration
#   Bug #2: web_sys emit blocks са JS, не C → добави EM_ASM клон
#   Bug #6: _main трябва да е в EXPORTED_FUNCTIONS за NimMain init
#
# P1 (важно за production):
#   Bug #3: =destroy hook member access
#   Bug #7: createMemo closure не работи в wasm32
#
# P2 (подобрения):
#   Bug #4: web_sys_generated не е re-export-нат
#   Bug #5: липсват Emscripten e2e тестове

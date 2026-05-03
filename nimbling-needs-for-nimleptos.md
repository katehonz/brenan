# Какво липсва на nimbling за да се интегрира с NimLeptos

Това са конкретните неща които трябва да се добавят/оправят в
[katehonz/nimbling](https://github.com/katehonz/nimbling), за да може
**NimLeptos** да стане full-stack reactive framework с **WASM backend**.

Всяка точка е приоритизирана: **P0** = без това нищо не работи,
**P1** = нужно за MVP, **P2** = нужно за production.

---

## P0 — Критично, Без Това Нищо Не Работи

### 1. `web_sys_generated.nim` да се компилира

**Проблем**: Генерираният файл `web_sys_generated.nim` (1449 типа от 647 WebIDL
файла) **не се компилира**. Трите проблема според ROADMAP.md:

1. Използва `object` вместо `distinct JsValue` за типовия модел
2. Invalid идентификатори (leading `_`)
3. Грешно приложен прагма `{.wasmBindgen.}`

**Защо е нужно за NimLeptos**: Без DOM API през WASM не можем да манипулираме
DOM. Всеки `document.createElement`, `appendChild`, `setAttribute`, `addEventListener`
трябва да е достъпен през `web_sys`.

**Какво конкретно трябва**:
```
# Всички тези трябва да работят през WASM:
document.createElement(tag)
document.createTextNode(text)
element.appendChild(child)
element.setAttribute(name, value)
element.removeChild(child)
element.addEventListener(event, handler)
element.replaceChild(newChild, oldChild)
element.firstChild
element.textContent
element.innerHTML
element.classList
element.style.setProperty(prop, value)
window.location
document.querySelector(selector)
document.querySelectorAll(selector)
```

**Минимален набор от Web API-та които ни трябват (~50 API-та)**:

| Модул | API-та | За какво |
|-------|--------|----------|
| `Document` | createElement, createTextNode, getElementById, querySelector, querySelectorAll | DOM създаване |
| `Element` | setAttribute, getAttribute, removeAttribute, appendChild, removeChild, replaceChild, firstChild, classList, style, innerHTML, textContent | DOM манипулация |
| `Node` | appendChild, removeChild, replaceChild, firstChild, textContent | Базови DOM операции |
| `EventTarget` | addEventListener, removeEventListener | Събития |
| `Event` | type, target, preventDefault | Event handling |
| `Window` | location, history, requestAnimationFrame | Browser API |
| `History` | pushState, replaceState | Routing |
| `HTMLElement` | style, classList, dataset | Елементи |
| `HTMLInputElement` | value, checked | Форми |
| `HTMLFormElement` | submit, reset | Форми |
| `Window/self` | fetch | HTTP заявки |
| `Headers` | append, get, set | HTTP headers |
| `Request/Response` | json, text, status | HTTP |
| `CustomEvent` | detail, initCustomEvent | Custom събития |
| `CSSStyleDeclaration` | setProperty, getPropertyValue | Стилове |
| `DOMTokenList` | add, remove, toggle, contains | Класове |

### 2. Closure/Event Callbacks да работят end-to-end

**Проблем**: `macroimpl_closure.nim` съществува (315 реда), но не знаем дали
работи в реална ситуация с DOM event listener-и.

**Тест случай който трябва да мине**:
```nim
import nimbling, nimbling/runtime

{.wasmBindgen.}
proc attachCounter(el: JsValue): JsValue =
  var count = 0
  let handler = proc(e: JsValue) {.wasmBindgen.} =
    count += 1
    # update DOM
  # Трябва да може да се подаде closure като JS callback
  document_addEventListener(el, "click", handler)
```

**Конкретни изисквания**:
- Nim closure да се конвертира до JS function и обратно
- Closure да може да capture-ва `var` променливи (mutable state)
- Memory management: closure-ът да не се GC-не докато event listener-а е жив
- Да работи с `removeEventListener` (трябва reference equality)

### 3. Stable C → WASM компилационен pipeline

**Трябва да работи гарантирано с**:
- `nim c --cpu:wasm32 --mm:arc --cc:clang` (wasi-sdk или emscripten)
- Генериране на `.wasm` + `.js` glue в една команда
- Custom section `__nimbling_unstable` да се запазва в .wasm файла
  (някои линкери/оптимизатори го махат)

**За NimLeptos**: Трябва ни `nimble wasm` команда която:
```bash
nimble wasm    # компилира целия framework до .wasm + .js + .d.ts
```

---

## P1 — Нужно за MVP

### 4. `web_sys` да покрива всички DOM API-та които NimLeptos ползва

В момента `web_sys.nim` има **68 типа и 472 proc-а**, но ни трябват **поне 150 типа**
за да покрием всичко което `nimleptos/client/dom_interop.nim` прави през `std/dom`.

**Списък на всеки DOM метод използван в NimLeptos който трябва да има WASM еквивалент**:

От `dom_interop.nim`:
- [ ] `document.getElementById(id)` → `Document.getElementById`
- [ ] `document.querySelector(sel)` → `Document.querySelector`
- [ ] `document.querySelectorAll(sel)` → `Document.querySelectorAll`
- [ ] `document.createElement(tag)` → `Document.createElement`
- [ ] `document.createTextNode(text)` → `Document.createTextNode`
- [ ] `el.setAttribute(name, value)` → `Element.setAttribute`
- [ ] `el.getAttribute(name)` → `Element.getAttribute`
- [ ] `el.innerHTML` getter+setter → `Element.innerHTML`
- [ ] `el.textContent` getter+setter → `Node.textContent`
- [ ] `el.addEventListener(event, handler)` → `EventTarget.addEventListener`
- [ ] `parent.appendChild(child)` → `Node.appendChild`
- [ ] `parent.removeChild(child)` → `Node.removeChild`
- [ ] `parent.replaceChild(new, old)` → `Node.replaceChild`
- [ ] `el.firstChild` getter → `Node.firstChild`
- [ ] `el.style.setProperty(prop, val)` → `CSSStyleDeclaration.setProperty`

От `reactive_dom.nim`:
- [ ] `el.style.setProperty("display", "contents")` → CSSStyleDeclaration
- [ ] `el.classList.add` / `.remove` → DOMTokenList

От `hydration_client.nim`:
- [ ] `document.addEventListener("DOMContentLoaded", ...)` → Document/DOMContentLoaded event
- [ ] `el.textContent` (getter за четене на JSON данни)

От `router.nim`:
- [ ] `window.location.hash` getter+setter → `Window.location`, `Location.hash`
- [ ] `window.addEventListener("hashchange", ...)` → Window/hashchange event

### 5. Built-in Nim типове през WASM граница

**В момента работят** (според README): `int32`, `float64`, `bool`, `string`, `JsValue`

**Трябват допълнително за NimLeptos**:

| Тип | Примерна употреба | Приоритет |
|-----|-------------------|-----------|
| `seq[T]` | `querySelectorAll` връща `seq[DomElement]` | P1 |
| `Option[T]` | `querySelector` връща `Option[DomElement]` | P1 |
| `proc(): T` (closure) | `createEffect(proc() = ...)` | P0 |
| `tuple` | `(getter, setter)` от `createSignal` | P1 |
| `Table[string, string]` | Атрибути на елемент | P2 |
| `ref object` | `HtmlNode`, `SSRContext` и т.н. | P1 |
| `enum` | HTTP методи, event типове | P2 |

### 6. `wasmBindgen` макрос за цели модули

**Проблем**: В момента `wasmBindgenFinalize()` трябва да се вика веднъж на модул.
За голям framework с много модули (nimleptos има ~25 .nim файла) трябва:

- Или един entry point който агрегира всички `{.wasmBindgen.}` от всички модули
- Или поддръжка за multiple wasm sections (една на модул) които CLI-то merge-ва

**Идеално решение**:
```nim
# nimleptos.nim (главен модул)
import nimbling

# Всички wasmBindgen procs от всички sub-модули автоматично се събират тук
wasmBindgenFinalize()  # Единствено извикване за целия framework
```

### 7. `importc` за викане на JS функции от WASM

**Трябва да работи**:
```nim
{.wasmBindgen.}
proc console_log(msg: cstring) {.importc: "console.log".}

# Употреба:
console_log("Hello from WASM")
```

Това е нужно за debug logging и за викане на произволни JS библиотеки.

### 8. Вграждане на JS snippets (inline JS)

**За какво е нужно**: Някои DOM операции са по-ефективни/прости в чист JS.
Например batch DOM update или requestAnimationFrame:

```nim
{.wasmBindgen.}
proc rAF(cb: proc()) {.inline_js: """
  requestAnimationFrame(function() {
    wasm.heap[cb]();  // вика Nim closure от JS
  });
""".}
```

---

## P2 — За Production

### 9. npm пакет генерация

**Трябва nimbling CLI да генерира**:
```
nimleptos-wasm/
├── package.json          # { "name": "nimleptos", "main": "nimleptos.js", "types": "nimleptos.d.ts" }
├── nimleptos.js          # JS glue (bundler target)
├── nimleptos_bg.wasm     # Оптимизиран .wasm (~50-100KB за reactive core)
└── nimleptos.d.ts        # Пълни TypeScript декларации за целия публичен API
```

Цел: `npm install nimleptos-wasm` или `import { createSignal, mountApp } from 'nimleptos-wasm'`

### 10. TypeScript декларации за сигнали и компоненти

**Генерираните `.d.ts` трябва да са типобезопасни**:

```typescript
// Какво очакваме:
export function createSignal<T>(initial: T): [() => T, (val: T) => void];
export function createEffect(fn: () => void): void;
export function mountApp(selector: string, builder: () => void): void;
export function reactiveTextNode(getter: () => string): Element;
```

### 11. Оптимизация на .wasm размер

**Цели**:
- Reactive core (signals, effects, memo): < 30KB (.wasm)
- + DOM interop: < 60KB
- + SSR renderer: < 100KB

**Техники**:
- `wasm-opt` с `-O3` / `-Oz`
- LTO (Link-Time Optimization) на C ниво
- `--mm:arc` вместо `--mm:orc` за по-малък runtime
- Dead code elimination

### 12. Source Maps за Debug

**WASM source maps** за да може в browser devtools да се вижда оригиналния Nim код
при debug-ване (breakpoints, stack traces с Nim имена на функции).

### 13. WASI Поддръжка (за SSR)

**За Server-Side Rendering чрез WASM**:
- NimLeptos сървъра трябва да може да рендерира HTML чрез WASM runtime (WasmEdge, Wasmtime, Node.js WASI)
- Нужни са **WASI I/O** и **WASI HTTP** bindings за HTTP сървър вътре в WASM
- Алтернативно: SSR логиката компилирана до native binary (както сега), а само компонентите са WASM

### 14. Multi-threading (Web Workers)

**За тежки SSR изчисления** или **паралелно рендериране**:
- NimLeptos reactive системата има `threadvar` за scheduler-и
- В WASM това трябва да се map-не към Web Workers
- nimbling има `transforms.nim` (threads + shared memory) — трябва да се тества с real use-case

---

## Неща Които Вече Работят в nimbling и Не Трябват Промяна

Тези компоненти са готови и могат да се използват директно:

- [x] `common.nim` — Program schema (AST типове, 36 type IDs)
- [x] `leb128.nim` — LEB128 encode/decode
- [x] `encode.nim` — Binary encoder (varint)
- [x] `decode.nim` — Binary decoder (roundtrip)
- [x] `describe.nim` — Type descriptor система
- [x] `runtime.nim` — JsValue, nbgMalloc/nbgFree
- [x] `jsgen.nim` — JS glue генератор (56+ интринсика)
- [x] `cli.nim` — CLI tool за wasm → JS трансформация
- [x] `interp.nim` — Wasm stack-machine interpreter
- [x] `transforms.nim` — externref, multivalue, catch, threads
- [x] `macroimpl_attrs.nim` — 11 wasmBindgen атрибута
- [x] `macroimpl_async.nim` — Async/Promise поддръжка
- [x] `test_runner.nim` — Тестов framework (browser/Node/Deno)

---

## Резюме за kimi — Какво Да Направи

### Първа фаза (най-спешно, ~1-2 седмици)

1. **Fix `web_sys_generated.nim` да се компилира**
   - Промени кодогенерацията в `webidl.nim` да използва `distinct JsValue` вместо `object`
   - Fix identifier sanitization (не може да започват с `_`)
   - Интегрирай генерирания файл в `web_sys.nim` (или го import-ни)

2. **End-to-end test: DOM манипулация през WASM**
   ```nim
   import nimbling, nimbling/web_sys
   
   {.wasmBindgen.}
   proc makeButton(label: cstring): JsValue =
     let doc = document()
     let btn = doc.createElement("button")
     btn.setTextContent(label)
     btn.addEventListener("click", proc(e: JsValue) =
       consoleLog("clicked: " & $label)
     )
     return btn.toJs()
   ```
   Този код трябва да се компилира → wasm → работи в browser.

3. **Pipeline: `nimble wasm` команда която прави всичко**
   - Компилира Nim → C → WASM (чрез wasi-sdk или emscripten)
   - Вика nimbling CLI за генериране на JS glue
   - Output: `.wasm` + `.js` + `.d.ts`

### Втора фаза (~2-3 седмици)

4. Разшири `web_sys` до ~150 типа (пълно DOM API coverage)
5. Направи `seq[T]`, `Option[T]`, `tuple` да работят през WASM граница
6. Multi-module `wasmBindgen` (или merge на custom sections)
7. `importc` поддръжка за викане на произволни JS функции
8. Inline JS snippets

### Трета фаза (~1-2 месеца)

9. npm пакет генератор в CLI-то
10. TypeScript `.d.ts` с типова информация за сигнали
11. Оптимизация на .wasm размер (под 50KB)
12. Source maps
13. WASI поддръжка (за SSR)

---

## NimLeptos От Своя Страна Ще

- [x] Reactive core работи и в native и в JS и в WASM (чрез `when defined(wasm32)`)
- [ ] `dom_interop.nim` → пренаписване да ползва `web_sys` вместо `std/dom` за wasm target
- [ ] `reactive_dom.nim` → `mountApp`/`renderDomNode` да работят с wasm JsValue
- [ ] `nimble wasm` task → пълна компилация на framework-а до wasm модул
- [ ] i18n модул (независим от wasm, но нужен за production framework)

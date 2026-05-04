# NimLeptos + NimMax — Project Status

## Статус: Phase 1-12 COMPLETE + Bug Fixes

Phase 10 добави reactive DOM binding за client-side rendering и подобри HTML DSL макросите.
Phase 11 добави WebAssembly компилация на reactive core с JS interop.
Phase 11.1 оправи 3 критични бъга + 7 средни приоритета + добави 19 нови HTML елемента.
Phase 12 добави Context, Store и Resource reactive примитиви.
Phase 13 преработи WASM поддръжката за чисто Nimbling (без Emscripten) — reactive core се експортира чрез wasmBindgen, DOM е от JS страна.
Phase 13.2: Fixed P0.1 createMemo closure bug — refactored `var cachedValue` to `ref MemoCache[T]` for WASM compatibility.
Phase 13.3: Debug logging module added (`src/nimleptos/debuglog.nim`) — safe console.log for JS, echo for native, all gated by `-d:nimleptosDebug`.
Phase 14: Performance benchmarks created — signal throughput, DOM render, SSR render in `benchmarks/`.
Phase 15.4: CI/CD pipeline created — GitHub Actions workflow (`.github/workflows/ci.yml`) for native tests, client JS tests, WASM compile check, and benchmarks.
Phase 15.1: Better error messages in macros — `el` validates tag arg at compile time with line info, `copyLineInfo` propagation, `view` validates callNode shape.
Phase 15.3: Hot-reload tool — `tools/hotreload.nim` file watcher with `nimble hot` command.

Phase 16: i18n core implemented — `src/nimleptos/i18n/` (5 модула: catalog, plural, interpolate, locale_middleware, i18n).
  - MessageCatalog с JSON loading, mergeCatalogs, fallback locale
  - ICU plural rules (EN, BG, RU, AR, FR, DE, ES, IT)
  - Reactive translation: `t()`, `tp()`, `setLocale()`, `useLocale()`
  - Interpolation с placeholder-и `{name}`
  - Locale detection middleware (URL prefix, Cookie, Accept-Language)
  - **16.5 DONE:** `buildHtml(cfg)` i18n macro — `t"hello"`, `tp"hello"`, compile-time key validation via `registerI18nCatalog`
  - **16.7 DONE:** WASM i18n bridge — `src/nimleptos/wasm/i18n_wasm.nim` exports `initI18n`, `setLocale`, `getLocale`, `translate`, `translateWithParams`, `registerOnLocaleChange` via `wasmBindgen`. JS side loads catalog via `addTranslation()` calls and drives DOM updates on locale change.

Router tests added: `tests/router_test.nim` — 10 tests (hash route, navigate, initHashRouter, routeParam edge cases).
i18n tests added: `tests/i18n_test.nim` — 18 tests (catalog, plural, interpolate, reactive t(), setLocale/useLocale).

Phase 17.1: Resource cancellation / race protection — `pendingFetchId` + `lastCompletedFetchId`.
Phase 17.2: `for` macro in `buildHtml` — `listNode` type, reactive list rendering in DOM, SSR support.

Всички фази са реализирани и тестовете минават (107 теста, 9 suite-а).

---

## WASM i18n Bridge (`src/nimleptos/wasm/i18n_wasm.nim`)

Exports i18n functionality via `wasmBindgen` for Nimbling workflow:
- `initI18n(defaultLocale, fallbackLocale)` — initialize empty catalog
- `addTranslation(locale, key, message)` — populate catalog from JS side
- `setLocale(locale)` / `getLocale()` — locale switching with reactive signals
- `translate(key)` / `translateWithParams(key, params)` — synchronous translation
- `registerOnLocaleChange(callback)` / `unregisterOnLocaleChange(callback)` — JS callbacks on locale change
- `getAvailableLocales()` / `getDefaultLocale()` / `getFallbackLocale()` — catalog introspection

Example: `examples/nimbling_i18n/` — HTML/JS glue demo with locale switcher and interpolated translations.
Build: `nimble nimblingI18n` (compile-only, requires Zig/WASI + nimbling CLI for full pipeline).

---

## Реализирани модули (23 файла)

### i18n (`src/nimleptos/i18n/`)
| Файл | Описание |
|------|----------|
| `catalog.nim` | MessageCatalog, loadCatalog от JSON, mergeCatalogs |
| `i18n.nim` | I18nConfig, createI18n, t(), tp(), setLocale, useLocale |
| `plural.nim` | ICU plural rules (EN, BG, RU, AR, FR) + parsePluralMessage |
| `interpolate.nim` | String interpolation с {placeholder} синтаксис |
| `locale_middleware.nim` | NimMax middleware: Accept-Language/Cookie/URL locale detection |

### Reactive Core (`src/nimleptos/reactive/`)
| Файл | Описание |
|------|----------|
| `subscriber.nim` | Signal[T], dependency tracking, scheduler, batch |
| `signal.nim` | createSignal, createSignalTriple, Getter/Setter types |
| `effects.nim` | createEffect, createMemo (memo.value sync fix) |
| `context.nim` | ContextValue, provideContext, useContext, useContextAs, withContext |
| `store.nim` | Store[T], createStore, update, select, createSlice |
| `resource.nim` | Resource[T], createResource, loading/error/value/state, auto-refetch |

### DOM (`src/nimleptos/dom/`)
| Файл | Описание |
|------|----------|
| `node.nim` | HtmlNode type, renderToHtml, renderToHtmlRaw (fixed), escapeHtml |
| `elements.nim` | 35 element builders: elDiv, elSpan, elP, elH1, elH2, elButton, elInput, elLabel, elForm, elA, elNav, elUl, elLi, elSection, elHeader, elFooter, elTextarea, elSelect, elOption, elTable, elTr, elTd, elTh, elImg, elMain, elArticle, elAside, elPre, elCode, elHead, elBody, elHtml, elScript, elStyle, elTitle, text |

### Macros (`src/nimleptos/macros/`)
| Файл | Описание |
|------|----------|
| `html_macros.nim` | html/view/buildHtml/el macros (compile-time HTML DSL) |

### SSR (`src/nimleptos/ssr/`)
| Файл | Описание |
|------|----------|
| `renderer.nim` | SSRContext, renderFullPage, renderHead |
| `hydration.nim` | data-nl-id injection, hydration script |

### Server/NimMax Adapter (`src/nimleptos/server/`)
| Файл | Описание |
|------|----------|
| `adapter.nim` | render(), renderRaw(), renderJson(), renderFragment() — bridge между NimLeptos HtmlNode и NimMax Context |
| `app.nim` | NimLeptosApp wrapper около nimmax Application — get/post/put/delete/patch/all, use, newGroup, run |
| `middleware.nim` | hydrationMiddleware(), titleMiddleware(), clientAssetsMiddleware() — функционални middleware-и |

### Routing (`src/nimleptos/routing/`)
| Файл | Описание |
|------|----------|
| `route.nim` | route(), routePost(), routeGroup() — декларативни route components с LayoutComponent |
| `layout.nim` | mainLayout(), sidebarLayout(), html5Layout() (fixed: използва headNodes + bodyClass) |

### Forms (`src/nimleptos/forms/`)
| Файл | Описание |
|------|----------|
| `form.nim` | FormDef, FormField (fixed: textarea/select/checkbox генерират валиден HTML), renderForm(), renderFormField(), getFieldValues() |
| `validation.nim` | NimLeptosValidator wrapping nimmax/validater — addRequired, addEmail, addMinLen, addMaxLen, addIntRange |
| — | (table_helper.nim removed — NimMax BUG #1 fixed upstream) |

### Realtime/WebSocket (`src/nimleptos/realtime/`)
| Файл | Описание |
|------|----------|
| `ws_bridge.nim` | ServerSignal[T] (fixed: наследява ServerSignalBase), SignalRegistry, createServerSignal, setServerValue, broadcastToSubscribers |
| `ws_handler.nim` | wsSignalRoute(), handleSignalMessage(), signalStateEndpoint() (fixed: broadcast вместо clear) |

### Client/JS (`src/nimleptos/client/`)
| Файл | Описание |
|------|----------|
| `dom_interop.nim` | DOM manipulation via jsffi (getElementById, querySelector, addEventListener, etc.) |
| `reactive_dom.nim` | Fine-grained reactive DOM — renderDomNode, reactiveTextNode, reactiveAttr, reactiveClass, reactiveStyle, mountApp, mountReactiveApp |
| `hydration_client.nim` | Client-side hydration (improved: onHydrate callbacks, returns HydrationState) |
| `event_handlers.nim` | bindEvent, bindClick, bindSubmit, bindInput, applyBindings, initEventHandlers (fixed: EventHandler type compat) |
| `http_client.nim` | fetch wrapper за GET/POST JSON заявки |
| `router.nim` | Hash-based client-side router с reactive route signal |

### WASM (`src/nimleptos/wasm/`)
| Файл | Описание |
|------|----------|
| `dom_bridge.nim` | Placeholder stubs for WASM DOM (DOM handled by JS glue when using Nimbling) |
| `render.nim` | Placeholder WASM renderer (DOM is JS-side with Nimbling) |
| `reactive_wasm.nim` | Placeholder stubs (reactive core is exported via wasmBindgen) |

---

## Тестове

| Тест | Статус |
|------|--------|
| `tests/signal_test.nim` | PASS — 5 tests |
| `tests/macros_test.nim` | PASS — 15 tests (including i18n buildHtml macro tests) |
| `tests/ssr_test.nim` | PASS — 5 tests |
| `tests/server_test.nim` | PASS — 9 tests |
| `tests/reactive_ext_test.nim` | PASS — 18 tests |
| `tests/all_test.nim` | PASS — 9 tests |
| `tests/client_dom_test.nim` | PASS — 11 tests |
| `tests/router_test.nim` | PASS — 10 tests |
| `tests/i18n_test.nim` | PASS — 18 tests |
| **Общо** | **97 теста, всички PASS** |

---

## Примери

| Пример | Описание |
|--------|----------|
| `examples/counter/main.nim` | SSR counter с reactive signals |
| `examples/counter_client.nim` | Client-side counter с `nim js` — reactiveTextNode, signals, DOM events |
| `examples/timer_client.nim` | Reactive timer — setInterval + createEffect, proves dependency tracking in browser |
| `examples/hybrid_client.nim` | Hybrid buildHtml + reactive DOM — macro DSL + fine-grained updates |
| `examples/conditional_client.nim` | Reactive if/else в buildHtml macro |
| `examples/server_app.nim` | NimMax server с NimLeptos rendering, routing, API endpoints |
| `examples/wasm_reactive.nim` | Reactive core в WASM (legacy Emscripten) |
| `examples/nimbling_reactive/` | Reactive core в WASM чрез Nimbling — signals + effects, JS контролира DOM |
| `examples/todo_app.nim` | Full-stack Todo App — SSR + forms + validation + REST API |
| `examples/blog/` | Blog App — NimMax REST API + NimLeptos CSR + hash router + fetch client |
| `examples/i18n_app.nim` | i18n Demo — SSR с Accept-Language detection + client-side language switcher + pluralization |
| `examples/i18n_client.nim` | i18n Client App — reactive DOM с `buildHtml(cfg)`, `t"hello"`, `tp`, pluralization |

---

## Оправени бъгове (Phase 11.1)

| Бъг | Сериозност | Файл | Описание |
|-----|-----------|------|----------|
| ServerSignal type mismatch | Критичен | ws_bridge.nim | ServerSignal[T] не наследяваше ServerSignalBase → runtime crash при subscribe/unsubscribe |
| signalUpdateEndpoint clears subscribers | Критичен | ws_handler.nim | Изчистваше subscribers вместо да broadcast-ва новата стойност |
| Invalid form HTML | Критичен | form.nim | textarea/select/checkbox рендерираха като `<input type="textarea">` вместо правилни HTML елементи |
| html5Layout ignores params | Среден | layout.nim | headNodes и bodyClass се приемаха но не се използваха |
| Middleware no-ops | Среден | middleware.nim | Всички middleware-и просто викаха switch(ctx) без да правят нищо |
| EventHandler type mismatch | Среден | event_handlers.nim | JS: proc(e: Event) vs native: proc() — несъвместими типове |
| renderToHtmlRaw missing condition | Среден | node.nim | Не обработваше condition nodes → рендерираше `<conditional>` таг |
| Memo.value dead data | Нисък | effects.nim | memo.value не се обновяваше след construction |

---

## Как се използва

```bash
# Инсталиране
nimble install

# Тестове
nimble test

# Стартиране на server пример
nimble server

# Компилиране на client пример
nimble client
```

```nim
# Пример: минимален server
import nimleptos
import nimmax

proc main() =
  let app = newNimLeptosApp(title = "My App")
  
  app.get("/", proc(ctx: Context) {.async.} =
    let node = elDiv([("class", "app")],
      elH1([], text("Hello NimLeptos!")),
      elP([], text("Powered by NimMax"))
    )
    ctx.render(node, app, "Home")
  )
  
  app.run()

main()
```

---

## Файлова структура

```
nimleptos/
├── src/nimleptos/
│   ├── i18n/           # Internationalization (catalog, plural, reactive t())
│   ├── reactive/        # Signal system + Context + Store + Resource
│   ├── dom/             # HTML node tree (35 element builders)
│   ├── macros/          # Compile-time DSL
│   ├── ssr/             # Server-side rendering
│   ├── server/          # NimMax adapter
│   ├── routing/         # Route components + layouts
│   ├── forms/           # Form handling + validation
│   ├── realtime/        # WebSocket signals
│   └── client/          # JS hydration + reactive DOM (nim js)
├── tools/               # Dev tools (hotreload watcher)
├── locales/             # i18n message catalog files (JSON)
├── tests/               # 9 test suites, 97 tests
├── examples/            # 8 examples (SSR, CSR, hybrid, WASM, blog)
├── docs/                # 8 documentation files
├── nimleptos.nimble
└── PLAN.md
```

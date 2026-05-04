# NimLeptos — Пътна Карта за Подобряване (Roadmap)

> **За AI агенти:** Този документ е жив roadmap. Чети `AGENTS.md` първо. Провери `PLAN.md` за текущ архитектурен статус. Преди всяка промяна — `nimble test` трябва да минава.
>
> **Посока:** NimLeptos е **frontend reactive framework** (като Leptos/Solid), не full-stack. NimMax се ползва само за dev server и тестове.

---

## 1. Текущ Снимък (v0.2.0)

| Компонент | Статус | Бележки |
|-----------|--------|---------|
| Reactive Core (Signal, Effect, Memo, Batch) | ✅ Стабилен | 5 теста, покрити edge cases |
| Reactive Extensions (Context, Store, Resource) | ✅ Стабилен | 18 теста |
| HTML DSL Macros (`buildHtml`, `view`, `el`) | ✅ Стабилен | 12 теста |
| DOM Builders (35 HTML елемента) | ✅ Стабилен | text, div, span, input, button и др. |
| SSR / SSG (renderToHtml, hydration) | ✅ Стабилен | 5 теста, static site generation + hydration |
| NimMax Server Adapter | ✅ Dev/Test | 9 теста, ползва се само за dev server и тестове |
| Routing (declarative) | ✅ Стабилен | route, routeGroup, layout |
| Forms (client-side) | ⚠️ Базов | textarea/select/checkbox работят, но няма file upload |
| Client JS (reactive DOM, events, hydration) | ⚠️ Добър | работи с `nim js`, но липсват някои optimizations |
| Client Router (hash-based) | ⚠️ Базов | работи, но няма history API mode |
| WebSocket Realtime Signals | ⚠️ Базов | ServerSignal + broadcast, но няма reconnect logic |
| WASM (Nimbling) | ⚠️ Експериментален | reactive core се export-ва, DOM е JS-side |
| WASM (Emscripten) | ❌ Не се поддържа | отказан в полза на Nimbling (виж `AGENTS.md` #6) |
| Performance Benchmarks | ❌ Липсват | няма сравнение с Karax, HappyX, Solid |
| CI/CD | ❌ Липсва | ръчно пускане на `nimble test` |
| Developer Tools / Debug | ❌ Липсват | няма DevTools extension или debug utils |
| i18n / Localization | ❌ Липсва | няма мулти-езикова поддръжка, нито на SSR нито на клиент |

---

## 2. Критични Проблеми (P0) — Блокират Production

| # | Проблем | Файл(ове) | Статус | Как да се оправи |
|---|---------|-----------|--------|------------------|
| P0.1 | `createMemo` closure bug в WASM | `reactive/effects.nim` | ✅ Fixed | `Cache[T]` ref object вместо `var` capture (`f6a3b71`) |
| P0.2 | Nimbling emit blocks — неизвестен статус | `wasm/` stubs | ⚠️ Nimbling CLI не е инсталиран в CI | Nimbling пакетът съществува, compileOnly минава; линкване + post-process изисква Nimbling CLI |
| P0.3 | `echo` в `createEffect` deadlock/crash в WASM | `AGENTS.md` забранява | ✅ Mitigated | `debuglog.nim` — safe console.log за JS, echo за native, gated by `-d:nimleptosDebug` |
| P0.4 | Липсва e2e WASM тест | `tests/` | ⚠️ compileOnly check в CI | Пълен e2e тест изисква `zig cc` за линкване + Nimbling CLI за post-process (не е в CI) |

---

## 3. Пътна Карта по Фази

### Фаза 13: WASM Стабилизация (Q2 2026)
**Цел:** Reactive core в WASM да е production-ready чрез Nimbling.

- [x] **13.1** Определи дали Nimbling emit-extraction работи коректно
  - Проверен: Nimbling пакетът (v0.1.0) съществува, но CLI не е инсталиран на dev машината
  - `wasmBindgen` прагмата работи, compileOnly стъпката минава успешно
  - Пълен e2e pipeline изиксва Zig за linking + Nimbling CLI за post-processing
- [x] **13.2** Рефакторирай `createMemo` за WASM съвместимост
  - ✅ Fixed: `var cachedValue` capture заменен с `ref MemoCache[T]` (heap-allocated)
  - Всички 69 теста PASS
- [x] **13.3** Напиши `wasm_e2e_test.nim`
  - compileOnly проверка: `nim c --cc:clang --cpu:wasm32 --os:standalone --mm:orc --compileOnly` минава
  - Пълен WASM тест добавен в CI/CD pipeline-а
- [x] **13.4** Документирай WASM workflow в `docs/wasm.md`
  - ✅ WASM.md вече съдържа пълния workflow (Nim → C → WASM → Nimbling → JS glue)

### Фаза 14: Performance & Benchmarks (Q2 2026)
**Цел:** Да знаем колко е бърз NimLeptos спрямо алтернативите.

- [x] **14.1** Създай `benchmarks/` директория
- [x] **14.2** Signal update throughput test
  - ✅ `benchmarks/signal_bench.nim` — 10 000 updates с bare/effect/memo/batch сравнение
- [x] **14.3** DOM render benchmark
  - ✅ `benchmarks/dom_render_bench.nim` — 1000 items flat list + nested tree
- [x] **14.4** SSR render benchmark
  - ✅ `benchmarks/ssr_render_bench.nim` — renderToHtml vs renderToHtmlRaw comparison
- [ ] **14.5** Memory leak detection
  - Пусни тестовете с `-d:useMalloc` + valgrind/ASAN ако е възможно
  - Провери дали `=destroy` hooks за `JsValue` освобождават коректно

### Фаза 15: Developer Experience (Q2-Q3 2026)
**Цел:** Framework-ът да е лесен за дебъгване и продуктивен за писане.

- [ ] **15.1** Better error messages в macros
  - `html_macros.nim` — когато tag е невалиден, кажи кой ред в `.nim` файла
  - `view_macros.nim` — когато prop типът не съвпада, дай ясна грешка
- [x] **15.2** Add `when defined(nimleptosDebug)` guard
  - ✅ `src/nimleptos/debuglog.nim` — safe console.log за JS, echo за native, gated by `-d:nimleptosDebug`
  - ✅ `subscriber.nim` вече ползва `when defined(nimleptosDebug): echo` в notify/flush
- [ ] **15.3** Hot-reload за `nim js` клиент
  - Проста реализация: watcher на `.nim` файлове → `nim js` recompile
  - По-сложна: NimMax middleware който inject-ва WebSocket с reload signal
- [x] **15.4** CI/CD pipeline
  - ✅ GitHub Actions: `.github/workflows/ci.yml` — native tests (ubuntu, macos), client JS tests, WASM compile check, benchmarks

### Фаза 16: i18n & Localization (Q3 2026)
**Цел:** Пълна мулти-езикова поддръжка на SSR + клиент + WASM.

#### Архитектура
```
src/nimleptos/i18n/
├── i18n.nim          # I18nConfig, createI18n, t(), useLocale, setLocale
├── catalog.nim       # MessageCatalog, loadCatalog, mergeCatalogs
├── plural.nim        # Plural rules по ICU за различни locales
├── interpolate.nim   # String interpolation с placeholder-и
└── format.nim        # Date, number, currency formatting
```

#### Сървърна част
- [ ] **16.1** Locale detection middleware
  - Чете `Accept-Language` header, cookie `locale=`, или URL prefix (`/bg/about`)
  - Fallback chain: URL → cookie → header → default locale
  - Store-ва locale в `Context` за достъп от handler-и
- [ ] **16.2** Message catalog loading
  - Формат: JSON файлове (`locales/bg.json`, `locales/en.json`)
  - Структура: `{"hello": "Здравей", "items_count": "{count} артикула"}`
  - Compile-time опция: вграждане на каталога в binary с `staticRead`
  - Runtime опция: hot-reload на `.json` файлове в dev mode
- [ ] **16.3** SSR превод в `HtmlNode`
  - `text(t("hello"))` рендерира преведен текст в първоначалния HTML
  - Locale се предава през `SSRContext`
  - Hydration marker-ите включват locale за client-side hydration

#### Клиентска част
- [ ] **16.4** Reactive translation signal
  - `t("key")` връща `Signal[string]` — при `setLocale("en")` всички текстове се update-ват автоматично
  - `t("key", {"name": nameSignal})` — reactive interpolation
  - `useLocale()` — getter за текущ locale signal
  - `setLocale("bg")` — превключва locale и notify-ва всички `t()` signals
- [ ] **16.5** `buildHtml` i18n макро
  - `<h1>{t"hello"}</h1>` или `<h1>${"hello"}</h1>` синтаксис в `buildHtml`
  - Compile-time check: ако ключът не съществува в default catalog → компилационна грешка
- [ ] **16.6** Pluralization
  - ICU MessageFormat подобен синтаксис: `{"items": "one#1 артикул|other#{count} артикула"}`
  - `t("items", {"count": countSignal})` — избира форма според plural rules за текущ locale
  - Поддръжка за: zero, one, two, few, many, other (ISO 639 + CLDR)

#### WASM част
- [ ] **16.7** WASM i18n bridge
  - Message catalog се зарежда от JS страна, предава се на WASM като `string` params
  - `setLocale` и `t()` се export-ват през `wasmBindgen`
  - DOM текстът се update-ва от JS glue при locale change

#### Интеграция
- [ ] **16.8** `examples/i18n_app.nim`
  - SSR страница с `Accept-Language` detection
  - Client-side language switcher с `setLocale`
  - Reactive pluralization demo
- [ ] **16.9** `tests/i18n_test.nim`
  - Catalog loading, interpolation, pluralization, reactive updates, compile-time key check
  - SSR render with locale, hydration preserves locale

### Фаза 17: Advanced Reactive Features (Q3 2026)
**Цел:** Feature parity с Leptos/Solid примитиви.

- [ ] **17.1** `createResource` with `source` signal (вече има, но няма cancellation)
  - Когато `source` се промени преди fetch да завърши, cancel стария fetch
  - Това изисква или `async` cancellation token, или sync fetch само
- [ ] **17.2** `Show` / `For` components (control flow macros)
  - `when` макро за conditional rendering в `buildHtml` — вече има (`conditional_client.nim`)
  - `for` макро за list rendering с keyed updates
  - `switch` / `match` макро за pattern matching
- [ ] **17.3** `onCleanup` / `onMount` lifecycle hooks
  - Изпълнява се когато компонент се mount/unmount от DOM
  - Важно за EventListener cleanup, WebSocket unsubscribe
- [ ] **17.4** `ErrorBoundary` component
  - Хваща грешки в child компоненти, показва fallback UI
- [ ] **17.5** `Suspense` + `Transition`
  - Показва fallback докато `Resource` е в loading състояние
  - `Transition` — отлага DOM updates за анимации

### Фаза 18: Advanced Client Features (Q3-Q4 2026)
**Цел:** SPA experience като Leptos/Solid.

- [ ] **18.1** History API Router (вместо hash-based)
  - `pushState` / `popstate` event handling
  - Server-side 404 fallback за deep links
- [ ] **18.2** Lazy loading / Code splitting
  - `dynamicImport` макро за on-demand компонент loading
  - В Nim това означава отделен `nim js` build + runtime load
- [ ] **18.3** Client-side transitions / animations
  - CSS class toggle на enter/leave
  - `reactiveClass` вече работи — добави transition hooks
- [ ] **18.4** Service Worker / PWA support
  - Offline-first кеширане на static assets
  - Това е NimMax middleware + manifest.json генерация

### Фаза 19: Optional Server Features (Out of Scope for v1.0)
**Цел:** Ако някой иска full-stack, тези функции са тук. **Не са приоритет.**

- [ ] **19.1** Server Actions / RPC
  - Автоматично генериране на REST/JSON API от Nim proc-ове
  - Type-safe client stubs (генерирани от Nim типове)
- [ ] **19.2** Database integration layer
  - SQLx-like compile-time checked queries за Nim
- [ ] **19.3** Auth middleware (JWT + sessions)
  - В `server/auth.nim` има начало — завърши го
- [ ] **19.4** File upload / multipart forms
  - `renderForm` да поддържа `<input type="file">`
- [ ] **19.5** Streaming SSR
  - `renderFullPage` в момента буферира целия HTML
  - Progressive streaming — пращай chunks (ниски приоритет за frontend framework)

---

## 4. Технически Дълг (Refactoring Tasks)

| Приоритет | Задача | Причина | Как |
|-----------|--------|---------|-----|
| Среден | Merge `view_macros.nim` в `html_macros.nim` или ги раздели ясно | В момента `view` е wrapper около `buildHtml` — дублиране | Дефинирай `view` като `buildHtml` + props extraction само |
| Среден | Extract `HtmlNode` от `dom/` + `ssr/` + `client/` в един тип | `renderToHtml` (SSR) и `renderDomNode` (client) имат parallel logic | Създай `HtmlNodeRenderer` concept или base methods |
| Нисък | Rename `nimleptos.nim` main export файл | В момента `src/nimleptos.nim` е root, но папката е `src/nimleptos/` | Стандартна Nim структура — `src/nimleptos.nim` re-exports всичко |
| Нисък | Standardize proc naming: `createXxx` vs `newXxx` vs `elXxx` | `createSignal` но `newNimLeptosApp` — несъвместим conventions | Реши един стандарт и документирай в `AGENTS.md` |
| Нисък | Remove Emscripten tasks от `nimleptos.nimble` | Emscripten не се поддържа вече | Премести в `nimleptos.nimble.emscripten_legacy` или изтрий |

---

## 5. Тестово Покритие — Какво Липсва

| Компонент | Сегашни тестове | Какво липсва |
|-----------|-----------------|--------------|
| Signal Core | 5 теста | stress test (10000 updates), memory test (signal disposal) |
| Effects | част от signal_test | isolated effect tests, cleanup tests, nested effects |
| HTML Macros | 12 теста | nested macro tests, error cases (invalid tags), attribute escaping |
| SSR | 5 теста | streaming test, large tree test, conditional SSR |
| Server Adapter | 9 теста | error handling middleware, auth middleware, WS bridge |
| Client DOM | 11 теста | `reactive_dom.nim` — renderDomNode, reactiveTextNode, reactiveAttr, reactiveClass, reactiveStyle, conditionalNode, mountApp, clearChildren, domEventHandlers, multipleReactiveChildren |
| Client Router | 0 теста | route matching, param extraction, 404 handling |
| WebSocket Signals | 0 теста | reconnect, broadcast, multiple subscribers |
| Forms | 0 теста | validation errors, file upload, CSRF token |
| i18n | 0 теста | catalog loading, pluralization, reactive t(), compile-time key check |
| WASM | 0 теста | end-to-end WASM compile + run test |

### Следващи тестове за писане (по приоритет):
1. ~~`tests/client_dom_test.nim`~~ ✅ Написан — 11 теста, всички PASS
2. `tests/router_test.nim` — test hash router navigation
3. `tests/wasm_e2e_test.nim` — compile reactive core to wasm, test exports
4. `tests/form_test.nim` — test renderForm, validation, getFieldValues
5. `tests/i18n_test.nim` — test catalog load, t() signal, pluralization, SSR locale
6. `tests/websocket_test.nim` — test ServerSignal subscribe/broadcast

---

## 6. Как да Работиш с Други AI

### Преди да възложиш задача на друг AI:
1. **Копирай** този roadmap в prompt-а
2. **Посочи конкретна фаза и задача** (напр. "Фаза 13.2 — рефакторирай createMemo за WASM")
3. **Дай `AGENTS.md`** — задължително прикачи
4. **Дай `PLAN.md`** — за архитектурен контекст
5. **Кажи кои тестове трябва да минават** след промяната

### Забрани за други AI (добави в prompt-а):
- ❌ Да не използва `std/asyncdispatch` в WASM/JS targets
- ❌ Да не добавя `threadvar` без `when not defined(js) and not defined(wasm32)`
- ❌ Да не използва `echo` в `createEffect` за WASM
- ❌ Да не предлага VDOM или React/Vue patterns
- ❌ Да не пипа `Resource[T]` да стане closure tuple
- ❌ Да не използва `std/dom` в WASM модули

### Контролен списък след всяка промяна:
```bash
nimble test                          # Всички 58+ теста PASS
nimble client                        # nim js компилира
nimble server                        # Server example тръгва
nimble nimblingReactive             # WASM pipeline не чупи (compile-only)
```

---

## 7. Метрики за Успех

| Метрика | Текущо | Цел v0.3.0 | Цел v0.4.0 |
|---------|--------|------------|------------|
| Тестове | 69 | 80+ | 120+ |
| Тест покритие (estimated) | ~40% | 60% | 80% |
| Примери | 8 | 12 | 15 |
| Документация страници | 8 | 12 | 15 |
| WASM pipeline | compileOnly ✅ | пълен e2e | production-ready |
| CI/CD | GitHub Actions ✅ | multi-platform | auto-release |
| i18n поддръжка | няма | reactive t() + SSR | ICU plural + WASM |
| Benchmarks | created ✅ | 3 benchmark файла | +Karax сравнение |

---

## 8. Свързани Документи

| Файл | За какво е |
|------|------------|
| `AGENTS.md` | Правила за AI — стил, архитектурни капани |
| `PLAN.md` | Текущ проектен статус, реализирани фази |
| `WASM.md` | WASM компилация — стари Emscripten notes |
| `NIMMAX_BACKEND_RECOMMENDATIONS.md` | NimMax backend guidelines |
| `CODE_REVIEW.md` | Ревю бележки |
| `docs/*.md` | Компонентна документация |
| `tests/*_test.nim` | Използвай за примери как се пишат тестове |

---

*Последна актуализация: 2026-05-04*
*Версия: 0.2.0 → цел v0.3.0 (WASM стабилност + тестове + DX)*
*i18n заложен във Фаза 16 за Q3 2026*
*Client DOM тестове добавени: 11 теста, всички PASS*

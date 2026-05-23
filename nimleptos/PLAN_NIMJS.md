# Plan: NimLeptos — Nim-JS Only Client Target
## План за премахване на активна WASM поддръжка и фокус върху `nim js`

> **Статус:** Draft — за изпълнение по-късно, когато проектът е готов за Phase 18+
> **Цел:** Да се архивира WASM поддръжката и да се инвестира цялата client-side енергия в `nim js` pipeline-а.

---

## Защо?

1. **Nim има `nim js` — това е суперсилата му.** Rust (Leptos) няма JS backend и задължително ползва WASM. Nim има директна компилация до JS.
2. **Пълноценен reactive DOM вече работи с `nim js`.** Signals, effects, fine-grained DOM updates, hydration, router, forms — всичко е там.
3. **WASM pipeline е 3-степенен и крехък.** `nim c` → C → `wasm32` (clang/zig) → `nimbling CLI` — изисква WASI SDK, външни инструменти и специални workaround-и за всеки нов feature.
4. **WASM модулите са placeholder-и.** `src/nimleptos/wasm/` не предлага реактивен DOM в браузъра — само bridge-ове за изчисления.
5. **Поддръжката на WASM е технически дълг.** Всеки нов feature (Store, Resource, Context, `for` macro в `buildHtml`) изисква допълнителни тестове и workaround-и за wasm32.

---

## Фаза 1: Deprecation & Freeze (1-2 дни)

### 1.1 Маркиране на WASM модулите
- [ ] Добави `## .. deprecated::` бележки в `src/nimleptos/wasm/*.nim`
- [ ] Добави `{.deprecated: "WASM support is frozen. Use nim js target instead.".}` на публичните proc-ове в `wasm/` ако е възможно
- [ ] Обнови `WASM.md` — добави ясна бележка в началото: **"This document is archived. WASM support is no longer actively developed."**

### 1.2 Archiving на nimbling примерите
- [ ] Премести `examples/nimbling_*` в `examples/archive/nimbling_*`
- [ ] Добави `README.md` в `examples/archive/` с обяснение защо са архивирани
- [ ] Премахни nimbling tasks от `nimleptos.nimble` или ги преименувай с префикс `archive_`

### 1.3 Документиране на решението
- [ ] Обнови `AGENTS.md` — премахни или маркирай като deprecated всички WASM-specific инструкции (panicoverride, threadvar правила, emit blocks, etc.)
- [ ] Добави бележка в `README.md` в секция "Targets" — "Client: `nim js` (recommended). WASM: experimental/archived."

---

## Фаза 2: CI/CD Cleanup (0.5-1 ден)

### 2.1 Опростяване на GitHub Actions
- [ ] Премахни WASM compile check от `.github/workflows/ci.yml`
- [ ] Премахни зависимостите от `wasi-sdk`, `zig`, `nimbling` в CI
- [ ] Ако `nimble test` вече е бърз — можеш да добавиш `nim js` тестове в CI (ако ги няма)

### 2.2 Nimble tasks cleanup
- [ ] Премахни `nimblingReactive`, `nimblingI18n` tasks от `nimleptos.nimble`
- [ ] Премахни WASM-specific flags и paths от `nimble` конфигурацията
- [ ] Остави само: `test`, `server`, `client`, `hot`, `benchmark`

---

## Фаза 3: Source Restructure (2-3 дни)

### 3.1 Преименуване на client модула (по желание)
- [ ] `src/nimleptos/client/` → `src/nimleptos/browser/` или го остави като `client/`
- [ ] Увери се, че `import nimleptos/client/*` е ясен и документиран път

### 3.2 Почистване на условна компилация
- [ ] Премахни `when defined(js) or defined(wasm32):` блокове, които имат специална логика за `wasm32` (освен ако не е нужна за `js`)
- [ ] В `subscriber.nim` — остави `when defined(js)` глобала и `when not defined(js)` за `threadvar` (това все още е валидно за native)
- [ ] Премахни `when defined(wasm32)` блокове от реактивния core, ако има такива

### 3.3 Преместване/архивиране на WASM модулите
- [ ] Премести `src/nimleptos/wasm/` в `src/nimleptos/_archive/wasm/` или просто го изтрий
- [ ] Ако запазиш i18n bridge-а — премести го в `src/nimleptos/client/wasm_bridge.nim` с бележка, че е legacy
- [ ] Обнови `src/nimleptos.nim` (ако има top-level import файл) — премахни WASM re-exports

---

## Фаза 4: Enhance nim js Client Experience (1-2 седмици)

### 4.1 Bundler интеграция
- [ ] Добави официална поддръжка за Vite/Webpack — `nim js` генерира `.js`, bundler-ът го обработва
- [ ] Добави пример с Vite: `examples/vite_counter/` с `vite.config.js` и `nim js --outdir:dist/`
- [ ] Тествай source maps (`nim js -g`)

### 4.2 По-малък JS output
- [ ] Тествай с `-d:release` и `--opt:size` за `nim js`
- [ ] Премахни dead code — увери се, че native-only модули (server, realtime) не се импортират в client code
- [ ] Разгледай `--experimental:jsbigint` или други Nim JS флагове за по-добър output

### 4.3 Hot reload за nim js
- [ ] Разшири `tools/hotreload.nim` да поддържа `nim js` compilation — при промяна на `.nim` файл, recompile и browser refresh
- [ ] Добави `nimble dev` task, който гледа `examples/*/client.nim` и ги recompile-ва

### 4.4 Better DOM interop
- [ ] Прегледай `src/nimleptos/client/dom_interop.nim` — добави липсващи DOM API-та, които ще ти трябват
- [ ] Добави `requestAnimationFrame` wrapper за анимации
- [ ] Добави `IntersectionObserver` helper за lazy loading компоненти

---

## Фаза 5: Examples & Docs (2-3 дни)

### 5.1 Всички примери да са `nim js`
- [ ] Премахни или update-ни `examples/wasm_reactive.nim` — направи го `examples/counter_js.nim`
- [ ] Добави примери за всички client features:
  - `examples/router_client.nim` — hash router
  - `examples/fetch_client.nim` — http client + Resource
  - `examples/form_client.nim` — client-side forms + validation
  - `examples/i18n_client.nim` — reactive i18n с `buildHtml(cfg)`

### 5.2 Документация
- [ ] Напиши `docs/client.md` — пълноценно ръководство за `nim js` client development
- [ ] Обнови `docs/dom.md` — премахни WASM references
- [ ] Обнови `docs/reactive.md` — фокусирай се на `nim js` signals/effects
- [ ] Добави comparison таблица: `nim js` vs WASM vs SSR

### 5.3 README update
- [ ] Секция "Quick Start" да показва само `nim js` и SSR
- [ ] Секция "Build Targets" — `nim c` (native/server), `nim js` (client), WASM (archived)
- [ ] Добави badges: "Tests Passing", "Nim >= 2.0.0"

---

## Фаза 6: Testing (2-3 дни)

### 6.1 Client тестове
- [ ] Увеличи `tests/client_dom_test.nim` — добави тестове за `reactiveAttr`, `reactiveClass`, `reactiveStyle`
- [ ] Добави `tests/client_router_test.nim` — client-side hash router тестове с jsdom
- [ ] Добави `tests/client_hydration_test.nim` — SSR → hydration цикъл

### 6.2 JS-specific regression tests
- [ ] Тествай, че `createMemo` работи коректно в `nim js` (вече го има, но провери)
- [ ] Тествай `Store[T]` и `Resource[T]` в `nim js` target
- [ ] Тествай `buildHtml` macro в `nim js` — всички HTML елементи + `for` macro

### 6.3 Премахни WASM тестовете
- [ ] Изтрий или архивирай `tests/wasm_e2e_test.nim`
- [ ] Обнови `tests/all_test.nim` — премахни WASM test imports

---

## Фаза 7: Performance & Polish (по желание, 1 седмица)

### 7.1 Bundle size analysis
- [ ] Измери output size на `nim js` за minimal counter app
- [ ] Цел: под 50KB minified за hello-world с signals
- [ ] Идентифицирай големи dependencies и ги направи lazy

### 7.2 Memory leaks
- [ ] Провери дали `createEffect` cleanup работи при unmount на DOM nodes
- [ ] Добави `dispose()` метод на ефекти/сигнали за ръчно cleanup

### 7.3 Developer Experience
- [ ] По-добри error messages в `buildHtml` macro при `nim js`
- [ ] Debug mode за client: `nim js -d:nimleptosDebug` (вече го има, провери дали работи)
- [ ] Browser DevTools интеграция — имена на ефекти/сигнали за debugging

---

## Файлове за изтриване/архивиране

```
src/nimleptos/wasm/              →  src/nimleptos/_archive/wasm/
examples/nimbling_counter/        →  examples/archive/nimbling_counter/
examples/nimbling_reactive/       →  examples/archive/nimbling_reactive/
examples/nimbling_i18n/           →  examples/archive/nimbling_i18n/
tests/wasm_e2e_test.nim           →  tests/archive/wasm_e2e_test.nim
examples/wasm_reactive.nim        →  изтрий или преработи за nim js
crate_initCounter.nbg             →  изтрий
crate_initI18n.nbg                →  изтрий
```

## Файлове за обновяване

```
README.md                         →  Премахни WASM references, фокус на nim js
WASM.md                           →  Добави "ARCHIVED" в началото
AGENTS.md                         →  Премахни WASM-specific инструкции
PLAN.md                           →  Маркирай Phase 13+ WASM фазите като archived
nimleptos.nimble                  →  Премахни nimbling tasks
.github/workflows/ci.yml          →  Премахни WASM compile step
docs/client.md                    →  Напиши ново ръководство за nim js
docs/*.md                         →  Премахни WASM references
src/nimleptos.nim                 →  Премахни WASM re-exports
```

---

## Критерии за успех

- [ ] `nimble test` минава без WASM тестове и без `defined(wasm32)` dependencies
- [ ] Всички примери в `examples/` са `nim js` или native SSR — нито един не изисква WASI SDK или nimbling
- [ ] README.md описва само два target-а: `nim c` (native/server) и `nim js` (client)
- [ ] `AGENTS.md` е 30% по-къс — без WASM капани
- [ ] CI pipeline е по-бърз с поне 2-3 минути (без WASM compile + nimbling)
- [ ] Нови client примери: router, fetch, form, i18n (всички с `nim js`)

---

## Рискове

| Риск | Вероятност | Митигация |
|------|-----------|-----------|
| Някой ползва WASM моста за i18n | Ниска | Запази `i18n_wasm.nim` в `_archive/` |
| Nimling стане стабилен и искаш да върнеш WASM | Ниска | Git history пази всичко — `git checkout` от стар commit |
| `nim js` има compiler бъг, който WASM няма | Много ниска | `nim js` е много по-зрял target от wasm32+standalone |
| Размерът на `nim js` output е твърде голям | Средна | `-d:release --opt:size`, tree shaking, bundler |

---

> **Забележка:** Този план е *draft*. Не го изпълнявай преди да си готов. Когато дойде време, започни с Фаза 1 и Фаза 2 — те са най-лесни и дават най-много "дъх" на проекта.

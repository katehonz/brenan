# NimLeptos + NimMax — Project Status

## Статус: Phase 1-11 COMPLETE + Bug Fixes

Phase 10 добави reactive DOM binding за client-side rendering и подобри HTML DSL макросите.
Phase 11 добави WebAssembly компилация на reactive core с JS interop.
Phase 11.1 оправи 3 критични бъга + 7 средни приоритета + добави 19 нови HTML елемента.

Всички фази са реализирани и тестовете минават (40 теста, 5 suite-а).

---

## Реализирани модули (23 файла)

### Reactive Core (`src/nimleptos/reactive/`)
| Файл | Описание |
|------|----------|
| `subscriber.nim` | Signal[T], dependency tracking, scheduler, batch |
| `signal.nim` | createSignal, Getter/Setter types |
| `effects.nim` | createEffect, createMemo (memo.value sync fix) |

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
| `table_helper.nim` | Workaround за nimmax TableRef[string, string] recursive override bug |

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

---

## Тестове

| Тест | Статус |
|------|--------|
| `tests/signal_test.nim` | PASS — 5 tests |
| `tests/macros_test.nim` | PASS — 12 tests |
| `tests/ssr_test.nim` | PASS — 5 tests |
| `tests/server_test.nim` | PASS — 9 tests |
| `tests/all_test.nim` | PASS — 9 tests |
| **Общо** | **40 теста, всички PASS** |

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
| `examples/wasm_reactive.nim` | Reactive core в WASM — signals + memos, контролирани от JS |

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
│   ├── reactive/        # Signal system
│   ├── dom/             # HTML node tree (35 element builders)
│   ├── macros/          # Compile-time DSL
│   ├── ssr/             # Server-side rendering
│   ├── server/          # NimMax adapter
│   ├── routing/         # Route components + layouts
│   ├── forms/           # Form handling + validation
│   ├── realtime/        # WebSocket signals
│   └── client/          # JS hydration (nim js)
├── tests/               # 5 test suites, 40 tests
├── examples/            # 7 examples (SSR, CSR, hybrid, WASM)
├── docs/                # 8 documentation files
├── nimleptos.nimble
└── PLAN.md
```

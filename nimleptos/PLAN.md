# NimLeptos + NimMax — Project Status

## Статус: Phase 1-10 COMPLETE

Phase 10 добави reactive DOM binding за client-side rendering и подобри HTML DSL макросите.

Всички фази са реализирани и тестовете минават.

---

## Реализирани модули (23 файла)

### Reactive Core (`src/nimleptos/reactive/`)
| Файл | Описание |
|------|----------|
| `subscriber.nim` | Signal[T], dependency tracking, scheduler, batch |
| `signal.nim` | createSignal, Getter/Setter types |
| `effects.nim` | createEffect, createMemo |

### DOM (`src/nimleptos/dom/`)
| Файл | Описание |
|------|----------|
| `node.nim` | HtmlNode type, renderToHtml, escapeHtml |
| `elements.nim` | elDiv, elSpan, elP, elH1, elH2, elButton, elInput, elLabel, elForm, elA, elNav, elUl, elLi, elSection, elHeader, elFooter, text |

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
| `middleware.nim` | hydrationMiddleware, titleMiddleware, clientAssetsMiddleware |

### Routing (`src/nimleptos/routing/`)
| Файл | Описание |
|------|----------|
| `route.nim` | route(), routePost(), routeGroup() — декларативни route components с LayoutComponent |
| `layout.nim` | mainLayout(), sidebarLayout(), html5Layout() |

### Forms (`src/nimleptos/forms/`)
| Файл | Описание |
|------|----------|
| `form.nim` | FormDef, FormField, renderForm(), renderFormField(), getFieldValues() |
| `validation.nim` | NimLeptosValidator wrapping nimmax/validater — addRequired, addEmail, addMinLen, addMaxLen, addIntRange |
| `table_helper.nim` | Workaround за nimmax TableRef[string, string] recursive override bug |

### Realtime/WebSocket (`src/nimleptos/realtime/`)
| Файл | Описание |
|------|----------|
| `ws_bridge.nim` | ServerSignal[T], SignalRegistry, createServerSignal, setServerValue (push updates) |
| `ws_handler.nim` | wsSignalRoute(), handleSignalMessage(), signalStateEndpoint() |

### Client/JS (`src/nimleptos/client/`)
| Файл | Описание |
|------|----------|
| `dom_interop.nim` | DOM manipulation via jsffi (getElementById, querySelector, addEventListener, etc.) |
| `reactive_dom.nim` | Fine-grained reactive DOM — renderDomNode, reactiveTextNode, reactiveAttr, reactiveClass, reactiveStyle, mountApp, mountReactiveApp |
| `hydration_client.nim` | Client-side hydration — loadHydrationData, hydrateNodes, hydrateApp |
| `event_handlers.nim` | bindEvent, bindClick, bindSubmit, bindInput, applyBindings, initEventHandlers |

---

## Тестове

| Тест | Статус |
|------|--------|
| `tests/all_test.nim` | PASS — 9 tests (signal, reactivity, memo, batch, HTML, SSR, hydration, escapeHtml, dependency tracking) |
| `tests/server_test.nim` | PASS — 9 tests (app creation, render, title, fragment, route component, layout, form, validation, route group) |
| `tests/signal_test.nim` | PASS |
| `tests/macros_test.nim` | PASS — 9 tests (buildHtml, el macro) |
| `tests/ssr_test.nim` | PASS |

---

## Примери

| Пример | Описание |
|--------|----------|
| `examples/counter/main.nim` | SSR counter с reactive signals |
| `examples/counter_client.nim` | Client-side counter с `nim js` — reactiveTextNode, signals, DOM events |
| `examples/server_app.nim` | NimMax server с NimLeptos rendering, routing, API endpoints |

---

## Известни проблеми

1. **nimmax bug**: `TableRef[string, string]` override в `nimmax/core/request.nim` причинява infinite recursion за `[]`, `[]=`, `hasKey`. Workaround: `forms/table_helper.nim` създава таблицата без nimmax scope.

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
│   ├── dom/             # HTML node tree
│   ├── macros/          # Compile-time DSL
│   ├── ssr/             # Server-side rendering
│   ├── server/          # NimMax adapter
│   ├── routing/         # Route components + layouts
│   ├── forms/           # Form handling + validation
│   ├── realtime/        # WebSocket signals
│   └── client/          # JS hydration (nim js)
├── tests/
├── examples/
├── nimleptos.nimble
└── PLAN.md
```

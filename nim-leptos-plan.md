# Leptos-like Framework for Nim - Project Plan

## Project Name
**NimLeptos** (working title)

## Overview
A full-stack reactive web framework for Nim inspired by Leptos (Rust), featuring fine-grained reactivity, HTML DSL macros, Server-Side Rendering (SSR), and client-side hydration.

---

## Core Pillars

### 1. Fine-Grained Reactivity (Signals)
- **Signal[T]** type: tracks dependencies, notifies observers on change
- **createSignal**: primitive for creating reactive state
- **createEffect**: side effects that track signal dependencies
- **createMemo**: derived computations with caching
- **batch**: group multiple signal updates into one notification

### 2. HTML DSL Macros
- **html** macro: transforms HTML-like syntax into Nim function calls
- **view!** macro: Leptos-style syntax for component definitions
- Support for: attributes, children, event handlers, fragments
- Compile-time validation of HTML structure

### 3. Server-Side Rendering (SSR)
- Initial HTML rendering on server
- Streaming support for progressive output
- Asset management and hydration markers

### 4. Hydration
- Client-side "attach" to pre-rendered HTML
- No full re-render on client load
- Progressive enhancement

---

## Technical Components

### Backend Layer
```
- HTTP Server: Jester, HappyX, or custom based on asynchttpserver
- Routing: Middleware-based request handling
- Template rendering: Integration with Nim's templating
```

### Reactive Core (`src/reactive/`)
```
signal.nim        - Signal[T] type implementation
effects.nim       - createEffect, createMemo
scheduler.nim     - Batched update scheduling
subscriber.nim    - Dependency tracking
```

### Macro System (`src/macros/`)
```
html_macros.nim   - html{} macro for HTML DSL
view_macros.nim   - view! macro for components
props_macros.nim  - Property extraction
```

### DOM Layer (`src/dom/`)
```
elements.nim      - HTML element builders
components.nim    - Component system
events.nim        - Event handler binding
```

### SSR Layer (`src/ssr/`)
```
renderer.nim      - Server-side HTML generation
hydration.nim     - Hydration markers and client bootstrap
streaming.nim     - Progressive streaming output
```

### Full-Stack Integration (`src/`)
```
app.nim           - Main application builder
route.nim         - Client/server routing
context.nim       - Request context handling
```

---

## Implementation Priorities

### Phase 1: Core Reactivity
- [ ] Implement `Signal[T]` with dependency tracking
- [ ] `createSignal` procedure
- [ ] `createEffect` for side effects
- [ ] Basic scheduler with batched updates

### Phase 2: HTML DSL
- [ ] `html` macro parsing HTML-like syntax
- [ ] Attribute binding syntax
- [ ] Event handler attachment
- [ ] Nested component support

### Phase 3: Server-Side Rendering
- [ ] HTML renderer using reactive tree
- [ ] Hydration marker injection
- [ ] Asset manifest integration

### Phase 4: Hydration
- [ ] Client-side signal restoration from DOM
- [ ] Event listener attachment to existing HTML
- [ ] Progressive enhancement handling

### Phase 5: Full-Stack Integration
- [ ] Route components with SSR support
- [ ] Form handling and mutations
- [ ] Error boundaries

---

## Existing Nim Projects to Learn From

| Project | Purpose | Key Takeaways |
|---------|---------|---------------|
| [HappyX](https://github.com/Haptic-Apps/HappyX) | Full-stack framework | Modern macro approach, SSR |
| [Karax](https://github.com/pragmagic/karax) | SPA with VDOM | Reactive patterns, component model |
| [Fidget](https://github.com/treeform/fidget) | UI framework | Rendering pipeline |
| [Jester](https://github.com/dom96/jester) | HTTP routing | Middleware patterns |

---

## Build Targets
- **nim js** - JavaScript compilation for client
- **nim c** - Native server binaries
- **nimble** - Package management

---

## File Structure
```
nimleptos/
├── src/
│   ├── reactive/
│   │   ├── signal.nim
│   │   ├── effects.nim
│   │   └── scheduler.nim
│   ├── macros/
│   │   ├── html_macros.nim
│   │   └── view_macros.nim
│   ├── dom/
│   │   ├── elements.nim
│   │   └── events.nim
│   ├── ssr/
│   │   ├── renderer.nim
│   │   └── hydration.nim
│   ├── app.nim
│   └── routes.nim
├── tests/
│   ├── signal_test.nim
│   ├── macros_test.nim
│   └── ssr_test.nim
├── examples/
│   ├── counter/
│   ├── todo/
│   └── hacker_news/
└── nimble.src
```

---

## Key Nim Features to Leverage
- **macros** module: AST manipulation for HTML DSL
- **closure** types: For reactive computations
- **concept**: For generic signal constraints
- **js** module: DOM access when compiling to JavaScript
- **asynchttpserver**: Built-in async HTTP server
- **htmlparser**: Server-side HTML generation

---

## Risks & Considerations

1. **Performance**: Fine-grained reactivity vs VDOM - direct DOM manipulation requires careful benchmarking
2. **Macro complexity**: HTML DSL macros can become hard to debug
3. **Hydration**: Tricky to implement correctly without full virtual DOM
4. **Ecosystem**: Less mature than Rust's wasm-bindgen/wasm-pack tooling

---

## Getting Started

```bash
# Clone repository
git clone https://github.com/yourusername/nimleptos
cd nimleptos

# Install dependencies
nimble install

# Run examples
nimble js -d:ssl examples/counter/main.nim
nim c -r examples/counter/server.nim
```

---

## References
- Leptos Book: https://leptos.dev/
- Karax Framework: https://github.com/pragmagic/karax
- Nim Macros Documentation: https://nim-lang.org/docs/macros.html
- jsffi: https://github.com/nim-lang/jsffi

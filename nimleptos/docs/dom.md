# HTML DSL & DOM

Two approaches for building HTML: **programmatic builder API** and **compile-time macros**.

---

## Element Builders

All follow the pattern `elTagName(attrs, children...)`:

### Text & Structure
| Builder | Tag | Children |
|---------|-----|----------|
| `text(content)` | text node | — |
| `elDiv` | `<div>` | yes |
| `elSpan` | `<span>` | yes |
| `elP` | `<p>` | yes |
| `elMain` | `<main>` | yes |
| `elSection` | `<section>` | yes |
| `elArticle` | `<article>` | yes |
| `elAside` | `<aside>` | yes |

### Headings
| Builder | Tag |
|---------|-----|
| `elH1` | `<h1>` |
| `elH2` | `<h2>` |

### Navigation & Layout
| Builder | Tag | Children |
|---------|-----|----------|
| `elHeader` | `<header>` | yes |
| `elFooter` | `<footer>` | yes |
| `elNav` | `<nav>` | yes |

### Lists
| Builder | Tag | Children |
|---------|-----|----------|
| `elUl` | `<ul>` | yes |
| `elLi` | `<li>` | yes |

### Forms
| Builder | Tag | Children |
|---------|-----|----------|
| `elForm` | `<form>` | yes |
| `elInput` | `<input>` | no (void) |
| `elLabel` | `<label>` | yes |
| `elButton` | `<button>` | yes |
| `elTextarea` | `<textarea>` | yes |
| `elSelect` | `<select>` | yes |
| `elOption` | `<option>` | yes |

### Tables
| Builder | Tag | Children |
|---------|-----|----------|
| `elTable` | `<table>` | yes |
| `elTr` | `<tr>` | yes |
| `elTd` | `<td>` | yes |
| `elTh` | `<th>` | yes |

### Media
| Builder | Tag | Children |
|---------|-----|----------|
| `elImg` | `<img>` | no (void) |

### Links
| Builder | Tag | Children |
|---------|-----|----------|
| `elA` | `<a>` | yes |

### Code
| Builder | Tag | Children |
|---------|-----|----------|
| `elPre` | `<pre>` | yes |
| `elCode` | `<code>` | yes |

### Document Structure
| Builder | Tag | Children |
|---------|-----|----------|
| `elHtml` | `<html>` | yes |
| `elHead` | `<head>` | yes |
| `elBody` | `<body>` | yes |
| `elScript` | `<script>` | yes |
| `elStyle` | `<style>` | yes |
| `elTitle` | `<title>` | yes |

### Usage

```nim
let page = elDiv([("class", "container")],
  elH1([], text("Welcome")),
  elP([("class", "subtitle")], text("Hello!")),
  elTable([("class", "data")],
    elTr([], elTh([], text("Name")), elTh([], text("Value"))),
    elTr([], elTd([], text("Foo")), elTd([], text("42")))
  ),
  elImg([("src", "/logo.png"), ("alt", "Logo")])
)

echo renderToHtml(page)
```

---

## HtmlNode Type

```nim
type HtmlNode* = ref object
  tag*: string
  attributes*: seq[(string, string)]
  events*: seq[(string, string)]
  children*: seq[HtmlNode]
  text*: string
  isText*: bool
  reactiveText*: proc(): string {.closure.}
  reactiveAttrs*: seq[ReactiveAttr]
  condition*: proc(): bool {.closure, gcsafe.}
  thenBranch*: HtmlNode
  elseBranch*: HtmlNode
```

---

## Rendering

- `renderToHtml(node)` — with HTML escaping
- `renderToHtmlRaw(node)` — without escaping (both handle condition nodes)
- `escapeHtml(s)` — escapes `&`, `<`, `>`, `"`

---

## Compile-Time Macros

`buildHtml` and `el` macros provide declarative, HTML-like syntax expanded at compile time.

```nim
let page = buildHtml:
  el("div", class="container"):
    el("h1"): text("Welcome")
    el("p", class="subtitle"): text("Hello!")
```

### Reactive Interpolation (JS target)

When compiled with `nim js`, text interpolation inside `buildHtml` automatically wraps in `reactiveTextNode`:

```nim
let (count, setCount) = createSignal(0)
let node = buildHtml:
  el("p"): text($count())  # auto-reactive on JS, static on native
```

### Conditional Rendering

```nim
let (show, setShow) = createSignal(true)
let node = buildHtml:
  el("div"):
    if show():
      el("p"): text("Visible")
    else:
      el("p"): text("Hidden")
```

### Element Attributes

```nim
let node = buildHtml:
  el("input", type="text", name="email", placeholder="Enter email")
  el("a", href="/about"): text("About")
```

# HTML DSL & DOM

NimLeptos provides two approaches for building HTML: a programmatic builder API and compile-time macros.

## Element Builders

Import `nimleptos/dom/elements` for the builder API:

```nim
import nimleptos/dom/elements

let page = elDiv([("class", "container")],
  elH1([], text("Welcome")),
  elP([("class", "subtitle")], text("Hello, NimLeptos!")),
  elButton([("onclick", "alert('clicked')")], text("Click me"))
)

echo renderToHtml(page)
# <div class="container"><h1>Welcome</h1><p class="subtitle">Hello, NimLeptos!</p><button onclick="alert(&#39;clicked&#39;)">Click me</button></div>
```

### Available Elements

| Proc | Tag | Self-closing |
|------|-----|--------------|
| `elDiv` | `<div>` | No |
| `elSpan` | `<span>` | No |
| `elP` | `<p>` | No |
| `elH1` | `<h1>` | No |
| `elH2` | `<h2>` | No |
| `elButton` | `<button>` | No |
| `elInput` | `<input>` | Yes |
| `elLabel` | `<label>` | No |
| `elForm` | `<form>` | No |
| `elA` | `<a>` | No |
| `elNav` | `<nav>` | No |
| `elUl` | `<ul>` | No |
| `elLi` | `<li>` | No |
| `elSection` | `<section>` | No |
| `elHeader` | `<header>` | No |
| `elFooter` | `<footer>` | No |
| `text` | (text node) | N/A |

### Constructor Pattern

All elements follow the same pattern:

```nim
elTagName(attrs, children...)
```

- `attrs`: `openArray[(string, string)]` — key-value attribute pairs
- `children`: `varargs[HtmlNode]` — child nodes

```nim
# Empty element
elDiv()

# With attributes only
elInput([("type", "text"), ("name", "email")])

# With children only
elP([], text("Hello"))

# With both
elA([("href", "/about")], text("About"))
```

## HtmlNode Type

```nim
type
  HtmlNode* = ref object
    tag*: string
    attributes*: seq[(string, string)]
    events*: seq[(string, string)]
    children*: seq[HtmlNode]
    text*: string
    isText*: bool
```

### Low-Level API

```nim
import nimleptos/dom/node

let node = elementNode("div")
node.addAttribute("class", "wrapper")
node.addChild(textNode("Hello"))
node.addChild(elementNode("br"))

echo renderToHtml(node)
# <div class="wrapper">Hello<br></br></div>
```

## Rendering

| Proc | Description |
|------|-------------|
| `renderToHtml(node)` | Renders with HTML escaping |
| `renderToHtmlRaw(node)` | Renders without escaping |
| `escapeHtml(s)` | Escapes `&`, `<`, `>`, `"` |

```nim
let node = elP([], text("<b>safe</b>"))
echo renderToHtml(node)     # <p>&lt;b&gt;safe&lt;/b&gt;</p>
echo renderToHtmlRaw(node)  # <p><b>safe</b></p>
```

## Compile-Time Macros

For a more concise syntax, use the `html` macro:

```nim
import nimleptos/macros/html_macros

# Coming in future versions
# let page = html:
#   div(class="container"):
#     h1: text "Hello"
#     p: text "World"
```

> Note: The macro DSL is experimental. The builder API is the recommended approach for production code.

## Nesting Patterns

### Lists

```nim
proc renderList(items: seq[string]): HtmlNode =
  var lis: seq[HtmlNode] = @[]
  for item in items:
    lis.add(elLi([], text(item)))
  elUl([], lis)
```

### Conditional Rendering

```nim
proc renderUser(name: string, isLoggedIn: bool): HtmlNode =
  if isLoggedIn:
    elDiv([], text("Welcome, " & name))
  else:
    elDiv([], text("Please log in"))
```

### Event Handlers

```nim
# Server-side: attributes only (no runtime binding)
let btn = elButton([
  ("id", "my-btn"),
  ("data-action", "increment"),
  ("onclick", "handleClick(this)")
], text("Click"))
```

For client-side event binding, see [Client Hydration](client.md).

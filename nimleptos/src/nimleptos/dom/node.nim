import std/strutils

when defined(js):
  import std/dom
  type DomEventHandler* = proc(e: Event) {.closure.}
else:
  type
    DomEventObj* = object of RootObj
    DomEvent* = ref DomEventObj
    DomEventHandler* = proc(e: DomEvent) {.closure.}

type
  ReactiveAttr* = tuple[name: string, getter: proc(): string {.closure.}]

  HtmlNode* = ref object
    tag*: string
    attributes*: seq[(string, string)]
    events*: seq[(string, string)]
    children*: seq[HtmlNode]
    text*: string
    isText*: bool
    reactiveText*: proc(): string {.closure.}  ## If set, this text node auto-updates in the browser
    reactiveAttrs*: seq[ReactiveAttr]  ## Attributes that auto-update in the browser
    condition*: proc(): bool {.closure, gcsafe.}  ## For conditional nodes (if/else)
    thenBranch*: HtmlNode  ## Shown when condition is true
    elseBranch*: HtmlNode  ## Shown when condition is false
    listItems*: proc(): seq[HtmlNode] {.closure, gcsafe.}  ## For list rendering (For macro)
    domEventHandlers*: seq[(string, DomEventHandler)]  ## Event handlers for CSR
    childBranch*: HtmlNode  ## For ErrorBoundary — the wrapped child tree
    errorCatcher*: proc(error: string): HtmlNode {.closure, gcsafe.}  ## Fallback UI factory
    lazyLoader*: proc(): HtmlNode {.closure, gcsafe.}  ## For lazy loading — loads content async
    fallbackBranch*: HtmlNode  ## Shown while lazy content is loading

proc escapeHtml*(s: string): string =
  result = s
  result = result.replace("&", "&amp;")
  result = result.replace("<", "&lt;")
  result = result.replace(">", "&gt;")
  result = result.replace("\"", "&quot;")

proc textNode*(content: string): HtmlNode =
  HtmlNode(text: content, isText: true)

proc reactiveTextNode*(content: string, getter: proc(): string {.closure.}): HtmlNode =
  ## Create a text node with reactive binding for CSR.
  ## The getter is called automatically when the node is rendered to DOM via `renderDomNode`.
  HtmlNode(text: content, isText: true, reactiveText: getter)

proc elementNode*(tag: string): HtmlNode =
  HtmlNode(tag: tag, isText: false)

proc addAttribute*(node: HtmlNode, key: string, value: string) =
  node.attributes.add((key, value))

proc addReactiveAttr*(node: HtmlNode, name: string, getter: proc(): string {.closure.}) =
  ## Add an attribute that automatically updates when the signal changes.
  ## Used by the buildHtml macro for reactive attribute interpolation.
  node.reactiveAttrs.add((name, getter))

proc conditionalNode*(condition: proc(): bool {.closure, gcsafe.}, thenBranch, elseBranch: HtmlNode): HtmlNode =
  ## Create a conditional node that shows/hides branches based on a signal.
  ## Used by the buildHtml macro for reactive if/else control flow.
  result = elementNode("conditional")
  result.condition = condition
  result.thenBranch = thenBranch
  result.elseBranch = elseBranch

proc listNode*(itemsGetter: proc(): seq[HtmlNode] {.closure, gcsafe.}): HtmlNode =
  ## Create a list node that renders a dynamic sequence of HtmlNodes.
  ## Used by the buildHtml macro for reactive for/list control flow.
  result = elementNode("list")
  result.listItems = itemsGetter

proc errorBoundaryNode*(child: HtmlNode, fallback: proc(error: string): HtmlNode {.closure, gcsafe.}): HtmlNode =
  ## Create an ErrorBoundary node that catches rendering errors.
  ## If `child` throws during rendering, `fallback` is called with the error message.
  result = HtmlNode(isText: false, childBranch: child, errorCatcher: fallback)

proc lazyNode*(loader: proc(): HtmlNode {.closure, gcsafe.}, fallback: HtmlNode): HtmlNode =
  ## Create a lazy-loaded node. Shows `fallback` immediately, then loads
  ## content via `loader` asynchronously. In SSR, always shows fallback.
  ##
  ## Usage:
  ##   let node = lazyNode(
  ##     proc(): HtmlNode = heavyComponent(),
  ##     buildHtml: div(class="skeleton"): text("Loading...")
  ##   )
  result = HtmlNode(isText: false, lazyLoader: loader, fallbackBranch: fallback)

proc addEvent*(node: HtmlNode, event: string, handlerId: string) =
  node.events.add((event, handlerId))

proc addDomEvent*(node: HtmlNode, event: string, handler: DomEventHandler) =
  node.domEventHandlers.add((event, handler))

proc addChild*(node: HtmlNode, child: HtmlNode) =
  node.children.add(child)

proc renderToHtml*(node: HtmlNode): string =
  if node.childBranch != nil:
    try:
      return renderToHtml(node.childBranch)
    except:
      let msg = getCurrentExceptionMsg()
      return renderToHtml(node.errorCatcher(msg))
  if node.lazyLoader != nil:
    return renderToHtml(node.fallbackBranch)
  if node.isText:
    return escapeHtml(node.text)
  if node.condition != nil:
    if node.condition():
      return renderToHtml(node.thenBranch)
    else:
      return renderToHtml(node.elseBranch)
  if node.listItems != nil:
    for child in node.listItems():
      result &= renderToHtml(child)
    return

  result = "<" & node.tag
  for (key, value) in node.attributes:
    result &= " " & key & "=\"" & escapeHtml(value) & "\""
  result &= ">"

  for child in node.children:
    result &= renderToHtml(child)

  result &= "</" & node.tag & ">"

proc renderToHtmlRaw*(node: HtmlNode): string =
  if node.childBranch != nil:
    try:
      return renderToHtmlRaw(node.childBranch)
    except:
      let msg = getCurrentExceptionMsg()
      return renderToHtmlRaw(node.errorCatcher(msg))
  if node.lazyLoader != nil:
    return renderToHtmlRaw(node.fallbackBranch)
  if node.isText:
    return node.text
  if node.condition != nil:
    if node.condition():
      return renderToHtmlRaw(node.thenBranch)
    else:
      return renderToHtmlRaw(node.elseBranch)
  if node.listItems != nil:
    for child in node.listItems():
      result &= renderToHtmlRaw(child)
    return

  result = "<" & node.tag
  for (key, value) in node.attributes:
    result &= " " & key & "=\"" & value & "\""
  result &= ">"

  for child in node.children:
    result &= renderToHtmlRaw(child)

  result &= "</" & node.tag & ">"

import std/macros
import std/strutils
import std/tables
import ../dom/node

export node

const eventAttrMap = {
  "onclick": "click", "oninput": "input", "onsubmit": "submit",
  "onchange": "change", "onfocus": "focus", "onblur": "blur",
  "onkeydown": "keydown", "onkeyup": "keyup",
  "onmouseenter": "mouseenter", "onmouseleave": "mouseleave",
  "onmouseover": "mouseover", "ondblclick": "dblclick",
}.toTable

proc isEventAttr(name: string): bool =
  name.toLowerAscii in eventAttrMap

proc getEventName(attrName: string): string =
  eventAttrMap.getOrDefault(attrName.toLowerAscii, "")

proc buildTextNode(text: string): NimNode =
  newCall("textNode", newStrLitNode(text))

proc buildReactiveTextNode(expr: NimNode): NimNode =
  ## For non-string-literal text expressions, generate:
  ##   when defined(js):
  ##     reactiveTextNode($expr, proc(): string = $expr)
  ##   else:
  ##     textNode($expr)
  let strExpr = newCall("$", expr)
  let getterProc = newNimNode(nnkLambda)
  getterProc.add(newEmptyNode())
  getterProc.add(newEmptyNode())
  getterProc.add(newEmptyNode())
  let formalParams = newNimNode(nnkFormalParams)
  formalParams.add(ident("string"))
  getterProc.add(formalParams)
  getterProc.add(newEmptyNode())
  getterProc.add(newEmptyNode())
  getterProc.add(newStmtList(strExpr))

  let reactiveCode = newCall("reactiveTextNode", strExpr, getterProc)
  let staticCode = newCall("textNode", strExpr)

  result = newNimNode(nnkWhenStmt)
  let definedJs = newCall("defined", ident("js"))
  let jsBranch = newNimNode(nnkElifBranch)
  jsBranch.add(definedJs)
  jsBranch.add(reactiveCode)
  let elseBranch = newNimNode(nnkElse)
  elseBranch.add(staticCode)
  result.add(jsBranch)
  result.add(elseBranch)

proc buildReactiveAttr(nodeVar: NimNode, name: string, expr: NimNode): NimNode =
  ## Generate:
  ##   when defined(js):
  ##     addReactiveAttr(node, "name", proc(): string = $expr)
  ##   else:
  ##     addAttribute(node, "name", $expr)
  let strExpr = newCall("$", expr)
  let getterProc = newNimNode(nnkLambda)
  getterProc.add(newEmptyNode())
  getterProc.add(newEmptyNode())
  getterProc.add(newEmptyNode())
  let formalParams = newNimNode(nnkFormalParams)
  formalParams.add(ident("string"))
  getterProc.add(formalParams)
  getterProc.add(newEmptyNode())
  getterProc.add(newEmptyNode())
  getterProc.add(newStmtList(strExpr))

  let reactiveCode = newCall("addReactiveAttr", nodeVar, newStrLitNode(name), getterProc)
  let staticCode = newCall("addAttribute", nodeVar, newStrLitNode(name), strExpr)

  result = newNimNode(nnkWhenStmt)
  let definedJs = newCall("defined", ident("js"))
  let jsBranch = newNimNode(nnkElifBranch)
  jsBranch.add(definedJs)
  jsBranch.add(reactiveCode)
  let elseBranch = newNimNode(nnkElse)
  elseBranch.add(staticCode)
  result.add(jsBranch)
  result.add(elseBranch)

proc buildEventHandlerCode(nodeVar: NimNode, eventName: string, handlerExpr: NimNode): NimNode =
  result = newNimNode(nnkWhenStmt)
  let definedJs = newCall("defined", ident("js"))
  let jsBranch = newNimNode(nnkElifBranch)
  jsBranch.add(definedJs)
  jsBranch.add(newCall("addDomEvent", nodeVar, newStrLitNode(eventName), handlerExpr))
  let elseBranch = newNimNode(nnkElse)
  elseBranch.add(newCall("addEvent", nodeVar, newStrLitNode(eventName), newCall("$", handlerExpr)))
  result.add(jsBranch)
  result.add(elseBranch)

proc buildElementCall(tag: string, staticAttrs: seq[(string, string)],
    reactiveAttrExprs: seq[(string, NimNode)], events: seq[(string, NimNode)],
    children: seq[NimNode]): NimNode =
  result = newNimNode(nnkStmtList)
  let nodeVar = genSym(nskLet, "node")
  result.add(newLetStmt(nodeVar, newCall("elementNode", newStrLitNode(tag))))

  for (key, value) in staticAttrs:
    result.add(newCall("addAttribute", nodeVar, newStrLitNode(key),
        newStrLitNode(value)))

  for (name, expr) in reactiveAttrExprs:
    result.add(buildReactiveAttr(nodeVar, name, expr))

  for (eventName, handlerExpr) in events:
    result.add(buildEventHandlerCode(nodeVar, eventName, handlerExpr))

  for child in children:
    result.add(newCall("addChild", nodeVar, child))

  result.add(nodeVar)

proc parseAttrs(args: NimNode, startIdx: int, extractBody: var NimNode): (seq[(string, string)], seq[(string, NimNode)], seq[(string, NimNode)]) =
  var staticAttrs: seq[(string, string)] = @[]
  var reactiveAttrs: seq[(string, NimNode)] = @[]
  var events: seq[(string, NimNode)] = @[]
  for i in startIdx ..< args.len:
    let arg = args[i]
    if arg.kind == nnkExprEqExpr and arg[0].kind == nnkIdent:
      let attrName = $arg[0]
      if isEventAttr(attrName):
        events.add((getEventName(attrName), arg[1]))
      elif arg[1].kind == nnkStrLit:
        staticAttrs.add((attrName, $arg[1]))
      else:
        reactiveAttrs.add((attrName, arg[1]))
    elif arg.kind == nnkInfix and arg.len == 3 and ($arg[0]).startsWith("=") and arg[1].kind == nnkIdent:
      let attrName = $arg[1]
      if isEventAttr(attrName):
        events.add((getEventName(attrName), arg[2]))
      elif arg[2].kind == nnkStrLit:
        staticAttrs.add((attrName, $arg[2]))
      else:
        reactiveAttrs.add((attrName, arg[2]))
    elif arg.kind == nnkStmtList:
      extractBody = arg
  result = (staticAttrs, reactiveAttrs, events)

proc extractAttrsAndBody(body: NimNode): tuple[staticAttrs: seq[(string, string)], reactiveAttrs: seq[(string, NimNode)], events: seq[(string, NimNode)], children: seq[NimNode]] =
  result.staticAttrs = @[]
  result.reactiveAttrs = @[]
  result.events = @[]
  result.children = @[]

  if body == nil:
    return

  for child in body:
    case child.kind
    of nnkStrLit:
      result.children.add(buildTextNode($child))
    of nnkCommand:
      if $child[0] == "text" and child.len >= 2:
        if child[1].kind == nnkStrLit:
          result.children.add(buildTextNode($child[1]))
        else:
          result.children.add(buildReactiveTextNode(child[1]))
    of nnkCall:
      let callee = $child[0]
      if callee == "text" and child.len >= 2:
        if child[1].kind == nnkStrLit:
          result.children.add(buildTextNode($child[1]))
        else:
          result.children.add(buildReactiveTextNode(child[1]))
        continue

      var tagName: string
      var nestedBody: NimNode = nil
      var sAttrs: seq[(string, string)] = @[]
      var rAttrs: seq[(string, NimNode)] = @[]
      var evts: seq[(string, NimNode)] = @[]

      if callee == "el" and child.len >= 2 and child[1].kind == nnkStrLit:
        tagName = $child[1]
        (sAttrs, rAttrs, evts) = parseAttrs(child, 2, nestedBody)
      else:
        tagName = callee
        (sAttrs, rAttrs, evts) = parseAttrs(child, 1, nestedBody)

      let (nestedStaticAttrs, nestedReactiveAttrs, nestedEvents, nestedChildren) = extractAttrsAndBody(nestedBody)
      for a in nestedStaticAttrs: sAttrs.add(a)
      for a in nestedReactiveAttrs: rAttrs.add(a)
      for e in nestedEvents: evts.add(e)
      result.children.add(buildElementCall(tagName, sAttrs, rAttrs, evts, nestedChildren))
    of nnkIfStmt:
      let ifBranch = child[0]  # ElifBranch
      let conditionExpr = ifBranch[0]
      let thenBody = ifBranch[1]  # StmtList
      
      var elseNode: NimNode = nil
      if child.len > 1 and child[1].kind == nnkElse:
        let elseBody = child[1][0]
        let (_, _, _, elseChildren) = extractAttrsAndBody(elseBody)
        if elseChildren.len == 1:
          elseNode = elseChildren[0]
        elif elseChildren.len > 1:
          elseNode = buildElementCall("div", @[], @[], @[], elseChildren)
        else:
          elseNode = newCall("elementNode", newStrLitNode("div"))

      if elseNode == nil:
        elseNode = newCall("elementNode", newStrLitNode("div"))

      let (_, _, _, thenChildren) = extractAttrsAndBody(thenBody)
      var thenNode: NimNode
      if thenChildren.len == 1:
        thenNode = thenChildren[0]
      elif thenChildren.len > 1:
        thenNode = buildElementCall("div", @[], @[], @[], thenChildren)
      else:
        thenNode = newCall("elementNode", newStrLitNode("div"))
      
      let conditionProc = newNimNode(nnkLambda)
      conditionProc.add(newEmptyNode())
      conditionProc.add(newEmptyNode())
      conditionProc.add(newEmptyNode())
      let formalParams = newNimNode(nnkFormalParams)
      formalParams.add(ident("bool"))
      conditionProc.add(formalParams)
      conditionProc.add(newEmptyNode())
      conditionProc.add(newEmptyNode())
      conditionProc.add(newStmtList(conditionExpr))
      
      result.children.add(newCall("conditionalNode", conditionProc, thenNode, elseNode))
    of nnkInfix, nnkPrefix:
      result.children.add(buildReactiveTextNode(child))
    of nnkIdent, nnkDotExpr, nnkBracketExpr, nnkPar, nnkCast, nnkObjConstr, nnkCurly, nnkLambda:
      result.children.add(buildReactiveTextNode(child))
    else:
      result.children.add(newCall("textNode", newCall("$", child)))

macro html*(body: untyped): untyped =
  let (staticAttrs, reactiveAttrs, events, children) = extractAttrsAndBody(body)
  if children.len == 1:
    result = children[0]
  elif children.len > 1:
    result = buildElementCall("div", staticAttrs, reactiveAttrs, events, children)
  else:
    result = newCall("elementNode", newStrLitNode("div"))

macro buildHtml*(body: untyped): untyped =
  ## Build an HtmlNode tree from a DSL.
  ## Automatically detects reactive expressions in text() and attributes
  ## and generates reactiveTextNode / addReactiveAttr when compiled with nim js.
  ## Event attributes (onClick, onInput, etc.) are detected and generate
  ## addDomEvent calls for client-side rendering.
  let (staticAttrs, reactiveAttrs, events, children) = extractAttrsAndBody(body)
  if children.len == 1:
    result = children[0]
  elif children.len > 1:
    result = buildElementCall("div", staticAttrs, reactiveAttrs, events, children)
  else:
    result = newCall("elementNode", newStrLitNode("div"))

macro el*(args: varargs[untyped]): untyped =
  ## Create an HTML element. First arg is tag name, rest are attrs or body.
  ## Attributes with non-string-literal values become reactive when compiled with nim js.
  ## Event attributes (onClick, onInput, etc.) generate addDomEvent for CSR.
  ## Usage:
  ##   el("div", class="app", id="main"):
  ##     text("Hello")
  if args.len == 0:
    error("el macro requires at least a tag name")
  let tag = $args[0]
  var body: NimNode = nil
  let (sAttrs, rAttrs, evts) = parseAttrs(args, 1, body)
  let (_, _, _, children) = extractAttrsAndBody(body)
  result = buildElementCall(tag, sAttrs, rAttrs, evts, children)

import std/macros
import std/strutils
import ../dom/node

export node

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

proc buildElementCall(tag: string, staticAttrs: seq[(string, string)],
    reactiveAttrExprs: seq[(string, NimNode)], children: seq[NimNode]): NimNode =
  result = newNimNode(nnkStmtList)
  let nodeVar = genSym(nskLet, "node")
  result.add(newLetStmt(nodeVar, newCall("elementNode", newStrLitNode(tag))))

  for (key, value) in staticAttrs:
    result.add(newCall("addAttribute", nodeVar, newStrLitNode(key),
        newStrLitNode(value)))

  for (name, expr) in reactiveAttrExprs:
    result.add(buildReactiveAttr(nodeVar, name, expr))

  for child in children:
    result.add(newCall("addChild", nodeVar, child))

  result.add(nodeVar)

proc extractAttrsAndBody(body: NimNode): tuple[staticAttrs: seq[(string, string)], reactiveAttrs: seq[(string, NimNode)], children: seq[NimNode]] =
  result.staticAttrs = @[]
  result.reactiveAttrs = @[]
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
      var staticAttrs: seq[(string, string)] = @[]
      var reactiveAttrs: seq[(string, NimNode)] = @[]
      var nestedBody: NimNode = nil

      if callee == "el" and child.len >= 2 and child[1].kind == nnkStrLit:
        tagName = $child[1]
        for i in 2 ..< child.len:
          let arg = child[i]
          if arg.kind == nnkExprEqExpr and arg[0].kind == nnkIdent:
            if arg[1].kind == nnkStrLit:
              staticAttrs.add(($arg[0], $arg[1]))
            else:
              reactiveAttrs.add(($arg[0], arg[1]))
          elif arg.kind == nnkInfix and arg.len == 3 and ($arg[0]).startsWith("=") and arg[1].kind == nnkIdent:
            if arg[2].kind == nnkStrLit:
              staticAttrs.add(($arg[1], $arg[2]))
            else:
              reactiveAttrs.add(($arg[1], arg[2]))
          elif arg.kind == nnkStmtList:
            nestedBody = arg
      else:
        tagName = callee
        for i in 1 ..< child.len:
          let arg = child[i]
          if arg.kind == nnkExprEqExpr and arg[0].kind == nnkIdent:
            if arg[1].kind == nnkStrLit:
              staticAttrs.add(($arg[0], $arg[1]))
            else:
              reactiveAttrs.add(($arg[0], arg[1]))
          elif arg.kind == nnkInfix and arg.len == 3 and ($arg[0]).startsWith("=") and arg[1].kind == nnkIdent:
            if arg[2].kind == nnkStrLit:
              staticAttrs.add(($arg[1], $arg[2]))
            else:
              reactiveAttrs.add(($arg[1], arg[2]))
          elif arg.kind == nnkStmtList:
            nestedBody = arg

      let (nestedStaticAttrs, nestedReactiveAttrs, nestedChildren) = extractAttrsAndBody(nestedBody)
      for a in nestedStaticAttrs:
        staticAttrs.add(a)
      for a in nestedReactiveAttrs:
        reactiveAttrs.add(a)
      result.children.add(buildElementCall(tagName, staticAttrs, reactiveAttrs, nestedChildren))
    of nnkIfStmt:
      let ifBranch = child[0]  # ElifBranch
      let conditionExpr = ifBranch[0]
      let thenBody = ifBranch[1]  # StmtList
      
      var elseNode: NimNode = nil
      if child.len > 1 and child[1].kind == nnkElse:
        let elseBody = child[1][0]  # StmtList
        let (_, _, elseChildren) = extractAttrsAndBody(elseBody)
        if elseChildren.len == 1:
          elseNode = elseChildren[0]
        elif elseChildren.len > 1:
          elseNode = buildElementCall("div", @[], @[], elseChildren)
        else:
          elseNode = newCall("elementNode", newStrLitNode("div"))
      
      if elseNode == nil:
        elseNode = newCall("elementNode", newStrLitNode("div"))
      
      let (_, _, thenChildren) = extractAttrsAndBody(thenBody)
      var thenNode: NimNode
      if thenChildren.len == 1:
        thenNode = thenChildren[0]
      elif thenChildren.len > 1:
        thenNode = buildElementCall("div", @[], @[], thenChildren)
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
    of nnkInfix:
      if child.len == 3 and $child[0] == "&":
        result.children.add(newCall("textNode", child))
      else:
        result.children.add(newCall("textNode", newCall("$", child)))
    of nnkPrefix:
      result.children.add(newCall("textNode", newCall("$", child)))
    else:
      result.children.add(newCall("textNode", newCall("$", child)))

macro html*(body: untyped): untyped =
  let (staticAttrs, reactiveAttrs, children) = extractAttrsAndBody(body)
  if children.len == 1:
    result = children[0]
  elif children.len > 1:
    result = buildElementCall("div", staticAttrs, reactiveAttrs, children)
  else:
    result = newCall("elementNode", newStrLitNode("div"))

macro buildHtml*(body: untyped): untyped =
  ## Build an HtmlNode tree from a DSL.
  ## Automatically detects reactive expressions in text() and attributes
  ## and generates reactiveTextNode / addReactiveAttr when compiled with nim js.
  let (staticAttrs, reactiveAttrs, children) = extractAttrsAndBody(body)
  if children.len == 1:
    result = children[0]
  elif children.len > 1:
    result = buildElementCall("div", staticAttrs, reactiveAttrs, children)
  else:
    result = newCall("elementNode", newStrLitNode("div"))

macro el*(args: varargs[untyped]): untyped =
  ## Create an HTML element. First arg is tag name, rest are attrs or body.
  ## Attributes with non-string-literal values become reactive when compiled with nim js.
  ## Usage:
  ##   el("div", class="app", id="main"):
  ##     text("Hello")
  if args.len == 0:
    error("el macro requires at least a tag name")
  let tag = $args[0]
  var staticAttrs: seq[(string, string)] = @[]
  var reactiveAttrs: seq[(string, NimNode)] = @[]
  var body: NimNode = nil

  for i in 1 ..< args.len:
    let arg = args[i]
    if arg.kind == nnkExprEqExpr and arg[0].kind == nnkIdent:
      if arg[1].kind == nnkStrLit:
        staticAttrs.add(($arg[0], $arg[1]))
      else:
        reactiveAttrs.add(($arg[0], arg[1]))
    elif arg.kind == nnkInfix and arg.len == 3 and ($arg[0]).startsWith("=") and arg[1].kind == nnkIdent:
      if arg[2].kind == nnkStrLit:
        staticAttrs.add(($arg[1], $arg[2]))
      else:
        reactiveAttrs.add(($arg[1], arg[2]))
    elif arg.kind == nnkStmtList:
      body = arg

  let (_, _, children) = extractAttrsAndBody(body)
  result = buildElementCall(tag, staticAttrs, reactiveAttrs, children)

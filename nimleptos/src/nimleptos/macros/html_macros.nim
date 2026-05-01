import std/macros
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

  # Build lambda: proc(): string = $expr
  let getterProc = newNimNode(nnkLambda)
  getterProc.add(newEmptyNode())  # name
  getterProc.add(newEmptyNode())  # generics
  getterProc.add(newEmptyNode())  # pragmas
  let formalParams = newNimNode(nnkFormalParams)
  formalParams.add(ident("string"))  # return type
  getterProc.add(formalParams)
  getterProc.add(newEmptyNode())  # reserved
  getterProc.add(newEmptyNode())  # reserved
  getterProc.add(newStmtList(strExpr))  # body

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

proc buildElementCall(tag: string, attrs: seq[(string, string)],
    children: seq[NimNode]): NimNode =
  result = newNimNode(nnkStmtList)
  let nodeVar = genSym(nskLet, "node")
  result.add(newLetStmt(nodeVar, newCall("elementNode", newStrLitNode(tag))))

  for (key, value) in attrs:
    result.add(newCall("addAttribute", nodeVar, newStrLitNode(key),
        newStrLitNode(value)))

  for child in children:
    result.add(newCall("addChild", nodeVar, child))

  result.add(nodeVar)

proc extractAttrsAndBody(body: NimNode): tuple[attrs: seq[(string, string)], children: seq[NimNode]] =
  result.attrs = @[]
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
      var attrs: seq[(string, string)] = @[]
      var nestedBody: NimNode = nil

      if callee == "el" and child.len >= 2 and child[1].kind == nnkStrLit:
        tagName = $child[1]
        for i in 2 ..< child.len:
          let arg = child[i]
          if arg.kind == nnkExprEqExpr and arg[0].kind == nnkIdent and arg[1].kind == nnkStrLit:
            attrs.add(($arg[0], $arg[1]))
          elif arg.kind == nnkStmtList:
            nestedBody = arg
      else:
        tagName = callee
        for i in 1 ..< child.len:
          let arg = child[i]
          if arg.kind == nnkExprEqExpr and arg[0].kind == nnkIdent and arg[1].kind == nnkStrLit:
            attrs.add(($arg[0], $arg[1]))
          elif arg.kind == nnkStmtList:
            nestedBody = arg

      let (nestedAttrs, nestedChildren) = extractAttrsAndBody(nestedBody)
      for a in nestedAttrs:
        attrs.add(a)
      result.children.add(buildElementCall(tagName, attrs, nestedChildren))
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
  let (attrs, children) = extractAttrsAndBody(body)
  if children.len == 1:
    result = children[0]
  elif children.len > 1:
    result = buildElementCall("div", attrs, children)
  else:
    result = newCall("elementNode", newStrLitNode("div"))

macro buildHtml*(body: untyped): untyped =
  ## Build an HtmlNode tree from a DSL.
  ## Usage:
  ##   let node = buildHtml:
  ##     el("div", class="app"):
  ##       el("h1"): text("Title")
  ##       el("p"): text("Hello")
  let (attrs, children) = extractAttrsAndBody(body)
  if children.len == 1:
    result = children[0]
  elif children.len > 1:
    result = buildElementCall("div", attrs, children)
  else:
    result = newCall("elementNode", newStrLitNode("div"))

macro el*(args: varargs[untyped]): untyped =
  ## Create an HTML element. First arg is tag name, rest are attrs or body.
  ## Usage:
  ##   el("div", class="app", id="main"):
  ##     text("Hello")
  if args.len == 0:
    error("el macro requires at least a tag name")
  let tag = $args[0]
  var attrs: seq[(string, string)] = @[]
  var body: NimNode = nil

  for i in 1 ..< args.len:
    let arg = args[i]
    if arg.kind == nnkExprEqExpr and arg[0].kind == nnkIdent and arg[1].kind == nnkStrLit:
      attrs.add(($arg[0], $arg[1]))
    elif arg.kind == nnkStmtList:
      body = arg

  let (_, children) = extractAttrsAndBody(body)
  result = buildElementCall(tag, attrs, children)

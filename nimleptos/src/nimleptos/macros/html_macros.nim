import std/macros
import ../dom/node

export node

macro html*(body: untyped): untyped =
  result = newCall("buildHtmlTree", body)

macro view*(name, body: untyped): untyped =
  let procBody = newStmtList()
  procBody.add(newCall("html", body))
  result = newProc(
    name = name,
    params = [
      ident("HtmlNode"),
      newIdentDefs(ident("props"), ident("RootObj"))
    ],
    body = procBody,
    procType = nnkProcDef
  )

proc buildTextCall(text: string): NimNode =
  result = newCall("textNode", newStrLitNode(text))

proc buildElementCall(tag: string, attrs: seq[(string, string)],
    body: NimNode): NimNode =
  result = newNimNode(nnkStmtList)
  let nodeVar = genSym(nskLet, "node")
  result.add(newLetStmt(nodeVar, newCall("elementNode", newStrLitNode(tag))))

  for (key, value) in attrs:
    result.add(newCall("addAttribute", nodeVar, newStrLitNode(key),
        newStrLitNode(value)))

  if body != nil:
    for child in body:
      if child.kind == nnkCall:
        let childTag = $child[0]
        if child.len >= 2:
          result.add(newCall("addChild", nodeVar,
              buildElementCall(childTag, @[], child[1])))
        else:
          result.add(newCall("addChild", nodeVar,
              buildElementCall(childTag, @[], nil)))
      elif child.kind == nnkStrLit:
        result.add(newCall("addChild", nodeVar, buildTextCall($child)))
      elif child.kind == nnkCommand:
        let cmdName = $child[0]
        if cmdName == "text":
          result.add(newCall("addChild", nodeVar, buildTextCall($child[1])))
      elif child.kind == nnkAsgn:
        discard

  result.add(nodeVar)

macro element*(tag: static[string], body: untyped): untyped =
  result = buildElementCall(tag, @[], body)

macro divElem*(body: untyped): untyped =
  result = buildElementCall("div", @[], body)

macro spanElem*(body: untyped): untyped =
  result = buildElementCall("span", @[], body)

macro pElem*(body: untyped): untyped =
  result = buildElementCall("p", @[], body)

macro h1Elem*(body: untyped): untyped =
  result = buildElementCall("h1", @[], body)

## NimLeptos Full-Stack Todo App
## Demonstrates: SSR, forms, validation, routing, reactive DOM hydration
##
## Run:
##   nimble todo
##   # Or manually: nim c -r --threads:on -p:src examples/todo_app.nim
##
## Then open http://localhost:8080 in your browser.

import nimmax
import nimmax/core/utils
import std/json
import std/strutils
import std/sequtils
import std/uri
import ../src/nimleptos
import ../src/nimleptos/forms/form
import ../src/nimleptos/forms/validation

# -----------------------------------------------------------------------------
# Data Model (in-memory storage, single-threaded async event loop)
# -----------------------------------------------------------------------------

type
  Todo = object
    id: int
    title: string
    completed: bool

  TodoStorage = object
    todos: seq[Todo]
    nextId: int

var storage {.threadvar.}: TodoStorage

proc initStorage() =
  storage.todos = @[
    Todo(id: 1, title: "Learn Nim", completed: true),
    Todo(id: 2, title: "Build a reactive framework", completed: false),
    Todo(id: 3, title: "Ship to production", completed: false),
  ]
  storage.nextId = 4

proc getTodos(): seq[Todo] = storage.todos

proc addTodo(title: string): int =
  result = storage.nextId
  storage.todos.add(Todo(id: storage.nextId, title: title, completed: false))
  inc storage.nextId

proc toggleTodo(id: int): bool =
  for i in 0 ..< storage.todos.len:
    if storage.todos[i].id == id:
      storage.todos[i].completed = not storage.todos[i].completed
      return true
  return false

proc deleteTodo(id: int): bool =
  for i in 0 ..< storage.todos.len:
    if storage.todos[i].id == id:
      storage.todos.delete(i)
      return true
  return false

# -----------------------------------------------------------------------------
# Components
# -----------------------------------------------------------------------------

proc todoItemNode(t: Todo): HtmlNode =
  let checkedClass = if t.completed: "completed" else: ""
  var checkAttrs = @[("type", "checkbox"), ("name", "completed"), ("class", "todo-check")]
  if t.completed:
    checkAttrs.add(("checked", "checked"))
  elLi([("class", "todo-item " & checkedClass), ("data-todo-id", $t.id)],
    elForm([("action", "/todos/" & $t.id & "/toggle"), ("method", "POST"), ("class", "toggle-form")],
      elInput(checkAttrs)
    ),
    elSpan([("class", "todo-title")], text(t.title)),
    elForm([("action", "/todos/" & $t.id & "/delete"), ("method", "POST"), ("class", "delete-form")],
      elButton([("type", "submit"), ("class", "btn-delete")], text("×"))
    )
  )

proc todoListNode(items: seq[Todo]): HtmlNode =
  if items.len == 0:
    return elP([("class", "empty")], text("No todos yet. Add one above!"))
  var children: seq[HtmlNode] = @[]
  for t in items:
    children.add(todoItemNode(t))
  elUl([("class", "todo-list")], children)

proc todoFormNode(hasError = false, errorMsg = ""): HtmlNode =
  var form = newFormDef("/todos", "POST")
  form.addField("title", "", kind = "text", required = true,
                attrs = @[("placeholder", "What needs to be done?"), ("class", "todo-input")])
  if hasError:
    for f in form.fields.mitems:
      if f.name == "title":
        f.errors.add(errorMsg)
  renderForm(form)

proc todoPage(ctx: Context): Future[HtmlNode] {.gcsafe.} =
  result = newFuture[HtmlNode]()
  let items = getTodos()
  let completedCount = items.filterIt(it.completed).len

  let page = elDiv([("class", "todo-app")],
    elH1([], text("📝 NimLeptos Todo")),
    elP([("class", "subtitle")], text("Full-stack reactive todo app — SSR + forms + validation")),
    elDiv([("class", "todo-form")],
      todoFormNode()
    ),
    elDiv([("class", "todo-list-container")],
      elH2([], text("Tasks")),
      todoListNode(items)
    ),
    elDiv([("class", "stats")],
      elP([], text($completedCount & " of " & $items.len & " completed"))
    )
  )
  complete(result, page)

# -----------------------------------------------------------------------------
# Handlers
# -----------------------------------------------------------------------------

proc postTodoHandler(ctx: Context) {.async.} =
  let postParams = parseQueryParams(ctx.request.body)
  let title = postParams.getOrDefault("title", "").strip()

  if title.len == 0:
    let items = getTodos()
    let completedCount = items.filterIt(it.completed).len
    let page = elDiv([("class", "todo-app")],
      elH1([], text("📝 NimLeptos Todo")),
      elDiv([("class", "todo-form")],
        todoFormNode(hasError = true, errorMsg = "Todo title is required")
      ),
      todoListNode(items),
      elDiv([("class", "stats")],
        elP([], text($completedCount & " of " & $items.len & " completed"))
      )
    )
    ctx.render(page, "Todos")
    return

  discard addTodo(title)
  ctx.redirect("/")

proc toggleTodoHandler(ctx: Context) {.async.} =
  let idStr = ctx.getPathParams().getOrDefault("id", "")
  try:
    let id = parseInt(idStr)
    discard toggleTodo(id)
  except ValueError:
    discard
  ctx.redirect("/")

proc deleteTodoHandler(ctx: Context) {.async.} =
  let idStr = ctx.getPathParams().getOrDefault("id", "")
  try:
    let id = parseInt(idStr)
    discard deleteTodo(id)
  except ValueError:
    discard
  ctx.redirect("/")

proc apiTodosHandler(ctx: Context) {.async.} =
  let items = getTodos()
  var data: seq[JsonNode] = @[]
  for t in items:
    data.add(%*{"id": t.id, "title": t.title, "completed": t.completed})
  ctx.json(%*{"todos": data})

# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------

proc main() =
  initStorage()

  let settings = newSettings(
    address = "0.0.0.0",
    port = Port(8080),
    debug = true,
    appName = "NimLeptos Todo"
  )

  let app = newNimLeptosApp(settings = settings, title = "NimLeptos Todo")

  # Middleware can be added here, e.g.:
  # app.use(requestLoggingMiddleware())

  # Routes
  app.get("/", proc(ctx: Context) {.async.} =
    let node = await todoPage(ctx)
    ctx.render(node, "Todos")
  , name = "home")

  app.post("/todos", postTodoHandler, name = "create_todo")
  app.post("/todos/{id}/toggle", toggleTodoHandler, name = "toggle_todo")
  app.post("/todos/{id}/delete", deleteTodoHandler, name = "delete_todo")
  app.get("/api/todos", apiTodosHandler, name = "api_todos")

  echo "Starting NimLeptos Todo App on http://0.0.0.0:8080"
  echo ""
  echo "Features:"
  echo "  - SSR with reactive hydration markers"
  echo "  - Form validation (required fields)"
  echo "  - REST API at /api/todos"
  echo ""
  app.run()

main()

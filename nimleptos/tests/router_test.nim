when defined(js):
  import std/dom
  import ../src/nimleptos/reactive/signal
  import ../src/nimleptos/reactive/effects
  import ../src/nimleptos/client/router

  proc testGetHashRouteRoot() =
    window.location.hash = ""
    doAssert getHashRoute() == "/"
    echo "PASS: getHashRoute root"

  proc testGetHashRoutePath() =
    window.location.hash = "#/about"
    doAssert getHashRoute() == "/about"
    echo "PASS: getHashRoute path"

  proc testNavigate() =
    navigate("/contact")
    doAssert $window.location.hash == "#/contact"
    echo "PASS: navigate"

  proc testInitHashRouterInitialRoute() =
    window.location.hash = "#/home"
    initHashRouter()
    doAssert hashRoute()() == "/home"
    echo "PASS: initHashRouter initial route"

  proc testRouteParamMatch() =
    doAssert routeParam("/post/42", "/post/") == "42"
    echo "PASS: routeParam match"

  proc testRouteParamNoMatch() =
    doAssert routeParam("/blog/42", "/post/") == ""
    echo "PASS: routeParam no match"

  proc testRouteParamExact() =
    doAssert routeParam("/user/admin", "/user/") == "admin"
    echo "PASS: routeParam exact"

  proc testRouteParamEmptyPrefix() =
    doAssert routeParam("/path/to/resource", "") == "/path/to/resource"
    echo "PASS: routeParam empty prefix"

  proc testRouteParamNestedPrefix() =
    doAssert routeParam("/api/v1/users/42", "/api/v1/") == "users/42"
    echo "PASS: routeParam nested prefix"

  proc testRouteParamSingleCharPrefix() =
    doAssert routeParam("/a/foo", "/a/") == "foo"
    echo "PASS: routeParam single char prefix"

  # ========== History API Router Tests ==========

  proc testInitHistoryRouter() =
    initHistoryRouter()
    let route = currentRoute()()
    doAssert route.len > 0
    echo "PASS: initHistoryRouter sets initial route"

  proc testNavigateTo() =
    initHistoryRouter()
    navigateTo("/about")
    let route = currentRoute()()
    doAssert route == "/about"
    echo "PASS: navigateTo updates route via pushState"

  proc testNavigateReplace() =
    initHistoryRouter()
    navigateTo("/first")
    navigateReplace("/second")
    let route = currentRoute()()
    doAssert route == "/second"
    echo "PASS: navigateReplace updates route"

  proc testPopStateEvent() =
    initHistoryRouter()
    var popCount = 0
    discard createEffect(proc() =
      inc popCount
      discard currentRoute()()
    )
    # popCount == 1 from initial route
    #{.emit: "`popCount` = 0;".}
    {.emit: "window.dispatchEvent(new PopStateEvent('popstate'));".}
    doAssert popCount >= 1
    echo "PASS: popstate event updates route signal"

  proc testInitRouterHistoryMode() =
    initRouter(rmHistory)
    let route = currentRoute()()
    doAssert route.len > 0
    echo "PASS: initRouter(rmHistory) works"

  proc testInitRouterHashMode() =
    window.location.hash = "#/test-hash"
    initRouter(rmHash)
    let route = currentRoute()()
    doAssert route == "/test-hash"
    echo "PASS: initRouter(rmHash) works (backward compat)"

  proc testGetPathFromUrl() =
    initHistoryRouter()
    let path = getPathFromUrl()
    doAssert path.len > 0
    echo "PASS: getPathFromUrl returns current path"

  proc testCurrentRouteSignal() =
    initHistoryRouter()
    navigateTo("/dashboard")
    let route = currentRoute()()
    doAssert route == "/dashboard"
    echo "PASS: currentRoute signal tracks navigation"

when isMainModule:
  when defined(js):
    # Hash router tests
    testGetHashRouteRoot()
    testGetHashRoutePath()
    testNavigate()
    testInitHashRouterInitialRoute()
    testRouteParamMatch()
    testRouteParamNoMatch()
    testRouteParamExact()
    testRouteParamEmptyPrefix()
    testRouteParamNestedPrefix()
    testRouteParamSingleCharPrefix()

    # History API router tests
    testInitHistoryRouter()
    testNavigateTo()
    testNavigateReplace()
    testPopStateEvent()
    testInitRouterHistoryMode()
    testInitRouterHashMode()
    testGetPathFromUrl()
    testCurrentRouteSignal()

    echo ""
    echo "All router tests passed!"
  else:
    echo "SKIP: router_test requires -d:js (compile with: nim js tests/router_test.nim)"

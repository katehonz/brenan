when defined(js):
  import std/dom
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

when isMainModule:
  when defined(js):
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
    echo ""
    echo "All router tests passed!"
  else:
    echo "SKIP: router_test requires -d:js (compile with: nim js tests/router_test.nim)"

## HTTP Client for NimLeptos (JS target)
## Thin wrapper around browser fetch API with JSON parsing

import std/json

when defined(js):
  import std/jsffi

  proc fetchRaw(url: cstring): JsObject {.importjs: "fetch(#)".}
  proc fetchRaw(url: cstring, options: JsObject): JsObject {.importjs: "fetch(#, #)".}
  proc thenRaw(p: JsObject, fn: proc(v: JsObject)): JsObject {.importjs: "#.then(#)".}
  proc catchRaw(p: JsObject, fn: proc(v: JsObject)): JsObject {.importjs: "#.catch(#)".}
  proc textRaw(p: JsObject): JsObject {.importjs: "#.text()".}

  type
    FetchSuccessCallback* = proc(data: JsonNode) {.closure.}
    FetchErrorCallback* = proc(msg: string) {.closure.}

  proc fetchGetJson*(url: string, onSuccess: FetchSuccessCallback, onError: FetchErrorCallback = nil) =
    ## Perform a GET request and parse JSON response
    let promise = fetchRaw(url.cstring)
    discard thenRaw(promise, proc(response: JsObject) =
      let textPromise = textRaw(response)
      discard thenRaw(textPromise, proc(textData: JsObject) =
        let jsonStr = $textData.to(cstring)
        try:
          onSuccess(parseJson(jsonStr))
        except JsonParsingError:
          if onError != nil:
            onError("JSON parse error")
      )
    )
    discard catchRaw(promise, proc(err: JsObject) =
      if onError != nil:
        onError($err.to(cstring))
    )

  proc fetchPostJson*(url: string, body: string, onSuccess: FetchSuccessCallback, onError: FetchErrorCallback = nil) =
    ## Perform a POST request with JSON body and parse JSON response
    var options = newJsObject()
    options["method"] = "POST".cstring
    options["headers"] = newJsObject()
    options["headers"]["Content-Type"] = "application/json".cstring
    options["body"] = body.cstring

    let promise = fetchRaw(url.cstring, options)
    discard thenRaw(promise, proc(response: JsObject) =
      let textPromise = textRaw(response)
      discard thenRaw(textPromise, proc(textData: JsObject) =
        let jsonStr = $textData.to(cstring)
        try:
          onSuccess(parseJson(jsonStr))
        except JsonParsingError:
          if onError != nil:
            onError("JSON parse error")
      )
    )
    discard catchRaw(promise, proc(err: JsObject) =
      if onError != nil:
        onError($err.to(cstring))
    )

else:
  type
    FetchSuccessCallback* = proc(data: JsonNode) {.closure.}
    FetchErrorCallback* = proc(msg: string) {.closure.}

  proc fetchGetJson*(url: string, onSuccess: FetchSuccessCallback, onError: FetchErrorCallback = nil) =
    discard

  proc fetchPostJson*(url: string, body: string, onSuccess: FetchSuccessCallback, onError: FetchErrorCallback = nil) =
    discard

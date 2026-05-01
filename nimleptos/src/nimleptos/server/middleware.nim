import nimmax

proc hydrationMiddleware*(ssrCtx: pointer): HandlerAsync =
  result = proc(ctx: Context): Future[void] {.async, gcsafe.} =
    await switch(ctx)

proc titleMiddleware*(defaultTitle: string): HandlerAsync =
  result = proc(ctx: Context): Future[void] {.async, gcsafe.} =
    ctx["__title__"] = %defaultTitle
    await switch(ctx)

proc clientAssetsMiddleware*(script: string = "", style: string = ""): HandlerAsync =
  result = proc(ctx: Context): Future[void] {.async, gcsafe.} =
    ctx["__client_script__"] = %script
    ctx["__client_style__"] = %style
    await switch(ctx)

import nimmax

proc hydrationMiddleware*(): HandlerAsync =
  result = proc(ctx: Context): Future[void] {.async, gcsafe.} =
    ctx["__hydration_enabled__"] = %true
    await switch(ctx)

proc titleMiddleware*(defaultTitle: string): HandlerAsync =
  result = proc(ctx: Context): Future[void] {.async, gcsafe.} =
    ctx["__title__"] = %defaultTitle
    await switch(ctx)

proc clientAssetsMiddleware*(script: string = "", style: string = ""): HandlerAsync =
  result = proc(ctx: Context): Future[void] {.async, gcsafe.} =
    if script.len > 0:
      ctx["__client_script__"] = %script
    if style.len > 0:
      ctx["__client_style__"] = %style
    await switch(ctx)

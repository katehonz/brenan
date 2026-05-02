import nimmax
import std/[asyncdispatch, strutils, json, times, tables, httpcore]
import jwt

type
  AuthUser* = ref object
    id*: string
    username*: string
    email*: string
    role*: string
    permissions*: seq[string]

  CredentialChecker* = proc(username, password: string): AuthUser {.gcsafe.}

  JwtConfig* = object
    secret*: string
    accessExpiry*: Duration
    refreshExpiry*: Duration
    issuer*: string

var defaultJwtConfig = JwtConfig(
  secret: "",
  accessExpiry: initDuration(hours = 1),
  refreshExpiry: initDuration(days = 30),
  issuer: "nimleptos",
)

proc claimsToAuthUser(claims: TableRef[string, Claim]): AuthUser =
  let sub = claims.getOrDefault("sub")
  if sub == nil:
    return nil
  let perms = claims.getOrDefault("perms")
  var permList: seq[string] = @[]
  if perms != nil and perms.node.kind == JString:
    permList = perms.node.getStr().split(",")
  AuthUser(
    id: sub.node.getStr(),
    username: claims.getOrDefault("username", newStringClaim("")).node.getStr(),
    email: claims.getOrDefault("email", newStringClaim("")).node.getStr(),
    role: claims.getOrDefault("role", newStringClaim("")).node.getStr(),
    permissions: permList,
  )

proc authUserToClaims(user: AuthUser, expiry: Duration): (JsonNode, TableRef[string, Claim]) =
  let now = getTime()
  let header = %*{"alg": %HS256, "typ": "JWT"}
  var claims = newClaims()
  claims["sub"] = newStringClaim(user.id)
  claims["username"] = newStringClaim(user.username)
  claims["role"] = newStringClaim(user.role)
  if user.email.len > 0:
    claims["email"] = newStringClaim(user.email)
  if user.permissions.len > 0:
    claims["perms"] = newStringClaim(user.permissions.join(","))
  claims["iat"] = newTimeClaim(now)
  claims["exp"] = newTimeClaim(now + expiry)
  result = (header, claims)

proc createAccessToken*(user: AuthUser, secret: string, expiry: Duration = defaultJwtConfig.accessExpiry): string =
  let (header, claims) = authUserToClaims(user, expiry)
  var token = initJWT(header, claims)
  token.sign(secret)
  return $token

proc createRefreshToken*(userId: string, secret: string, expiry: Duration = defaultJwtConfig.refreshExpiry): string =
  let now = getTime()
  let header = %*{"alg": %HS256, "typ": "JWT"}
  var claims = newClaims()
  claims["sub"] = newStringClaim(userId)
  claims["token_type"] = newStringClaim("refresh")
  claims["iat"] = newTimeClaim(now)
  claims["exp"] = newTimeClaim(now + expiry)
  var token = initJWT(header, claims)
  token.sign(secret)
  return $token

proc verifyToken*(tokenStr: string, secret: string = defaultJwtConfig.secret): AuthUser =
  try:
    let token = tokenStr.toJWT()
    if not token.verify(secret, HS256):
      return nil
    if token.claims.getOrDefault("token_type", newStringClaim("")).node.getStr() == "refresh":
      return nil
    return claimsToAuthUser(token.claims)
  except CatchableError:
    return nil

proc verifyRefreshToken*(tokenStr: string, secret: string = defaultJwtConfig.secret): string =
  try:
    let token = tokenStr.toJWT()
    if not token.verify(secret, HS256):
      return ""
    if token.claims.getOrDefault("token_type", newStringClaim("")).node.getStr() != "refresh":
      return ""
    return token.claims["sub"].node.getStr()
  except CatchableError:
    return ""

proc extractAuthUser*(ctx: Context): AuthUser =
  let node = ctx["nl_auth_user"]
  if node.kind == JNull:
    return nil
  let permsRaw = node{"perms"}.getStr("")
  var permList: seq[string] = @[]
  if permsRaw.len > 0:
    permList = permsRaw.split(",")
  AuthUser(
    id: node{"id"}.getStr(),
    username: node{"username"}.getStr(),
    email: node{"email"}.getStr(),
    role: node{"role"}.getStr(),
    permissions: permList,
  )

proc setContextAuthUser*(ctx: Context, user: AuthUser) =
  ctx["nl_auth_user"] = %*{
    "id": user.id,
    "username": user.username,
    "email": user.email,
    "role": user.role,
    "perms": user.permissions.join(","),
  }

proc isAuthenticated*(ctx: Context): bool =
  ctx.extractAuthUser() != nil

proc hasRole*(ctx: Context, role: string): bool =
  let user = ctx.extractAuthUser()
  if user == nil:
    return false
  return user.role == role

proc hasPermission*(ctx: Context, perm: string): bool =
  let user = ctx.extractAuthUser()
  if user == nil:
    return false
  return perm in user.permissions

proc setJwtConfig*(config: JwtConfig) =
  defaultJwtConfig = config

proc setJwtSecret*(secret: string) =
  defaultJwtConfig.secret = secret

proc jwtAuthMiddleware*(secret: string = defaultJwtConfig.secret): HandlerAsync =
  let s = secret
  result = proc(ctx: Context): Future[void] {.async, gcsafe.} =
    var tokenStr = ""
    let hvals = ctx.request.headers.table.getOrDefault("Authorization", @[""])
    if hvals.len > 0:
      let hv = hvals[0]
      if hv.len >= 7 and hv[0..6].toLowerAscii() == "bearer ":
        tokenStr = hv[7 .. ^1].strip()
    if tokenStr.len > 0:
      let user = verifyToken(tokenStr, s)
      if user != nil:
        ctx.setContextAuthUser(user)
    await switch(ctx)

proc requireAuth*(secret: string = defaultJwtConfig.secret, redirectPath: string = "/login"): HandlerAsync =
  result = proc(ctx: Context): Future[void] {.async, gcsafe.} =
    if not ctx.isAuthenticated():
      ctx.redirect(redirectPath)
      return
    await switch(ctx)

proc requireRole*(role: string, redirectPath: string = "/login"): HandlerAsync =
  result = proc(ctx: Context): Future[void] {.async, gcsafe.} =
    if not ctx.isAuthenticated():
      ctx.redirect(redirectPath)
      return
    if not ctx.hasRole(role):
      ctx.response.code = Http403
      ctx.response.body = "Forbidden: insufficient role"
      return
    await switch(ctx)

proc requirePermission*(perm: string, redirectPath: string = "/login"): HandlerAsync =
  result = proc(ctx: Context): Future[void] {.async, gcsafe.} =
    if not ctx.isAuthenticated():
      ctx.redirect(redirectPath)
      return
    if not ctx.hasPermission(perm):
      ctx.response.code = Http403
      ctx.response.body = "Forbidden: insufficient permissions"
      return
    await switch(ctx)

proc loginHandler*(checkCreds: CredentialChecker, secret: string = defaultJwtConfig.secret): HandlerAsync =
  let s = secret
  let accessExp = defaultJwtConfig.accessExpiry
  let refreshExp = defaultJwtConfig.refreshExpiry
  result = proc(ctx: Context): Future[void] {.async, gcsafe.} =
    let username = ctx.request.postParams.getOrDefault("username", "")
    let password = ctx.request.postParams.getOrDefault("password", "")
    if username.len == 0 or password.len == 0:
      ctx.json(%*{"error": "username and password required"}, Http400)
      return
    let user = checkCreds(username, password)
    if user == nil:
      ctx.json(%*{"error": "invalid credentials"}, Http401)
      return
    let accessToken = createAccessToken(user, s, accessExp)
    let refreshToken = createRefreshToken(user.id, s, refreshExp)
    ctx.json(%*{
      "access_token": accessToken,
      "refresh_token": refreshToken,
      "token_type": "Bearer",
      "expires_in": accessExp.inSeconds,
      "user": {"id": user.id, "username": user.username, "role": user.role},
    }, Http200)

proc refreshHandler*(secret: string = defaultJwtConfig.secret): HandlerAsync =
  let s = secret
  let accessExp = defaultJwtConfig.accessExpiry
  result = proc(ctx: Context): Future[void] {.async, gcsafe.} =
    let refreshTokenStr = ctx.request.postParams.getOrDefault("refresh_token", "")
    if refreshTokenStr.len == 0:
      ctx.json(%*{"error": "refresh_token required"}, Http400)
      return
    let userId = verifyRefreshToken(refreshTokenStr, s)
    if userId.len == 0:
      ctx.json(%*{"error": "invalid or expired refresh token"}, Http401)
      return
    var user = AuthUser(id: userId)
    let accessToken = createAccessToken(user, s, accessExp)
    ctx.json(%*{
      "access_token": accessToken,
      "token_type": "Bearer",
      "expires_in": accessExp.inSeconds,
    }, Http200)

proc decodeToken*(tokenStr: string): JsonNode =
  try:
    let token = tokenStr.toJWT()
    var payload = newJObject()
    for key, claim in token.claims:
      payload[key] = claim.node
    result = payload
  except CatchableError:
    result = newJNull()

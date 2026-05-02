# Препоръки за развитие на NimMax Backend

> Този файл описва какви модули и функционалности да се добавят в `nimmax`, за да стане пълноценен production backend за `nimleptos` (и не само).
> Препоръките са **универсални** — важат за всяко full-stack приложение, не само за счетоводна програма.

---

## 1. Database Layer (Критично)

### Защо
В момента `nimmax` няма интеграция с база данни. Всички примери ползват in-memory storage.

### Какво да се добави
- **DB Connection Pool** — SQLite, PostgreSQL, MySQL
- **Async DB драйвери** — `asyncpg`-еквивалент за Nim или поне thread-safe пул
- **Migration система** — файлове `migrations/001_create_users.sql`, CLI команда `nimmax migrate`
- **Minimal ORM или Query Builder** — не е задължително да е пълен ORM, но поне:
  ```nim
  db.table("users").where("role = ?", "admin").select("id, username")
  ```

### Препоръчителни Nim пакети
- `norm` — ORM за Nim
- `ndb` или `db_connector` — ниско ниво
- `allographer` — query builder + migration

---

## 2. Password Hashing (Критично за Security)

### Защо
`nimleptos` има JWT auth, но **не** hash-ва паролите. `checkCreds` callback-ът е отговорност на потребителя.

### Какво да се добави в nimmax
- `nimmax/auth/hashing` модул:
  ```nim
  proc hashPassword*(password: string): string
  proc verifyPassword*(password, hash: string): bool
  ```
- Поддръжка за **bcrypt** или **argon2** (чрез `bcrypt` nimble пакет)
- Да се вгради в `nimmax/middlewares/auth` като helper, не като задължителен middleware

---

## 3. Rate Limiting (Критично за Production)

### Защо
Няма защита от brute-force атаки върху `/login`, `/api/*` и т.н.

### Какво да се добави
- `nimmax/middlewares/ratelimit.nim` — вече има файл, но да се подсили:
  - Rate limit по **IP + route**
  - Rate limit по **user ID** (за logged-in users)
  - Sliding window или token bucket алгоритъм
  - Конфигурация през `Settings`:
    ```nim
    settings.rateLimit = RateLimitConfig(
      requestsPerMinute: 60,
      burst: 10,
      blockDuration: initDuration(minutes = 5)
    )
    ```
  - Redis/DB backend за distributed rate limiting (аклко има няколко инстанса)

---

## 4. Request Logging & Observability

### Защо
В момента `nimmax` има `debug = true` в Settings, но няма structured logging.

### Какво да се добави
- **Structured Logger** — JSON log format:
  ```json
  {"timestamp":"2026-05-02T10:00:00Z","level":"INFO","method":"GET","path":"/api/users","status":200,"duration_ms":12,"ip":"10.0.0.1"}
  ```
- **Request ID middleware** — генерира `X-Request-ID` за всяка заявка и го прокарва през целия pipeline
- **Access Log middleware** — аналог на Apache/Nginx access log
- **Performance Metrics** — `nimmax/metrics` с basic counters: requests/sec, avg response time, error rate

---

## 5. File Upload Handling

### Защо
Няма модул за multipart/form-data файл ъплоуд. Нужно е за аватари, документи, експорти.

### Какво да се добави
- `nimmax/core/upload.nim` или `nimmax/middlewares/upload.nim`:
  - Parse multipart форми
  - Валидация: max file size, allowed mime types
  - Storage abstraction: local disk, S3-compatible (MinIO, AWS S3)
  - Virus scanning hook (опционално)

---

## 6. Email Integration

### Защо
Забравена парола, потвърждение на регистрация, нотификации — всичко това изисква email.

### Какво да се добави
- `nimmax/mail` модул:
  - SMTP изпращане (чрез `smtp` от stdlib или `prologue` mail)
  - Email template engine (HTML + text версии)
  - Queue за email-и (изпращане във фонов режим)
  - Preview режим за development (email-ите се записват в файл вместо да се изпращат)

---

## 7. Background Jobs / Task Queue

### Защо
Тежки операции (PDF генерация, импорт на CSV, масови email-и) не трябва да блокират HTTP нишката.

### Какво да се добави
- `nimmax/queue` модул:
  - In-memory опашка (за dev/single-instance)
  - Redis-backed опашка (за production)
  - Worker процеси:
    ```nim
    proc sendEmailJob*(payload: JsonNode) {.job.}
    ```
  - Retry логика с exponential backoff
  - Dead letter queue

---

## 8. API Documentation (OpenAPI/Swagger)

### Защо
Полезно за frontend екипа и за външни интеграции.

### Какво да се добави
- **Schema Definition** — DSL или типове, които описват request/response:
  ```nim
  type LoginRequest = object
    username*: string
    password*: string
  ```
- **Auto-generate OpenAPI spec** — от route definitions + типове
- **Swagger UI endpoint** — `/docs` или `/swagger`

---

## 9. Caching Layer

### Защо
В момента има `nimmax/cache/lrucache.nim` и `lfucache.nim`, но не са интегрирани като middleware.

### Какво да се добави
- **HTTP Cache Middleware** — `Cache-Control`, `ETag`, `Last-Modified`:
  ```nim
  app.get("/api/config", getConfig, middlewares = @[cacheMiddleware(duration = minutes(5))])
  ```
- **Response Cache** — кешира цели HTTP response-и в памет или Redis
- **DB Query Cache** — кешира често изпълнявани заявки

---

## 10. Health Checks & Readiness

### Защо
Kubernetes, Docker Swarm и load balancer-и се нуждаят от health check endpoint.

### Какво да се добави
- Built-in `/health` endpoint:
  ```json
  {"status":"ok","uptime":3600,"version":"1.0.0"}
  ```
- `/ready` endpoint — проверява DB connection, Redis, и други зависимости
- Graceful shutdown — при `SIGTERM` спира да приема нови заявки, изчаква текущите да приключат

---

## 11. Environment-Based Configuration

### Защо
`newSettings()` е hardcoded. Production конфигурация трябва да идва от env vars или config файлове.

### Какво да се добави
- **`.env` support** — `nimmax/core/configure.nim` да зарежда `.env` файл
- **Typed config** — `settings.port = getEnv("PORT", "8080").parseInt()`
- **Config validation** — при стартиране проверява дали всички required env vars са налични
- **Secrets management** — integration с HashiCorp Vault или поне отделен `secrets.nim`

---

## 12. Testing Utilities (Разширяване)

### Защо
`nimmax/testing/mocking.nim` е добър старт, но може повече.

### Какво да се добави
- **DB Transaction Rollback в тестове** — всяка тестова заявка се изпълнява в транзакция, която се rollback-ва
- **HTTP Client за тестове** — `app.testGet("/")` връща response object с assertions:
  ```nim
  let resp = app.testGet("/api/users")
  resp.assertStatus(200)
  resp.assertJsonContains("users")
  ```
- **Factory pattern** за test data:
  ```nim
  let user = createFactory(User, username: "test", role: "admin")
  ```

---

## 13. WebSocket Enhancements

### Защо
В момента има базов WebSocket, но `nimleptos` realtime модула ползва глобален registry с Lock.

### Какво да се добави
- **Room/Channel abstraction** — `ws.join("room:123")`, `ws.broadcast("room:123", msg)`
- **Presence tracking** — кой е онлайн в дадена стая
- **Message persistence** — запазване на последните N съобщения за offline clients
- **WebSocket authentication** — проверка на JWT token при handshake

---

## Приоритети (MoSCoW)

| Приоритет | Модул | Защо |
|-----------|-------|------|
| **Must** | Database + Migrations | Без това няма persistent data |
| **Must** | Password Hashing | Security requirement |
| **Must** | Rate Limiting | Security requirement |
| **Should** | Structured Logging | Production debugging |
| **Should** | File Upload | Universal need |
| **Should** | Health Checks | Deployment requirement |
| **Could** | Background Jobs | Performance |
| **Could** | Email | User engagement |
| **Could** | OpenAPI | DX |
| **Could** | WebSocket Rooms | Realtime features |

---

## Забележка

Тези препоръки са **универсални** и важат за всяко full-stack приложение. Когато започне конкретният проект (напр. счетоводна програма), може да се филтрират само нужните модули и да се добавят domain-specific неща (напр. аудит лог, multi-tenant middleware, PDF generation).

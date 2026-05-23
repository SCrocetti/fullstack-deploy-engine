# fullstack-deploy-engine
A specialized deployment engine that choreographs, compiles, and ships decoupled **Spring Boot (Maven)** and **React (pnpm)** applications using Bash automation and multi-stage Docker orchestration.

## Architecture & Lifecycles

The engine treats the repository as a decoupled monorepo, executing localized builds before containerizing the final artifacts and securing them behind a single gateway.
```

            [ Public Web Traffic (Ports 80/443) ]
                               |
                               v
                  +--------------------------+
                  |   Nginx Reverse Proxy    |
                  +--------------------------+
                   /                        \
                  /                          \
      (Proxies /api/*)                     (Proxies /*)
                /                              \
               v                                v
 +--------------------------+      +--------------------------+
 |   Spring Boot Backend    |      |     React Frontend       |
 |        (Java JRE)        |      |      (Static Nginx)      |
 +--------------------------+      +--------------------------+
              |
     (Internal Network)
              |
              v
 +--------------------------+
 |   PostgreSQL Database    |
 |    (Data Persistent)     |
 +--------------------------+
```
### 1. Frontend Pipeline (React + pnpm)
* **Dependency Management:** Utilizes `pnpm` for fast, disk-efficient node_modules caching across builds.
* **Compilation:** Bundles static assets via standard build scripts (`pnpm build`).
* **Production Image:** Multi-stage `Dockerfile` copies the compiled assets into an efficient **Nginx** or Alpine-based image.

### 2. Backend Pipeline (Spring Boot + Maven)
* **Compilation:** Leverages Maven wrapper (`./mvnw`) to compile and package a production-ready fat JAR, bypassing local environment discrepancies.
* **Database Evolution:** Integrates **Flyway** within the Spring lifecycle to automatically run schema versioning and data migration scripts on application startup.
* **Production Image:** Multi-stage build isolates the build environment from the lean, runtime Eclipse Temurin OpenJDK JRE layer.

### 3. Orchestration & Edge Gateway (Docker Compose)
* **Nginx Reverse Proxy:** Acts as the single entry point to the infrastructure, mapping external ports (80/443), handling SSL termination, routing `/api/*` traffic to the backend, and remaining requests to the frontend UI.
* **PostgreSQL Isolation:** Isolates the database container completely within the internal Docker virtual network, unreachable directly from the host or external internet.
* **Lifecycle Management:** Handles environmental secrets, healthcheck constraints (ensuring Spring waits for Postgres to be fully operational before booting and executing Flyway migrations), and custom volume persistence definitions.

---

> **Tip:** By separating the build step (running `pnpm build` and `mvn package` on the host runner or in early Docker stages), you keep your final production containers incredibly lightweight and secure—free of development tooling, node_modules, or source code.
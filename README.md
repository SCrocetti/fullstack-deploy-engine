# fullstack-deploy-engine / motor-de-despliegue-stackcompleto

[English](#english) | [Español](#espanol)

---

## 🇺🇸 English <a id="english"></a>

A specialized deployment engine that choreographs, compiles, and ships decoupled **Spring Boot (Maven)** and **Vite React (pnpm)** applications using Bash automation and multi-stage Docker orchestration.

## Architecture & Lifecycles

The engine treats the repository as a decoupled monorepo, executing localized builds before containerizing the final artifacts and securing them behind a single gateway. It enforces strict network isolation by separating the infrastructure into two distinct virtual networks: an external-facing network for the frontend and gateway, and an entirely isolated internal backend network.

```
            [ Public Web Traffic (Port 80) ]
                               |
                               v
                  +--------------------------+
                  |   Nginx Reverse Proxy    |
                  +--------------------------+
                        /              \
         (front-network)                \
                      /                  \
                     v                    \ (front-network)
        +--------------------------+       \
        |   Spring Boot Backend    |        v
        |    (Gateway Entrypoint)  |  +--------------------------+
        +--------------------------+  |   Vite React Frontend    |
                     |                |      (Static Nginx)      |
              (back-network)          +--------------------------+
                     |
                     v
        +--------------------------+
        |   PostgreSQL Database    |
        |    (Data Persistent)     |
        +--------------------------+
```

### 1. Frontend Pipeline
* **Dependency Management:** Utilizes `pnpm` for fast, disk-efficient node_modules caching across builds.
* **Compilation:** Bundles static assets via standard production **Vite React** build scripts.
* **Production Image:** A lightweight, single-stage Alpine-Nginx image that hosts the pre-compiled assets.

### 2. Backend Pipeline
* **Compilation:** Leverages Maven wrapper (`./mvnw`) to compile and package a production-ready fat JAR.
* **Database Evolution:** Integrates **Flyway** within the Spring lifecycle to automatically run schema versioning and data migration scripts on application startup.
* **Production Image:** Single-stage `Dockerfile` copies the pre-compiled fat JAR into a lean, runtime Eclipse Temurin OpenJDK JRE layer.

### 3. Orchestration & Edge Gateway (Docker Compose)
* **Nginx Reverse Proxy:** Acts as the single entry point to the infrastructure, mapping external port (80) and handling routing rules. It connects exclusively to `front-network`.
* **Network Isolation Topology:** Enforces complete infrastructure segregation using two separate bridge networks:
  * `front-network`: Connects the Nginx proxy, the frontend container, and the backend application gateway entrypoint.
  * `back-network`: Connects exclusively the backend application and the PostgreSQL database.
* **PostgreSQL Isolation:** Isolates the database container completely within `back-network`, making it reachable only by the backend. It remains entirely invisible and unreachable from the frontend container, the host machine, or the external internet.
* **Lifecycle Management:** Coordinates a strict sequential startup using healthcheck constraints (ensuring the backend waits for Postgres, and the Nginx orchestrator waits for both frontend and backend to be healthy before routing traffic) alongside environmental secrets and volume persistence definitions.

---

## ⚙️ Local Configuration (.env)

Before executing any script, you must create a `.env` file in the root of this infrastructure directory using the provided template. This file is excluded via `.gitignore` to prevent secret leaks.

To set it up quickly, copy the example file **.env.example** and edit it with your local parameters:

``` bash
# 1. Copy the template to create your local environment file
cp .env.example .env

# 2. Open and configure your secrets and paths
nano .env
```

The template contains the following structure:

``` ini
# --- Launcher language configuration ---
SYSTEM_LANG=en

# --- Database Configuration (PostgreSQL) ---
DB_NAME=project_db
DB_USER=project_user
DB_PASSWORD=secure_password_placeholder

# --- Environment Profiles ---
BACK_PROFILE=prod

# --- Source Code Local Paths (Directory Structure) ---
BACK_DIR=../project-backend-source
FRONT_DIR=../project-frontend-source
```

## 🔑 Access Control & Remote Setup (SSH)

To guarantee seamless automated remote deployments via the launcher engine, your local workstation must be configured using key-based authentication (**ED25519**) and a dedicated Host alias within your SSH client configuration targeting a non-root `deployer` user.

### 1. Configure Local SSH Host Alias
Edit or create your local `~/.ssh/config` file and append the following structure:

```
Host project-server
    HostName 190.x.x.x              # Your remote server target IP
    User deployer                   # Your non-root remote deployment user
    Port xx                         # SSH Port
    AddressFamily xxxx              # Points to the usage of IPv4 or IPv6
    IdentityFile ~/.ssh/id_ed25519_project_deployer
    AddKeysToAgent yes
```

### 2. SSH Agent Automation
The `launcher.sh` includes runtime verification for the `ssh-agent`. When triggering a remote deployment lifecycle, the script validates if your private key is already loaded in the active session. If not, it will securely prompt for your passphrase exactly once per terminal lifecycle.

---

## 🚀 Server Provisioning & Bootstrapping

Before triggering the first automated deployment pipeline, the target remote server environment must be provisioned with the appropriate folder hierarchies, execution groups, and strict volume I/O permissions using an admin account.

### Step 1: Automated Key Deployment & Workspace Setup
From your local workstation terminal, generate the dedicated deployment key and push it to the remote server using your existing server administrative account:

``` bash
# 1. Generate the dedicated deployment key pair locally, with its corresponding passphrase

ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_project_deployer -C "deployer@infrastructure" -N "YourSafePassphrase"
# 2. Add the key pair to your local running SSH agent session
ssh-add ~/.ssh/id_ed25519_project_deployer

# 3. Securely copy the public key to the server utilizing an administrative account
# and set the permisions so ssh works for that user
# Replace 'admin_user' and '190.x.x.x' with your target bootstrap credentials
ssh administrative_user@190.x.x.x "mkdir -p /home/deployer/.ssh && chmod 700 /home/deployer/.ssh && echo '$(cat ~/.ssh/id_ed25519_project_deployer.pub)' >> /home/deployer/.ssh/authorized_keys && chmod 600 /home/deployer/.ssh/authorized_keys && chown -R deployer:deployer /home/deployer/.ssh"
```

### Step 2: Remote Administrative Environment Provisioning
Access your remote server environment via terminal using your administrative user to configure permissions, docker groups, and path architectures:

``` bash
# 1. Connect to your server using your administrative credential
ssh administrative_user@190.x.x.x

# 2. Grant the non-root 'deployer' user access to manage Docker contexts without sudo privileges
sudo usermod -aG docker deployer

# 3. Structure directories for orchestration metadata and database persistence under the deployer environment
sudo mkdir -p /home/deployer/project-infra
sudo mkdir -p /home/deployer/data/postgres

# 4. Enforce strict filesystem lockout boundaries on the raw database volume
# Restricts permissions and assigns ownership exclusively to the containerized PostgreSQL engine (UID 999)
sudo chown -R 999:999 /home/deployer/data/postgres
sudo chmod -R 700 /home/deployer/data/postgres

# 5. Correct global directory ownership of the deployment workspace back to the deployer user
sudo chown -R deployer:deployer /home/deployer/project-infra

# 6. Apply group updates instantly without needing a full server reboot
sudo systemctl restart docker
```

---

## 🛠️ Operating the Launcher Engine

The `launcher.sh` script is the interactive gateway to control, build, and orchestrate the service lifecycles. 

### Execution
To start the pipeline menu, run:

``` bash
./launcher.sh
```

#### Interactive Pipeline Menu
When you execute the script, an interactive command-line interface prompts you to select the target deployment destination: option 1 for local container initialization, or option 2 for secure remote orchestration via SSH.

1. **Deploy LOCAL Environment**
   * **Local Build:** Compiles the Spring Boot backend via Maven and builds the React frontend static assets using Vite (`pnpm build`).
   * **Staging:** Copies the compiled binaries, assets, and Dockerfiles into temporary local build directories (`./backend-build` and `./frontend-build`).
   * **Orchestration:** Runs `docker compose up -d --build` locally to spin up or update the containers.
   * **Cleanup:** Automatically deletes the temporary local build folders from disk upon completion.

2. **Deploy REMOTE Infrastructure (SSH)**
   * **Security Check:** Ensures `BACK_PROFILE` is set to `prod` in your `.env` before proceeding to prevent environment corruption.
   * **Local Compilation:** Builds the backend and React/Vite frontend locally so the remote server doesn't need Maven, Node, or package managers installed.
   * **SSH Agent Validation:** Checks if your deployer SSH key (`id_ed25519_project_deployer`) is active in the agent; if missing, prompts for your passphrase before attempting any connection.
   * **File Transfer:** Uses `scp` to copy the complete deployment context to the remote server, including:
     * The localized staging environments (`./backend-build` and `./frontend-build` containing the compiled applications and their specific Dockerfiles/configs).
     * The reverse proxy configuration (`./nginx`).
     * The orchestration blueprint (`./docker-compose.yml`).
   * **Remote Execution:** Establishes an `ssh` connection to export core environment variables (`DB_NAME`, `DB_USER`, `DB_PASSWORD`, `BACK_PROFILE`) and trigger `docker compose up -d --build` on the remote host.
   * **Double Cleanup:** Wipes the temporary build folders from the remote server immediately after the containers are up, and deletes the local temporary build workspaces upon final completion.
---

## 🔒 Architecture & Network Topology

The infrastructure is orchestrated using a multi-container Docker architecture isolated behind a reverse proxy. 

### Network Isolation & Routing
* **Edge Reverse Proxy:** The `orchestrator-nginx` service is the only container that exposes public ports (`80:80`). It acts as a single gatekeeper, handling security headers and distributing traffic internally.
* **Service Routing:** Public traffic is reverse-proxied internally based on paths:
  * `/api/` requests are forwarded directly to the Spring Boot application (`backend-service:8080`).
  * All other traffic (`/`) routes to the separate `frontend-service:80` container, which serves the compiled React/Vite assets.
* **Network Segmentation:** Services are isolated across two separate bridge networks:
  * `front-network`: Connects the edge proxy with the frontend and backend containers.
  * `back-network`: Isolates communication exclusively between the backend container and the PostgreSQL database (`db-service`). The database is entirely inaccessible to the frontend container and the outside world.

### Hardening & Context Protections
* **Actuator Protection:** The edge proxy explicitly intercepts and drops public traffic targeting `/api/actuator` endpoints with a `403 Forbidden` rule, keeping Spring Boot management states confidential.
* **Security Headers:** Nginx enforces basic security configurations on all incoming requests, including strict `X-Frame-Options`, `X-Content-Type-Options`, and a restricted `Content-Security-Policy`.
* **Zero-Footprint Compilation:** To minimize disk utilization and reduce security vulnerabilities on the remote host, the engine utilizes a local staging approach. Temporary workspace folders (`./backend-build` and `./frontend-build`) are immediately deleted from both the local environment and the remote machine as soon as container building finishes.

---

## 📊 System Telemetry & Log Operations

[cite_start]Container workloads enforce automated runtime log rotation (capped at 10MB per file, retaining up to 3 historic files per service)[cite: 1]. System auditing, diagnostics, and snapshot archiving are unified into a single local utility script.

### 🛠️ The Log Inspection Utility (`log_inspection.sh`)
The `log_inspection.sh` script is a localized operational tool used to inspect active stdout/stderr streams or extract stamped forensic packages from either the local machine or the remote server host. The script features built-in signal traps, allowing you to stream live container logs and press `Ctrl+C` to cleanly kill the stream and return instantly back to the interactive script menu without crashing your session.

``` bash
./log_inspection.sh
```
### 🔄 Execution Workflow Logic
When initialized, the utility drives operations through a step-by-step interactive lifecycle:

1. **Language Initialization:** Prompts for operational language (English/Español) to localize runtime output logs and interactive choices.
2. **Environment Target Selection:** Prompts whether to query the `local` environment or connect to the `remote` server topology.
   * *Fallback Protection:* If the remote server connection fails or drops, the engine immediately prints a critical error sequence and halts execution (`exit 1`).
3. **Operational Mode Choice:**
   * *Mode 1 (Stream Live Logs):* Attaches cleanly to the container runtime via `docker logs -f`. Interrupting via `Ctrl+C` breaks the stream and pops you safely back to the menu.
   * *Mode 2 (Generate Diagnostic File):* Requests a maximum line threshold (defaulting to the complete log buffer if left empty).
4. **Target Service Selection:** Selects an individual container architecture node (`backend`, `frontend`, `orchestrator-nginx`, `db`), or triggers option `5) All Services`.

### 📂 Unified Diagnostic Workspace (`~/project-logs`)
The script utilizes `~/project-logs` on your local host machine as the central workspace for all diagnostic outputs, automatically segregating files by their environment source:

* **`~/project-logs/local/`** — Houses files generated during local infrastructure analysis.
* **`~/project-logs/remote/`** — Houses archived forensic packages pulled down via secure copy from the remote server host before being purged from the server's disk layer.

### 🗜️ Snapshot Archiving & Naming Conventions
When executing an archive pipeline, the engine captures the target buffer, logs it to a raw flat file, and wraps it into a compressed tarball (`.tar.gz`). If **All Services** is selected, the output package cleanly holds four distinct, individually isolated files—one for every separate service architecture layer. 

Packages are dynamically labeled using the container identity and an operational timestamp:

```text
~/project-logs/
├── local/
│   ├── log_[service_name]_[YYYYMMDD_HHMMSS].tar.gz
│   └── log_all_services_[YYYYMMDD_HHMMSS].tar.gz
└── remote/
    ├── log_[service_name]_[YYYYMMDD_HHMMSS].tar.gz
    └── log_all_services_[YYYYMMDD_HHMMSS].tar.gz
```

> 💡 **Tailoring to Your Project**
> 
> This architecture is designed to be highly generic, but naming matters for images, containers, and directories. If you want to personalize this setup:
> * Search and replace references to `project` (in scripts, `pom.xml`, `package.json`, SSH keys, and paths) with your actual project name.
> * If you rename any core service (like `backend` or `frontend`), make sure to cascade those updates everywhere—especially across your `launcher.sh`, `docker-compose.yml`, Nginx proxy routing files, and `log_inspection.sh`. Ensure all references stay aligned so the orchestration infrastructure doesn't break.

## 🇪🇸 Español <a id="espanol"></a>

Un motor de despliegue especializado que coordina, compila y envía aplicaciones desacopladas de **Spring Boot (Maven)** y **Vite React (pnpm)** utilizando automatización en Bash y orquestación multi-etapa en Docker.

## Arquitectura y Ciclos de Vida

El motor trata el repositorio como un monorrepo desacoplado, ejecutando compilaciones locales antes de contenerizar los artefactos finales y asegurarlos detrás de una única puerta de enlace. Implementa un aislamiento estricto de red al separar la infraestructura en dos redes virtuales distintas: una red orientada al exterior para el frontend y el proxy, y una red interna para el backend completamente aislada.

```
               [ Tráfico Web Público (Puerto 80) ]
                               |
                               v
                  +--------------------------+
                  |   Proxy Inverso Nginx    |
                  +--------------------------+
                        /              \
         (front-network)                \
                      /                  \
                     v                    \ (front-network)
        +--------------------------+       \
        |    Backend Spring Boot   |        v
        |  (Punto Entrada Gateway) |  +--------------------------+
        +--------------------------+  |   Frontend Vite React    |
                     |                |      (Nginx Estático)    |
              (back-network)          +--------------------------+
                     |
                     v
        +--------------------------+
        |   Base de Datos Postgre  |
        |    (Persistencia Datos)  |
        +--------------------------+
```
### 1. Pipeline del Frontend
* **Gestión de Dependencias:** Utiliza `pnpm` para un almacenamiento en caché de `node_modules` rápido y eficiente en disco a lo largo de las compilaciones.
* **Compilación:** Empaqueta los activos estáticos mediante scripts de compilación de producción estándar de **Vite React**.
* **Imagen de Producción:** Una imagen liviana de una sola etapa basada en Alpine-Nginx que aloja los activos precompilados.

### 2. Pipeline del Backend
* **Compilación:** Aprovecha el wrapper de Maven (`./mvnw`) para compilar y empaquetar un archivo JAR ejecutable listo para producción.
* **Evolución de la Base de Datos:** Integra **Flyway** dentro del ciclo de vida de Spring para ejecutar automáticamente scripts de migración de datos y versionado del esquema durante el inicio de la aplicación.
* **Imagen de Producción:** Una `Dockerfile` de una sola etapa copia el JAR precompilado en una capa de ejecución liviana de Eclipse Temurin OpenJDK JRE.

### 3. Orquestación y Proxy de Borde (Docker Compose)
* **Proxy Inverso Nginx:** Actúa como el único punto de entrada a la infraestructura, mapeando el puerto externo (80) y gestionando las reglas de enrutamiento. Se conecta exclusivamente a `front-network`.
* **Topología de Aislamiento de Red:** Implementa la segregación completa de la infraestructura utilizando dos redes puente independientes:
  * `front-network`: Conecta el proxy Nginx, el contenedor del frontend y el punto de entrada del backend.
  * `back-network`: Conecta exclusivamente la aplicación backend y la base de datos PostgreSQL.
* **Aislamiento de PostgreSQL:** Aísla el contenedor de la base de datos completamente dentro de `back-network`, haciéndolo accesible únicamente por el backend. Permanece totalmente invisible e inaccesible desde el contenedor del frontend, la máquina host o el internet externo.
* **Gestión del Ciclo de Vida:** Coordina un inicio secuencial estricto utilizando restricciones de verificación de estado (asegurando que el backend espere a Postgres, y el orquestador Nginx espere a que tanto el frontend como el backend estén saludables antes de dirigir el tráfico) junto con definiciones de volúmenes persistentes y secretos de entorno.

---

## ⚙️ Configuración Local (.env)

Antes de ejecutar cualquier script, debes crear un archivo `.env` en la raíz de este directorio de infraestructura utilizando la plantilla provista. Este archivo está excluido a través de `.gitignore` para evitar la filtración de secretos.

Para configurarlo rápidamente, copia el archivo de ejemplo **.env.example** y edítalo con tus parámetros locales:

``` bash
# 1. Copiar la plantilla para crear tu archivo de entorno local
cp .env.example .env

# 2. Abrir y configurar tus secretos y rutas
nano .env
```

La plantilla contiene la siguiente estructura:

``` ini
# --- Configuración de idioma del lanzador ---
SYSTEM_LANG=es

# --- Configuración de la Base de Datos (PostgreSQL) ---
DB_NAME=project_db
DB_USER=project_user
DB_PASSWORD=secure_password_placeholder

# --- Perfiles de Entorno ---
BACK_PROFILE=prod

# --- Rutas Locales del Código Fuente (Estructura de Directorios) ---
BACK_DIR=../project-backend-source
FRONT_DIR=../project-frontend-source
```

## 🔑 Control de Acceso y Configuración Remota (SSH)

Para garantizar despliegues remotos automatizados y fluidos a través del script lanzador, tu estación de trabajo local debe estar configurada mediante autenticación basada en claves (**ED25519**) y un alias de Host dedicado dentro de la configuración de tu cliente SSH apuntando a un usuario `deployer` que no sea root.

### 1. Configurar el Alias de Host SSH Local
Edita o crea tu archivo local `~/.ssh/config` y añade la siguiente estructura:

```
Host project-server
    HostName 190.x.x.x              # IP de tu servidor remoto objetivo
    User deployer                   # Tu usuario de despliegue remoto no-root
    Port xx                         # Puerto SSH
    AddressFamily xxxx              # Apunta al uso de IPv4 o IPv6
    IdentityFile ~/.ssh/id_ed25519_project_deployer
    AddKeysToAgent yes
```

### 2. Automatización del Agente SSH
El script `launcher.sh` incluye verificación en tiempo de ejecución para el `ssh-agent`. Al activar un ciclo de vida de despliegue remoto, el script valida si tu clave privada ya está cargada en la sesión activa. Si no es así, solicitará de manera segura tu frase de contraseña exactamente una vez por cada ciclo de vida de la terminal.

---

## 🚀 Aprovisionamiento y Preparación del Servidor

Antes de activar el primer pipeline de despliegue automatizado, el entorno del servidor remoto objetivo debe ser aprovisionado con las jerarquías de carpetas adecuadas, grupos de ejecución y permisos estrictos de E/S de volúmenes utilizando una cuenta de administrador.

### Paso 1: Despliegue Automatizado de Claves y Configuración del Espacio de Trabajo
Desde la terminal de tu estación de trabajo local, genera la clave de despliegue dedicada y envíala al servidor remoto utilizando tu cuenta administrativa existente del servidor:

``` bash
### 2. Automatización del Agente SSH
El script `launcher.sh` incluye verificación en tiempo de ejecución para el `ssh-agent`. Al activar un ciclo de vida de despliegue remoto, el script valida si tu clave privada ya está cargada en la sesión activa. Si no es así, solicitará de manera segura tu frase de contraseña exactamente una vez por cada ciclo de vida de la terminal.

---

## 🚀 Aprovisionamiento y Preparación del Servidor

Antes de activar el primer pipeline de despliegue automatizado, el entorno del servidor remoto objetivo debe ser aprovisionado con las jerarquías de carpetas adecuadas, grupos de ejecución y permisos estrictos de E/S de volúmenes utilizando una cuenta de administrador.

### Paso 1: Despliegue Automatizado de Claves y Configuración del Espacio de Trabajo
Desde la terminal de tu estación de trabajo local, genera la clave de despliegue dedicada y envíala al servidor remoto utilizando tu cuenta administrativa existente del servidor:

``` bash
# 1. Generar el par de claves de despliegue dedicado localmente, con su correspondiente frase de contraseña
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_project_deployer -C "deployer@infrastructure" -N "TuContrasenaSegura"

# 2. Añadir el par de claves a la sesión activa del agente SSH local
ssh-add ~/.ssh/id_ed25519_project_deployer

# 3. Copiar de forma segura la clave pública al servidor utilizando una cuenta administrativa
# y establecer los permisos para que ssh funcione correctamente para ese usuario
# Reemplaza 'user_admin' y '190.x.x.x' con tus credenciales de preparación objetivo
ssh administrative_user@190.x.x.x "mkdir -p /home/deployer/.ssh && chmod 700 /home/deployer/.ssh && echo '$(cat ~/.ssh/id_ed25519_project_deployer.pub)' >> /home/deployer/.ssh/authorized_keys && chmod 600 /home/deployer/.ssh/authorized_keys && chown -R deployer:deployer /home/deployer/.ssh"
```

### Paso 2: Aprovisionamiento Administrativo del Entorno Remoto
Accede a la terminal de tu servidor remoto utilizando tu usuario administrativo para configurar permisos, grupos de docker y las arquitecturas de rutas:

``` bash
# 1. Conectarse al servidor usando tu credencial administrativa
ssh administrative_user@190.x.x.x

# 2. Otorgar al usuario no-root 'deployer' acceso para gestionar contextos de Docker sin privilegios de sudo
sudo usermod -aG docker deployer

# 3. Estructurar los directorios para los metadatos de orquestación y la persistencia de la base de datos bajo el entorno del deployer
sudo mkdir -p /home/deployer/project-infra
sudo mkdir -p /home/deployer/data/postgres

# 4. Aplicar restricciones estrictas de bloqueo en el sistema de archivos sobre el volumen de la base de datos cruda
# Restringe los permisos y asigna la propiedad exclusivamente al motor de PostgreSQL contenerizado (UID 999)
sudo chown -R 999:999 /home/deployer/data/postgres
sudo chmod -R 700 /home/deployer/data/postgres

# 5. Corregir la propiedad global del directorio del espacio de trabajo de despliegue devolviéndola al usuario deployer
sudo chown -R deployer:deployer /home/deployer/project-infra

# 6. Aplicar las actualizaciones de grupo instantáneamente sin necesidad de reiniciar por completo el servidor
sudo systemctl restart docker
```

---

## 🛠️ Operación del Motor Lanzador

El script `launcher.sh` es la puerta de entrada interactiva para controlar, compilar y orquestar los ciclos de vida de los servicios.

### Ejecución
Para iniciar el menú del pipeline, ejecuta:

``` bash
./launcher.sh
```

#### Menú Interactivo del Pipeline
Al ejecutar el script, una interfaz de línea de comandos interactiva te solicitará que selecciones el destino del despliegue: la opción 1 para la inicialización local de contenedores, o la opción 2 para la orquestación remota segura mediante SSH.

1. **Desplegar Entorno LOCAL**
   * **Compilación Local:** Compila el backend de Spring Boot mediante Maven y construye los activos estáticos del frontend de React usando Vite (`pnpm build`).
   * **Preparación (Staging):** Copia los binarios, activos y Dockerfiles compilados en los directorios de construcción locales temporales (`./backend-build` y `./frontend-build`).
   * **Orquestación:** Ejecuta `docker compose up -d --build` localmente para levantar o actualizar los contenedores.
   * **Limpieza:** Elimina automáticamente del disco las carpetas temporales de construcción local al finalizar de manera exitosa.

2. **Desplegar Infraestructura REMOTA (SSH)**
   * **Verificación de Seguridad:** Asegura que `BACK_PROFILE` esté configurado en `prod` en tu archivo `.env` antes de proceder para evitar la corrupción del entorno.
   * **Compilación Local:** Compila el backend y el frontend de React/Vite localmente para que el servidor remoto no necesite tener instalados Maven, Node o gestores de paquetes.
   * **Transferencia de Archivos:** Utiliza `scp` para copiar el contexto completo de despliegue al servidor remoto, incluyendo:
     * Los entornos de preparación localizados (`./backend-build` y `./frontend-build` que contienen las aplicaciones compiladas y sus Dockerfiles/configuraciones específicas).
     * La configuración del proxy inverso (`./nginx`).
     * El diseño de orquestación (`./docker-compose.yml`).
   * **Ejecución Remota:** Establece una conexión `ssh` para exportar las variables de entorno principales (`DB_NAME`, `DB_USER`, `DB_PASSWORD`, `BACK_PROFILE`) y activar `docker compose up -d --build` en el host remoto.
   * **Doble Limpieza:** Borra las carpetas temporales de construcción del servidor remoto inmediatamente después de que los contenedores estén activos, y elimina los espacios de trabajo temporales de construcción locales tras la finalización definitiva.

---

## 🔒 Arquitectura y Topología de Red

La infraestructura está orquestada utilizando una arquitectura Docker de múltiples contenedores aislados detrás de un proxy inverso.

### Aislamiento de Red y Enrutamiento
* **Proxy Inverso de Borde:** El servicio `orchestrator-nginx` es el único contenedor que expone puertos públicos (`80:80`). Actúa como un guardián único, gestionando las cabeceras de seguridad y distribuyendo el tráfico internamente.
* **Enrutamiento de Servicios:** El tráfico público es redirigido internamente por el proxy inverso en función de las rutas de acceso:
  * Las peticiones hacia `/api/` se reenvían directamente a la aplicación Spring Boot (`backend-service:8080`).
  * Todo el resto del tráfico (`/`) se dirige al contenedor independiente `frontend-service:80`, que sirve los activos compilados de React/Vite.
* **Segmentación de Red:** Los servicios están aislados a través de dos redes puente independientes:
  * `front-network`: Conecta el proxy de borde con los contenedores del frontend y del backend.
  * `back-network`: Aísla la comunicación exclusivamente entre el contenedor del backend y la base de datos PostgreSQL (`db-service`). La base de datos es completamente inaccesible para el contenedor del frontend y el mundo exterior.

### Fortalecimiento y Protecciones de Contexto
* **Protección del Actuator:** El proxy de borde intercepta y descarta explícitamente el tráfico público dirigido a los endpoints `/api/actuator` con una regla `403 Forbidden`, manteniendo la confidencialidad de los estados de gestión de Spring Boot.
* **Cabeceras de Seguridad:** Nginx implementa configuraciones básicas de seguridad en todas las solicitudes entrantes, incluyendo reglas estrictas de `X-Frame-Options`, `X-Content-Type-Options` y una Política de Seguridad de Contenido (`Content-Security-Policy`) restringida.
* **Compilación de Huella Cero:** Para minimizar la utilización del disco y reducir las vulnerabilidades de seguridad en el host remoto, el motor utiliza un enfoque de preparación local. Las carpetas temporales del espacio de trabajo (`./backend-build` and `./frontend-build`) se eliminan inmediatamente tanto del entorno local como de la máquina remota tan pronto como finaliza la construcción de los contenedores.

---

## 📊 Telemetría del Sistema y Operaciones de Logs

Las cargas de trabajo de los contenedores imponen reglas automatizadas de rotación de logs en tiempo de ejecución (limitadas a un máximo de 10 MB por archivo, reteniendo hasta 3 archivos históricos por servicio). La auditoría del sistema, los diagnósticos y el archivo de instantáneas están unificados en un único script de utilidad local.

### 🛠️ La Utilidad de Inspección de Logs (`log_inspection.sh`)
El script `log_inspection.sh` es una herramienta operativa localizada que se utiliza para inspeccionar los flujos activos de stdout/stderr o extraer paquetes forenses con marca de tiempo tanto de la máquina local como del servidor remoto. El script cuenta con capturas de señales integradas, lo que te permite transmitir logs de contenedores en vivo y presionar `Ctrl+C` para detener la transmisión limpiamente y regresar de inmediato al menú interactivo del script sin interrumpir tu sesión de la terminal.

``` bash
./log_inspection.sh
```

### 🔄 Lógica del Flujo de Ejecución
Cuando se inicializa, la utilidad guía las operaciones a través de un ciclo de vida interactivo paso a paso:

1. **Inicialización de Idioma:** Solicita el idioma operativo (English/Español) para localizar las opciones interactivas y los mensajes de salida en la sesión.
2. **Selección del Entorno Objetivo:** Pregunta si se debe consultar el entorno `local` o conectarse a la topología del servidor `remoto`.
   * *Protección ante Fallos:* Si la conexión con el servidor remoto falla o se interrumpe, el motor imprime inmediatamente una secuencia de error crítico y detiene la ejecución (`exit 1`).
3. **Elección del Modo Operativo:**
   * *Modo 1 (Stream de Logs en Vivo):* Se conecta limpiamente al entorno de ejecución del contenedor mediante `docker logs -f`. Interrumpir con `Ctrl+C` detiene la transmisión y te regresa de forma segura al menú.
   * *Modo 2 (Generar Archivo de Diagnóstico):* Solicita un límite máximo de líneas (estableciendo por defecto el búfer completo de logs si se deja vacío).
4. **Selección del Servicio Objetivo:** Selecciona un nodo individual de la arquitectura de contenedores (`backend`, `frontend`, `orchestrator-nginx`, `db`), o activa la opción `5) Todos los servicios`.

### 📂 Espacio de Trabajo de Diagnóstico Unificado (`~/project-logs`)
El script utiliza `~/project-logs` en tu máquina host local como el espacio de trabajo central para todos los resultados de diagnóstico, segregando automáticamente los archivos según el entorno de origen:

* **`~/project-logs/local/`** — Alberga los archivos generados durante el análisis de la infraestructura local.
* **`~/project-logs/remote/`** — Alberga los paquetes forenses archivados descargados mediante copia segura desde el servidor remoto antes de ser eliminados de la capa de disco del servidor.

### 🗜️ Archivo de Instantáneas y Convenciones de Nomenclatura
Al ejecutar un pipeline de archivado, el motor captura el búfer seleccionado, lo registra en un archivo plano estructurado y lo empaqueta en un archivo comprimido (`.tar.gz`). Si se selecciona **Todos los servicios**, el paquete final contiene de forma limpia cuatro archivos individuales y aislados, uno para cada capa de la arquitectura del servicio.

Los paquetes se etiquetan dinámicamente utilizando la identidad del contenedor y una marca de tiempo operativa:

```text
~/project-logs/
├── local/
│   ├── log_[nombre_del_servicio]_[AAAAMMDD_HHMMSS].tar.gz
│   └── log_all_services_[AAAAMMDD_HHMMSS].tar.gz
└── remote/
    ├── log_[nombre_del_servicio]_[AAAAMMDD_HHMMSS].tar.gz
    └── log_all_services_[AAAAMMDD_HHMMSS].tar.gz
```
> 💡 **Adaptación a tu Proyecto**
> 
> Esta arquitectura está diseñada para ser altamente genérica, pero la nomenclatura es importante para las imágenes, los contenedores y los directorios. Si deseas personalizar esta estructura:
> * Busca y reemplaza las referencias a `project` (en scripts, `pom.xml`, `package.json`, llaves SSH y rutas) por el nombre real de tu proyecto.
> * Si renombras algún servicio principal (como `backend` o `frontend`), asegúrate de replicar esos cambios en todas partes, especialmente en tus archivos `launcher.sh`, `docker-compose.yml`, los archivos de configuración de enrutamiento de Nginx y en `log_inspection.sh`. Asegúrate de que todas las referencias se mantengan alineadas para que la infraestructura de orquestación no falle.
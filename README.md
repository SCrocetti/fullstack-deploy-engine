# fullstack-deploy-engine / motor-de-despliegue-stackcompleto

[English](#english) | [Español](#espanol)

---

## 🇺🇸 English <a id="english"></a>

A deployment engine that choreographs, compiles, and ships decoupled **Spring Boot (Maven)** and **Vite React (pnpm)** applications using Bash automation and multi-stage Docker orchestration.

## Architecture & Lifecycles

The engine treats the repository as a decoupled monorepo, executing localized builds before containerizing the final artifacts and securing them behind a single gateway. It enforces strict network isolation by separating the infrastructure into two distinct layers: an external-facing Frontend Gateway and an entirely isolated internal backend network.

```
                [ Public Web Traffic (Port 80) ]
                               |
                               v
                  +--------------------------+
                  |   Nginx Frontend & Proxy |
                  |  (Serves React + Routes) |
                  +--------------------------+
                               |
                        (front-network)
                               |
                               v
                  +--------------------------+
                  |   Spring Boot Backend    |
                  +--------------------------+
                               |
                        (back-network)
                               |
                               v
                  +--------------------------+
                  |   PostgreSQL Database    |
                  +--------------------------+
```
### 1. Frontend & Gateway Pipeline
* **Dependency Management:** Utilizes `pnpm` for fast, disk-efficient node_modules caching across builds.
* **Compilation:** Bundles static assets via standard production **Vite React** build scripts.
* **Production Image:** A lightweight, single-stage Alpine-Nginx image. This container acts as both the **Edge Gateway** and the **Web Server**: it embeds and serves the pre-compiled static assets directly, while simultaneously managing the reverse-proxy routing rules.

### 2. Backend Pipeline
* **Compilation:** Leverages the Maven wrapper (./mvnw) to compile and package a production-ready fat JAR containing the application and all its dependencies.
* **Database Evolution:** Integrates **Flyway** within the Spring lifecycle to automatically run schema versioning and data migration scripts on application startup.
* **Production Image:** Single-stage `Dockerfile` copies the pre-compiled fat JAR into a lean, runtime Eclipse Temurin OpenJDK JRE layer.

### 3. Orchestration & Network Isolation (Docker Compose)
* **Unified Edge Gateway:** The Nginx container acts as the single entry point to the infrastructure, mapping the external port (80). It hosts the frontend assets and handles API routing rules, connecting to the `front-network`.
* **Network Isolation Topology:** Enforces complete infrastructure segregation using two separate bridge networks:
  * `front-network`: Connects the unified Nginx frontend/proxy container and the backend application entrypoint.
  * `back-network`: Connects exclusively the backend application and the PostgreSQL database.
* **PostgreSQL Isolation:** Isolates the database container completely within `back-network`, making it reachable only by the backend. It remains entirely invisible and unreachable from the frontend/proxy container, the host machine, or the external internet.
* **Credential Management via Docker Secrets:** The environment strictly prohibits injecting sensitive credentials (`DB_USER`, `DB_PASSWORD`, `DB_NAME`) via standard operating system environment variables. Instead, it leverages the Docker Secrets subsystem, mounting these keys as read-only files in virtual memory under the `/run/secrets/` path. This completely mitigates attack vectors oriented toward credential leaks via process inspection (`docker inspect`) or system environment dumps.
* **Data Persistence & Volume Ownership:** The stateful storage layer defined in `docker-compose.yml` mounts the PostgreSQL cluster files directly to a relative directory on the host: `/home/deployer/data/postgres`.
* **Cascading Cluster Initialization & Ready Checks:** To prevent service race conditions and initial boot failures, the cluster relies on native health checks and strict startup sequencing:
  * **Frontend & Gateway:** The central `frontend-service` gateway container features its own dedicated internal health check to expose up-to-date availability states. It relies on dependency gates to ensure the `backend-service` is completely healthy before finalizing its inbound routing initialization loop.
* **Horizontal Scaling & Native Round-Robin:** The architecture is pre-configured for seamless horizontal scaling. By default, it initializes with a single instance (`replicas: 1`). To scale out the backend layer to handle higher traffic loads, increase the value of the `deploy.replicas` property inside the `backend-service` block of `docker-compose.yml`. The unified edge gateway utilizes Docker's internal DNS engine (`127.0.0.11`) to dynamically detect new backend instances and perform automatic round-robin load balancing without modifying the Nginx routing profiles.

#### Routing
* **Edge Routing:** The Nginx service is the only container that exposes public ports (`80:80`). It acts as a single gatekeeper, handling security headers, serving the user interface, and distributing traffic internally.
* **Service Routing:** Public traffic hitting the gateway is handled based on paths:
  * `/api/` requests are reverse-proxied internally and forwarded directly to the Spring Boot application (`backend-service:8080`).
    * **Actuator Protection:** The edge proxy explicitly intercepts and drops public traffic targeting `/api/actuator` endpoints with a `403 Forbidden` rule, keeping Spring Boot management states confidential.
  * All other traffic (`/`) is resolved locally by Nginx, serving the compiled React/Vite assets directly from its own filesystem.

#### Gateway Headers
The Nginx service layer implements strict defense-in-depth parameters on every active HTTP transaction:

* **Clickjacking Protection**: Force-injects security parameters to deny framing.

``` conf
X-Frame-Options "SAMEORIGIN"
```

* **MIME Sniffing Prevention**: Disables style/script sniffing exploits natively.

``` conf
X-Content-Type-Options "nosniff"
```

* **Content Security Policy (CSP)**: Employs a strict whitelist policy allowing local assets while blocking external execution models.

``` conf
default-src 'self';

script-src 'self';

style-src 'self' 'unsafe-inline';

object-src 'none';

frame-src 'none';
```

* **Asset Performance Optimization**: Caches application fonts, compiled UI scripts, styles, and media assets for 6 months while silencing access logs to eliminate disk I/O bottlenecks.

``` conf
location ~* \.(?:ico|css|js|gif|jpe?g|png|woff2?|eot|ttf|svg)$ {
    expires 6M;
    public;
    access_log off;
}
```

---
## 📋 Local Workstation Prerequisites
Before configuring or initializing the engine, ensure your local development workstation has the following core binaries active within your system path:

* Docker & Docker Compose v2+ or v5+ (Core environment containerization and local testing platform)
* rclone (Secure, non-interactive cloud backup storage syncing)
* gnupg (Asymmetric cryptographic vault utility)
* msmtp & msmtp-mta (Lightweight SMTP relay client used locally for manual monitoring script verification tests)

To install these development tools on a clean Ubuntu/Debian local machine, run:

``` bash
sudo apt update && sudo apt install docker-compose-v2 rclone gnupg msmtp msmtp-mta -y
```

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
## 🌐 Execution Language & Runtime Flag Matrix
The underlying shell infrastructure respects localization rules based on execution environments, command-line arguments, or interactive terminal menus:

* **Launcher Engine (`launcher.sh`):** Exclusively sources its configuration rules and target language dynamically from your local root `.env` template file (`SYSTEM_LANG="en"|"es"`).
* **Telemetry & Automation Tools (`monitor_stack.sh`, `backup_engine.sh`):** Support immediate terminal argument flags to enable specific language profiles on demand (e.g., `./monitor_stack.sh --lang=es`).
* **Interaction Engine (`log_inspection.sh`):** Features an interactive command-line interface (CLI) terminal menu that allows you to dynamically choose your preferred UI language directly upon execution before running tasks.

## 🔑 Access Control & Remote Setup (SSH)

To guarantee seamless automated remote connections for the launcher engine, the backup engine or the log inspector, your local workstation must be configured using key-based authentication (**ED25519**) and a dedicated Host alias within your SSH client configuration targeting a non-root `deployer` user.

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
The `launcher.sh` and the `log_inspector.sh` include runtime verification for the `ssh-agent`. When triggering a remote lifecycle, the script validates if your private key is already loaded in the active session. If not, it will securely prompt for your passphrase exactly once per terminal lifecycle.

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

# 3. Adds the deployer user, securely copy the public key to the server utilizing an administrative account
# and set the permisions so ssh works for that user
# Replace 'admin_user' and '190.x.x.x' with your target bootstrap credentials
ssh administrative_user@190.x.x.x "sudo adduser deployer mkdir -p /home/deployer/.ssh && chmod 700 /home/deployer/.ssh && echo '$(cat ~/.ssh/id_ed25519_project_deployer.pub)' >> /home/deployer/.ssh/authorized_keys && chmod 600 /home/deployer/.ssh/authorized_keys && chown -R deployer:deployer /home/deployer/.ssh"
```
>> **Recommendation:** Ensure that maintenance tasks, structural migrations, or container manual restarts are consistently executed under the same deployer user account to avoid permission alignment conflicts or missing volume discrepancies.

### Step 2: Provision Remote Dependencies
Before running the deployment script, establish an SSH session as an administrator to your targeted remote production node and ensure its core server-side binaries are installed. The remote environment requires:

* Docker & Docker Compose v2 or higher (To pull, construct, and orchestrate the live container ecosystem)
* msmtp & msmtp-mta (The native mail delivery client responsible for pushing critical runtime telemetry alerts directly from the host filesystem)

To provision your clean remote Debian/Ubuntu server instance with these required server-side tools, run the following command remotely using your administrative setup:

```bash
# Replace 'administrative_user' and '190.x.x.x' with your target bootstrap credentials
ssh administrative_user@190.x.x.x "sudo apt update && sudo apt install docker-compose-v2 msmtp msmtp-mta -y"
``` 

### Step 3: Remote Administrative Environment Provisioning
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

>⚠️ **CRITICAL EXECUTION RULE:** The deployment orchestrator parses runtime context using local configurations and explicit workspace alignments. Never change your working directory context or invoke execution vectors out-of-bounds from outside the root directory structure.
> Always trigger execution directly from the monorepo root:

To start the pipeline menu, run:

``` bash
./launcher.sh
```
#### Interactive Pipeline Menu
Upon executing the script, an interactive command-line interface (supporting English and Spanish based on the `SYSTEM_LANG` variable) will prompt you to select the deployment target: option 1 for local container initialization, or option 2 for secure remote orchestration via SSH.

1. **Deploy LOCAL Environment**
   * **Inbound Cleanup:** Run a preemptive cleanup cycle (`do_clear`) that wipes previous temporary build contexts and removes the local secrets directory (`./secrets`) to prevent data contamination.
   * **Local Compilation:** Compiles the Spring Boot backend via Maven (`app.jar`) and builds the frontend static assets using the `pnpm` engine.
   * **Staging Preparation:** Centralizes artifacts and configurations inside the temporary `./backend-build` and `./frontend-build` directories.
   * **Secrets Injection:** Reads credentials from the environment, dynamically generates plaintext files, and injects the configuration into the internal properties structure.
   * **Orchestration:** Launches the local infrastructure, forcing container recreation and removing orphans via `docker compose up -d --build --force-recreate --remove-orphans`.
   * **Post-Deployment Shielding:** **Secrets are preserved locally** but undergo strict filesystem permission shielding (`chmod 700` for the directory and `chmod 600` for the plaintext files).

2. **Deploy REMOTE Infrastructure (SSH)**
   * **Security Verification:** Strictly validates that `BACK_PROFILE` is set exactly to `prod` in your `.env` file. Otherwise, it aborts immediately to protect the environment.
   * **Local Staging Cycle:** Cleans up previous contexts, compiles both frontend and backend natively, and generates the local secrets payload.
   * **SSH Authentication:** Checks if the SSH agent has active identities; if not, interactively prompts for your private key's passphrase.
   * **Secure Transfer (SCP):** Synchronizes all staged contexts, orchestration files, the Nginx proxy, telemetry scripts and configurations, and the secrets payload directly to the remote directory (`/home/deployer/project-infra/`).
   * **Remote Orchestration & Injection:** Establishes the connection to initialize the stack on the server. Docker reads the physical secrets structure, injecting it in an isolated manner as read-only in-memory files for the services.
   * **Lifecycle Management & Contingency Handling (Trap):**
     * **On the Remote Server (Success Path):** Ensures secrets persistence by applying their final access shielding (`chmod 600`). The build directories (`backend-build` and `frontend-build`) **are kept intact** since the execution bypasses the cleanup `trap`.
     * **On the Remote Server (Failure Path):** If the `docker compose` command fails or is unexpectedly interrupted, the signal handler (`trap`) triggers immediately, **wiping the build directories and completely destroying the remote `./secrets` folder** to prevent leaking unshielded credentials.
     * **On the Local Machine:** Once the remote operation is confirmed successful, the engine runs a preventive full wipe (`do_clear`) that removes the build folders and generated secrets from your local workspace, keeping your station clean of persistent keys.

---

## 📊 System Telemetry & Log Operations

Container workloads enforce automated runtime log rotation (capped at 50MB per file, retaining up to 5 historic files per service). System auditing, diagnostics, and snapshot archiving are unified into a single local utility script.

### 🛠️ The Log Inspection Utility (`log_inspection.sh`)
The `log_inspection.sh` script is a localized operational tool that lets you live-stream active stdout/stderr logs or generate `.tar` archives of existing logs. It supports these functions for both the local machine and remote server hosts.

> ⚠️ **CRITICAL EXECUTION RULE:** The log inspector analyzes the execution context using local configurations and explicit workspace alignments. Never change your working directory or invoke execution vectors outside the boundaries of the root directory.
>
> Always execute the command directly from the root of the monorepo:

``` bash
./log_inspection.sh
```
### 🔄 Execution Workflow Logic
When initialized, the utility drives operations through a step-by-step interactive lifecycle:

1. **Language Initialization:** Prompts for operational language (English/Español) to localize runtime output logs and interactive choices.
2. **Environment Target Selection:** Prompts whether to query the `local` environment or connect to the `remote` server topology.
   * *Fallback Protection:* If the remote server connection fails or drops, the engine immediately prints a critical error sequence and halts execution (`exit 1`).
3. **Operational Mode Choice:**
   * **Mode 1 (Stream Live Logs):** Attaches cleanly to the container runtime via `docker logs -f`. Interrupting via `Ctrl+C` breaks the stream and pops you safely back to the menu. 
    * **Remote Log Stream Interruption Control (Ctrl+C):** When streaming remote container logs live, `log_inspection.sh` explicitly invokes the SSH execution pipeline utilizing the `-t` argument flag. Enforcing this pseudo-terminal allocation ensures that typing `Ctrl+C` successfully sends the interrupt signal down the active SSH tunnel directly to the remote TTY, allowing the script execution traps to gracefully close down background streams without killing your local terminal environment session.
   * **Mode 2 (Generate Diagnostic File):** Requests a maximum line threshold (defaulting to the complete log buffer if left empty).
    
4. **Target Service Selection:** Selects an individual container (`1) backend-service`, `2) frontend-service` or `3) db-service`), or if in **Mode 2** the option `4) All Services` is available for picking.
Depending in the current target environment and operation mode, the inspector will:
  * **Local target environment:**
    * **Mode 1:** Stream the logs for the selected service runing `docker logs -f "$TARGET_SERVICE"`
    * **Mode 2:** Produce an isolated, timestamped compressed diagnostic archive:
      * **Targeted Single-Service:** The resulting tar file will have this naming convention: 
      ``` bash
      TAR_NAME="log_${TARGET_SERVICE}_${TIMESTAMP}.tar.gz"
      ```
      This tar file contains the service corresponding .log file (e.g., `backend.log`, `frontend.log`, `db.log`).
      * **Targeted ALL Services:** The resulting tar file will have this naming convention:
      ``` bash
      TAR_NAME="log_all_services_${TIMESTAMP}.tar.gz"
      ```
      This tar file contains all the services corresponding .log files (`backend.log`, `frontend.log`, `db.log`).
  * **Remote target environment:**
    * **Mode 1:** Connects by ssh to the remote host and streams the logs for the selected service runing `docker logs -f "$TARGET_SERVICE"`
    * **Mode 2:** 
      * **.log file generation:** all .log files will be stored in a temporary directory when generated.
      * **Tar file generation:** A tar file is generated from the contents of the temporary folder and stored in the `/home/deployer` directory, appending a unique entropy string to the name to avoid collisions.
      * **Result transferring:** The resulting compressed file is securely transferred to the local host executing the inspector, adopting the uniform naming matrix defined above.
      * **Clean up:** Once the execution loop concludes or triggers a termination signal trap, all temporary working paths and remote staging archives are automatically pruned.
  * **Storing the resulting .tar files:** To store the resulting tarfiles, the log inspection tool will generate this folder structure:
    ```text
    ~/project-logs/
    ├── local/
    │   ├── log_[service_name]_[YYYYMMDD_HHMMSS].tar.gz
    │   └── log_all_services_[YYYYMMDD_HHMMSS].tar.gz
    └── remote/
        ├── log_[service_name]_[YYYYMMDD_HHMMSS].tar.gz
        └── log_all_services_[YYYYMMDD_HHMMSS].tar.gz
    ```
  
## 💾 Database Backup Engine Architecture

A remote database backup generation and saving tool. The architecture is built to run strictly within a local environment—streaming production data states over secure SSH tunneling channels, executing localized cryptographic signing routines, and concurrently distributing artifacts onto distinct, isolated cloud ecosystems to prevent single-point-of-failure infrastructure states.

### Asymmetric Cryptographic Key Pair Derivation (Curve25519)

To ensure maximum performance and high-grade defense vectors, the environment relies on Elliptic Curve Cryptography. Run the interactive manual initialization expert generator on your primary workstation. When prompted, select option 9 (ECC and ECC), select Curve 25519, set the expiration parameters to 0 (never expires), name the identity token metadata exactly `backup-master@local`, and secure it with a strong master password string.

``` bash
gpg --expert --full-generate-key
```

### Exporting Public Locking Mask and Private Key Escrow

The runtime execution script requires only the public key component to safely lock down the binary stream. Locate the key registry configuration and export the public key armor block. Afterward, export the raw backup private key armor string, copy its contents completely, paste it inside an encrypted note within your password manager vault, and securely erase it from your storage host filesystem.

``` bash
# Export public locking key asset
gpg --export --armor backup-master@local > backup_public.asc

# Export private key for cold storage inside a password manager
gpg --export-secret-keys --armor backup-master@local > private-key.asc
```

### Target Host Cryptographic Keys Integration

If configuring a secondary workstation host environment to execute the automated cron routines instead of the original key derivation machine, import the public tracking file key into the native GPG keyring topology to authorize target formatting streams.

``` bash
gpg --import backup_public.asc
```

### Secure Target Providers Provisioning (Rclone Setup)

The automated backup pipeline uses `rclone` to handle connection routines with cloud targets using obscured keys or localized OAuth sessions. Run the configuration tool to begin the interactive verification setup loop.

``` bash
rclone config
```
### Cloud Target Provider Authentication Guidelines

During the interactive registration prompt sequence, create three distinct target profile mappings matching the names configured inside the engine script precisely:

* **MEGA Setup Routine:** Select `n` (New Remote). Assign the name key `mega`. Choose the service registry identifier corresponding to `mega`. Input your primary account email identity and security password keys, then save the entry.
* **Google Drive Setup Routine:** Select `n` (New Remote). Assign the name key `gdrive`. Choose the service registry identifier corresponding to `drive`. Leave client configurations blank, select scope layer `1` (Full Access), and allow the automatic web browser verification flow to capture the authentication token.
* **pCloud Setup Routine:** Select `n` (New Remote). Assign the name key `pcloud`. Choose the service registry identifier corresponding to `pcloud`. Advance past advanced configurations and follow the automatic browser redirect sequence to allow rclone to sign structural authorization variables.

### Script Execution Permissions Assignment

To allow the local host operating environment to invoke and execute the automated backup pipeline, the file metadata must be modified to grant explicit execution permissions through the POSIX security subsystem.

```bash
chmod +x backup_engine.sh
```
### Manual Pipeline Integration Test Verification

To validate structural infrastructure pathways before switching completely to cron execution, perform a manual initialization run in your workstation terminal context and observe state telemetry outputs.

``` bash
./backup_engine.sh --lang=en
```
### Automation Task Scheduling Integration (Cron)

To guarantee consistent historical state persistence routines without human friction, link the backup script directly into the underlying operating system user automation scheduler:

``` bash
crontab -e
```
### Mapping Execution Boundaries Within Crontab Config

Append the configuration mapping string at the base of your crontab definitions file. The configuration below triggers an automated orchestration pipeline process sequence every single weekday (Monday through Friday) at exactly 12:00 PM, parsing the explicit system language parameter flags and capturing execution states into local files. Ensure you replace the file path placeholder with your actual file placement address.

``` bash
0 12 * * 1-5 /absolute/path/to/backup_engine.sh --lang=en >> /absolute/path/to/backup_cron.log 2>&1
```
### Disaster Recovery Restoration Blueprint

In a critical recovery deployment scenario, retrieve your stored asymmetric private key block from your password manager vault and save its text stream into a localized file named `private.key`. Import the file configuration into the staging environment keyring, download the target `.gpg` binary artifact from your cloud storage backup history, and execute the localized decryption recovery block.

``` bash
# Import the cold storage private configuration asset
gpg --import private.key

# Decrypt the cloud binary state into a readable database dump
gpg --batch --decrypt -o decrypted_database.sql.gz backup_20260528_120000.sql.gz.gpg
```

## 🖥️ Monitor Stack Integration
An automated infrastructure health subsystem designed for resource-constrained hosting environments. By querying Docker's health statuses via a single-pass JSON stream, the script evaluates stack health and dispatches multiplexed component log notifications if error vectors emerge.

### Remote Administrative Setup & Configuration
Because this telemetry micro-engine is scheduled to run natively on your remote deployment target, establish an SSH session as an administrator to your server and configure the subsystem:

#### 1. Decoupled Properties Management
Configuration rules are isolated inside `monitor_stack.properties`. Open the file on your remote server and provide a space-separated list of target notification emails:

**File:** `monitor_stack.properties`  
Space-separated list of target notification emails:

``` ini
ALERT_MAILS_LIST="your-email@gmail.com backup-alerts@gmail.com"
```

#### 2. Verify Telemetry Endpoints Manually
Execute a manual test pass to verify that your msmtp mail configurations, credentials, and network pathways are correct without forcing a real application failure:

``` bash
./monitor_stack.sh --test --lang=en
```
> **Note:** Passing `--test` skips the container failure evaluation and forces an instant verification diagnostic dispatch to your active mail configuration targets.

#### 3. Alert Suppression and Suppression Latches (Anti-Flood Protection)
To safeguard team inboxes from infinite loops during server downtime, the subsystem features a persistent lock state-machine:
* **On Failure:** The engine fires exactly one unified log report email to the active mailing list and touches a state tracking file (`.alert_active`), suppressing subsequent redundant alert dispatches on cron loops.
* **On Recovery:** Once all container services return to a completely healthy status, the engine removes `.alert_active` and logs a recovery note (`💚 SYSTEM RECOVERY DETECTED`), re-arming the telemetry triggers automatically.

To manually force a suppressed monitor back into an active testing state while nodes are down, clear the tracking latch directly:

``` bash
rm -f .alert_active
```

### Cron Task Automation Scheduling
Grant execution permissions to the script file within your project workspace repository:

``` bash
chmod +x monitor_stack.sh
```

Open your host terminal automation crontab definition layer to register the checking cycle:

``` bash
crontab -e
```
### Crontab Mapping Profile
Append the scheduling parameters at the base of the file interface. This configures the runtime loop to check status boundaries precisely every 5 minutes:

``` bash
*/5 * * * * /home/deployer/project-infra/monitor_stack.sh --lang=en
```

## 💡 Custom Project Adaptation & Refactoring Guide
This architecture is structured to be modular and fully decoupled, but uses uniform variables to keep orchestration simple. If you wish to migrate this engine blueprint into your own custom project domains, perform a global search-and-replace for the following key string values across your editor:

* `project-server`: The default SSH configuration host alias targeted by `launcher.sh` and `log_inspection.sh` to route all remote server communication.
* `id_ed25519_project_deployer`: The cryptographic private/public SSH key pair mapped inside your identity keyrings for secure server authentication.
* `/home/deployer/project-infra`: The absolute root deployment directory created on your target remote hosting server.
* `/home/deployer/project-logs`: The mapped local workstation folder destination where your remote log synchronization and multi-tab code inspections are stored.

**Global project references:** If you modify the core naming configurations for base modules or folder structures, ensure you identically mirror those changes inside `launcher.sh`, `monitor_stack.sh`, `backup_engine.sh`, Nginx server blocks, and your core `docker-compose.yml` configuration files. Ensure all references remain perfectly aligned to avoid breaking orchestrations.

## 🇪🇸 Español <a id="espanol"></a>

Un motor de despliegue que coordina, compila y envía aplicaciones desacopladas de **Spring Boot (Maven)** y **Vite React (pnpm)** utilizando automatización en Bash y orquestación Docker en múltiples etapas.

## Arquitectura y Ciclos de Vida

El motor trata al repositorio como un monorrepo desacoplado, ejecutando compilaciones localizadas antes de contenerizar los artefactos finales y asegurarlos detrás de una única puerta de enlace (gateway). Impone un aislamiento de red estricto al separar la infraestructura en dos capas distintas: una puerta de enlace Frontend orientada al exterior y una red de backend interna completamente aislada.

```
          [ Tráfico Web Público (Puerto 80) ]
                           |
                           v
              +--------------------------+
              |  Nginx Frontend & Proxy  |
              |  (Sirve React + Rutas)   |
              +--------------------------+
                           |
                    (front-network)
                           |
                           v
              +--------------------------+
              |    Backend Spring Boot   |
              +--------------------------+
                           |
                    (back-network)
                           |
                           v
              +--------------------------+
              |   Base de Datos Postgres  |
              +--------------------------+
```
### 1. Pipeline del Frontend y la Puerta de Enlace
* **Gestión de Dependencias:** Utiliza `pnpm` para un almacenamiento en caché de node_modules rápido y eficiente en disco a lo largo de las compilaciones.
* **Compilación:** Empaqueta los activos estáticos a través de los scripts de compilación de producción estándar de **Vite React**.
* **Imagen de Producción:** Una imagen ligera de Alpine-Nginx en una sola etapa. Este contenedor actúa tanto de **Edge Gateway** como de **Servidor Web**: integra y sirve los activos estáticos precompilados directamente, mientras gestiona simultáneamente las reglas de enrutamiento del proxy inverso.

### 2. Pipeline del Backend
* **Compilación:** Aprovecha el optimizador de Maven (./mvnw) para compilar y empaquetar un fat JAR listo para producción que contiene la aplicación y todas sus dependencias.
* **Evolución de la Base de Datos:** Integra **Flyway** dentro del ciclo de vida de Spring para ejecutar automáticamente el control de versiones del esquema y los scripts de migración de datos al iniciar la aplicación.
* **Imagen de Producción:** Un `Dockerfile` de una sola etapa copia el fat JAR precompilado en una capa de ejecución ligera de Eclipse Temurin OpenJDK JRE.

### 3. Orquestación y Aislamiento de Red (Docker Compose)
* **Puerta de Enlace Edge Unificada:** El servicio Nginx es el único punto de entrada a la infraestructura, mapeando el puerto externo (80). Aloja los activos del frontend y maneja las reglas de enrutamiento de la API, conectándose a la red `front-network`.
* **Topología de Aislamiento de Red:** Impone una segregación completa de la infraestructura utilizando dos redes puente (bridge) separadas:
  * `front-network`: Conecta el contenedor unificado de frontend/proxy Nginx y el punto de entrada de la aplicación backend.
  * `back-network`: Conecta exclusivamente la aplicación backend y la base de datos PostgreSQL.
* **Aislamiento de PostgreSQL:** Aísla el contenedor de la base de datos completamente dentro de `back-network`, haciéndolo accesible solo por el backend. Permanece enteramente invisible e inaccesible desde el contenedor frontend/proxy, la máquina host o el internet exterior.
* **Gestión de Credenciales a través de Docker Secrets:** El entorno prohíbe estrictamente la inyección de credenciales sensibles (`DB_USER`, `DB_PASSWORD`, `DB_NAME`) mediante variables de entorno estándar del sistema operativo. En su lugar, aprovecha el subsistema Docker Secrets, montando estas llaves como archivos de solo lectura en la memoria virtual bajo la ruta `/run/secrets/`. Esto mitiga por completo los vectores de ataque orientados a la fuga de credenciales mediante la inspección de procesos (`docker inspect`) o volcados de entorno del sistema.
* **Persistencia de Datos y Propiedad de Volúmenes:** La capa de almacenamiento con estado definida en `docker-compose.yml` monta los archivos del clúster de PostgreSQL directamente en un directorio relativo en el host: `/home/deployer/data/postgres`.
* **Inicialización del Clúster en Cascada y Verificaciones de Disponibilidad:** Para evitar condiciones de carrera en los servicios y fallos de arranque inicial, el clúster se basa en verificaciones de salud nativas y secuencias de inicio estrictas:
  * **Disponibilidad de la Base de Datos:** El contenedor del servicio backend incluye compuertas de salud de dependencias que evalúan la instancia de PostgreSQL utilizando `pg_isready`, bloqueando la secuencia de inicio del backend hasta que el motor de la base de datos esté completamente preparado para aceptar conexiones de sockets TCP/IP.
  * **Frontend y Puerta de Enlace:** El contenedor central de la puerta de enlace `frontend-service` cuenta con su propia verificación de salud interna dedicada para exponer estados de disponibilidad actualizados. Depende de compuertas de dependencia para garantizar que el `backend-service` esté completamente sano antes de finalizar su bucle de inicialización de enrutamiento entrante.
* **Escalamiento Horizontal y Round-Robin Nativo:** La arquitectura está preconfigurada para un escalamiento horizontal transparente. Por defecto, se inicializa con una sola instancia del backend (`replicas: 1`). Para escalar la capa del backend y soportar mayores cargas de tráfico, simplemente aumente el valor de la propiedad `deploy.replicas` dentro del bloque `backend-service` en el archivo `docker-compose.yml`. El gateway unificado utiliza el motor de DNS interno de Docker (`127.0.0.11`) para detectar dinámicamente las nuevas instancias del backend y realizar un balanceo de carga round-robin automático, sin necesidad de modificar los perfiles de enrutamiento de Nginx.

#### Enrutamiento
* **Enrutamiento Edge:** El servicio Nginx es el único contenedor que expone puertos públicos (`80:80`). Actúa como un único guardián, manejando las cabeceras de seguridad, sirviendo la interfaz de usuario y distribuyendo el tráfico internamente.
* **Enrutamiento de Servicios:** El tráfico público que llega a la puerta de enlace se maneja en función de las rutas:
  * Las solicitudes hacia `/api/` se redirigen mediante proxy inverso internamente y se reenvían directamente a la aplicación Spring Boot (`backend-service:8080`).
    * **Protección del Actuator:** El proxy edge intercepta y descarta explícitamente el tráfico público dirigido a los endpoints `/api/actuator` con una regla `403 Forbidden`, manteniendo confidenciales los estados de gestión de Spring Boot.
  * Todo el demás tráfico (`/`) es resuelto localmente por Nginx, sirviendo los activos compilados de React/Vite directamente desde su propio sistema de archivos.

#### Cabeceras de la Puerta de Enlace
La capa del servicio Nginx implementa parámetros estrictos de defensa en profundidad en cada transacción HTTP activa:

* **Protección contra Clickjacking**: Inyecta a la fuerza parámetros de seguridad para denegar el enmarcado.

``` conf 
X-Frame-Options "SAMEORIGIN"
```

* **Prevención de MIME Sniffing**: Desactiva de forma nativa los exploits de sniffing de estilos/scripts.

``` conf
X-Content-Type-Options "nosniff"
```

* **Política de Seguridad del Contenido (CSP)**: Emplea una política estricta de lista blanca que permite los activos locales mientras bloquea los modelos de ejecución externos.

``` conf
default-src 'self';

script-src 'self';

style-src 'self' 'unsafe-inline';

object-src 'none';

frame-src 'none';
```

* **Optimización del Rendimiento de Activos**: Almacena en caché las fuentes de la aplicación, los scripts de la interfaz de usuario compilados, los estilos y los activos multimedia durante 6 meses, al tiempo que silencia los registros de acceso para eliminar los cuellos de botella de E/S en disco.

``` conf
location ~* \.(?:ico|css|js|gif|jpe?g|png|woff2?|eot|ttf|svg)$ {
    expires 6M;
    public;
    access_log off;
}
```

---
## 📋 Prerrequisitos de la Estación de Trabajo Local
Antes de configurar o inicializar el motor, asegúrate de que tu estación de trabajo de desarrollo local tenga los siguientes binarios principales activos dentro de la ruta del sistema:

* Docker y Docker Compose v2+ o v5+ (Contenerización del entorno principal y plataforma de pruebas locales)
* rclone (Sincronización segura y no interactiva de almacenamiento de copias de seguridad en la nube)
* gnupg (Utilidad de bóveda criptográfica asimétrica)
* msmtp y msmtp-mta (Cliente de retransmisión SMTP ligero utilizado localmente para pruebas de verificación de scripts de monitoreo manual)

Para instalar estas herramientas de desarrollo en una máquina local limpia con Ubuntu/Debian, ejecuta:

``` bash
sudo apt update && sudo apt install docker-compose-v2 rclone gnupg msmtp msmtp-mta -y
```
## ⚙️ Configuración Local (.env)

Antes de ejecutar cualquier script, debes crear un archivo `.env` en la raíz de este directorio de infraestructura utilizando la plantilla provista. Este archivo está excluido a través de `.gitignore` para evitar fugas de secretos.

Para configurarlo rápidamente, copia el archivo de ejemplo **.env.example** y edítalo con tus parámetros locales:

``` bash
# 1. Copia la plantilla para crear tu archivo de entorno local
cp .env.example .env

# 2. Abre y configura tus secretos y rutas
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
## 🌐 Idioma de Ejecución y Matriz de Flags en Tiempo de Ejecución
La infraestructura de shell subyacente respeta las reglas de localización basadas en los entornos de ejecución, los argumentos de la línea de comandos o los menús interactivos de la terminal:

* **Motor del Lanzador (`launcher.sh`):** Obtiene exclusivamente sus reglas de configuración e idioma de destino de forma dinámica a partir de tu archivo de plantilla local `.env` en la raíz (`SYSTEM_LANG="en"|"es"`).
* **Herramientas de Telemetría y Automatización (`monitor_stack.sh`, `backup_engine.sh`):** Admiten flags de argumentos inmediatos en la terminal para habilitar perfiles de idioma específicos bajo demanda (por ejemplo, `./monitor_stack.sh --lang=es`).
* **Motor de Interacción (`log_inspection.sh`):** Cuenta con un menú interactivo en la interfaz de línea de comandos (CLI) de la terminal que te permite elegir dinámicamente tu idioma de interfaz preferido directamente al ejecutarse antes de correr las tareas.

## 🔑 Control de Acceso y Configuración Remota (SSH)

Para garantizar conexiones remotas automatizadas y fluidas para el motor del lanzador, el motor de copias de seguridad o el inspector de registros, tu estación de trabajo local debe estar configurada mediante autenticación basada en llaves (**ED25519**) y un alias de Host dedicado dentro de la configuración de tu cliente SSH dirigido a un usuario `deployer` que no sea root.

### 1. Configurar el Alias de Host SSH Local
Edita o crea tu archivo local `~/.ssh/config` y añade la siguiente estructura:

```
Host project-server
    HostName 190.x.x.x              # La IP de destino de tu servidor remoto
    User deployer                   # Tu usuario de despliegue remoto no raíz
    Port xx                         # Puerto SSH
    AddressFamily xxxx              # Apunta al uso de IPv4 o IPv6
    IdentityFile ~/.ssh/id_ed25519_project_deployer
    AddKeysToAgent yes
```

### 2. Automatización del Agente SSH
El `launcher.sh` y el `log_inspection.sh` incluyen una verificación en tiempo de ejecución para el `ssh-agent`. Al activar un ciclo de vida remoto, el script valida si tu llave privada ya está cargada en la sesión activa. Si no es así, te solicitará de forma segura tu frase de contraseña exactamente una vez por ciclo de vida de la terminal.

---

## 🚀 Aprovisionamiento del Servidor y Bootstrapping

Antes de activar el primer pipeline de despliegue automatizado, el entorno del servidor remoto de destino debe ser aprovisionado con las jerarquías de carpetas adecuadas, los grupos de ejecución y permisos estrictos de E/S de volúmenes utilizando una cuenta de administrador.

### Paso 1: Despliegue Automatizado de Llaves y Configuración del Espacio de Trabajo
Desde la terminal de tu estación de trabajo local, genera la llave de despliegue dedicada y envíala al servidor remoto utilizando tu cuenta administrativa del servidor existente:

``` bash
# 1. Genera el par de llaves de despliegue dedicado localmente, con su correspondiente frase de contraseña
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_project_deployer -C "deployer@infrastructure" -N "TuFraseDeContraseñaSegura"

# 2. Añade el par de llaves a la sesión activa de tu agente SSH local
ssh-add ~/.ssh/id_ed25519_project_deployer

# 3. Añade el usuario deployer ,copia de forma segura la llave pública al servidor utilizando una cuenta administrativa
# y establece los permisos para que el ssh funcione para ese usuario
# Reemplaza 'admin_user' and '190.x.x.x' con tus credenciales de destino para el bootstrap
ssh administrative_user@190.x.x.x "sudo adduser deployer && sudo mkdir -p /home/deployer/.ssh && sudo chmod 700 /home/deployer/.ssh && echo '$(cat ~/.ssh/id_ed25519_project_deployer.pub)' | sudo tee -a /home/deployer/.ssh/authorized_keys && sudo chmod 600 /home/deployer/.ssh/authorized_keys && sudo chown -R deployer:deployer /home/deployer/.ssh"
```

>> **Recomendación:** Asegúrate de que las tareas de mantenimiento, las migraciones estructurales o los reinicios manuales de contenedores se ejecuten consistentemente bajo la misma cuenta de usuario deployer para evitar conflictos de alineación de permisos o discrepancias por volúmenes faltantes.

### Paso 2: Aprovisionar Dependencias Remotas
Antes de ejecutar el script de despliegue, establece una sesión SSH como administrador en tu nodo de producción remoto objetivo y asegúrate de que sus binarios principales del lado del servidor estén instalados. El entorno remoto requiere:

* Docker y Docker Compose v2 o superior (Para descargar, construir y orquestar el ecosistema de contenedores en vivo)
* msmtp y msmtp-mta (El cliente de entrega de correo nativo responsable de enviar alertas críticas de telemetría en tiempo de ejecución directamente desde el sistema de archivos del host)

Para aprovisionar tu instancia de servidor remoto Debian/Ubuntu limpia con estas herramientas requeridas del lado del servidor, ejecuta el siguiente comando de forma remota utilizando tu configuración administrativa:

``` bash
# Reemplaza 'administrative_user' y '190.x.x.x' con tus credenciales de destino
ssh administrative_user@190.x.x.x "sudo apt update && sudo apt install docker-compose-v2 msmtp msmtp-mta -y"
```

### Paso 3: Aprovisionamiento del Entorno Administrativo Remoto
Accede a tu remoto entorno de servidor vía terminal utilizando tu usuario administrativo para configurar los permisos, los grupos de docker y las arquitecturas de rutas:

``` bash
# 1. Conéctate a tu servidor utilizando tu credencial administrativa
ssh administrative_user@190.x.x.x

# 2. Concede al usuario no raíz 'deployer' acceso para gestionar contextos de Docker sin privilegios de sudo
sudo usermod -aG docker deployer

# 3. Estructura los directorios para los metadatos de orquestación y la persistencia de la base de datos bajo el entorno de deployer
sudo mkdir -p /home/deployer/project-infra
sudo mkdir -p /home/deployer/data/postgres

# 4. Impone límites estrictos de bloqueo del sistema de archivos en el volumen bruto de la base de datos
# Restringe los permisos y asigna la propiedad exclusivamente al motor PostgreSQL contenedorizado (UID 999)
sudo chown -R 999:999 /home/deployer/data/postgres
sudo chmod -R 700 /home/deployer/data/postgres

# 5. Corrige la propiedad global de los directorios del espacio de trabajo de despliegue devolviéndola al usuario deployer
sudo chown -R deployer:deployer /home/deployer/project-infra

# 6. Aplica las actualizaciones de grupo instantáneamente sin necesidad de reiniciar por completo el servidor
sudo systemctl restart docker
```

---
## 🛠️ Operando el Motor del Lanzador

El script `launcher.sh` es la puerta de entrada interactiva para controlar, construir y orquestar los ciclos de vida de los servicios.

### Ejecución

>⚠️ **REGLA CRÍTICA DE EJECUCIÓN:** El orquestador de despliegue analiza el contexto de tiempo de ejecución utilizando configuraciones locales y alineaciones explícitas del espacio de trabajo. Nunca cambies el contexto de tu directorio de trabajo ni invoques vectores de ejecución fuera de los límites de la estructura del directorio raíz.
> Ejecuta siempre la activación directamente desde la raíz del monorrepo:

Para iniciar el menú del pipeline, ejecuta:

``` bash
./launcher.sh
```

#### Menú Interactivo del Pipeline
Al ejecutar el script, una interfaz de línea de comandos interactiva (que admite inglés y español en función de la variable `SYSTEM_LANG`) te pedirá que selecciones el destino del despliegue: la opción 1 para la inicialización de contenedores locales, o la opción 2 para la orquestación remota segura a través de SSH.

1. **Desplegar Entorno LOCAL**
   * **Limpieza Entrante:** Ejecuta un ciclo de limpieza preventivo (`do_clear`) que borra los contextos de compilación temporales anteriores y elimina el directorio de secretos locales (`./secrets`) para evitar la contaminación de datos.
   * **Compilación Local:** Compila el backend de Spring Boot a través de Maven (`app.jar`) y construye los activos estáticos del frontend utilizando el motor `pnpm`.
   * **Preparación del Staging:** Centraliza los artefactos y las configuraciones dentro de los directorios temporales `./backend-build` y `./frontend-build`.
   * **Inyección de Secretos:** Lee las credenciales del entorno, genera dinámicamente archivos de texto plano e inyecta la configuración en la estructura de propiedades internas.
   * **Orchestración:** Lanza la infraestructura local, forzando la recreación de contenedores y eliminando los huérfanos a través de `docker compose up -d --build --force-recreate --remove-orphans`.
   * **Protección Post-Despliegue:** **Los secretos se preservan localmente** pero se someten a un estricto blindaje de permisos en el sistema de archivos (`chmod 700` para el directorio y `chmod 600` para los archivos de texto plano).

2. **Desplegar Infraestructura REMOTA (SSH)**
   * **Verificación de Seguridad:** Valida estrictamente que `BACK_PROFILE` esté configurado exactamente como `prod` en tu archivo `.env`. De lo contrario, aborta inmediatamente para proteger el entorno.
   * **Ciclo de Staging Local:** Limpia los contextos previos, compila de forma nativa tanto el frontend como el backend y genera el payload de secretos locales.
   * **Autenticación SSH:** Comprueba si el agente SSH tiene identidades activas; si no es así, solicita de forma interactiva la frase de contraseña de tu llave privada.
   * **Transferencia Segura (SCP):** Sincroniza todos los contextos preparados, los archivos de orquestación, el proxy Nginx, los scripts y configuraciones de telemetría y el payload de secretos directamente al directorio remoto (`/home/deployer/project-infra/`).
   * **Orquestación e Inyección Remota:** Establece la conexión para inicializar el stack en el servidor. Docker lee la estructura física de los secretos, inyectándola de forma aislada como archivos de solo lectura en memoria para los servicios.
   * **Gestión del Ciclo de Vida y Manejo de Contingencias (Trap):**
     * **En el Servidor Remoto (Camino de Éxito):** Garantiza la persistencia de los secretos aplicando su blindaje de acceso final (`chmod 600`). Los directorios de compilación (`backend-build` y `frontend-build`) **se mantienen intactos** ya que la ejecución omite el comando de limpieza `trap`.
     * **En el Servidor Remoto (Camino de Fallo):** Si el comando `docker compose` falla o se interrumpe inesperadamente, el manejador de señales (`trap`) se activa inmediatamente, **borrando los directorios de compilación y destruyendo por completo la carpeta remota `./secrets`** para evitar la filtración de credenciales sin protección.
     * **En la Máquina Local:** Una vez que se confirma el éxito de la operation remota, el motor ejecuta un borrado completo preventivo (`do_clear`) que elimina las carpetas de compilación y los secretos generados de tu espacio de trabajo local, manteniendo tu estación limpia de llaves persistentes.

---
## 📊 Telemetría del Sistema y Operaciones de Registros

Las cargas de trabajo de los contenedores imponen una rotación automatizada de registros en tiempo de ejecución (con un límite de 50 MB por archivo, reteniendo hasta 5 archivos históricos por servicio). La auditoría del sistema, los diagnósticos y el archivo de instantáneas se unifican en un único script de utilidad local.

### 🛠️ Herramienta de Inspección de Logs (`log_inspection.sh`)
El script `log_inspection.sh` es una herramienta operativa local que te permite transmitir en vivo los logs activos de stdout/stderr o generar archivos `.tar` con los logs existentes. Soporta estas funciones tanto para la máquina local como para servidores remotos.

> ⚠️ **REGLA CRÍTICA DE EJECUCIÓN:** El inspector de registros analiza el contexto de ejecución utilizando configuraciones locales y alineaciones explícitas del espacio de trabajo. Nunca cambies tu directorio de trabajo ni invoques vectores de ejecución fuera de los límites del directorio raíz.
>
> Ejecuta siempre el comando directamente desde la raíz del monorrepo:

``` bash
./log_inspection.sh
```
### 🔄 Lógica del Flujo de Trabajo de Ejecución
Cuando se inicializa, la utilidad conduce las operaciones a través de un ciclo de vida interactivo paso a paso:

1. **Inicialización del Idioma:** Solicita el idioma operativo (English/Español) para localizar los registros de salida en tiempo de ejecución y las opciones interactivas.
2. **Selección del Entorno de Destino:** Pregunta si se debe consultar el entorno `local` o conectarse a la topología del servidor `remote`.
   * *Protección de Fallback:* Si la conexión con el servidor remoto falla o se cae, el motor imprime inmediatamente una secuencia de error crítico y detiene la ejecución (`exit 1`).
3. **Elección del Modo Operativo:**
   * **Modo 1 (Transmitir Registros en Vivo):** Se conecta limpiamente al tiempo de ejecución del contenedor a través de `docker logs -f`. Interrumpir mediante `Ctrl+C` rompe el flujo y te devuelve de forma segura al menú. 
     * **Control de Interrupción del Flujo de Registros Remoto (Ctrl+C):** Al transmitir registros de contenedores remotos en vivo, `log_inspection.sh` invoca explícitamente el pipeline de ejecución SSH utilizando el flag de argumento `-t`. Imponer esta asignación de pseudo-terminal garantiza que al escribir `Ctrl+C` se envíe con éxito la señal de interrupción a través del túnel SSH activo directamente a la TTY remota, permitiendo que las trampas de ejecución del script cierren con gracia los flujos en segundo plano sin matar la sesión de tu entorno de terminal local.
   * **Modo 2 (Generar Archivo de Diagnóstico):** Solicita un umbral máximo de líneas (por defecto se toma el búfer de registro completo si se deja vacío).
    
4. **Selección del Servicio de Destino:** Selecciona un contenedor individual (`1) backend-service`, `2) frontend-service` o `3) db-service`), o si estás en el **Modo 2**, la opción `4) All Services` estará disponible para su elección.
Dependiendo del entorno de destino actual y del modo de operación, el inspector hará lo siguiente:
  * **Entorno de destino local:**
    * **Modo 1:** Transmite los registros para el servicio seleccionado ejecutando `docker logs -f "$TARGET_SERVICE"`
    * **Modo 2:** Produce un archivo de diagnóstico comprimido aislado y con marca de tiempo:
      * **Servicio Único Seleccionado:** El archivo tar resultante tendrá esta convención de nomenclatura: 
      ``` bash
      TAR_NAME="log_${TARGET_SERVICE}_${TIMESTAMP}.tar.gz"
      ```
      Este archivo tar contiene el archivo .log correspondiente al servicio (por ejemplo, `backend.log`, `frontend.log`, `db.log`).
      * **TODOS los Servicios Seleccionados:** El archivo tar resultante tendrá esta convención de nomenclatura:
      ``` bash
      TAR_NAME="log_all_services_${TIMESTAMP}.tar.gz"
      ```
      Este archivo tar contiene todos los archivos .log correspondientes a los servicios (`backend.log`, `frontend.log`, `db.log`).
  * **Entorno de destino remoto:**
    * **Modo 1:** Se conecta por ssh al host remoto y transmite los registros para el servicio seleccionado ejecutando `docker logs -f "$TARGET_SERVICE"`
    * **Modo 2:** * **Generación de archivos .log:** todos los archivos .log se almacenarán en un directorio temporal al generarse.
      * **Generación de archivos Tar:** Se genera un archivo tar a partir del contenido de la carpeta temporal y se almacena en el directorio `/home/deployer`, añadiendo una cadena de entropía única al nombre para evitar colisiones.
      * **Transferencia de Resultados:** El archivo comprimido resultante se transfiere de forma segura al host local que ejecuta el inspector, adoptando la matriz de nomenclatura uniforme definida anteriormente.
      * **Limpieza:** Una vez que concluye el bucle de ejecución o se activa una trampa de señal de terminación, todas las rutas de trabajo temporales y los archivos de staging remotos se eliminan automáticamente.
  * **Almacenamiento de los archivos .tar resultantes:** Para almacenar los archivos tar resultantes, la herramienta de inspección de registros generará esta estructura de carpetas:

  ```
  ~/project-logs/
  ├── local/
  │   ├── log_[nombre_del_servicio]_[AAAAMMDD_HHMMSS].tar.gz
  │   └── log_all_services_[AAAAMMDD_HHMMSS].tar.gz
  └── remote/
      ├── log_[nombre_del_servicio]_[AAAAMMDD_HHMMSS].tar.gz
      └── log_all_services_[AAAAMMDD_HHMMSS].tar.gz 
  ```

## 💾 Arquitectura del Motor de Copias de Seguridad de la Base de Datos

Una herramienta de generación y guardado de copias de seguridad de bases de datos remotas. La arquitectura está diseñada para ejecutarse estrictamente dentro de un entorno local—transmitiendo estados de datos de producción sobre canales seguros de tunelización SSH, ejecutando rutinas de firma criptográfica localizadas y distribuyendo concurrentemente artefactos en ecosistemas de nube distintos e aislados para evitar estados de infraestructura con puntos únicos de fallo.

### Derivación de Pares de Llaves Criptográficas Asimétricas (Curve25519)

Para garantizar el máximo rendimiento y vectores de defensa de alto nivel, el entorno se basa en la Criptografía de Curva Elíptica. Ejecuta el generador experto de inicialización manual interactivo en tu estación de trabajo principal. Cuando se te solicite, selecciona la opción 9 (ECC y ECC), selecciona Curve 25519, establece los parámetros de expiración en 0 (nunca expira), nombra los metadatos del token de identidad exactamente `backup-master@local` y asegúralos con una cadena de contraseña maestra fuerte.

``` bash
gpg --expert --full-generate-key
```

### Exportación de la Máscara de Encripción Pública y Custodia de la Llave Privada

El script de ejecución en tiempo de ejecución requiere únicamente el componente de la llave pública para encriptar de forma segura el flujo binario. Localiza la configuración del registro de llaves y exporta el bloque de armadura de la llave pública. Después, exporta la cadena de armadura de la llave privada de respaldo en bruto, copia su contenido por completo, pégalo dentro de una nota cifrada en tu bóveda de gestión de contraseñas y bórralo de forma segura del sistema de archivos del host de almacenamiento.

``` bash
# Exportar el activo de la llave de bloqueo pública
gpg --export --armor backup-master@local > backup_public.asc

# Exportar la llave privada para almacenamiento en frío dentro de un gestor de contraseñas
gpg --export-secret-keys --armor backup-master@local > private-key.asc
```

### Integración de Llaves Criptográficas en el Host de Destino

Si estás configurando un entorno de host de estación de trabajo secundario para ejecutar las rutinas de cron automatizadas en lugar de la máquina de derivación de llaves original, importa el archivo de la llave de seguimiento pública en la topología nativa del llavero de GPG para autorizar los flujos de formato de destino.

``` bash
gpg --import backup_public.asc
```

### Aprovisionamiento Seguro de Proveedores de Destino (Configuración de Rclone)

El pipeline de copias de seguridad automatizado utiliza `rclone` para manejar las rutinas de conexión con los objetivos de la nube utilizando llaves ocultas o sesiones OAuth localizadas. Ejecuta la herramienta de configuración para comenzar el bucle interactivo de configuración de verificación.

``` bash
rclone config
```

### Directrices de Autenticación del Proveedor de Destino en la Nube

Durante la secuencia interactiva de solicitudes de registro, crea tres mapeos de perfiles de destino distintos que coincidan exactamente con los nombres configurados dentro del script del motor:

* **Rutina de Configuración de MEGA:** Selecciona `n` (New Remote). Asigna la llave de nombre `mega`. Elige el identificador de registro de servicio correspondiente a `mega`. Introduce el correo electrónico de identidad de tu cuenta principal y las llaves de contraseña de seguridad, luego guarda la entrada.
* **Rutina de Configuración de Google Drive:** Selecciona `n` (New Remote). Asigna la llave de nombre `gdrive`. Elige el identificador de registro de servicio correspondiente a `drive`. Deja las configuraciones del cliente en blanco, selecciona la capa de alcance `1` (Full Access) y permite que el flujo de verificación automática del navegador web capture el token de autenticación.
* **Rutina de Configuración de pCloud:** Selecciona `n` (New Remote). Asigna la llave de nombre `pcloud`. Elige el identificador de registro de servicio correspondiente a `pcloud`. Avanza más allá de las configuraciones avanzadas y sigue la secuencia de redirección automática del navegador para permitir que rclone firme las variables de autorización estructurales.

### Asignación de Permisos de Ejecución del Script

Para permitir que el entorno operativo del host local invoque y ejecute el pipeline de copias de seguridad automatizado, se deben modificar los metadatos del archivo para conceder permisos de ejecución explícitos a través del subsistema de seguridad de POSIX.

``` bash
chmod +x backup_engine.sh
```

### Verificación Manual de la Prueba de Integración del Pipeline

Para validar las rutas de la infraestructura estructural antes de cambiar por completo a la ejecución de cron, realiza una ejecución de inicialización manual en el contexto de la terminal de tu estación de trabajo y observa las salidas de telemetría de estado.

``` bash
./backup_engine.sh --lang=es
```

### Integración de la Programación de Tareas de Automatización (Cron)

Para garantizar rutinas consistentes de persistencia de estado histórico sin fricción humana, vincula el script de copia de seguridad directamente en el programador de automatización de usuarios del sistema operativo subyacente:

``` bash
crontab -e
```

### Mapeo de Límites de Ejecución Dentro de la Configuración de Crontab

Añade la cadena de mapeo de configuración en la base de tu archivo de definiciones de crontab. La configuración siguiente activa una secuencia de procesos de pipeline de orquestación automatizada cada día de la semana (de lunes a viernes) a las 12:00 PM exactamente, analizando los flags de parámetros de idioma del sistema explícitos y capturando los estados de ejecución en archivos locales. Asegúrate de reemplazar el marcador de posición de la ruta del archivo con tu dirección real de ubicación del archivo.

``` bash
0 12 * * 1-5 /ruta/absoluta/a/backup_engine.sh --lang=es >> /ruta/absoluta/a/backup_cron.log 2>&1
```

### Plan de Restauración para la Recuperación ante Desastres

En un escenario de despliegue de recuperación crítica, recupera tu bloque de llave privada asimétrica almacenado desde tu bóveda del gestor de contraseñas y guarda su flujo de texto en un archivo localizado llamado `private.key`. Importa la configuración del archivo en el llavero del entorno de staging, descarga el artefacto binario `.gpg` de destino desde tu historial de copias de seguridad de almacenamiento en la nube y ejecuta el bloque de recuperación de descifrado localizado.

``` bash
# Importar el activo de configuración privada del almacenamiento en frío
gpg --import private.key

# Descifrar el estado binario de la nube en un volcado de base de datos legible
gpg --batch --decrypt -o decrypted_database.sql.gz backup_20260528_120000.sql.gz.gpg
```

## 🖥️ Integración del Monitor del Stack
Un subsistema automatizado de salud de la infraestructura diseñado para entornos de alojamiento con recursos limitados. Al consultar los estados de salud de Docker a través de un flujo JSON de una sola pasada, el script evalúa la salud del stack y despacha notificaciones de registro de componentes multiplexados si surgen vectores de error.

### Configuración y Ajustes Administrativos Remotos
Debido a que este micro-motor de telemetría está programado para ejecutarse de forma nativa en tu objetivo de despliegue remoto, establece una sesión SSH como administrador en tu servidor y configura el subsistema:

#### 1. Gestión de Propiedades Desacoplada
Las reglas de configuración están aisladas dentro de `monitor_stack.properties`. Abre el archivo en tu servidor remoto y proporciona una lista separada por espacios de los correos electrónicos de destino para las notificaciones:

**Archivo:** `monitor_stack.properties`  
Lista separada por espacios de los correos electrónicos de destino para las notificaciones:

``` ini
ALERT_MAILS_LIST="your-email@gmail.com backup-alerts@gmail.com"
```

#### 2. Verificar los Endpoints de Telemetría Manualmente
Ejecuta un pase de prueba manual para verificar que tus configuraciones de correo msmtp, credenciales y rutas de red sean correctas sin forzar un fallo real de la aplicación:

``` bash
./monitor_stack.sh --test --lang=es
```

> **Nota:** Pasar `--test` omite la evaluación de fallos del contenedor y fuerza el envío instantáneo de un diagnóstico de verificación a tus objetivos de configuración de correo activos.

#### 3. Supresión de Alertas y Pestillos de Supresión (Protección Anti-Inundación)
Para salvaguardar las bandejas de entrada del equipo de bucles infinitos durante el tiempo de inactividad del servidor, el subsistema cuenta con una máquina de estados de bloqueo persistente:
* **En caso de Fallo:** El motor dispara exactamente un correo electrónico unificado de informe de registro a la lista de correo activa y toca un archivo de seguimiento de estado (`.alert_active`), suprimiendo los envíos de alertas redundantes subsecuentes en los bucles de cron.
* **En caso de Recuperación:** Una vez que todos los servicios de contenedores vuelven a un estado completamente sano, el motor elimina `.alert_active` y registra una nota de recuperación (`💚 SYSTEM RECOVERY DETECTED`), rearmando los disparadores de telemetría automáticamente.

Para manualmente forzar a un monitor suprimido a volver a un estado de prueba activo mientras los nodos están caídos, borra el pestillo de seguimiento directamente:

``` bash
rm -f .alert_active
```

### Programación de la Automatización de Tareas de Cron
Concede permisos de ejecución al archivo de script dentro del repositorio de tu espacio de trabajo del proyecto:

``` bash
chmod +x monitor_stack.sh
```

Abre la capa de definición de crontab de automatización de la terminal de tu host para registrar el ciclo de verificación:

``` bash
crontab -e
```

### Perfil de Mapeo de Crontab
Añade los parámetros de programación en la base del archivo de interfaz. Esto configura el bucle de tiempo de ejecución para comprobar los límites de estado con precisión cada 5 minutos:

``` bash
*/5 * * * * /home/deployer/project-infra/monitor_stack.sh --lang=es
```

## 💡 Guía de Adaptación y Refactorización de Proyectos Personalizados
Esta arquitectura está estructurada para ser modular y totalmente desacoplada, pero utiliza variables uniformes para mantener la orquestación simple. Si deseas migrar este plano del motor a tus propios dominios de proyectos personalizados, realiza una búsqueda y reemplazo global para los siguientes valores de cadena clave a lo largo de tu editor:

* `project-server`: El alias de host de configuración SSH por defecto al que apuntan `launcher.sh` y `log_inspection.sh` para enrutar toda la comunicación con el servidor remoto.
* `id_ed25519_project_deployer`: El par de llaves SSH criptográficas privada/pública mapeado dentro de tus llaveros de identidad para una autenticación segura en el servidor.
* `/home/deployer/project-infra`
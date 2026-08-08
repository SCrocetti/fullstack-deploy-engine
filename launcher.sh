#!/bin/bash

# ==============================================================================
# 1. ENVIRONMENT VARIABLES LOADING & LANGUAGE SETUP
# ==============================================================================
if [ -f .env ]; then
   source .env
else
    echo "❌ Error: Required .env file not found. / No se encontró el archivo .env."
    exit 1
fi

if [ -z "$SYSTEM_LANG" ]; then
    SYSTEM_LANG="en"
fi

declare -rA TXT_EXEC_TRACE TXT_WIPING_CTX TXT_START_BUILD TXT_ERR_PATHS \
           TXT_BUILD_BACKEND TXT_ERR_BACKEND TXT_BUILD_FRONTEND \
           TXT_ERR_FRONTEND TXT_SSH_EMPTY TXT_SSH_DETECTED \
           TXT_DEPLOY_MENU_TITLE TXT_DEPLOY_MENU_LOC TXT_DEPLOY_MENU_REM \
           TXT_DEPLOY_MENU_PROMPT TXT_TRIGGER_LOCAL TXT_LOCAL_SUCCESS \
           TXT_ERR_LOCAL TXT_ERR_SEC_TITLE TXT_ERR_SEC_REQ TXT_ERR_SEC_CURR \
           TXT_ERR_SEC_ABORT TXT_PREPARE_REMOTE TXT_ERR_REMOTE_DIR \
           TXT_ERR_SCP TXT_SWITCH_REMOTE TXT_REMOTE_SUCCESS \
           TXT_ERR_REMOTE TXT_INVALID_OPTION

# --- Spanish (es) ---
TXT_EXEC_TRACE[es]="=== TRAZA DE EJECUCIÓN DEL LANZADOR %s ===\n"
TXT_WIPING_CTX[es]="🧹 Limpiando contextos temporales por error en ejecución..."
TXT_START_BUILD[es]="📦 --- INICIANDO PIPELINES DE COMPILACIÓN ---"
TXT_ERR_PATHS[es]="❌ Error: Las rutas BACK_DIR o FRONT_DIR no son válidas. Verifique el .env."
TXT_BUILD_BACKEND[es]="☕ Compilando artefactos del Backend (Spring Boot / Maven)..."
TXT_ERR_BACKEND[es]="❌ Error: Falló la compilación del Backend. Revise %s\n"
TXT_BUILD_FRONTEND[es]="📦 Compilando assets estáticos del Frontend (pnpm Engine)..."
TXT_ERR_FRONTEND[es]="❌ Error: Falló la compilación del Frontend. Revise %s\n"
TXT_SSH_EMPTY[es]="🔒 El agente SSH está vacío. Ingrese la passphrase:"
TXT_SSH_DETECTED[es]="✅ Clave SSH detectada en el agente."
TXT_DEPLOY_MENU_TITLE[es]="--- MOTOR DE DESPLIEGUE FULLSTACK ---"
TXT_DEPLOY_MENU_LOC[es]="1) Desplegar Infraestructura LOCAL"
TXT_DEPLOY_MENU_REM[es]="2) Desplegar Infraestructura REMOTA (Destino SSH)"
TXT_DEPLOY_MENU_PROMPT[es]="Seleccione el pipeline de destino [1-2]: "
TXT_TRIGGER_LOCAL[es]="🏠 Iniciando la inicialización de contenedores LOCALES..."
TXT_LOCAL_SUCCESS[es]="✅ DESPLIEGUE LOCAL EXITOSO"
TXT_ERR_LOCAL[es]="❌ Error: La orquestación local ha fallado. Detalles en %s\n"
TXT_ERR_SEC_TITLE[es]="❌ ERROR DE SEGURIDAD CRÍTICO:"
TXT_ERR_SEC_REQ[es]="   El despliegue remoto requiere que BACK_PROFILE sea exactamente 'prod'."
TXT_ERR_SEC_CURR[es]="   Perfil actual detectado en .env: '%s'\n"
TXT_ERR_SEC_ABORT[es]="   Cancelando la operación para evitar corrupción de entorno."
TXT_PREPARE_REMOTE[es]="🌐 Preparando entorno remoto y enviando construcciones..."
TXT_ERR_REMOTE_DIR[es]="❌ Error: No se pudo preparar el directorio remoto en el servidor."
TXT_ERR_SCP[es]="❌ Error: Falló la transferencia de archivos (scp)."
TXT_SWITCH_REMOTE[es]="🚀 Ejecutando la orquestación de contenedores en el servidor remoto..."
TXT_REMOTE_SUCCESS[es]="✅ DESPLIEGUE REMOTO EXITOSO"
TXT_ERR_REMOTE[es]="❌ Error: La orquestación remota falló. Revise los detalles al final de %s\n"
TXT_INVALID_OPTION[es]="Opción de menú inválida. Abortando secuencia del motor."

# --- English (en) ---
TXT_EXEC_TRACE[en]="=== LAUNCHER EXECUTION TRACE %s ===\n"
TXT_WIPING_CTX[en]="🧹 Wiping temporary build contexts due to failure..."
TXT_START_BUILD[en]="📦 --- STARTING APPLICATION BUILD PIPELINES ---"
TXT_ERR_PATHS[en]="❌ Error: BACK_DIR or FRONT_DIR path is invalid. Check your .env file."
TXT_BUILD_BACKEND[en]="☕ Compiling Backend Artifacts (Spring Boot / Maven)..."
TXT_ERR_BACKEND[en]="❌ Error: Backend compilation failed. Check %s\n"
TXT_BUILD_FRONTEND[en]="📦 Compiling Frontend Static Assets (pnpm Engine)..."
TXT_ERR_FRONTEND[en]="❌ Error: Frontend compilation failed. Check %s\n"
TXT_SSH_EMPTY[en]="🔒 SSH agent is empty. Please enter your passphrase:"
TXT_SSH_DETECTED[en]="✅ SSH key detected in the agent."
TXT_DEPLOY_MENU_TITLE[en]="--- FULLSTACK DEPLOY ENGINE ---"
TXT_DEPLOY_MENU_LOC[en]="1) Deploy LOCAL Infrastructure"
TXT_DEPLOY_MENU_REM[en]="2) Deploy REMOTE Infrastructure (SSH Target)"
TXT_DEPLOY_MENU_PROMPT[en]="Select target pipeline destination [1-2]: "
TXT_TRIGGER_LOCAL[en]="🏠 Triggering LOCAL container initialization..."
TXT_LOCAL_SUCCESS[en]="✅ LOCAL DEPLOYMENT SUCCESSFUL"
TXT_ERR_LOCAL[en]="❌ Error: Local orchestration failed. See %s\n"
TXT_ERR_SEC_TITLE[en]="❌ CRITICAL SECURITY ERROR:"
TXT_ERR_SEC_REQ[en]="   Remote deployment requires BACK_PROFILE to be exactly 'prod'."
TXT_ERR_SEC_CURR[en]="   Current profile detected in .env: '%s'\n"
TXT_ERR_SEC_ABORT[en]="   Aborting operation to prevent environment mismatch."
TXT_PREPARE_REMOTE[en]="🌐 Preparing remote host environment and shipping builds..."
TXT_ERR_REMOTE_DIR[en]="❌ Error: Failed to initialize target directory space on remote server."
TXT_ERR_SCP[en]="❌ Error: File payload delivery failed (scp)."
TXT_SWITCH_REMOTE[en]="🚀 Executing container orchestration on remote server..."
TXT_REMOTE_SUCCESS[en]="✅ REMOTE DEPLOYMENT SUCCESSFUL"
TXT_ERR_REMOTE[en]="❌ Error: Deployment sequence failed on remote engine host. Check tail logs in %s\n"
TXT_INVALID_OPTION[en]="Invalid menu alternative. Aborting engine sequence."

LOG_FILE="./launcher.log"
printf "${TXT_EXEC_TRACE[$SYSTEM_LANG]}" "$(date)" >> "$LOG_FILE"

# ==============================================================================
# 2. MOTOR ARCHITECTURE UTILITIES & HOOKS
# ==============================================================================
do_clear() {
    echo "${TXT_WIPING_CTX[$SYSTEM_LANG]}"
    rm -rf ./backend-build ./frontend-build ./secrets > /dev/null 2>&1
}

do_compile() {
    echo "${TXT_START_BUILD[$SYSTEM_LANG]}"

    if [ ! -d "$BACK_DIR" ] || [ ! -d "$FRONT_DIR" ]; then
        echo "${TXT_ERR_PATHS[$SYSTEM_LANG]}"
        exit 1
    fi

    echo "${TXT_BUILD_BACKEND[$SYSTEM_LANG]}"
    
    "$BACK_DIR/mvnw" -f "$BACK_DIR/pom.xml" clean package -DskipTests >> "$LOG_FILE" 2>&1
    MVN_EXIT=$?
    
    if [ $MVN_EXIT -ne 0 ]; then
        printf "${TXT_ERR_BACKEND[$SYSTEM_LANG]}" "$LOG_FILE"
        exit 1
    fi
    
    mkdir -p ./backend-build
    cp "$BACK_DIR/target/app.jar" ./backend-build/app.jar >> "$LOG_FILE" 2>&1
    [[ -f "$BACK_DIR/Dockerfile" ]] && cp "$BACK_DIR/Dockerfile" ./backend-build/

    echo "${TXT_BUILD_FRONTEND[$SYSTEM_LANG]}"
    
    pnpm -C "$FRONT_DIR" build >> "$LOG_FILE" 2>&1
    PNPM_EXIT=$?
    
    if [ $PNPM_EXIT -ne 0 ]; then
        printf "${TXT_ERR_FRONTEND[$SYSTEM_LANG]}" "$LOG_FILE"
        exit 1
    fi
        
    mkdir -p ./frontend-build
    cp -r "$FRONT_DIR/dist" ./frontend-build/dist >> "$LOG_FILE" 2>&1
    cp -r ./nginx/* ./frontend-build/ >> "$LOG_FILE" 2>&1
}

do_check_ssh_agent(){
    local KEY_PATH="$HOME/.ssh/id_ed25519_project_deployer"

    if ! ssh-add -l > /dev/null 2>&1; then
        echo "${TXT_SSH_EMPTY[$SYSTEM_LANG]}"
        ssh-add "$KEY_PATH" || exit 1
    else
        echo "${TXT_SSH_DETECTED[$SYSTEM_LANG]}"
    fi
}

do_inject_secrets() {
    # Save current system umask, set strict umask (user read/write only)
    OLD_UMASK=$(umask)
    umask 077

    # Safely create the directory with 700 permissions
    mkdir -p "./secrets"

    # Generate raw secret files (created with 600 permissions)
    echo "$DB_NAME" > "./secrets/db_name.txt"
    echo "$DB_USER" > "./secrets/db_user.txt"
    echo "$DB_PASSWORD" > "./secrets/db_password.txt"

    # Generate Spring Boot configuration properties
    echo "spring.datasource.url=jdbc:postgresql://db-service:5432/\${FILE:/run/secrets/db_name}" > "./secrets/spring_secrets.properties"
    echo "spring.datasource.username=\${FILE:/run/secrets/db_user}" >> "./secrets/spring_secrets.properties"
    echo "spring.datasource.password=\${FILE:/run/secrets/db_password}" >> "./secrets/spring_secrets.properties"

    # Restore the original system umask
    umask "$OLD_UMASK"
}

# ==============================================================================
# 3. INTERACTIVE ORCHESTRATION INTERFACE
# ==============================================================================
echo "${TXT_DEPLOY_MENU_TITLE[$SYSTEM_LANG]}"
echo "${TXT_DEPLOY_MENU_LOC[$SYSTEM_LANG]}"
echo "${TXT_DEPLOY_MENU_REM[$SYSTEM_LANG]}"
read -p "${TXT_DEPLOY_MENU_PROMPT[$SYSTEM_LANG]}" OPC

case $OPC in
    1)
        do_clear
        do_compile
        echo "${TXT_TRIGGER_LOCAL[$SYSTEM_LANG]}"
        do_inject_secrets  # <-- This securely creates everything at 700/600 automatically
        
        docker compose up -d --build --force-recreate --remove-orphans >> "$LOG_FILE" 2>&1

        if [ $? -eq 0 ]; then
            echo "${TXT_LOCAL_SUCCESS[$SYSTEM_LANG]}"
            exit 0
        else
            printf "${TXT_ERR_LOCAL[$SYSTEM_LANG]}" "$LOG_FILE"
            exit 1
        fi
        ;;
    2)
        if [ "$BACK_PROFILE" != "prod" ]; then
            echo "${TXT_ERR_SEC_TITLE[$SYSTEM_LANG]}"
            echo "${TXT_ERR_SEC_REQ[$SYSTEM_LANG]}"
            printf "${TXT_ERR_SEC_CURR[$SYSTEM_LANG]}" "$BACK_PROFILE"
            echo "${TXT_ERR_SEC_ABORT[$SYSTEM_LANG]}"
            exit 1
        fi
        do_clear
        do_compile
        do_check_ssh_agent
        do_inject_secrets

        echo "${TXT_PREPARE_REMOTE[$SYSTEM_LANG]}"

        if ! ssh -q project-server "mkdir -p /home/deployer/project-infra && rm -rf /home/deployer/project-infra/secrets /home/deployer/project-infra/backend-build /home/deployer/project-infra/frontend-build"; then
            echo "${TXT_ERR_REMOTE_DIR[$SYSTEM_LANG]}"
            exit 1
        fi

        # Transferencia encomillando el destino para evitar problemas de interpretación de rutas
        scp -q -r ./backend-build ./frontend-build ./docker-compose.yml ./nginx ./monitor_stack.sh ./monitor_stack.properties ./secrets project-server:"/home/deployer/project-infra/"
        if [ $? -ne 0 ]; then
            echo "${TXT_ERR_SCP[$SYSTEM_LANG]}"
            exit 1
        fi
        echo "${TXT_SWITCH_REMOTE[$SYSTEM_LANG]}"
        
        ssh -q -T project-server >> "$LOG_FILE" 2>&1 << 'EOF'
            set -e
            
            BASE_DIR="/home/deployer/project-infra"

            chmod 600 "$BASE_DIR/monitor_stack.properties"
            chmod 700 "$BASE_DIR/secrets" || true
            chmod 600 "$BASE_DIR/secrets"/* || true

            trap 'rm -rf "$BASE_DIR/backend-build" "$BASE_DIR/frontend-build" "$BASE_DIR/secrets"' ERR INT TERM
            
            docker compose -f "$BASE_DIR/docker-compose.yml" up -d --build --force-recreate --remove-orphans

            trap - ERR INT TERM
EOF
        if [ $? -eq 0 ]; then
            echo "${TXT_REMOTE_SUCCESS[$SYSTEM_LANG]}"
            do_clear
            exit 0
        else
            printf "${TXT_ERR_REMOTE[$SYSTEM_LANG]}" "$LOG_FILE"
            exit 1
        fi
        ;;
    *)
        echo "${TXT_INVALID_OPTION[$SYSTEM_LANG]}"
        exit 1
        ;;
esac
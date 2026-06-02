#!/bin/bash

# ==============================================================================
# 0. WORKSPACE ENVIRONMENT INITIALIZATION
# ==============================================================================
mkdir -p "$HOME/project-logs/local" "$HOME/project-logs/remote"

# Static definitions mapped from docker-compose orchestration topology
SERVICES=("backend-service" "frontend-service" "db-service")
REMOTE_HOST="project-server"
SSH_KEY_PATH="$HOME/.ssh/id_ed25519_project_deployer"

# ==============================================================================
# 1. LANGUAGE & INITIALIZATION SETTINGS
# ==============================================================================

declare -rA TXT_TITLE TXT_ENV_PROMPT TXT_ENV_LOC TXT_ENV_REM TXT_TARGET_ENV_LOCAL \
           TXT_TARGET_ENV_REMOTE TXT_INVALID_ENVIROMENT TXT_MODE_PROMPT TXT_MODE_STR \
           TXT_MODE_FILE TXT_INVALID_MODE TXT_SRV_PROMPT TXT_SRV_ALL TXT_TARGET_SERVICE \
           TXT_INVALID_SERVICE TXT_TAIL_PROMPT TXT_SSH_AGENT_EMPTY TXT_SSH_KEY_DETECTED \
           TXT_SSH_ERR TXT_FAILED_REMOTE_CONNECTION TXT_FAILED_LOCAL_SERVICE \
           TXT_FAILED_REMOTE_DUMP_SERVICE TXT_STREAM_START TXT_FAILED_LOCAL_COMPRESS \
           TXT_FAILED_REMOTE_COMPRESS TXT_UNEXPECTED_REMOTE_EXIT_CODE \
           TXT_FAILED_SCP_TRANSFER TXT_FILE_SUCCESS TXT_CLEAN_REMOTE TXT_CONTINUE TXT_EXIT \
           TXT_SSH_CONNECTION_FAILED TXT_FAILED_ADDING_SSH_KEY TXT_LOG_GENERATION_FAILED \
           TXT_REMOTE_CLEAN_FAILURE

# --- Spanish (es) Mappings ---
TXT_TITLE[es]="=== INSPECTOR DE TELEMETRÍA Y LOGS ==="
TXT_ENV_PROMPT[es]="Seleccione el entorno de ejecución:"
TXT_ENV_LOC[es]="1) Infraestructura LOCAL"
TXT_ENV_REM[es]="2) Infraestructura REMOTA (SSH)"
TXT_TARGET_ENV_LOCAL[es]="Entorno Objetivo: LOCAL"
TXT_TARGET_ENV_REMOTE[es]="Entorno Objetivo: REMOTO"
TXT_INVALID_ENVIROMENT[es]="❌ Elección de entorno inválida. Por favor seleccione 1 o 2."
TXT_MODE_PROMPT[es]="Seleccione el modo operativo:"
TXT_MODE_STR[es]="1) Stream en Vivo (Ver en pantalla - Salir con Ctrl+C)"
TXT_MODE_FILE[es]="2) Generar Archivo de Diagnóstico (.tar.gz)"
TXT_INVALID_MODE[es]="❌ Elección de modo inválida. Por favor seleccione 1 o 2."
TXT_SRV_PROMPT[es]="Seleccione el servicio objetivo:"
TXT_SRV_ALL[es]="4) Todos los servicios (Paquete Combinado)"
TXT_TARGET_SERVICE[es]="Servicio Objetivo: "
TXT_INVALID_SERVICE[es]="❌ Elección de servicio inválida. Por favor seleccione una opción válida."
TXT_TAIL_PROMPT[es]="¿Cuántas líneas desea extraer? (Presione Enter para TODO o ingrese un número): "
TXT_SSH_AGENT_EMPTY[es]="🔒 El agente SSH está vacío. Ingrese la passphrase:"
TXT_SSH_KEY_DETECTED[es]="✅ Clave SSH detectada en el agente."
TXT_FAILED_ADDING_SSH_KEY[es]="❌ Error: No se pudo agregar la clave SSH al agente."
TXT_SSH_ERR[es]="❌ Error: La conexión segura SSH no pudo alcanzar ${REMOTE_HOST}."
TXT_FAILED_REMOTE_CONNECTION[es]="❌ Error: La conexión remota inicial de diagnóstico ha fallado."
TXT_FAILED_LOCAL_SERVICE[es]="❌ Error: No se pudo acceder a los logs del servicio local "
TXT_SSH_CONNECTION_FAILED[es]="❌ Error: La conexión segura SSH ha fallado o no se puede alcanzar el servicio remoto"
TXT_FAILED_REMOTE_DUMP_SERVICE[es]="❌ Error: El entorno remoto no pudo volcar los logs para el servicio: "
TXT_STREAM_START[es]="⚡ Iniciando stream. Presione Ctrl+C para regresar al menú de servicios..."
TXT_LOG_GENERATION_FAILED[es]="❌ Error: No se generaron archivos de log para el/los servicio(s) seleccionado(s)."
TXT_FAILED_LOCAL_COMPRESS[es]="❌ Error: No se pudo compilar el archivo tarball de diagnóstico local."
TXT_FAILED_REMOTE_COMPRESS[es]="❌ Error: No se pudo compilar el archivo tarball de diagnóstico remoto."
TXT_UNEXPECTED_REMOTE_EXIT_CODE[es]="❌ Error: La ejecución remota terminó con un código de salida inesperado"
TXT_FAILED_SCP_TRANSFER[es]="❌ Error: La transferencia segura de archivos (SCP) falló o no pudo entregar el paquete objetivo."
TXT_FILE_SUCCESS[es]="✅ Archivo guardado con éxito en:"
TXT_CLEAN_REMOTE[es]="🧹 Limpiando activos temporales en el host remoto..."
TXT_REMOTE_CLEAN_FAILURE[es]="⚠️ Advertencia: La limpieza remota puede haber fallado. Por favor, verifique el host remoto en busca de archivos residuales."
TXT_CONTINUE[es]="Presione [Enter] para continuar..."
TXT_EXIT[es]="Salir / Volver"

# --- English (en) Mappings ---
TXT_TITLE[en]="=== TELEMETRY & LOG INSPECTION UTILITY ==="
TXT_ENV_PROMPT[en]="Select execution target environment:"
TXT_ENV_LOC[en]="1) LOCAL Infrastructure"
TXT_ENV_REM[en]="2) REMOTE Infrastructure (SSH Target)"
TXT_TARGET_ENV_LOCAL[en]="Target Environment: LOCAL"
TXT_TARGET_ENV_REMOTE[en]="Target Environment: REMOTE"
TXT_INVALID_ENVIROMENT[en]="❌ Invalid environment choice. Please select 1 or 2."
TXT_MODE_PROMPT[en]="Select operational mode:"
TXT_MODE_STR[en]="1) Stream Live Logs (On-Screen View - Exit with Ctrl+C)"
TXT_MODE_FILE[en]="2) Generate Diagnostic File (.tar.gz Package)"
TXT_INVALID_MODE[en]="❌ Invalid mode choice. Please select 1 or 2."
TXT_SRV_PROMPT[en]="Select target core service:"
TXT_SRV_ALL[en]="4) All Services (Combined Archive Package)"
TXT_TARGET_SERVICE[en]="Target Service: "
TXT_INVALID_SERVICE[en]="❌ Invalid service choice. Please select a valid option."
TXT_TAIL_PROMPT[en]="How many lines to tail? (Press Enter for ALL or input a number): "
TXT_SSH_AGENT_EMPTY[en]="🔒 SSH agent is empty. Please enter your passphrase:"
TXT_SSH_KEY_DETECTED[en]="✅ SSH key detected in the agent."
TXT_FAILED_ADDING_SSH_KEY[en]="❌ Error: Failed to add SSH key to the agent."
TXT_SSH_ERR[en]="❌ Error: Secure SSH transport layer connection failed to reach ${REMOTE_HOST}."
TXT_FAILED_REMOTE_CONNECTION[en]="❌ Error: Initial diagnostic connection to remote host failed."
TXT_FAILED_LOCAL_SERVICE[en]="❌ Error: Failed to access logs for local service "
TXT_SSH_CONNECTION_FAILED[en]="❌ Error: Secure SSH connection failed or cannot reach remote service"
TXT_FAILED_REMOTE_DUMP_SERVICE[en]="❌ Error: Remote environment failed to dump logs for service: "
TXT_STREAM_START[en]="⚡ Initializing stream. Press Ctrl+C to step back into the service menu..."
TXT_LOG_GENERATION_FAILED[en]="❌ Error: No log files were generated for the selected service(s)."
TXT_FAILED_LOCAL_COMPRESS[en]="❌ Error: Failed to compile local diagnostic package archive."
TXT_FAILED_REMOTE_COMPRESS[en]="❌ Error: Failed to compile remote diagnostic log tarball package."
TXT_UNEXPECTED_REMOTE_EXIT_CODE[en]="❌ Error: Remote execution terminated with unexpected exit code"
TXT_FAILED_SCP_TRANSFER[en]="❌ Error: Secure file transfer (SCP) dropped or failed to deliver target package."
TXT_FILE_SUCCESS[en]="✅ Forensic package successfully deposited to:"
TXT_CLEAN_REMOTE[en]="🧹 Cleaning up temporary assets on remote host..."
TXT_REMOTE_CLEAN_FAILURE[en]="⚠️ Warning: Remote cleanup may have failed. Please check the remote host for residual files."
TXT_CONTINUE[en]="Press [Enter] to continue..."
TXT_EXIT[en]="Exit / Go Back"

# Language prompt selection
clear
echo "Choose Language / Seleccione el Idioma:"
echo "1) English (en)"
echo "2) Español (es)"
read -p "[1-2]: " LANG_OPT

if [ "$LANG_OPT" = "1" ]; then
    RUN_LANG="en"
elif [ "$LANG_OPT" = "2" ]; then
    RUN_LANG="es"
else
    echo "❌ Invalid choice / Selección inválida. Exiting..."
    exit 1
fi

# ==============================================================================
# 2. CORE HELPER MECHANICS
# ==============================================================================
do_check_ssh_agent(){
    if ! ssh-add -l > /dev/null 2>&1; then
        echo "${TXT_SSH_AGENT_EMPTY[$RUN_LANG]}"
        ssh-add "$SSH_KEY_PATH" || { echo "${TXT_FAILED_ADDING_SSH_KEY[$RUN_LANG]}"; return 1; }
    else
        echo "${TXT_SSH_KEY_DETECTED[$RUN_LANG]}"
        return 0
    fi
}

get_timestamp() {
    date +"%Y%m%d_%H%M%S"
}

# ==============================================================================
# 3. ENVIRONMENT TARGET CHOICE (OUTER LOOP)
# ==============================================================================
while true; do
    clear
    echo "${TXT_TITLE[$RUN_LANG]}"
    echo "----------------------------------------"
    echo "${TXT_ENV_PROMPT[$RUN_LANG]}"
    echo "${TXT_ENV_LOC[$RUN_LANG]}"
    echo "${TXT_ENV_REM[$RUN_LANG]}"
    echo "q) ${TXT_EXIT[$RUN_LANG]}"
    read -p "[1-2-q]: " ENV_CHOICE

    if [ "$ENV_CHOICE" = "q" ] || [ -z "$ENV_CHOICE" ]; then
        break
    fi

    if [ "$ENV_CHOICE" = "2" ]; then
        TARGET_ENV="remote"
        TXT_TARGET_ENV="${TXT_TARGET_ENV_REMOTE[$RUN_LANG]}"
        if ! do_check_ssh_agent; then
            echo -n "${TXT_CONTINUE[$RUN_LANG]}"
            read -p ""
            continue 
        fi
    elif [ "$ENV_CHOICE" = "1" ]; then
        TARGET_ENV="local"
        TXT_TARGET_ENV="${TXT_TARGET_ENV_LOCAL[$RUN_LANG]}"  
    else
        echo "${TXT_INVALID_ENVIROMENT[$RUN_LANG]}"
        echo -n "${TXT_CONTINUE[$RUN_LANG]}"
        read -p ""
        continue 
    fi

    # ==========================================================================
    # 4. OPERATIONAL MODE CHOICE (MID LOOP)
    # ==========================================================================
    while true; do
        clear
        echo "${TXT_TITLE[$RUN_LANG]}"
        echo "$TXT_TARGET_ENV"
        echo "----------------------------------------"
        echo "${TXT_MODE_PROMPT[$RUN_LANG]}"
        echo "${TXT_MODE_STR[$RUN_LANG]}"
        echo "${TXT_MODE_FILE[$RUN_LANG]}"
        echo "q) ${TXT_EXIT[$RUN_LANG]} (Environment Menu)"
        read -p "[1-2-q]: " OP_MODE
        
        if [ "$OP_MODE" = "q" ] || [ -z "$OP_MODE" ]; then
            break 
        fi
        if [ "$OP_MODE" != "1" ] && [ "$OP_MODE" != "2" ]; then
            echo "${TXT_INVALID_MODE[$RUN_LANG]}"
            echo -n "${TXT_CONTINUE[$RUN_LANG]}"
            read -p ""
            continue
        fi
        
        # ======================================================================
        # 5. SERVICE SELECT & RUN ACTION WORKFLOW (INNER LOOP)
        # ======================================================================
        while true; do
            clear
            echo "${TXT_TITLE[$RUN_LANG]}"
            echo "$TXT_TARGET_ENV"
            echo "----------------------------------------"
            echo "${TXT_SRV_PROMPT[$RUN_LANG]}"
            echo "1) ${SERVICES[0]}"
            echo "2) ${SERVICES[1]}"
            echo "3) ${SERVICES[2]}"
            
            if [ "$OP_MODE" = "2" ]; then
                echo "${TXT_SRV_ALL[$RUN_LANG]}"
                echo "q) ${TXT_EXIT[$RUN_LANG]} (Mode Menu)"
                read -p "[1-2-3-4-q]: " SRV_OPT
            else
                echo "q) ${TXT_EXIT[$RUN_LANG]} (Mode Menu)"
                read -p "[1-2-3-q]: " SRV_OPT
            fi

            if [ "$SRV_OPT" = "q" ] || [ -z "$SRV_OPT" ]; then
                break
            fi
            
            if [ "$SRV_OPT" = "4" ] && [ "$OP_MODE" = "2" ]; then
                TARGET_SERVICE="all"
            elif [[ "$SRV_OPT" =~ ^[1-3]$ ]]; then
                TARGET_SERVICE="${SERVICES[$((SRV_OPT - 1))]}"
            else
                echo "${TXT_INVALID_SERVICE[$RUN_LANG]}"
                echo -n "${TXT_CONTINUE[$RUN_LANG]}"
                read -p ""
                continue 
            fi

            # ------------------------------------------------------------------
            # MODE 1: STREAM LIVE LOG VIEWING ACTION
            # ------------------------------------------------------------------
            if [ "$OP_MODE" = "1" ]; then
                clear
                echo "${TXT_STREAM_START[$RUN_LANG]}"
                echo "--> ${TXT_TARGET_SERVICE[$RUN_LANG]} $TARGET_SERVICE"
                echo "------------------------------------------------------------------------"
                
                # --- LOCAL STREAMING ---
                if [ "$TARGET_ENV" = "local" ]; then
                    if ! (
                        docker logs -f "$TARGET_SERVICE" 2>/dev/null
                    ); then
                        echo "❌ Error: Cannot reach service '$TARGET_SERVICE' or Docker daemon is down."
                        echo -n "${TXT_CONTINUE[$RUN_LANG]}"
                        read -p ""
                        continue 
                    fi

                # --- REMOTE STREAMING ---
                else
                    if ! ssh -T "$REMOTE_HOST" "true" >/dev/null 2>&1; then
                        echo "${TXT_SSH_ERR[$RUN_LANG]}"
                        echo -n "${TXT_CONTINUE[$RUN_LANG]}"
                        read -p ""
                        continue
                    fi
                    ssh -t "$REMOTE_HOST" bash -s -- "$TARGET_SERVICE" << 'EOF'
                        TARGET="$1"
                        docker logs -f "$TARGET"
EOF
                    SSH_EXIT_STATUS=$?
                    
                    if [ $SSH_EXIT_STATUS -ne 0 ] && [ $SSH_EXIT_STATUS -ne 130 ]; then
                        echo "${TXT_SSH_CONNECTION_FAILED[$RUN_LANG]} '$TARGET_SERVICE'"
                        echo -n "${TXT_CONTINUE[$RUN_LANG]}"
                        read -p ""
                        continue
                    fi
                fi
                
                echo -n "${TXT_CONTINUE[$RUN_LANG]}"
                read -p ""
            
            # ------------------------------------------------------------------
            # MODE 2: GENERATE FORENSIC TARBALL FILE ACTION
            # ------------------------------------------------------------------
            elif [ "$OP_MODE" = "2" ]; then
                echo -n "${TXT_TAIL_PROMPT[$RUN_LANG]}"
                read -r TAIL_LINES
                
                if [[ "$TAIL_LINES" =~ ^[0-9]+$ ]]; then
                    DOCKER_TAIL=( "--tail" "$TAIL_LINES" )
                else
                    DOCKER_TAIL=()
                fi

                TIMESTAMP=$(get_timestamp)
                
                # ==============================================================
                # --- LOCAL FILE ASSEMBLY ROUTINE ---
                # ==============================================================
                if [ "$TARGET_ENV" = "local" ]; then
                    LOCAL_DIR="$HOME/project-logs/local"
                    TMP_DIR=$(mktemp -d -t project-logs-staging.XXXXXXXXXX)
                    trap 'rm -rf "$TMP_DIR"' EXIT
                    
                    
                    ERR_CODE=0
                    FAILED_SERVICE_NAME=""
                    if [ "$TARGET_SERVICE" = "all" ]; then
                        TAR_NAME="log_all_services_${TIMESTAMP}.tar.gz"
                        for srv in "${SERVICES[@]}"; do
                            if ! docker logs "${DOCKER_TAIL[@]}" "$srv" > "$TMP_DIR/${srv}.log" 2>&1; then
                                ERR_CODE=1
                                FAILED_SERVICE_NAME="$srv"
                                break 
                            fi
                        done
                    else
                        TAR_NAME="log_${TARGET_SERVICE}_${TIMESTAMP}.tar.gz"
                        if ! docker logs "${DOCKER_TAIL[@]}" "$TARGET_SERVICE" > "$TMP_DIR/${TARGET_SERVICE}.log" 2>&1; then
                            ERR_CODE=1
                            FAILED_SERVICE_NAME="$TARGET_SERVICE"
                        fi
                    fi
                    if [ $ERR_CODE -ne 0 ]; then
                        echo "${TXT_FAILED_LOCAL_SERVICE[$RUN_LANG]} '$FAILED_SERVICE_NAME'."
                        rm -rf "$TMP_DIR"
                        
                        echo -n "${TXT_CONTINUE[$RUN_LANG]}"
                        read -p ""
                        continue
                    fi
                    ( shopt -s nullglob && LOG_FILES_LIST=("$TMP_DIR"/*.log) && (( ${#LOG_FILES_LIST[@]} == 0 )) ) && {
                        echo "${TXT_LOG_GENERATION_FAILED[$RUN_LANG]}"
                        rm -rf "$TMP_DIR"
                        
                        echo -n "${TXT_CONTINUE[$RUN_LANG]}"
                        read -p ""
                        continue
                    }
                    if ! (tar -czf "$LOCAL_DIR/$TAR_NAME" -C "$TMP_DIR" .) >/dev/null 2>&1; then
                        echo "${TXT_FAILED_LOCAL_COMPRESS[$RUN_LANG]}"
                        
                        rm -rf "$TMP_DIR"
                        
                        echo -n "${TXT_CONTINUE[$RUN_LANG]}"
                        read -p ""
                        continue
                    fi
                    
                    trap '' EXIT
                    rm -rf "$TMP_DIR"
                    
                    echo ""
                    echo "${TXT_FILE_SUCCESS[$RUN_LANG]} $LOCAL_DIR/$TAR_NAME"
                    echo -n "${TXT_CONTINUE[$RUN_LANG]}"
                    read -p ""

                # ==============================================================
                # --- REMOTE FILE ASSEMBLY ROUTINE (SSH/SCP) ---
                # ==============================================================
                else
                    LOCAL_DIR="$HOME/project-logs/remote"
                    
                    entropy=$(head -c 512 /dev/urandom | LC_ALL=C tr -dc 'a-zA-Z0-9' | head -c 12)
                    if [ "$TARGET_SERVICE" = "all" ]; then
                        TAR_NAME="log_all_services_${TIMESTAMP}_${entropy}.tar.gz"
                        TARGET_LIST="${SERVICES[*]}"
                    else
                        TAR_NAME="log_${TARGET_SERVICE}_${TIMESTAMP}_${entropy}.tar.gz"
                        TARGET_LIST="$TARGET_SERVICE"
                    fi
                    
                    if ! ssh -T "$REMOTE_HOST" "true" >/dev/null 2>&1; then
                        echo "${TXT_FAILED_REMOTE_CONNECTION[$RUN_LANG]}"
                        echo -n "${TXT_CONTINUE[$RUN_LANG]}"
                        read -p ""
                        continue
                    fi
                    TAIL_VAL="${DOCKER_TAIL[1]:-}"
                    FAILED_SERVICE=$(ssh -T "$REMOTE_HOST" bash -s -- "$TAIL_VAL" "$TARGET_LIST" "$TAR_NAME" << 'EOF'
                        
                        REMOTE_TAIL_VAL="$1"
                        REMOTE_TARGET_LIST="$2"
                        REMOTE_TAR_NAME="$3"

                        if [[ -n "$REMOTE_TAIL_VAL" && ! "$REMOTE_TAIL_VAL" =~ ^[0-9]+$ ]]; then
                            exit 3
                        fi

                        STAGING_DIR="/home/deployer/project-logs-staging"
                        mkdir -p "$STAGING_DIR"
                        
                        trap 'rm -rf "$STAGING_DIR"' EXIT INT TERM
                        
                        HAVE_ERRORS=0
                        FAILED_SRV=""
                        read -r -a SRV_ARRAY <<< "$REMOTE_TARGET_LIST"

                        for srv in "${SRV_ARRAY[@]}"; do
                            if [ "$REMOTE_TAIL_VAL" != "" ] ; then 
                                if ! docker logs --tail "$REMOTE_TAIL_VAL" "$srv" > "$STAGING_DIR/${srv}.log" 2>&1; then
                                    HAVE_ERRORS=1
                                    FAILED_SRV="$srv"
                                    break
                                fi
                            else
                                if ! docker logs "$srv" > "$STAGING_DIR/${srv}.log" 2>&1; then
                                    HAVE_ERRORS=1
                                    FAILED_SRV="$srv"
                                    break
                                fi
                            fi
                        done
                        
                        if [ "$HAVE_ERRORS" -eq 1 ]; then
                            echo "$FAILED_SRV"
                            exit 1
                        fi
                        
                        if ! tar -czf "/home/deployer/$REMOTE_TAR_NAME" -C "$STAGING_DIR" . >/dev/null 2>&1; then
                            exit 2
                        fi
EOF
                    )
                    REMOTE_EXIT_CODE=$?

                    if [ $REMOTE_EXIT_CODE -ne 0 ]; then
                        if [ $REMOTE_EXIT_CODE -eq 2 ]; then
                            echo "${TXT_FAILED_REMOTE_COMPRESS[$RUN_LANG]}"
                        elif [ $REMOTE_EXIT_CODE -eq 1 ]; then
                            read -r -a SERVICES_ARR <<< "$TARGET_LIST"
                            echo "${TXT_FAILED_REMOTE_DUMP_SERVICE[$RUN_LANG]} '$FAILED_SERVICE'."
                        else
                            echo "${TXT_UNEXPECTED_REMOTE_EXIT_CODE[$RUN_LANG]} $REMOTE_EXIT_CODE."
                        fi
                        echo -n "${TXT_CONTINUE[$RUN_LANG]}"
                        read -p ""
                        continue
                    fi
                    LOCAL_TAR_NAME="${TAR_NAME//_${entropy}/}"
                    
                    if scp -q "$REMOTE_HOST:/home/deployer/$TAR_NAME" "$HOME/project-logs/remote/$LOCAL_TAR_NAME"; then
                        echo ""
                        echo "${TXT_FILE_SUCCESS[$RUN_LANG]} $HOME/project-logs/remote/$LOCAL_TAR_NAME"
                    else
                        echo "${TXT_FAILED_SCP_TRANSFER[$RUN_LANG]}"
                    fi

                    echo "${TXT_CLEAN_REMOTE[$RUN_LANG]}"
                    # Define your local variable
                    LOCAL_TAR_NAME="your-file-v1.tar.gz"

                    ssh -T "$REMOTE_HOST" bash -s -- "$TAR_NAME" << 'EOF'
                        REMOTE_TAR_NAME="$1"

                        if [ -z "$REMOTE_TAR_NAME" ]; then
                            exit 1
                        fi

                        rm -rf /home/deployer/project-logs-staging
                        rm -f "/home/deployer/$REMOTE_TAR_NAME"
EOF
                    if [ $? -ne 0 ]; then
                        echo 
                    fi
                    echo ""
                    echo -n "${TXT_CONTINUE[$RUN_LANG]}"
                    read -p ""
                fi
            fi
        done
    done
done
#!/bin/bash

# ==============================================================================
# 0. WORKSPACE ENVIRONMENT INITIALIZATION
# ==============================================================================
mkdir -p "$HOME/project-logs/local" "$HOME/project-logs/remote"

# Static definitions mapped from docker-compose orchestration topology
SERVICES=("backend" "frontend" "orchestrator-nginx" "db")
REMOTE_HOST="project-server"
SSH_KEY_PATH="$HOME/.ssh/id_ed25519_project_deployer"

# ==============================================================================
# 1. LANGUAGE & INITIALIZATION SETTINGS
# ==============================================================================
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

# Text Strings Maps
if [ "$RUN_LANG" = "es" ]; then
    TXT_TITLE="=== INSPECTOR DE TELEMETRÍA Y LOGS ==="
    TXT_ENV_PROMPT="Seleccione el entorno de ejecución:"
    TXT_ENV_LOC="1) Infraestructura LOCAL"
    TXT_ENV_REM="2) Infraestructura REMOTA (SSH)"
    TXT_TARGET_ENV_LOCAL="Entorno Objetivo: LOCAL"
    TXT_TARGET_ENV_REMOTE="Entorno Objetivo: REMOTO"
    TXT_INVALID_ENVIROMENT="❌ Elección de entorno inválida. Por favor seleccione 1 o 2."
    TXT_MODE_PROMPT="Seleccione el modo operativo:"
    TXT_MODE_STR="1) Stream en Vivo (Ver en pantalla - Salir con Ctrl+C)"
    TXT_MODE_FILE="2) Generar Archivo de Diagnóstico (.tar.gz)"
    TXT_INVALID_MODE="❌ Elección de modo inválida. Por favor seleccione 1 o 2."
    TXT_SRV_PROMPT="Seleccione el servicio objetivo:"
    TXT_SRV_ALL="5) Todos los servicios (Paquete Combinado)"
    TXT_TARGET_SERVICE="Servicio Objetivo: "
    TXT_INVALID_SERVICE="❌ Elección de servicio inválida. Por favor seleccione una opción válida."
    TXT_TAIL_PROMPT="¿Cuántas líneas desea extraer? (Presione Enter para TODO o ingrese un número): "
    TXT_SSH_AGENT_EMPTY="🔒 El agente SSH está vacío. Ingrese la passphrase:"
    TXT_SSH_KEY_DETECTED="✅ Clave SSH detectada en el agente."
    TXT_SSH_ERR="❌ Error: La conexión segura SSH no pudo alcanzar ${REMOTE_HOST}."
    TXT_FAILED_LOCAL_SERVICES="❌ Error: No se pudo acceder a los logs de los siguientes servicios locales: "
    TXT_FAILED_LOCAL_SERVICE="❌ Error: No se pudo acceder a los logs del servicio local "
    TXT_FAILED_REMOTE_DUMP_SERVICE="❌ Error: El entorno remoto no pudo volcar los logs para el servicio: "
    TXT_STREAM_START="⚡ Iniciando stream. Presione Ctrl+C para regresar al menú de servicios..."
    TXT_FAILED_LOCAL_COMPRESS="❌ Error: No se pudo compilar el archivo tarball de diagnóstico local."
    TXT_FAILED_REMOTE_COMPRESS="❌ Error: No se pudo compilar el archivo tarball de diagnóstico remoto."
    TXT_UNEXPECTED_REMOTE_EXIT_CODE="❌ Error: La ejecución remota terminó con un código de salida inesperado"
    TXT_FAILED_SCP_TRANSFER="❌ Error: La transferencia segura de archivos (SCP) falló o no pudo entregar el paquete objetivo."
    TXT_FILE_SUCCESS="✅ Archivo guardado con éxito en:"
    TXT_CLEAN_REMOTE="🧹 Limpiando activos temporales en el host remoto..."
    TXT_CONTINUE="Presione [Enter] para continuar..."
    TXT_EXIT="Salir / Volver"
else
    TXT_TITLE="=== TELEMETRY & LOG INSPECTION UTILITY ==="
    TXT_ENV_PROMPT="Select execution target environment:"
    TXT_ENV_LOC="1) LOCAL Infrastructure"
    TXT_ENV_REM="2) REMOTE Infrastructure (SSH Target)"
    TXT_TARGET_ENV_LOCAL="Target Environment: LOCAL"
    TXT_TARGET_ENV_REMOTE="Target Environment: REMOTE"
    TXT_INVALID_ENVIROMENT="❌ Invalid environment choice. Please select 1 or 2."
    TXT_MODE_PROMPT="Select operational mode:"
    TXT_MODE_STR="1) Stream Live Logs (On-Screen View - Exit with Ctrl+C)"
    TXT_MODE_FILE="2) Generate Diagnostic File (.tar.gz Package)"
    TXT_INVALID_MODE="❌ Invalid mode choice. Please select 1 or 2."
    TXT_SRV_PROMPT="Select target core service:"
    TXT_SRV_ALL="5) All Services (Combined Archive Package)"
    TXT_TARGET_SERVICE="Target Service: "
    TXT_INVALID_SERVICE="❌ Invalid service choice. Please select a valid option."
    TXT_TAIL_PROMPT="How many lines to tail? (Press Enter for ALL or input a number): "
    TXT_SSH_AGENT_EMPTY="🔒 SSH agent is empty. Please enter your passphrase:"
    TXT_SSH_KEY_DETECTED="✅ SSH key detected in the agent."
    TXT_SSH_ERR="❌ Error: Secure SSH transport layer connection failed to reach ${REMOTE_HOST}."
    TXT_FAILED_LOCAL_SERVICES="❌ Error: Failed to access logs for the following local services: "
    TXT_FAILED_LOCAL_SERVICE="❌ Error: Failed to access logs for local service "
    TXT_FAILED_REMOTE_DUMP_SERVICE="❌ Error: Remote environment failed to dump logs for service: "
    TXT_STREAM_START="⚡ Initializing stream. Press Ctrl+C to step back into the service menu..."
    TXT_FAILED_LOCAL_COMPRESS="❌ Error: Failed to compile local diagnostic package archive."
    TXT_FAILED_REMOTE_COMPRESS="❌ Error: Failed to compile remote diagnostic log tarball package."
    TXT_UNEXPECTED_REMOTE_EXIT_CODE= "❌ Error: Remote execution terminated with unexpected exit code"
    TXT_FAILED_SCP_TRANSFER="❌ Error: Secure file transfer (SCP) dropped or failed to deliver target package."
    TXT_FILE_SUCCESS="✅ Forensic package successfully deposited to:"
    TXT_CLEAN_REMOTE="🧹 Cleaning up temporary assets on remote host..."
    TXT_CONTINUE="Press [Enter] to continue..."
    TXT_EXIT="Exit / Go Back"
fi


# ==============================================================================
# 2. CORE HELPER MECHANICS
# ==============================================================================
do_check_ssh_agent(){
    if ! ssh-add -l > /dev/null 2>&1; then
        echo "$TXT_SSH_AGENT_EMPTY"
        ssh-add "$SSH_KEY_PATH" || exit 1
    else
        echo "$TXT_SSH_KEY_DETECTED"
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
    echo "$TXT_TITLE"
    echo "----------------------------------------"
    echo "$TXT_ENV_PROMPT"
    echo "$TXT_ENV_LOC"
    echo "$TXT_ENV_REM"
    echo "3) $TXT_EXIT"
    read -p "[1-3]: " ENV_CHOICE

    if [ "$ENV_CHOICE" = "3" ] || [ -z "$ENV_CHOICE" ]; then
        break
    fi

    if [ "$ENV_CHOICE" = "2" ]; then
        TARGET_ENV="remote"
        TXT_TARGET_ENV="$TXT_TARGET_ENV_REMOTE"
        do_check_ssh_agent
    elif [ "$ENV_CHOICE" = "1" ]; then
        TARGET_ENV="local"
        TXT_TARGET_ENV="$TXT_TARGET_ENV_LOCAL"  
    else
        echo "$TXT_INVALID_ENVIROMENT"
        read -p "$TXT_CONTINUE"
        continue 
    fi

    # ==========================================================================
    # 4. OPERATIONAL MODE CHOICE (MID LOOP)
    # ==========================================================================
    while true; do
        clear
        echo "$TXT_TITLE"
        echo "$TXT_TARGET_ENV"
        echo "----------------------------------------"
        echo "$TXT_MODE_PROMPT"
        echo "$TXT_MODE_STR"
        echo "$TXT_MODE_FILE"
        echo "3) $TXT_EXIT (Environment Menu)"
        read -p "[1-3]: " OP_MODE
        
        if [ "$OP_MODE" = "3" ] || [ -z "$OP_MODE" ]; then
            break 
        fi
        if [ "$OP_MODE" != "1" ] && [ "$OP_MODE" != "2" ]; then
            echo "$TXT_INVALID_MODE"
            read -p "$TXT_CONTINUE"
            continue
        fi
        
        # ======================================================================
        # 5. SERVICE SELECT & RUN ACTION WORKFLOW (INNER LOOP)
        # ======================================================================
        while true; do
            clear
            echo "$TXT_TITLE"
            echo "$TXT_TARGET_ENV"
            echo "----------------------------------------"
            echo "$TXT_SRV_PROMPT"
            echo "1) ${SERVICES[0]}"
            echo "2) ${SERVICES[1]}"
            echo "3) ${SERVICES[2]}"
            echo "4) ${SERVICES[3]}"
            
            if [ "$OP_MODE" = "2" ]; then
                echo "$TXT_SRV_ALL"
                echo "6) $TXT_EXIT (Mode Menu)"
                read -p "[1-6]: " SRV_OPT
            else
                echo "5) $TXT_EXIT (Mode Menu)"
                read -p "[1-5]: " SRV_OPT
            fi

            if [[ "$OP_MODE" == "2" && "$SRV_OPT" == "6" ]] || [[ "$OP_MODE" == "1" && "$SRV_OPT" == "5" ]] || [ -z "$SRV_OPT" ]; then
                break
            fi
            
            if [ "$SRV_OPT" = "5" ] && [ "$OP_MODE" = "2" ]; then
                TARGET_SERVICE="all"
            elif [ "$SRV_OPT" -ge 1 ] && [ "$SRV_OPT" -le 4 ]; then
                TARGET_SERVICE="${SERVICES[$((SRV_OPT - 1))]}"
            else
                echo "$TXT_INVALID_SERVICE"
                read -p "$TXT_CONTINUE"
                continue 
            fi

            # ------------------------------------------------------------------
            # MODE 1: STREAM LIVE LOG VIEWING ACTION
            # ------------------------------------------------------------------
            if [ "$OP_MODE" = "1" ]; then
                clear
                echo "$TXT_STREAM_START"
                echo "--> $TXT_TARGET_SERVICE $TARGET_SERVICE"
                echo "------------------------------------------------------------------------"
                
                # --- LOCAL STREAMING ---
                if [ "$TARGET_ENV" = "local" ]; then
                    # We run the subshell. If the subshell returns a failure exit code (1)...
                    if ! (
                        trap 'echo ""; exit 0' INT
                        docker logs -f "$TARGET_SERVICE" 2>/dev/null
                    ); then
                        echo "❌ Error: Cannot reach service '$TARGET_SERVICE' or Docker daemon is down."
                        read -p "$TXT_CONTINUE"
                        continue # Drops back to service menu instead of crashing entire utility
                    fi

                # --- REMOTE STREAMING ---
                else

                    # Test foundational SSH Link viability before attempting data run
                    if ! ssh -T "$REMOTE_HOST" "true" >/dev/null 2>&1; then
                        echo "$TXT_SSH_ERR"
                        read -p "$TXT_CONTINUE"
                        continue
                    fi

                    # Temporarily ignore INT in parent so Ctrl+C goes directly to SSH/Remote Docker
                    trap '' INT 

                    # Run SSH. If  remote docker logs fails...
                    if ! ssh -t "$REMOTE_HOST" "docker logs -f $TARGET_SERVICE"; then
                        trap - INT # Restore parent trap immediately on error
                        echo "❌ Error: Secure SSH connection failed or remote service '$TARGET_SERVICE' is unreachable."
                        read -p "$TXT_CONTINUE"
                        continue
                    fi
                    
                    trap - INT # Restore parent trap after successful normal exit
                fi
                
                echo ""
                read -p "$TXT_CONTINUE"
            
            # ------------------------------------------------------------------
            # MODE 2: GENERATE FORENSIC TARBALL FILE ACTION
            # ------------------------------------------------------------------
            elif [ "$OP_MODE" = "2" ]; then
                echo ""
                read -p "$TXT_TAIL_PROMPT" TAIL_LINES
                
                if [[ "$TAIL_LINES" =~ ^[0-9]+$ ]]; then
                    TAIL_ARG="-n $TAIL_LINES"
                else
                    TAIL_ARG=""
                fi
                
                TIMESTAMP=$(get_timestamp)
                
                # ==============================================================
                # --- LOCAL FILE ASSEMBLY ROUTINE ---
                # ==============================================================
                if [ "$TARGET_ENV" = "local" ]; then
                    LOCAL_DIR="$HOME/project-logs/local"
                    TMP_DIR="/tmp/project-logs-staging"
                    mkdir -p "$TMP_DIR"
                    
                    ERR_CODE=0
                    FAILED_SERVICES=()
                    if [ "$TARGET_SERVICE" = "all" ]; then
                        TAR_NAME="log_all_services_${TIMESTAMP}.tar.gz"
                        for srv in "${SERVICES[@]}"; do
                            if ! docker logs $TAIL_ARG "$srv" > "$TMP_DIR/${srv}.log" 2>&1; then
                                ERR_CODE=1
                                FAILED_SERVICES+=("$srv")
                                break
                            fi
                        done
                    else
                        TAR_NAME="log_${TARGET_SERVICE}_${TIMESTAMP}.tar.gz"
                        if ! docker logs $TAIL_ARG "$TARGET_SERVICE" > "$TMP_DIR/${TARGET_SERVICE}.log" 2>&1; then
                            ERR_CODE=2
                        fi
                    fi
                    
                    # Validate log collection stage
                    if [ $ERR_CODE -ne 0 ]; then
                        rm -rf "$TMP_DIR"
                        if [ $ERR_CODE -eq 1 ]; then
                            echo "$TXT_FAILED_LOCAL_SERVICES${FAILED_SERVICES[*]}."
                        else
                            echo "$TXT_FAILED_LOCAL_SERVICE '$TARGET_SERVICE'."
                        fi
                        read -p "$TXT_CONTINUE"
                        continue
                    fi
                    
                    # Compress and validate tarball stage
                    if ! (cd "$TMP_DIR" && tar -czf "$LOCAL_DIR/$TAR_NAME" *.log) >/dev/null 2>&1; then
                        rm -rf "$TMP_DIR"
                        echo "$TXT_FAILED_LOCAL_COMPRESS"
                        read -p "$TXT_CONTINUE"
                        continue
                    fi
                    
                    rm -rf "$TMP_DIR"
                    echo ""
                    echo "$TXT_FILE_SUCCESS $LOCAL_DIR/$TAR_NAME"
                    read -p "$TXT_CONTINUE"

                # ==============================================================
                # --- REMOTE FILE ASSEMBLY ROUTINE (SSH/SCP) ---
                # ==============================================================
                # !!!!! CUIDADO: aca los logs estan en dure y deben  venir de TXT....
                else
                    REMOTE_DIR="~/project-logs-staging"
                    LOCAL_DIR="$HOME/project-logs/remote"
                    
                    # Establish target services context
                    if [ "$TARGET_SERVICE" = "all" ]; then
                        TAR_NAME="log_all_services_${TIMESTAMP}.tar.gz"
                        REMOTE_TARGETS=("${SERVICES[@]}")
                    else
                        TAR_NAME="log_${TARGET_SERVICE}_${TIMESTAMP}.tar.gz"
                        REMOTE_TARGETS=("$TARGET_SERVICE")
                    fi
                    
                    # Test foundational SSH Link viability before attempting data run
                    if ! ssh -T "$REMOTE_HOST" "true" >/dev/null 2>&1; then
                        echo "$TXT_FAILED_REMOTE_CONNECTION"
                        read -p "$TXT_CONTINUE"
                        continue
                    fi
                    
                    ssh -T "$REMOTE_HOST" bash << EOF
                        mkdir -p $REMOTE_DIR
                        
                        EXIT_TRACKER=10
                        for srv in ${REMOTE_TARGETS[@]}; do
                            if ! docker logs $TAIL_ARG "\$srv" > "$REMOTE_DIR/\${srv}.log" 2>&1; then
                                exit \$EXIT_TRACKER
                            fi
                            EXIT_TRACKER=\$((EXIT_TRACKER + 1))
                        done
                        
                        if ! (cd $REMOTE_DIR && tar -czf ~/$TAR_NAME *.log) >/dev/null 2>&1; then
                            exit 99
                        fi
EOF
                    REMOTE_EXIT_CODE=$?
                    
                    # Handle specific failures returned by remote host execution context
                    if [ $REMOTE_EXIT_CODE -ne 0 ]; then
                        if [ $REMOTE_EXIT_CODE -eq 99 ]; then
                            echo "$TXT_FAILED_REMOTE_COMPRESS"
                        elif [ $REMOTE_EXIT_CODE -ge 10 ] && [ $REMOTE_EXIT_CODE -lt 99 ]; then
                            FAILED_INDEX=$((REMOTE_EXIT_CODE - 10))
                            FAILED_SERVICE="${REMOTE_TARGETS[$FAILED_INDEX]}"
                            echo "$TXT_FAILED_REMOTE_DUMP_SERVICE'$FAILED_SERVICE'."
                        else
                            echo "$TXT_UNEXPECTED_REMOTE_EXIT_CODE $REMOTE_EXIT_CODE."
                        fi
                    fi

                    # Secure Copy stage with validation checks (Only runs if remote execution succeeded!)
                    SCP_SUCCESS=1
                    if [ $REMOTE_EXIT_CODE -eq 0 ]; then
                        if ! scp -q "$REMOTE_HOST:~/$TAR_NAME" "$LOCAL_DIR/"; then
                            echo "$TXT_FAILED_SCP_TRANSFER"
                            SCP_SUCCESS=0
                        fi
                    fi

                    # ==========================================================
                    # UNIFIED REMOTE CLEANUP & COMPLETION GUARD
                    # ==========================================================
                    echo "$TXT_CLEAN_REMOTE"
                    ssh -T "$REMOTE_HOST" "rm -rf $REMOTE_DIR ~/$TAR_NAME" >/dev/null 2>&1

                    if [ $REMOTE_EXIT_CODE -eq 0 ] && [ $SCP_SUCCESS -eq 1 ]; then
                        echo ""
                        echo "$TXT_FILE_SUCCESS $LOCAL_DIR/$TAR_NAME"
                    fi
                    
                    # 3. Single Navigation Pause (Both success and failure paths meet here)
                    echo ""
                    read -p "$TXT_CONTINUE"
                    # Naturally loops back to the service menu without needing a manual 'continue'
                fi
            fi
        done
    done
done
#!/bin/bash

# ==============================================================================
# 0. WORKSPACE ENVIRONMENT INITIALIZATION
# ==============================================================================
# Ensure permanent destination structures exist cleanly on the local host machine
mkdir -p "$HOME/project-logs/local" "$HOME/project-logs/remote"

# ==============================================================================
# 1. LANGUAGE & INITIALIZATION SETTINGS
# ==============================================================================
clear
echo "Choose Language / Seleccione el Idioma:"
echo "1) English (en)"
echo "2) Español (es)"
read -p "[1-2]: " LANG_OPT

if [ "$LANG_OPT" = "2" ]; then
    RUN_LANG="es"
else
    RUN_LANG="en"
fi

# Text Strings Maps
if [ "$RUN_LANG" = "es" ]; then
    TXT_TITLE="=== INSPECTOR DE TELEMETRÍA Y LOGS ==="
    TXT_ENV_PROMPT="Seleccione el entorno de ejecución:"
    TXT_ENV_LOC="1) Infraestructura LOCAL"
    TXT_ENV_REM="2) Infraestructura REMOTA (SSH)"
    TXT_TARGET_ENV_LOCAL="Entorno Objetivo: LOCAL"
    TXT_TARGET_ENV_REMOTE="Entorno Objetivo: REMOTO"
    TXT_MODE_PROMPT="Seleccione el modo operativo:"
    TXT_MODE_STR="1) Stream en Vivo (Ver en pantalla - Salir con Ctrl+C)"
    TXT_MODE_FILE="2) Generar Archivo de Diagnóstico (.tar.gz)"
    TXT_SRV_PROMPT="Seleccione el servicio objetivo:"
    TXT_SRV_ALL="5) Todos los servicios (Paquete Combinado)"
    TXT_TARGET_SERVICE="Servicio Objetivo: "
    TXT_TAIL_PROMPT="¿Cuántas líneas desea extraer? (Presione Enter para TODO o ingrese un número): "
    TXT_SSH_AGENT_EMPTY="🔒 El agente SSH está vacío. Ingrese la passphrase:"
    TXT_SSH_KEY_DETECTED="✅ Clave SSH detectada en el agente."
    TXT_SSH_ERR="❌ Error: No se pudo establecer conexión SSH segura con 'project-server'."
    TXT_STREAM_START="⚡ Iniciando stream. Presione Ctrl+C para regresar al menú principal..."
    TXT_FILE_SUCCESS="✅ Archivo guardado con éxito en:"
    TXT_CLEAN_REMOTE="🧹 Limpiando rastros efímeros en el servidor remoto..."
    TXT_CONTINUE="Presione [Enter] para continuar..."
    TXT_EXIT="Salir del Inspector"
else
    TXT_TITLE="=== TELEMETRY & LOG INSPECTION UTILITY ==="
    TXT_ENV_PROMPT="Select execution target environment:"
    TXT_ENV_LOC="1) LOCAL Infrastructure"
    TXT_ENV_REM="2) REMOTE Infrastructure (SSH Target)"
    TXT_TARGET_ENV_LOCAL="Target Environment: LOCAL"
    TXT_TARGET_ENV_REMOTE="Target Environment: REMOTE"
    TXT_MODE_PROMPT="Select operational mode:"
    TXT_MODE_STR="1) Stream Live Logs (On-Screen View - Exit with Ctrl+C)"
    TXT_MODE_FILE="2) Generate Diagnostic File (.tar.gz Package)"
    TXT_SRV_PROMPT="Select target core service:"
    TXT_SRV_ALL="5) All Services (Combined Archive Package)"
    TXT_TARGET_SERVICE="Target Service: "
    TXT_TAIL_PROMPT="How many lines to tail? (Press Enter for ALL or input a number): "
    TXT_SSH_AGENT_EMPTY="🔒 SSH agent is empty. Please enter your passphrase:"
    TXT_SSH_KEY_DETECTED="✅ SSH key detected in the agent."
    TXT_SSH_ERR="❌ Error: Secure SSH connection link to 'project-server' failed."
    TXT_STREAM_START="⚡ Initializing stream. Press Ctrl+C to step back into the main menu..."
    TXT_FILE_SUCCESS="✅ Forensic package successfully deposited to:"
    TXT_CLEAN_REMOTE="🧹 Purging ephemeral tracking footprints from remote host..."
    TXT_CONTINUE="Press [Enter] to continue..."
    TXT_EXIT="Exit Inspector"
fi

# Static definitions mapped from docker-compose orchestration topology
SERVICES=("backend" "frontend" "orchestrator-nginx" "db")
REMOTE_HOST="project-server"
SSH_KEY_PATH="$HOME/.ssh/id_ed25519_project_deployer"

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
# 3. ENVIRONMENT TARGET CHOICE
# ==============================================================================
clear
echo "$TXT_TITLE"
echo "----------------------------------------"
echo "$TXT_ENV_PROMPT"
echo "$TXT_ENV_LOC"
echo "$TXT_ENV_REM"
echo "3) $TXT_EXIT"
read -p "[1-3]: " ENV_CHOICE

if [ "$ENV_CHOICE" = "3" ]; then
        break
fi

if [ "$ENV_CHOICE" = "2" ]; then
    TARGET_ENV="remote"
    TXT_TARGET_ENV="$TXT_TARGET_ENV_REMOTE"
    do_check_ssh_agent
else
    TARGET_ENV="local"
    TXT_TARGET_ENV="$TXT_TARGET_ENV_LOCAL"  
fi

# ==============================================================================
# 4. MAIN INTERACTIVE EXECUTION LOOP
# ==============================================================================
while true; do
    clear
    echo "$TXT_TITLE"
    echo "$TXT_TARGET_ENV"
    echo "----------------------------------------"
    echo "$TXT_MODE_PROMPT"
    echo "$TXT_MODE_STR"
    echo "$TXT_MODE_FILE"
    echo "3) $TXT_EXIT"
    read -p "[1-3]: " OP_MODE
    
    if [ "$OP_MODE" = "3" ]; then
        break
    fi
    if [ "$OP_MODE" != "1" ] && [ "$OP_MODE" != "2" ]; then
        continue
    fi
    
    # Service Selection Sub-menu
    clear
    echo "$TXT_TITLE"
    echo "----------------------------------------"
    echo "$TXT_SRV_PROMPT"
    echo "1) ${SERVICES[0]}"
    echo "2) ${SERVICES[1]}"
    echo "3) ${SERVICES[2]}"
    echo "4) ${SERVICES[3]}"
    if [ "$OP_MODE" = "2" ]; then
        echo "$TXT_SRV_ALL"
        echo "6) $TXT_EXIT"
        read -p "[1-6]: " SRV_OPT
    else
        echo "5) $TXT_EXIT"
        read -p "[1-5]: " SRV_OPT
    fi

    
    if [[ "$OP_MODE" == "2" && "$SRV_OPT" == "6" ]] || [[ "$OP_MODE" == "1" && "$SRV_OPT" == "5" ]]; then
        break
    else
        if [ "$SRV_OPT" = "5" ] && [ "$OP_MODE" = "2" ]; then
            TARGET_SERVICE="all"
        elif [ "$SRV_OPT" -ge 1 ] && [ "$SRV_OPT" -le 4 ]; then
            TARGET_SERVICE="${SERVICES[$((SRV_OPT - 1))]}"
        else
            continue
        fi
    fi

    # --------------------------------------------------------------------------
    # MODE 1: STREAM LIVE LOG VIEWING WORKFLOW
    # --------------------------------------------------------------------------
    if [ "$OP_MODE" = "1" ]; then
        clear
        echo "$TXT_STREAM_START"
        echo "--> $TXT_TARGET_SERVICE $TARGET_SERVICE"
        echo "------------------------------------------------------------------------"
        
        if [ "$TARGET_ENV" = "local" ]; then
            (
                trap 'exit 0' INT
                docker logs -f "$TARGET_SERVICE"
            )
        else
            trap 'trap - INT' INT
            ssh -t "$REMOTE_HOST" "docker logs -f $TARGET_SERVICE"
            trap - INT
        fi
        
        echo ""
        read -p "$TXT_CONTINUE"
        continue
    
    # --------------------------------------------------------------------------
    # MODE 2: GENERATE FORENSIC TARBALL FILE WORKFLOW
    # --------------------------------------------------------------------------
    elif [ "$OP_MODE" = "2" ]; then
        echo ""
        read -p "$TXT_TAIL_PROMPT" TAIL_LINES
        
        if [[ "$TAIL_LINES" =~ ^[0-9]+$ ]]; then
            TAIL_ARG="-n $TAIL_LINES"
        else
            TAIL_ARG=""
        fi
        
        TIMESTAMP=$(get_timestamp)
        
        # --- Local File Assembly ---
        if [ "$TARGET_ENV" = "local" ]; then
            LOCAL_DIR="$HOME/project-logs/local"
            TMP_DIR="/tmp/project-logs-staging"
            mkdir -p "$TMP_DIR"
            
            if [ "$TARGET_SERVICE" = "all" ]; then
                TAR_NAME="log_all_services_${TIMESTAMP}.tar.gz"
                for srv in "${SERVICES[@]}"; do
                    docker logs $TAIL_ARG "$srv" > "$TMP_DIR/${srv}.log" 2>&1
                done
                cd "$TMP_DIR" && tar -czf "$LOCAL_DIR/$TAR_NAME" *.log && cd - > /dev/null
            else
                TAR_NAME="log_${TARGET_SERVICE}_${TIMESTAMP}.tar.gz"
                docker logs $TAIL_ARG "$TARGET_SERVICE" > "$TMP_DIR/${TARGET_SERVICE}.log" 2>&1
                cd "$TMP_DIR" && tar -czf "$LOCAL_DIR/$TAR_NAME" "${TARGET_SERVICE}.log" && cd - > /dev/null
            fi
            
            rm -rf "$TMP_DIR"
            echo ""
            echo "$TXT_FILE_SUCCESS $LOCAL_DIR/$TAR_NAME"
            read -p "$TXT_CONTINUE"
            continue

        # --- Remote File Assembly via SSH/SCP ---
        else
            REMOTE_DIR="~/project-logs-staging"
            LOCAL_DIR="$HOME/project-logs/remote"
            
            if [ "$TARGET_SERVICE" = "all" ]; then
                TAR_NAME="log_all_services_${TIMESTAMP}.tar.gz"
                
                ssh -T "$REMOTE_HOST" << EOF
                    mkdir -p $REMOTE_DIR
                    docker logs $TAIL_ARG backend > $REMOTE_DIR/backend.log 2>&1
                    docker logs $TAIL_ARG frontend > $REMOTE_DIR/frontend.log 2>&1
                    docker logs $TAIL_ARG orchestrator-nginx > $REMOTE_DIR/orchestrator-nginx.log 2>&1
                    docker logs $TAIL_ARG db > $REMOTE_DIR/db.log 2>&1
                    cd $REMOTE_DIR && tar -czf ~/$TAR_NAME *.log
EOF
            else
                TAR_NAME="log_${TARGET_SERVICE}_${TIMESTAMP}.tar.gz"
                ssh -T "$REMOTE_HOST" << EOF
                    mkdir -p $REMOTE_DIR
                    docker logs $TAIL_ARG $TARGET_SERVICE > $REMOTE_DIR/${TARGET_SERVICE}.log 2>&1
                    cd $REMOTE_DIR && tar -czf ~/$TAR_NAME ${TARGET_SERVICE}.log
EOF
            fi
            
            scp -q "$REMOTE_HOST:~/$TAR_NAME" "$LOCAL_DIR/"
            
            echo "$TXT_CLEAN_REMOTE"
            ssh -T "$REMOTE_HOST" "rm -rf $REMOTE_DIR ~/$TAR_NAME"
            
            echo ""
            echo "$TXT_FILE_SUCCESS $LOCAL_DIR/$TAR_NAME"
            read -p "$TXT_CONTINUE"
            continue
        fi
    fi
done
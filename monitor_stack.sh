    #!/bin/bash

    #  Multi-Language Localization Bundles
    declare -rA TXT_HEAD TXT_INVALID_EMAIL TXT_MISSING_PROPERTIES TXT_MISSING_ALERT_LIST TXT_DOCKER_PS_ERROR TXT_SUBJECT TXT_BANNER TXT_DESC TXT_STATUS TXT_UNHEALTHY_CONTAINERS TXT_LOGS TXT_FOOTER TXT_NOMINAL TXT_DISPATCH TXT_SMTP_ERR TXT_MISSING_COMPOSE TXT_TEST_RUN TXT_ALERT_STATUS TXT_SUPPRESSED TXT_RECOVERED

    # English localization profiles
    TXT_HEAD[en]="🏁 Starting Services Health Monitoring"
    TXT_INVALID_EMAIL[en]="CRITICAL ERROR: Invalid email address detected"
    TXT_MISSING_PROPERTIES[en]="CRITICAL ERROR: Configuration file missing"
    TXT_MISSING_ALERT_LIST[en]="CRITICAL ERROR: Alert email list not configured"
    TXT_DOCKER_PS_ERROR[en]="CRITICAL ERROR: Failed to execute 'docker compose ps' command"
    TXT_SUBJECT[en]="🚨 CRITICAL: Infrastructure Node Unhealthy"
    TXT_BANNER[en]="   ALERT: DETECTED UNHEALTHY SERVICE NODE WITHIN DEPLOYMENT STACK    "
    TXT_DESC[en]="The monitoring subsystem triggered an infrastructure alert vector.\nOne or more containers failed their native healthcheck thresholds."
    TXT_STATUS[en]="--- CURRENT STACK STATUS ---"
    TXT_UNHEALTHY_CONTAINERS[en]="Unhealthy containers detected:"
    TXT_LOGS[en]="--- LAST 200 LINES OF SYS LOG DIAGNOSTICS ---"
    TXT_FOOTER[en]="Automated payload generation complete. Please check the remote host."
    TXT_NOMINAL[en]="Infrastructure status nominal. All healthchecks verified."
    TXT_DISPATCH[en]="Alerts dispatched to active list for:"
    TXT_SMTP_ERR[en]="CRITICAL ERROR: msmtp pipeline failed with exit status:"
    TXT_MISSING_COMPOSE[en]="ERROR: Target file 'docker-compose.yml' not found in the script directory."
    TXT_TEST_RUN[en]="[Manual Script Integration Test Run]"
    TXT_ALERT_STATUS[en]="ALARM TRIGGERED"
    TXT_SUPPRESSED[en]="ALERT SUPPRESSED: System is still down. Lock file active to prevent email flooding."
    TXT_RECOVERED[en]="💚 SYSTEM RECOVERY DETECTED: Disassembling alert suppression lock file."

    # Spanish localization profiles
    TXT_HEAD[es]="🏁 Iniciando Monitoreo de Salud de Servicios"
    TXT_INVALID_EMAIL[es]="ERROR CRÍTICO: Dirección de correo electrónico inválida detectada"
    TXT_MISSING_PROPERTIES[es]="Error crítico: Archivo de configuración no encontrado"
    TXT_MISSING_ALERT_LIST[es]="Error crítico: La lista de correos de alerta no está configurada"
    TXT_DOCKER_PS_ERROR[es]="Error crítico: Fallo al ejecutar el comando 'docker compose ps'"
    TXT_SUBJECT[es]="🚨 CRÍTICO: Nodo de Infraestructura Inestable"
    TXT_BANNER[es]="   ALERTA: SE DETECTÓ UN NODO INESTABLE EN EL STACK DE DESPLIEGUE    "
    TXT_DESC[es]="El subsistema de monitoreo activó un vector de alerta.\nUno o más contenedores fallaron sus umbrales nativos de healthcheck."
    TXT_STATUS[es]="--- ESTADO ACTUAL DEL STACK ---"
    TXT_UNHEALTHY_CONTAINERS[es]="Contenedores inestables detectados:"
    TXT_LOGS[es]="--- ÚLTIMAS 200 LÍNEAS DE DIAGNÓSTICO DE LOGS ---"
    TXT_FOOTER[es]="Generación de reporte automatizado completa. Por favor, revise el servidor."
    TXT_NOMINAL[es]="Estado de infraestructura nominal. Todos los healthchecks verificados."
    TXT_DISPATCH[es]="Alertas despachadas a la lista activa para:"
    TXT_SMTP_ERR[es]="ERROR CRÍTICO: El pipeline de msmtp falló con estatus de salida:"
    TXT_MISSING_COMPOSE[es]="ERROR: El archivo objetivo 'docker-compose.yml' no se encuentra en el directorio del script."
    TXT_TEST_RUN[es]="[Prueba de Integración Manual del Script]"
    TXT_ALERT_STATUS[es]="ALARMA ACTIVADA"
    TXT_SUPPRESSED[es]="ALERTA SUPRIMIDA: El sistema sigue caído. Archivo de bloqueo activo para evitar inundación de correos."
    TXT_RECOVERED[es]="💚 RECUPERACIÓN DEL SISTEMA DETECTADA: Desarmando archivo de bloqueo de alerta."

    # =====================================================================
    # MONITOR STACK SUB-ENGINE
    # =====================================================================
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

    #  Configuration Defaults & File Realignment
    PROPERTIES_FILE="monitor_stack.properties"
    COMPOSE_FILE="docker-compose.yml"
    LOG_FILE="$SCRIPT_DIR/monitor_stack.log"
    LOCK_FILE="$SCRIPT_DIR/.alert_active"
    SYSTEM_LANG="en" # Default fallback language profile
    TESTING=0



    # Robust Multi-Argument Parser Loop
    while [ "$#" -gt 0 ]; do
        case "$1" in
            --test)
                TESTING=1
                shift
                ;;
            --lang=es)
                SYSTEM_LANG="es"
                shift
                ;;
            --lang=en)
                SYSTEM_LANG="en"
                shift
                ;;
            *)
                shift
                ;;
        esac
    done


    # Initialize Session Header in Log File
    echo -e "\n=========================================================" >> "$LOG_FILE"
    echo " ${TXT_HEAD[$SYSTEM_LANG]} [$(date '+%Y-%m-%d %H:%M:%S')]" >> "$LOG_FILE"
    echo "=========================================================" >> "$LOG_FILE"

    RECIPIENTS=()
    # Load Properties Subsystem Dynamically
    if [ -f "$SCRIPT_DIR/$PROPERTIES_FILE" ]; then
        ALERT_MAILS_LIST=$(grep -v '^[[:space:]]*#' "$SCRIPT_DIR/$PROPERTIES_FILE" | grep '^[[:space:]]*ALERT_MAILS_LIST=' | cut -d'=' -f2- | tr -d '"' | tr -d "'")
        
        ALERT_MAILS_LIST="${ALERT_MAILS_LIST//[^a-zA-Z0-9@., _+-]/}"

        ALERT_MAILS_LIST="${ALERT_MAILS_LIST//,/ }"

        ALERT_MAILS_LIST=$(echo "$ALERT_MAILS_LIST" | tr -s ' ')
        validate_email_syntax() {
            python3 -c "
        import sys
        from email.message import EmailMessage
        from email.errors import HeaderParseError
        msg = EmailMessage()
        try:
            msg['To'] = sys.argv[1]
            if msg['To'].addresses[0].username == '' or len(msg.defects) > 0:
                sys.exit(1)
            if '.' not in msg['To'].addresses[0].domain:
                sys.exit(1)
        except (IndexError, HeaderParseError, AttributeError):
            sys.exit(1)
        " "$1" 2>/dev/null
        }
        read -r -a RECIPIENTS <<< "$ALERT_MAILS_LIST"
        for email in "${RECIPIENTS[@]}"; do
            if ! validate_email_syntax "$email"; then
                echo "[$(date '+%Y-%m-%d %H:%M:%S')] ${TXT_INVALID_EMAIL[$SYSTEM_LANG]}: $email" >> "$LOG_FILE"
                echo "---------------------------------------------------------" >> "$LOG_FILE"
                exit 1
            fi
        done

    else
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] ${TXT_MISSING_PROPERTIES[$SYSTEM_LANG]}" >> "$LOG_FILE"
        echo "---------------------------------------------------------" >> "$LOG_FILE"
        exit 1
    fi

    if [ -z "$ALERT_MAILS_LIST" ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] ${TXT_MISSING_ALERT_LIST[$SYSTEM_LANG]}" >> "$LOG_FILE"
        echo "---------------------------------------------------------" >> "$LOG_FILE"
        exit 1
    fi

    # Compose Presence Verification
    if [ ! -f "$SCRIPT_DIR/$COMPOSE_FILE" ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] ${TXT_MISSING_COMPOSE[$SYSTEM_LANG]}" >> "$LOG_FILE"
        echo "---------------------------------------------------------" >> "$LOG_FILE"
        exit 1
    fi

    # Extract Topology Data Streams (Queries the system EXACTLY once)
    if ! RAW_PS_OUTPUT=$(docker compose -f "$SCRIPT_DIR/$COMPOSE_FILE" ps --format json 2>> "$LOG_FILE"); then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] ${TXT_DOCKER_PS_ERROR[$SYSTEM_LANG]}" >> "$LOG_FILE"
        echo "---------------------------------------------------------" >> "$LOG_FILE"
        exit 1
    fi
    # !!!!! CAMBIAR PARA QUE ANDE CON UN JSON ARRAY ,USANDO jq !!!!
    UNHEALTHY_CONTAINERS=$(echo "$RAW_PS_OUTPUT" | grep '"Health":"unhealthy"')

    # Evaluation Logic Gate
    if [ -n "$UNHEALTHY_CONTAINERS" ] || [ "$TESTING" -eq 1 ]; then
        
        # Check if we should suppress the alert email due to an existing failure lock
        if [ -f "$LOCK_FILE" ] && [ "$TESTING" -eq 0 ]; then
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] ${TXT_SUPPRESSED[$SYSTEM_LANG]}" >> "$LOG_FILE"
            echo "---------------------------------------------------------" >> "$LOG_FILE"
            exit 0
        fi

        # Initialize secure temp allocations for writing file buffers
        EMAIL_BODY_FILE=$(mktemp)

        # Defensive System Trap Configuration: Wipes the temporary body file on exit or crash
        trap 'if [ -n "${EMAIL_BODY_FILE}" ]; then rm -f "$EMAIL_BODY_FILE"; fi' EXIT INT TERM


        # !!!!! CAMBIAR PARA QUE ANDE CON UN JSON ARRAY ,USANDO jq !!!!
        # Isolate text evaluation mapping paths using localized variables
        if [ "$TESTING" -eq 1 ] && [ -z "$UNHEALTHY_CONTAINERS" ]; then
            CONTAINER_NAMES="${TXT_TEST_RUN[$SYSTEM_LANG]}"
        else
            CONTAINER_NAMES=$(echo "$UNHEALTHY_CONTAINERS" | awk -F'"Name":"' '$2 ~ /./ {print $2}' | cut -d'"' -f1 | tr '\n' ',' | sed 's/,$//' | sed 's/,/, /g')    
        fi

        # Read multiplexed logs and clean out dirty ANSI terminal color escapes
        RAW_LOGS=$(docker compose -f "$SCRIPT_DIR/$COMPOSE_FILE" logs --tail=200 2>&1)
        CONTAINERS_LAST_LOGS=$(echo "$RAW_LOGS" | sed 's/\x1b\[[0-9;]*m//g')
        
        
        # Construct unified message block structure payloads
        {
            echo "====================================================================="
            echo "${TXT_BANNER[$SYSTEM_LANG]}"
            echo "====================================================================="
            printf "%b\n" "${TXT_DESC[$SYSTEM_LANG]}"
            echo ""
            echo "${TXT_STATUS[$SYSTEM_LANG]}"
            echo "${TXT_UNHEALTHY_CONTAINERS[$SYSTEM_LANG]} $CONTAINER_NAMES"
            echo ""
            echo "${TXT_LOGS[$SYSTEM_LANG]}"
            echo "$CONTAINERS_LAST_LOGS"
            echo ""
            echo "====================================================================="
            echo "${TXT_FOOTER[$SYSTEM_LANG]}"
        } > "$EMAIL_BODY_FILE"
        
        # Concurrently loop dispatch emails safely to all targets
        SMTP_ERRORS=0
        for email in "${RECIPIENTS[@]}"; do
            {
            echo "Subject: ${TXT_SUBJECT[$SYSTEM_LANG]} [${CONTAINER_NAMES}] - $(date '+%Y-%m-%d %H:%M:%S')"
            echo "To: $email"
            echo "MIME-Version: 1.0"
            echo "Content-Type: text/plain; charset=UTF-8"
            echo ""
            cat "$EMAIL_BODY_FILE"
            } | msmtp "$email" 2>> "$LOG_FILE"
            
            if [ ${PIPESTATUS[1]} -ne 0 ]; then
                ((SMTP_ERRORS++))
            fi
        done

        # Log operational transaction results cleanly back to logs and establish anti-flood lock
        if [ "$SMTP_ERRORS" -eq 0 ]; then
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] ${TXT_ALERT_STATUS[$SYSTEM_LANG]}: ${TXT_DISPATCH[$SYSTEM_LANG]} $CONTAINER_NAMES" >> "$LOG_FILE"
            echo "---------------------------------------------------------" >> "$LOG_FILE"
            if [ "$TESTING" -eq 0 ]; then
                touch "$LOCK_FILE"
            fi
        else
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] ${TXT_SMTP_ERR[$SYSTEM_LANG]} ($SMTP_ERRORS dispatches failed)." >> "$LOG_FILE"
            echo "---------------------------------------------------------" >> "$LOG_FILE"
        fi
    else
        # System is healthy. Check if we just recovered from an alert state to dismantle the lock
        if [ -f "$LOCK_FILE" ]; then
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] ${TXT_RECOVERED[$SYSTEM_LANG]}" >> "$LOG_FILE"
            rm -f "$LOCK_FILE"
        fi

        # Output nominal confirmation to system log trace allocations
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] ${TXT_NOMINAL[$SYSTEM_LANG]}" >> "$LOG_FILE"
        echo "---------------------------------------------------------" >> "$LOG_FILE"
    fi
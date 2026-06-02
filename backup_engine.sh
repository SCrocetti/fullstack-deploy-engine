#!/bin/bash
set -o pipefail
SYSTEM_LANG="en"
# Safe parameter parser that allows unknown flags to pass through without crashing
while [[ "$#" -gt 0 ]]; do
    case "$1" in
        --lang=en) SYSTEM_LANG="en" ; shift ;;
        --lang=es) SYSTEM_LANG="es" ; shift ;;
        *) shift ;; 
    esac
done

# ==============================================================================
# 0. LANGUAGE TRANSLATION ENGINE MAPPINGS
# ==============================================================================

# --- Massive Declaration Block ---
declare -rA TXT_STARTING_ROUTINE_LOG TXT_CREATING_STAGING_DIR_ERROR TXT_STEP_1 TXT_STEP_1_SUCCESS TXT_STEP_2_START \
           TXT_SYNCING_TARGET TXT_UPLOAD_SUCCESS TXT_PRUNING_ARCHIVES TXT_UPLOAD_FAILED \
           TXT_STAGE_3_SUCCESS TXT_STAGE_4_SUCCESS TXT_CRITICAL_UPLOAD_ERROR \
           TXT_CRITICAL_UPLOAD_KEEP TXT_CRITICAL_PIPE_ERROR TXT_ERR_SSH \
           TXT_ERR_GZIP TXT_ERR_GPG TXT_ERR_MISSING_FILE TXT_CHECK_DETAILS

# --- Spanish (es) Mappings ---
TXT_STARTING_ROUTINE_LOG[es]="🏁 [%s] Iniciando Rutina de Respaldo"
TXT_CREATING_STAGING_DIR_ERROR[es]="🚨 ERROR: No se pudo crear el directorio de staging."
TXT_STEP_1[es]="⏳ [1/4] Extrayendo base de datos remota y aplicando cifrado asimétrico GPG..."
TXT_STEP_1_SUCCESS[es]="🔒 Paso 1/4: Extracción y cifrado exitosos: "
TXT_STEP_2_START[es]="☁️ Paso 2/4: Enviando carga útil cifrada a los proveedores de almacenamiento..."
TXT_SYNCING_TARGET[es]="   -> Sincronizando con destino: "
TXT_UPLOAD_SUCCESS[es]="      ✅ Carga a %s exitosa."
TXT_PRUNING_ARCHIVES[es]="      🧹 Eliminando archivos antiguos de más de 10 años en "
TXT_UPLOAD_FAILED[es]="      🚨 ADVERTENCIA: ¡Falló la carga a %s! Revise %s"
TXT_STAGE_3_SUCCESS[es]="🗑️ Paso 3/4: Memoria caché de almacenamiento local eliminada."
TXT_STAGE_4_SUCCESS[es]="🎉 Paso 4/4: Respaldo completado exitosamente (%s carga(s) verificada(s))."
TXT_CRITICAL_UPLOAD_ERROR[es]="🚨 ERROR CRÍTICO: ¡No se pudo cargar el archivo en NINGUNO de los destinos en la nube!"
TXT_CRITICAL_UPLOAD_KEEP[es]="   Conservando el archivo original en: %s para intervención manual inmediata."
TXT_CRITICAL_PIPE_ERROR[es]="🚨 ERROR CRÍTICO: El pipeline ha fallado."
TXT_ERR_SSH[es]="   ❌ Falló la extracción remota (SSH/Docker)."
TXT_ERR_GZIP[es]="   ❌ Falló la compresión (gzip)."
TXT_ERR_GPG[es]="   ❌ Falló el cifrado de datos (GPG)."
TXT_ERR_MISSING_FILE[es]="   ❌ El archivo final cifrado no fue creado."
TXT_CHECK_DETAILS[es]="   🔍 Revise los detalles completos en: "

# --- English (en) Mappings ---
TXT_STARTING_ROUTINE_LOG[en]="🏁 [%s] Starting Backup Routine"
TXT_CREATING_STAGING_DIR_ERROR[en]="🚨 ERROR: Failed to create staging directory."
TXT_STEP_1[en]="⏳ [1/4] Extracting remote database and applying asymmetric GPG encryption..."
TXT_STEP_1_SUCCESS[en]="🔒 Step 1/4: Extraction and encryption successful: "
TXT_STEP_2_START[en]="☁️ Step 2/4: Shipping encrypted payload to cloud storage providers..."
TXT_SYNCING_TARGET[en]="   -> Syncing to target: "
TXT_UPLOAD_SUCCESS[en]="      ✅ Upload to %s successful."
TXT_PRUNING_ARCHIVES[en]="      🧹 Pruning archives older than 10 years on "
TXT_UPLOAD_FAILED[en]="      🚨 WARNING: Upload to %s failed! Check %s"
TXT_STAGE_3_SUCCESS[en]="🗑️ Step 3/4: Local staging cache purged."
TXT_STAGE_4_SUCCESS[en]="🎉 Step 4/4: Backup completed successfully (%s upload(s) verified)."
TXT_CRITICAL_UPLOAD_ERROR[en]="🚨 CRITICAL ERROR: Payload could not be uploaded to ANY cloud destinations!"
TXT_CRITICAL_UPLOAD_KEEP[en]="   Keeping raw staging file at: %s for immediate manual intervention."
TXT_CRITICAL_PIPE_ERROR[en]="🚨 CRITICAL ERROR: The pipeline has failed."
TXT_ERR_SSH[en]="   ❌ Remote extraction failed (SSH/Docker)."
TXT_ERR_GZIP[en]="   ❌ Compression failed (gzip)."
TXT_ERR_GPG[en]="   ❌ Data encryption failed (GPG)."
TXT_ERR_MISSING_FILE[en]="   ❌ The final encrypted file artifact was not created."
TXT_CHECK_DETAILS[en]="   🔍 Check complete details in: "

# ==============================================================================
# WORKSPACE & LOG SYSTEM INITIALIZATION
# ==============================================================================
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
STAGING_DIR="$HOME/project-backups/staging"
LOG_FILE="$HOME/project-backups/backup.log"
FILE_NAME="backup_$TIMESTAMP.sql.gz.gpg"
RECIPIENT_IDENTITY="backup-master@local"
RETENTION_DAYS=3650

REMOTE_TARGETS=(
  "mega:ProjectBackups/remote"
  "gdrive:ProjectBackups/remote"
  "pcloud:ProjectBackups/remote"
)

mkdir -p "$STAGING_DIR" || { echo "${TXT_CREATING_STAGING_DIR_ERROR[$SYSTEM_LANG]}"; exit 1; }

# Initialize backup session header in log
echo -e "\n=========================================================" >> "$LOG_FILE"
printf -v AUX_MSG "${TXT_STARTING_ROUTINE_LOG[$SYSTEM_LANG]}" "$(date)"
echo "$AUX_MSG" >> "$LOG_FILE"
echo "=========================================================" >> "$LOG_FILE"


# Single, clean helper function to rule them all
log_message() {
    echo "$1" | tee -a "$LOG_FILE"
}

# Cleanup utility hook (leaves staging intact only on critical upload failures)
do_cleanup() {
    if [ "${UPLOAD_COMPLETE_GUARD:-0}" -eq 1 ]; then
        rm -f "$STAGING_DIR/$FILE_NAME" > /dev/null 2>&1
    fi
}
trap do_cleanup EXIT INT TERM

# ==============================================================================
# STEP 1: DISTRIBUTED EXTRACTION & STREAM CIPHER PIPELINE
# ==============================================================================
log_message "${TXT_STEP_1[$SYSTEM_LANG]}"

# Streaming extraction via secure tunnel directly through compression and encryption engines
ssh -q -T project-server bash -s << 'EOF' 2>> "$LOG_FILE" | gzip 2>> "$LOG_FILE" | gpg --batch --yes --trust-model always --encrypt --recipient "$RECIPIENT_IDENTITY" -o "$STAGING_DIR/$FILE_NAME" 2>> "$LOG_FILE"
docker exec db-service sh -c '
    export PGPASSWORD=$(cat /run/secrets/db_password);
    export PGUSER=$(cat /run/secrets/db_user);
    export PGDATABASE=$(cat /run/secrets/db_name);
    pg_dump
'
EOF
# Capture pipeline statuses immediately before any other command runs
PIPE_RESULTS=("${PIPESTATUS[@]}")
SSH_EXIT=${PIPE_RESULTS[0]}
GZIP_EXIT=${PIPE_RESULTS[1]}
GPG_EXIT=${PIPE_RESULTS[2]}

# Verify structural success across the pipeline
if [ "$SSH_EXIT" -eq 0 ] && [ "$GZIP_EXIT" -eq 0 ] && [ "$GPG_EXIT" -eq 0 ] && [ -f "$STAGING_DIR/$FILE_NAME" ]; then
    log_message "${TXT_STEP_1_SUCCESS[$SYSTEM_LANG]}$FILE_NAME"
    log_message "${TXT_STEP_2_START[$SYSTEM_LANG]}"
    
    SUCCESSFUL_UPLOADS=0

    for TARGET in "${REMOTE_TARGETS[@]}"; do
        log_message "${TXT_SYNCING_TARGET[$SYSTEM_LANG]}[$TARGET]..."

        # Execute replication over cloud storage engines (detailed errors saved to log)
        rclone copy "$STAGING_DIR/$FILE_NAME" "$TARGET" >> "$LOG_FILE" 2>&1
        
        if [ $? -eq 0 ]; then
            printf -v AUX_MSG "${TXT_UPLOAD_SUCCESS[$SYSTEM_LANG]}" "[$TARGET]"
            log_message "$AUX_MSG"
            
            log_message "${TXT_PRUNING_ARCHIVES[$SYSTEM_LANG]}[$TARGET]..."

            ((SUCCESSFUL_UPLOADS++))
            rclone delete --include "backup_*.sql.gz.gpg" --max-depth 1 --min-age "${RETENTION_DAYS}d" "${TARGET%/}/" >> "$LOG_FILE" 2>&1
        else
            printf -v AUX_MSG "${TXT_UPLOAD_FAILED[$SYSTEM_LANG]}" "[$TARGET]" "$LOG_FILE"
            log_message "$AUX_MSG"
        fi
    done

    # ==========================================================================
    # FINAL ORCHESTRATION EVALUATION & WRAP-UP
    # ==========================================================================
    if [ "$SUCCESSFUL_UPLOADS" -gt 0 ]; then
        # Activate cleanup guard flag to allow safe deletion of local cache
        UPLOAD_COMPLETE_GUARD=1
        
        log_message "${TXT_STAGE_3_SUCCESS[$SYSTEM_LANG]}"
        
        printf -v AUX_MSG "${TXT_STAGE_4_SUCCESS[$SYSTEM_LANG]}" "$SUCCESSFUL_UPLOADS"
        log_message "$AUX_MSG"
    else
        log_message "${TXT_CRITICAL_UPLOAD_ERROR[$SYSTEM_LANG]}"
        
        printf -v AUX_MSG "${TXT_CRITICAL_UPLOAD_KEEP[$SYSTEM_LANG]}" "$STAGING_DIR/$FILE_NAME"
        log_message "$AUX_MSG"
        exit 1
    fi
else
    log_message "${TXT_CRITICAL_PIPE_ERROR[$SYSTEM_LANG]}"
    [ "$SSH_EXIT" -ne 0 ] && log_message "${TXT_ERR_SSH[$SYSTEM_LANG]}"
    [ "$GZIP_EXIT" -ne 0 ] && log_message "${TXT_ERR_GZIP[$SYSTEM_LANG]}"
    [ "$GPG_EXIT" -ne 0 ] && log_message "${TXT_ERR_GPG[$SYSTEM_LANG]}"
    [ ! -f "$STAGING_DIR/$FILE_NAME" ] && log_message "${TXT_ERR_MISSING_FILE[$SYSTEM_LANG]}"
    log_message "${TXT_CHECK_DETAILS[$SYSTEM_LANG]}$LOG_FILE"
    exit 1
fi
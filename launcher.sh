#!/bin/bash

# ==============================================================================
# 1. ENVIRONMENT VARIABLES LOADING & LANGUAGE SETUP
# ==============================================================================
if [ -f .env ]; then
   export $(grep -v '^#' .env | grep -v '^$' | xargs)
else
    echo "❌ Error: Required .env file not found. / No se encontró el archivo .env."
    exit 1
fi

# Default to English if SYSTEM_LANG is not explicitly specified in .env
if [ -z "$SYSTEM_LANG" ]; then
    SYSTEM_LANG="en"
fi

# ==============================================================================
# 2. LOCAL COMPILATION FUNCTION
# ==============================================================================
do_compile() {
    if [ "$SYSTEM_LANG" = "es" ]; then
        echo "📦 --- INICIANDO PIPELINES DE COMPILACIÓN ---"
    else
        echo "📦 --- STARTING APPLICATION BUILD PIPELINES ---"
    fi

    # Strict path validation
    if [ ! -d "$BACK_DIR" ] || [ ! -d "$FRONT_DIR" ]; then
        if [ "$SYSTEM_LANG" = "es" ]; then
            echo "❌ Error: Las rutas BACK_DIR o FRONT_DIR no son válidas. Verifique el .env."
        else
            echo "❌ Error: BACK_DIR or FRONT_DIR path is invalid. Check your .env file."
        fi
        exit 1
    fi

    if [ "$SYSTEM_LANG" = "es" ]; then
        echo "☕ Compilando artefactos del Backend (Spring Boot / Maven)..."
    else
        echo "☕ Compiling Backend Artifacts (Spring Boot / Maven)..."
    fi
    
    cd "$BACK_DIR" && ./mvnw clean package -DskipTests > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        exit 1
    fi
    cd - > /dev/null
    
    mkdir -p ./backend-build
    cp "$BACK_DIR"/target/*.jar ./backend-build/app.jar > /dev/null 2>&1
    [[ -f "$BACK_DIR"/Dockerfile ]] && cp "$BACK_DIR"/Dockerfile ./backend-build/

    if [ "$SYSTEM_LANG" = "es" ]; then
        echo "📦 Compilando assets estáticos del Frontend (pnpm Engine)..."
    else
        echo "📦 Compilating Frontend Static Assets (pnpm Engine)..."
    fi
    
    cd "$FRONT_DIR" && pnpm build > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        exit 1
    fi
    cd - > /dev/null
        
    mkdir -p ./frontend-build

    cp -r "$FRONT_DIR"/dist/* ./frontend-build/dist/ > /dev/null 2>&1

    [ -f "$FRONT_DIR"/nginx.conf ] && cp "$FRONT_DIR"/nginx.conf ./frontend-build/
    [ -f "$FRONT_DIR"/Dockerfile ] && cp "$FRONT_DIR"/Dockerfile ./frontend-build/
}

# ==============================================================================
# 3. WORKSPACE CLEANUP FUNCTION
# ==============================================================================
do_clear() {
    if [ "$SYSTEM_LANG" = "es" ]; then
        echo "🧹 Eliminando contextos de construcción temporales del disco..."
    else
        echo "🧹 Wiping temporary build contexts from disk..."
    fi
    rm -rf ./backend-build ./frontend-build > /dev/null 2>&1
}

# ==============================================================================
# 4. INTERACTIVE ORCHESTRATION INTERFACE
# ==============================================================================
if [ "$SYSTEM_LANG" = "es" ]; then
    echo "--- MOTOR DE DESPLIEGUE FULLSTACK ---"
    echo "1) Desplegar Infraestructura LOCAL"
    echo "2) Desplegar Infraestructura REMOTA (Destino SSH)"
    read -p "Seleccione el pipeline de destino [1-2]: " OPC
else
    echo "--- FULLSTACK DEPLOY ENGINE ---"
    echo "1) Deploy LOCAL Infrastructure"
    echo "2) Deploy REMOTE Infrastructure (SSH Target)"
    read -p "Select target pipeline destination [1-2]: " OPC
fi

case $OPC in
    1)
        do_compile
        if [ "$SYSTEM_LANG" = "es" ]; then
            echo "🏠 Iniciando la inicialización de contenedores LOCALES..."
        else
            echo "🏠 Triggering LOCAL container initialization..."
        fi

        docker compose up -d --build --force-recreate --remove-orphans > /dev/null 2>&1

        if [ $? -eq 0 ]; then
            do_clear
            if [ "$SYSTEM_LANG" = "es" ]; then
                echo "✅ DESPLIEGUE LOCAL EXITOSO"
            else
                echo "✅ LOCAL DEPLOYMENT SUCCESSFUL"
            fi
        else
            if [ "$SYSTEM_LANG" = "es" ]; then
                echo "❌ Error: La orquestación de Docker Compose local ha fallado."
            else
                echo "❌ Error: Local Docker Compose orchestration failed."
            fi
            exit 1
        fi
        ;;
    2)
        if [ "$BACK_PROFILE" != "prod" ]; then
            if [ "$SYSTEM_LANG" = "es" ]; then
                echo "❌ ERROR DE SEGURIDAD CRÍTICO:"
                echo "   El despliegue remoto requiere que BACK_PROFILE sea exactamente 'prod'."
                echo "   Perfil actual detectado en .env: '$BACK_PROFILE'"
                echo "   Cancelando la operación para evitar corrupción de entorno."
            else
                echo "❌ CRITICAL SECURITY ERROR:"
                echo "   Remote deployment requires BACK_PROFILE to be exactly 'prod'."
                echo "   Current profile detected in .env: '$BACK_PROFILE'"
                echo "   Aborting operation to prevent environment mismatch."
            fi
            exit 1
        fi
        do_compile
        if [ "$SYSTEM_LANG" = "es" ]; then
            echo "🌐 Enviando construcciones y metadatos a la arquitectura remota..."
        else
            echo "🌐 Shipping builds and metadata to the remote server architecture..."
        fi

        # 1. Ejecutar el SCP
        scp -q -r ./backend-build ./frontend-build ./docker-compose.yml ./nginx project-server:~/project-infra/ > /dev/null 2>&1

        # 2. VALIDAR SI EL SCP FUE EXITOSO
        if [ $? -ne 0 ]; then
            if [ "$SYSTEM_LANG" = "es" ]; then
                echo "❌ Error: Falló la transferencia de archivos (SCP) al servidor remoto."
            else
                echo "❌ Error: File transfer (SCP) to the remote server failed."
            fi
            exit 1
        fi

        # 3. Solo si el SCP funcionó, procedemos con el SSH
        if [ "$SYSTEM_LANG" = "es" ]; then
            echo "🚀 Iniciando el conmutador de servicios en el servidor remoto..."
        else
            echo "🚀 Initializing remote containerized services switcher..."
        fi
        
        ssh -q -T project-server << EOF > /dev/null
            cd ~/project-infra || exit 1

            export DB_NAME="$DB_NAME"
            export DB_USER="$DB_USER"
            export DB_PASSWORD="$DB_PASSWORD"
            export BACK_PROFILE="$BACK_PROFILE"

            docker compose up -d --build --force-recreate --remove-orphans > /dev/null 2>&1

            DEPLOY_STATUS=\$?

            rm -rf backend-build frontend-build > /dev/null 2>&1
            exit \$DEPLOY_STATUS
EOF
        if [ $? -eq 0 ]; then
            do_clear
            if [ "$SYSTEM_LANG" = "es" ]; then
                echo "✅ DESPLIEGUE REMOTO EXITOSO"
            else
                echo "✅ REMOTE DEPLOYMENT SUCCESSFUL"
            fi
        else
            if [ "$SYSTEM_LANG" = "es" ]; then
                echo "❌ Error: El despliegue falló en el servidor remoto."
            else
                echo "❌ Error: Deployment sequence failed on the remote infrastructure host."
            fi
        fi
        ;;
    *)
        if [ "$SYSTEM_LANG" = "es" ]; then
            echo "Opción de menú inválida. Abortando secuencia del motor."
        else
            echo "Invalid menu alternative. Aborting engine sequence."
        fi
        exit 1
        ;;
esac
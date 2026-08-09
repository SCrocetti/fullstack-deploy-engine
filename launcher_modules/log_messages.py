ERR_CANT_LOAD_ENV = "❌ Error: Can't load the required '.env' file for initialization."
ERR_INVALID_LANGUAGE = (LANGUAGE) => `❌ Error: Language '${LANGUAGE}' not supported. Defaulting to 'ENG'.`

ERR_DEPENDENCY_NOT_FOUND["ENG"] = (dependency) => `❌ Error: Required dependency '${dependency}' not found. Please install it and try again.`
ERR_DEPENDENCY_NOT_FOUND["ESP"] = (dependency) => `❌ Error: Dependencia obligatoria '${dependency}' no encontrada. Por favor, instálala e inténtalo de nuevo.`

INFO_EXECUTING_COMMAND["ENG"] = (command) => `🚀 Executing command: ${command}...`
INFO_EXECUTING_COMMAND["ESP"] = (command) => `🚀 Ejecutando comando: ${command}...`

ERR_COMMAND_EXECUTION_FAILED["ENG"] = (description) => `❌ Command execution failed: '${description}'. Check 'launcher.log' for details.`
ERR_COMMAND_EXECUTION_FAILED["ESP"] = (description) => `❌ Falló la ejecución del comando: '${description}'. Revisa 'launcher.log' para más detalles.`

EXCEPTION_BACK_PROFILE_NOT_DEFINED ["ENG"] = "BACK_PROFILE is not defined in the .env file."
EXCEPTION_BACK_PROFILE_NOT_DEFINED ["ESP"] = "BACK_PROFILE no está definido en el archivo .env."

EXCEPTION_BACK_PROFILE_NOT_PROD ["ENG"] = "The backend is not in the production profile."
EXCEPTION_BACK_PROFILE_NOT_PROD ["ESP"] = "El backend no se encuentra en el perfil de producción."

ERR_BACK_PROFILE_VALIDATION_FAILED ["ENG"] = (exception) => `❌ Error: Backend profile validation failed: ${exception}`
ERR_BACK_PROFILE_VALIDATION_FAILED ["ESP"] = (exception) => `❌ Error: La validación del perfil del backend falló: ${exception}`

ERR_ALIAS_SSH_CONECTION_NOT_DEFINED ["ENG"] = "❌ Error: ALIAS_SSH_CONECTION is not defined in the .env file."
ERR_ALIAS_SSH_CONECTION_NOT_DEFINED ["ESP"] = "❌ Error: ALIAS_SSH_CONECTION no está definido en el archivo .env."

ERR_SSH_KEY_NOT_FOUND ["ENG"] = (alias) => `❌ Error: No IdentityFile found for SSH alias '${alias}' in ~/.ssh/config.`
ERR_SSH_KEY_NOT_FOUND ["ESP"] = (alias) => `❌ Error: No se encontró un IdentityFile para el alias SSH '${alias}' en ~/.ssh/config.`

ERR_SSH_KEY_PUBLIC_NOT_FOUND ["ENG"] = (pub_key_path) => `❌ Error: Public key not found at '${pub_key_path}'.`
ERR_SSH_KEY_PUBLIC_NOT_FOUND ["ESP"] = (pub_key_path) => `❌ Error: No se encontró la llave pública en '${pub_key_path}'.`

INFO_VERIFIYING_KEY_IN_AGENT ["ENG"] = "🔑 Verifying if the project's key is loaded in the SSH Agent..."
INFO_VERIFIYING_KEY_IN_AGENT ["ESP"] = "🔑 Verificando si la llave del proyecto está cargada en el Agente SSH..."

ERR_FAILED_AGENT_VERIFICATION ["ENG"] = (exception) => `❌ Error: Failed to verify SSH Agent. Details: ${exception}`
ERR_FAILED_AGENT_VERIFICATION ["ESP"] = (exception) => `❌ Error: Falló la verificación del Agente SSH. Detalles: ${exception}`

INFO_KEY_LOADED ["ENG"] = (alias) => `✅ The key for '${alias}' is already loaded in the SSH Agent.`
INFO_KEY_LOADED ["ESP"] = (alias) => `✅ La llave para '${alias}' ya está cargada en el Agente SSH.`

WARNING_KEY_NOT_LOADED ["ENG"] = (alias) => `⚠️ The key for '${alias}' is NOT loaded in the SSH Agent. Please enter the passphrase.`
WARNING_KEY_NOT_LOADED ["ESP"] = (alias) => `⚠️ La llave para '${alias}' NO está cargada en el Agente SSH. Por favor, introduce la passphrase.`

INFO_KEY_LOADED_SUCCESSFULLY ["ENG"] = (project) => `✅ The key for the project '${project}' has been successfully loaded into the SSH Agent.`
INFO_KEY_LOADED_SUCCESSFULLY ["ESP"] = (project) => `✅ La llave para el proyecto '${project}' se ha cargado correctamente en el Agente SSH.`

ERR_FAILED_TO_LOAD_KEY ["ENG"] = (exitCode) => `❌ Error: Failed to load the key into the SSH Agent. Exit code: ${exitCode}`
ERR_FAILED_TO_LOAD_KEY ["ESP"] = (exitCode) => `❌ Error: Falló la carga de la llave en el Agente SSH. Código de salida: ${exitCode}`

INFO_COMPILING_BACKEND ["ENG"] = (project) => `📦 Compiling backend for project '${project}'...`
INFO_COMPILING_BACKEND ["ESP"] = (project) => `📦 Compilando backend para el proyecto '${project}'...`

ERRR_BACK_DIR_NOT_FOUND ["ENG"] = "❌ Error: Backend source code directory not found. Please check the .env configuration."
ERRR_BACK_DIR_NOT_FOUND ["ESP"] = "❌ Error: No se encontró el directorio de código fuente del backend. Por favor, verifica la configuración en el archivo .env."

COMMAND_BACKEND_COMPILATION ["ENG"] = "Compiling backend using Maven..."
COMMAND_BACKEND_COMPILATION ["ESP"] = "Compilando backend usando Maven..."

INFO_COMPILING_FRONTEND ["ENG"] = (project) => `📦 Compiling frontend for project '${project}'...`
INFO_COMPILING_FRONTEND ["ESP"] = (project) => `📦 Compilando frontend para el proyecto '${project}'...`

ERR_FRONT_DIR_NOT_FOUND ["ENG"] = "❌ Error: Frontend source code directory not found. Please check the .env configuration."
ERR_FRONT_DIR_NOT_FOUND ["ESP"] = "❌ Error: No se encontró el directorio de código fuente del frontend. Por favor, verifica la configuración en el archivo .env."

COMMAND_FRONTEND_COMPILATION ["ENG"] = "Compiling frontend using pnpm..."
COMMAND_FRONTEND_COMPILATION ["ESP"] = "Compilando frontend usando pnpm..."

INFO_STARTING_COMPILATION_PIPELINE ["ENG"] =  (project) => `📦 Starting compilation pipeline for project '${project}'...`
INFO_STARTING_COMPILATION_PIPELINE ["ESP"] = (project) => `📦 --- Iniciando pipeline de compilación para el proyecto '${project}' ---`

INFO_CLEANING_TEMPORAL_CONTEXTS ["ENG"] = "🧹 Cleaning previous build temporary contexts..."
INFO_CLEANING_TEMPORAL_CONTEXTS ["ESP"] = "🧹 Limpiando contextos de compilación anteriores..."

WARNING_COULD_NOT_REMOVE_TEMPORAL_DIR ["ENG"] = (dir, error) => `⚠️ Could not remove ${dir}: ${error}`
WARNING_COULD_NOT_REMOVE_TEMPORAL_DIR ["ESP"] = (dir, error) => `⚠️ No se pudo remover ${dir}: ${error}`

INFO_INITIALIZING_FRONTEND_BUILD ["ENG"] = "📁 Initializing frontend build directory..." 
INFO_INITIALIZING_FRONTEND_BUILD ["ESP"] = "📁 Inicializando carpeta de construcción del frontend..."

INFO_COPYING_DOCKER_ENVIRONMENT ["ENG"] = "📁 Copying Docker environment to temporary directory..."
INFO_COPYING_DOCKER_ENVIRONMENT ["ESP"] = "📁 Copiando entorno de Docker a carpeta temporal..."

INFO_CLEANING_AND_COPYING_FILES_TO_DEPLOYMENT ["ENG"] = "📁 Cleaning deployment folder and copying files to it..."
INFO_CLEANING_AND_COPYING_FILES_TO_DEPLOYMENT ["ESP"] = "📁 Limpiando carpeta de despliegue y copiando archivos a la misma..."

INFO_CONNECTING_TO_REMOTE ["ENG"] = (alias) => `🚀 Connecting to '${alias}' to prepare remote deployment...`
INFO_CONNECTING_TO_REMOTE ["ESP"] = (alias) => `🚀 Conectando a '${alias}' para preparar despliegue remoto...`

INFO_COMPRESSING_TEMPORAL_DIR ["ENG"] = (dir) => `📦 Compressing temporary directory '${dir}'...`
INFO_COMPRESSING_TEMPORAL_DIR ["ESP"] = (dir) => `📦 Comprimiendo directorio temporal '${dir}'...`

INFO_REMOVING_REMOTE_DIR ["ENG"] = (dir) => `🧹 Removing existing remote directory '${dir}'...`
INFO_REMOVING_REMOTE_DIR ["ESP"] = (dir) => `🧹 Remviendo directorio remoto existente '${dir}'...`

INFO_CREATING_REMOTE_DIR ["ENG"] = (dir) => `📁 Creating clean remote directory '${dir}'...`
INFO_CREATING_REMOTE_DIR ["ESP"] = (dir) => `📁 Creando directorio remoto limpio '${dir}'...`

INFO_TRANSFERRING_COMPRESSED_FILE ["ENG"] = "🚀 Transferring compressed file via SCP..."
INFO_TRANSFERRING_COMPRESSED_FILE ["ESP"] = "🚀 Transfiriendo archivo comprimido vía SCP..."

INFO_DECOMPRESSING_REMOTE_DIR ["ENG"] = (dir) => `📂 Decompressing files in remote directory '${dir}'...`
INFO_DECOMPRESSING_REMOTE_DIR ["ESP"] = (dir) => `📂 Descomprimiendo archivos en el directorio remoto '${dir}'...`

INFO_FILES_COPIED_SUCCESSFULLY_TO_REMOTE ["ENG"] = "✅ Files successfully copied to the remote directory."
INFO_FILES_COPIED_SUCCESSFULLY_TO_REMOTE ["ESP"] = "✅ Archivos copiados con éxito al directorio remoto."

ERR_FAILED_TO_COPY_FILES_TO_REMOTE ["ENG"] = (exception) => `❌ Error: Failed to copy files to the remote directory. Details: ${exception}`
ERR_FAILED_TO_COPY_FILES_TO_REMOTE ["ESP"] = (exception) => `❌ Error: Falló la copia de archivos al directorio remoto. Detalles: ${exception}`

INFO_LOADING_DEPLOYMENT_IDENTITIES ["ENG"] = "👤 Loading deployment identities (UID and GID)..."
INFO_LOADING_DEPLOYMENT_IDENTITIES ["ESP"] = "👤 Cargando identidades de despliegue (UID y GID)..."

INFO_DEPLOYMENT_IDENTITIES_LOADED ["ENG"] = (uid, gid) => `✅ Deployment identities loaded: UID=${uid}, GID=${gid}.`
INFO_DEPLOYMENT_IDENTITIES_LOADED ["ESP"] = (uid, gid) => `✅ Identidades de despliegue cargadas: UID=${uid}, GID=${gid}.`

ERR_FAILED_TO_LOAD_DEPLOYMENT_IDENTITIES ["ENG"] = (exception) => `❌ Error: Failed to load deployment identities. Details: ${exception}`
ERR_FAILED_TO_LOAD_DEPLOYMENT_IDENTITIES ["ESP"] = (exception) => `❌ Error: Falló la carga de identidades de despliegue. Detalles: ${exception}`

INFO_RECOVERING_ENVIROMENT_VARIABLES_FOR_REMOTE_DEPLOYMENT ["ENG"] = "Recovering enviroment variables for deployment to remote server..."
INFO_RECOVERING_ENVIROMENT_VARIABLES_FOR_REMOTE_DEPLOYMENT ["ESP"] = "Recuperando variables de entorno para despliegue en el servidor remoto..."

EXCEPTION_CANT_RECOVER_DEPLOYMENT_IDENTITIE_FROM_REMOTE ["ENG"] = "Can't recover the UID or GID from the server"
EXCEPTION_CANT_RECOVER_DEPLOYMENT_IDENTITIE_FROM_REMOTE ["ESP"] = "No se pudo recuperar el UID o GID del servidor"

EXCEPTION_INFISICAL_PROJECT_ID_NOT_DEFINED_IN_ENV ["ENG"] = "INFISICAL_PROJECT_ID not defined in the .env"
EXCEPTION_INFISICAL_PROJECT_ID_NOT_DEFINED_IN_ENV ["ESP"] = "INFISICAL_PROJECT_ID no definido en el .env"

EXCEPTION_BACK_PROFILE_NOT_DEFINED_IN_ENV ["ENG"] = "BACK_PROFILE not defined in the .env"
EXCEPTION_BACK_PROFILE_NOT_DEFINED_IN_ENV ["ESP"] = "BACK_PROFILE no definido en el .env"

ERR_FAILED_TO_RECOVER_ENVIROMENT_VARIABLES_FOR_REMOTE_DEPLOYMENT ["ENG"] = (exception) => `❌ Error: Failed to recover the enviroment variables for remote deployment: ${exception}` 
ERR_FAILED_TO_RECOVER_ENVIROMENT_VARIABLES_FOR_REMOTE_DEPLOYMENT ["ESP"] = (exception) => `❌ Error: No se pudieron obtener las variables de entorno para el despligue remoto: ${exception}`

INFO_STARTING_LOCAL_CONTAINERS ["ENG"] = "🏠 Starting local containers via Docker Compose..."
INFO_STARTING_LOCAL_CONTAINERS ["ESP"] = "🏠 Iniciando contenedores locales via Docker Compose..."

COMMAND_CONTAINER_ORCHESTRATION_LOCAL ["ENG"] = "Containers Orchestration"
COMMAND_CONTAINER_ORCHESTRATION_LOCAL ["ESP"] = "Orquestación de Contenedores"

INFO_LOCAL_DEPLOYMENT_SUCCESS ["ENG"] = "✅ LOCAL DEPLOYMENT SUCCESSFUL - INFRASTRUCTURE OPERATIONAL IN THE ENVIRONMENT"
INFO_LOCAL_DEPLOYMENT_SUCCESS ["ESP"] = "✅ DESPLIEGUE LOCAL EXITOSO - INFRAESTRUCTURA OPERATIVA EN EL ENTORNO"

ERR_FAILED_TO_EXECUTE_LOCAL_DOCKER_COMPOSE ["ENG"] = "❌ Error: Failed to execute Docker Compose for local deployment."
ERR_FAILED_TO_EXECUTE_LOCAL_DOCKER_COMPOSE ["ESP"] = "❌ Error: Falló la ejecución de Docker Compose para el despliegue local."

INFO_STARTING_REMOTE_CONTAINERS ["ENG"] = "🏠 Starting remote containers via Docker Compose..."
INFO_STARTING_REMOTE_CONTAINERS ["ESP"] = "🏠 Iniciando contenedores remotos via Docker Compose...".

INFO_EXCECUTING_REMOTE_DOCKER_COMPOSE ["ENG"] = (route) => `⚡ Executing docker compose on the remote route '${route}'...`
INFO_EXCECUTING_REMOTE_DOCKER_COMPOSE ["ESP"] = (route) => `⚡ Ejecutando docker compose en la ruta remota: '${route}'...`

INFO_REMOTE_DEPLOYMENT_SUCCESS ["ENG"] = "✅ REMOTE DEPLOYMENT SUCCESSFUL - INFRASTRUCTURE OPERATIONAL ON THE SERVER"
INFO_REMOTE_DEPLOYMENT_SUCCESS ["ESP"] = "✅ DESPLIEGUE REMOTO EXITOSO - INFRAESTRUCTURA OPERATIVA EN EL SERVIDOR"

ERR_FAILED_TO_EXECUTE_REMOTE_DOCKER_COMPOSE ["ENG"] = (alias,exception) => `❌ Error: Failed to execute remote deployment to '${alias}'. Details: ${exception}`
ERR_FAILED_TO_EXECUTE_REMOTE_DOCKER_COMPOSE ["ESP"] = (alias,exception) => `❌ Error: No se pudo ejecutar el despliegue remoto en '${alias}'. Detalles: ${exception}`

ERR_DEPLOYMENT_FAILED ["ENG"] = (exception) => `❌ Deployment failed critically due to an error: ${exception}`
ERR_DEPLOYMENT_FAILED ["ESP"] = (exception) => `❌ El despliegue falló críticamente debido a un error: ${exception}`
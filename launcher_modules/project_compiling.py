import sys
import shutil
import logging
from .utils import execute_command
from .configurations import (
    LANGUAGE,
    PROJECT_NAME, 
    FRONTEND_BUILD_DIR, 
    PUBLIC_BACK_BUILD_DIR,
    BACK_DIR, 
    FRONT_DIR
)
from .log_messages import (
    INFO_COMPILING_BACKEND,
    ERR_BACK_DIR_NOT_FOUND,
    COMMAND_BACKEND_COMPILATION,
    INFO_COMPILING_FRONTEND,
    ERR_FRONT_DIR_NOT_FOUND,
    COMMAND_FRONTEND_COMPILATION,
    ERR_BACKEND_ARTIFACT_NOT_FOUND,
    ERR_FRONTEND_ARTIFACT_NOT_FOUND,
    INFO_STARTING_COMPILATION_PIPELINE
)
def compile_backend():
    """Compiles the backend of the project and copies its artifact to the build directory."""
    logging.info(INFO_COMPILING_BACKEND[LANGUAGE](PROJECT_NAME))
    if not BACK_DIR.exists():
        logging.error(ERR_BACK_DIR_NOT_FOUND[LANGUAGE])
        sys.exit(1)
        
    execute_command("./mvnw clean package -DskipTests", BACK_DIR, COMMAND_BACKEND_COMPILATION[LANGUAGE])
    PUBLIC_BACK_BUILD_DIR.mkdir(parents=True, exist_ok=True)
    
    jar_origen = BACK_DIR / "target" / "app.jar"
    if not jar_origen.exists():
        jars_encontrados = list((BACK_DIR / "target").glob("*.jar"))
        if jars_encontrados: 
            jar_origen = jars_encontrados[0]

    if not jar_origen.exists():
        logging.error(ERR_BACKEND_ARTIFACT_NOT_FOUND[LANGUAGE])
        sys.exit(1)

    shutil.copy(jar_origen, PUBLIC_BACK_BUILD_DIR / "app.jar")
    if (BACK_DIR / "Dockerfile").exists():
        shutil.copy(BACK_DIR / "Dockerfile", PUBLIC_BACK_BUILD_DIR / "Dockerfile")

def compile_frontend():
    """Compiles the frontend of the project and copies its artifact to the build directory."""
    logging.info(INFO_COMPILING_FRONTEND[LANGUAGE](PROJECT_NAME))
    if not FRONT_DIR.exists():
        logging.error(ERR_FRONT_DIR_NOT_FOUND[LANGUAGE])
        sys.exit(1)
        
    execute_command("pnpm build", FRONT_DIR, COMMAND_FRONTEND_COMPILATION[LANGUAGE])
    
    out_dir = FRONT_DIR / "out"
    if not out_dir.exists():
        logging.error(ERR_FRONTEND_ARTIFACT_NOT_FOUND[LANGUAGE])
        sys.exit(1)

    destino_front_public = FRONTEND_BUILD_DIR / "public-portal" / "out"
    destino_front_public.mkdir(parents=True, exist_ok=True)
    shutil.copytree(out_dir, destino_front_public, dirs_exist_ok=True)
def compile_and_prepare_project():
    """Compiles and prepares the project for deployment, including both backend and frontend components."""
    logging.info(INFO_STARTING_COMPILATION_PIPELINE[LANGUAGE](PROJECT_NAME))
    compile_backend()
    compile_frontend()
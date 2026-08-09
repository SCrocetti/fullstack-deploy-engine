#!/usr/bin/env python3
"""
DEPLOYMENT ENGINE (PYTHON ENGINE)
"""

import sys
import logging

from launcher_modules.utils import verify_dependencies, validate_backend_profile, prepare_ssh_agent

from launcher_modules.infraestructure_mounting import (
    clean_temporal_contexts,
    initialize_frontend_build,
    copy_docker_environment_to_temporal,
    copy_files_to_deployment,
    copy_files_to_remote_deployment,
    launch_docker_orchestration_local,
    launch_docker_orchestration_remote
)

from launcher_modules.project_compiling import (
    compile_and_prepare_project
)
from launcher_modules.configuraciones import (
    LANGUAGE
)
from launcher_modules.log_messages import (
    ERR_DEPLOYMENT_FAILED
)

MENU_TITTLE ["ENG"] = "=== DEPLOYMENT ENGINE (PYTHON ENGINE) ==="
MENU_TITTLE ["ESP"] = "=== MOTOR DE DESPLIEGUE (MOTOR PYTHON) ==="
MENU_OPTIONS ["ENG"] = [
    "1. Local Deployment",
    "2. Remote Deployment",
    "3. Exit"
]
MENU_OPTIONS ["ESP"] = [
    "1. Despliegue Local",
    "2. Despliegue Remoto",
    "3. Salir"
]
MENU_PROMPT ["ENG"] = "\nSelect an option from 1 to 3: "
MENU_PROMPT ["ESP"] = "\nSeleccione una opción del 1 al 3:
MENU_INVALID_OPTION ["ENG"] = "❌ Invalid option. Please try again."
MENU_INVALID_OPTION ["ESP"] = "❌ Opción inválida. Por favor, inténtelo de nuevo."

def local_deployment():
    """Executes the local deployment of the infrastructure."""
    verify_dependencies()
    
    clean_temporal_contexts()
    initialize_frontend_build()
    
    compile_and_prepare_project()
    
    copiying_docker_environment_to_temporal()
    clean_destination_folder_and_copy_files_to_deployment()
    launch_docker_orchestration_local()
    
    clean_temporal_contexts()
    sys.exit(0)
def remote_deployment():
    """Executes the remote deployment of the infrastructure."""
    verify_dependencies()
    validate_backend_profile()
    prepare_ssh_agent()


    clean_temporal_contexts()
    initialize_frontend_build()
    
    compile_and_prepare_project()
    
    copy_docker_environment_to_temporal()
    clean_and_copy_to_remote_deployment()
    launch_docker_orchestration_remote()
    
    clean_temporal_contexts()
    sys.exit(0)
if __name__ == "__main__":
    
    try:
        menu = {
            "1": local_deployment,
            "2": remote_deployment
        }
        while True:
            print(MENU_TITTLE[LANGUAGE])
            for option in MENU_OPTIONS[LANGUAGE]:
                print(option)
            
            seleccion = input(MENU_PROMPT[LANGUAGE]).strip()
            
            if seleccion in menu:
                menu[seleccion]() 
            elif seleccion == "3":
                break
            else:
                print(MENU_INVALID_OPTION[LANGUAGE])
        
    except Exception as e:
        logging.error(ERR_DEPLOYMENT_FAILED[LANGUAGE](e))
        sys.exit(1)
import shutil
import logging
import sys
import os
import pwd
import grp
import tarfile
from fabric import Connection
from .utils import execute_command
from .configurations import (
    LANGUAGE, 
    PROJECT_NAME,
    BASE_DIR,
    FRONTEND_BUILD_DIR, 
    TEMPORAL_DIR, 
    DEPLOYMENT_DIR,
    INFRASTRUCTURE_DIR,
    ALIAS_SSH_CONNECTION, 
    INFISICAL_PROJECT_ID, 
    BACK_PROFILE
)
from .log_messages import (
    INFO_CLEANING_TEMPORAL_CONTEXTS,
    WARNING_COULD_NOT_REMOVE_TEMPORAL_DIR,
    INFO_INITIALIZING_FRONTEND_BUILD,
    INFO_COPYING_DOCKER_ENVIRONMENT,
    INFO_CLEANING_AND_COPYING_FILES_TO_DEPLOYMENT,
    INFO_CONNECTING_TO_REMOTE,
    INFO_COMPRESSING_TEMPORAL_DIR,
    INFO_REMOVING_REMOTE_DIR,
    INFO_CREATING_REMOTE_DIR,
    INFO_TRANSFERRING_COMPRESSED_FILE,
    INFO_DECOMPRESSING_REMOTE_DIR,
    INFO_FILES_COPIED_SUCCESSFULLY_TO_REMOTE,
    INFO_LOADING_DEPLOYMENT_IDENTITIES,
    INFO_DEPLOYMENT_IDENTITIES_LOADED,
    ERR_FAILED_TO_LOAD_DEPLOYMENT_IDENTITIES,
    INFO_RECOVERING_ENVIRONMENT_VARIABLES_FOR_REMOTE_DEPLOYMENT,
    EXCEPTION_CANT_RECOVER_DEPLOYMENT_IDENTITY_FROM_REMOTE,
    EXCEPTION_INFISICAL_PROJECT_ID_NOT_DEFINED_IN_ENV,
    EXCEPTION_BACK_PROFILE_NOT_DEFINED_IN_ENV,
    ERR_FAILED_TO_RECOVER_ENVIRONMENT_VARIABLES_FOR_REMOTE_DEPLOYMENT,
    INFO_STARTING_LOCAL_CONTAINERS,
    COMMAND_CONTAINER_ORCHESTRATION_LOCAL,
    INFO_LOCAL_DEPLOYMENT_SUCCESS,
    ERR_FAILED_TO_EXECUTE_LOCAL_DOCKER_COMPOSE,
    INFO_STARTING_REMOTE_CONTAINERS,
    INFO_EXECUTING_REMOTE_DOCKER_COMPOSE,
    INFO_REMOTE_DEPLOYMENT_SUCCESS,
    ERR_FAILED_TO_EXECUTE_REMOTE_DOCKER_COMPOSE
)

def clean_temporal_contexts():
    """Deletes previous local build temporary directories safely."""
    logging.info(INFO_CLEANING_TEMPORAL_CONTEXTS[LANGUAGE])
    if TEMPORAL_DIR.exists():
        try:
            shutil.rmtree(TEMPORAL_DIR)
        except Exception as e:
            logging.warning(WARNING_COULD_NOT_REMOVE_TEMPORAL_DIR[LANGUAGE](TEMPORAL_DIR, e))

def initialize_frontend_build():
    """Initializes the frontend build directory by mapping configuration files and Nginx container definitions."""
    logging.info(INFO_INITIALIZING_FRONTEND_BUILD[LANGUAGE])
    FRONTEND_BUILD_DIR.mkdir(parents=True, exist_ok=True)
    shutil.copytree(BASE_DIR / "nginx", FRONTEND_BUILD_DIR, dirs_exist_ok=True)
def copying_docker_environment_to_temporal():
    """Copies the Docker environment directories for database and compose to the temporary directory."""
    logging.info(INFO_COPYING_DOCKER_ENVIRONMENT[LANGUAGE])
    shutil.copytree(BASE_DIR / "db-public", TEMPORAL_DIR / "db-public", dirs_exist_ok=True)
    shutil.copy(BASE_DIR / "docker-compose.yml", TEMPORAL_DIR / "docker-compose.yml")
def clean_and_copy_files_to_deployment():
    """Cleans the destination folder on the local host and mounts the infrastructure there."""
    logging.info(INFO_CLEANING_AND_COPYING_FILES_TO_DEPLOYMENT[LANGUAGE])
    
    shutil.rmtree(INFRASTRUCTURE_DIR, ignore_errors=True)
    INFRASTRUCTURE_DIR.mkdir(parents=True, exist_ok=True)

    shutil.copytree(TEMPORAL_DIR, INFRASTRUCTURE_DIR, dirs_exist_ok=True)

def clean_and_copy_to_remote_deployment():
    """Cleans the destination folder on the remote host, compresses the temporary directory, uploads it, and decompresses it there."""
    logging.info(INFO_CONNECTING_TO_REMOTE[LANGUAGE](ALIAS_SSH_CONNECTION))
    
    tar_file = TEMPORAL_DIR.parent / "temporal.tar.gz"
    tar_file_route = f"{INFRASTRUCTURE_DIR}/temporal.tar.gz"
    
    try:
        logging.info(INFO_COMPRESSING_TEMPORAL_DIR[LANGUAGE](TEMPORAL_DIR))
        with tarfile.open(tar_file, "w:gz") as tar:
            tar.add(str(TEMPORAL_DIR), arcname=".")

        with Connection(ALIAS_SSH_CONNECTION) as c:
            infrastructure_dir_str = str(INFRASTRUCTURE_DIR)
            
            logging.info(INFO_REMOVING_REMOTE_DIR[LANGUAGE](infrastructure_dir_str))
            c.run(f"rm -rf {infrastructure_dir_str}")
            logging.info(INFO_CREATING_REMOTE_DIR[LANGUAGE](infrastructure_dir_str))
            c.run(f"mkdir -p {infrastructure_dir_str}")

            logging.info(INFO_TRANSFERRING_COMPRESSED_FILE[LANGUAGE])
            c.put(str(tar_file), remote=tar_file_route)
            
            logging.info(INFO_DECOMPRESSING_REMOTE_DIR[LANGUAGE](infrastructure_dir_str))
            c.run(f"tar -xzf {tar_file_route} -C {infrastructure_dir_str}")
            
            c.run(f"rm {tar_file_route}")
            
            logging.info(INFO_FILES_COPIED_SUCCESSFULLY_TO_REMOTE[LANGUAGE])

    except Exception as e:
        logging.error(ERR_FAILED_TO_COPY_FILES_TO_REMOTE[LANGUAGE](e))
        sys.exit(1)
        
    finally:
        if os.path.exists(tar_file):
            os.remove(tar_file)
def load_deployment_identities():
    """Reads the UID of 'deployer' and the GID of 'deployer-group' and sets them in the environment."""
    logging.info(INFO_LOADING_DEPLOYMENT_IDENTITIES[LANGUAGE])
    try:
        uid = pwd.getpwnam("deployer").pw_uid
        gid = grp.getgrnam("deployer-group").gr_gid
        
        os.environ["DEPLOYER_UID"] = str(uid)
        os.environ["DEPLOYER_GROUP_GID"] = str(gid)
        
        logging.info(INFO_DEPLOYMENT_IDENTITIES_LOADED[LANGUAGE](uid, gid))
    except KeyError as e:
        logging.error(ERR_FAILED_TO_LOAD_DEPLOYMENT_IDENTITIES[LANGUAGE](e))
        sys.exit(1)
def obtain_remote_environment_variables():
    """
    Recovers the environment variables needed to start the remote deployment on docker
    Returns a dictionary with the environment variables ready to use
    """
    logging.info(INFO_RECOVERING_ENVIRONMENT_VARIABLES_FOR_REMOTE_DEPLOYMENT[LANGUAGE])
    try:
        uid=""
        gid=""
        with Connection(ALIAS_SSH_CONNECTION) as c:
            uid_res = c.run("id -u deployer", hide=True)
            uid = uid_res.stdout.strip()
            
            gid_res = c.run("getent group deployer-group | cut -d: -f3", hide=True)
            gid = gid_res.stdout.strip()
        
        if not uid or not gid:
            raise ValueError(EXCEPTION_CANT_RECOVER_DEPLOYMENT_IDENTITY_FROM_REMOTE[LANGUAGE])

        if not INFISICAL_PROJECT_ID:
            raise ValueError(EXCEPTION_INFISICAL_PROJECT_ID_NOT_DEFINED_IN_ENV[LANGUAGE])
        
        if not BACK_PROFILE:
            raise ValueError(EXCEPTION_BACK_PROFILE_NOT_DEFINED_IN_ENV[LANGUAGE])
        return {
            "DEPLOYER_UID": uid,
            "DEPLOYER_GROUP_GID": gid,
            "INFISICAL_PROJECT_ID": INFISICAL_PROJECT_ID,
            "BACK_PROFILE": BACK_PROFILE
        }
        
    except Exception as e:
        logging.error(ERR_FAILED_TO_RECOVER_ENVIRONMENT_VARIABLES_FOR_REMOTE_DEPLOYMENT[LANGUAGE](e))
        sys.exit(1)
def launch_docker_orchestration_local():
    """Launches the Docker Compose command to bring up the local infrastructure."""
    logging.info(INFO_STARTING_LOCAL_CONTAINERS[LANGUAGE])
    load_deployment_identities()
    comando_compose = "docker compose up -d --build --force-recreate --remove-orphans"
    
    if execute_command(comando_compose, INFRASTRUCTURE_DIR, COMMAND_CONTAINER_ORCHESTRATION_LOCAL[LANGUAGE]):
        logging.info("======================================================================")
        logging.info(INFO_LOCAL_DEPLOYMENT_SUCCESS[LANGUAGE])
        logging.info("======================================================================")
    else:
        logging.error(ERR_FAILED_TO_EXECUTE_LOCAL_DOCKER_COMPOSE[LANGUAGE])
        sys.exit(1)
def launch_docker_orchestration_remote():
    """Launches the Docker Compose command to bring up the remote infrastructure."""
    logging.info(INFO_STARTING_REMOTE_CONTAINERS[LANGUAGE])
    logging.info(INFO_CONNECTING_TO_REMOTE[LANGUAGE](ALIAS_SSH_CONNECTION))
    try:
        env_remoto = obtain_remote_environment_variables()
        with Connection(ALIAS_SSH_CONNECTION) as c:
            
            
            comando_compose = "docker compose up -d --build --force-recreate --remove-orphans"
            
            logging.info(INFO_EXECUTING_REMOTE_DOCKER_COMPOSE[LANGUAGE](INFRASTRUCTURE_DIR))
            
            with c.cd(str(INFRASTRUCTURE_DIR)):
                c.run(comando_compose, env=env_remoto)
                
        logging.info("======================================================================")
        logging.info(INFO_REMOTE_DEPLOYMENT_SUCCESS[LANGUAGE])
        logging.info("======================================================================")
    except Exception as e:
        logging.error(ERR_FAILED_TO_EXECUTE_REMOTE_DOCKER_COMPOSE[LANGUAGE](ALIAS_SSH_CONNECTION, e))
        sys.exit(1)
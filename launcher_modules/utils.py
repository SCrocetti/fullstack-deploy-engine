import sys
import os
import shutil
import logging
import subprocess
from paramiko.config import SSHConfig
from .configuraciones import (
    LANGUAGE, 
    PROJECT_NAME, 
    ALIAS_SSH_CONECTION, 
    BACK_PROFILE
)
from log_messages import (
    ERR_DEPENDENCY_NOT_FOUND,
    INFO_EXECUTING_COMMAND, 
    ERR_COMMAND_EXECUTION_FAILED, 
    EXCEPTION_BACK_PROFILE_NOT_DEFINED, 
    EXCEPTION_BACK_PROFILE_NOT_PROD, 
    ERR_BACK_PROFILE_VALIDATION_FAILED, 
    ERR_ALIAS_SSH_CONECTION_NOT_DEFINED, 
    ERR_SSH_KEY_NOT_FOUND, 
    ERR_SSH_KEY_PUBLIC_NOT_FOUND, 
    INFO_VERIFIYING_KEY_IN_AGENT
)
def verify_dependencies():
    """Checks that essential CLI tools are installed on the system.""""
    for comand in ["docker", "pnpm"]:
        if not shutil.which(comand):
            logging.error(ERR_DEPENDENCY_NOT_FOUND[LANGUAGE](comand))
            sys.exit(1)

def execute_command(command, working_directory, description):
    """Encapsulates the execution of subprocesses, redirecting output to the launcher.log file."""
    logging.info(INFO_EXECUTING_COMMAND[LANGUAGE](command))
    try:
        with open("launcher.log", "a", encoding="utf-8") as log_file:
            resultado = subprocess.run(
                command,
                cwd=working_directory,
                stdout=log_file,
                stderr=log_file,
                shell=True,
                check=True
            )
        return resultado.returncode == 0
    except subprocess.CalledProcessError:
        logging.error(ERR_COMMAND_EXECUTION_FAILED[LANGUAGE](description))
        sys.exit(1)
def validate_backend_profile():
    """Validates that the backend profile is in production for remote deployment."""
    try:
        if not BACK_PROFILE:
            raise ValueError(EXCEPTION_BACK_PROFILE_NOT_DEFINED[LANGUAGE])
        if BACK_PROFILE!="prod":
            raise ValueError(EXCEPTION_BACK_PROFILE_NOT_PROD[LANGUAGE])
    except Exception as e:
        logging.error(ERR_BACK_PROFILE_VALIDATION_FAILED[LANGUAGE](e))
        sys.exit(1)
        
def prepare_ssh_agent():
    """
    Verifies if the specific key defined by the SSH alias in the .env
    is already loaded in the SSH Agent. If not, it invokes ssh-add interactively
    so that the user can enter the passphrase.
    """
    
    if not ALIAS_SSH_CONECTION:
        logging.error(ERR_ALIAS_SSH_CONECTION_NOT_DEFINED[LANGUAGE])
        sys.exit(1)
        
    ssh_config_path = os.path.expanduser("~/.ssh/config")
    key_path = None
    
    if os.path.exists(ssh_config_path):
        with open(ssh_config_path, "r") as f:
            config = SSHConfig()
            config.parse(f)
            host_config = config.lookup(ALIAS_SSH_CONECTION)
            if 'identityfile' in host_config:
                key_path = os.path.expanduser(host_config['identityfile'][0])

    if not key_path:
        logging.error(ERR_SSH_KEY_NOT_FOUND[LANGUAGE](ALIAS_SSH_CONECTION))
        sys.exit(1)
        
    pub_key_path = f"{key_path}.pub"
    
    try:
        with open(pub_key_path, "r") as f:
            pub_content = f.read().strip().split()[1] 
    except FileNotFoundError:
        logging.error(ERR_SSH_KEY_PUBLIC_NOT_FOUND[LANGUAGE](pub_key_path))
        sys.exit(1)

    logging.info(INFO_VERIFIYING_KEY_IN_AGENT[LANGUAGE])

    try:
        with open("launcher.log", "a", encoding="utf-8") as log_file:
            listed_result = subprocess.run(
                ["ssh-add", "-L"],
                stdout=subprocess.PIPE,
                stderr=log_file,
                text=True,
                check=False 
            )
        keys_in_agent = listed_result.stdout
    except Exception as e:
        logging.error(ERR_FAILED_AGENT_VERIFICATION[LANGUAGE](e))
        sys.exit(1)

    if pub_content in keys_in_agent:
        logging.info(INFO_KEY_LOADED[LANGUAGE](ALIAS_SSH_CONECTION))
    else:
        logging.warning(WARNING_KEY_NOT_LOADED[LANGUAGE](ALIAS_SSH_CONECTION))
        
        try:
            subprocess.run(
                ["ssh-add", key_path],
                check=True
            )
            logging.info(INFO_KEY_LOADED_SUCCESSFULLY[LANGUAGE](PROJECT_NAME))
            
        except subprocess.CalledProcessError as e:
            logging.error(ERR_FAILED_TO_LOAD_KEY[LANGUAGE](e.returncode))
            sys.exit(1)
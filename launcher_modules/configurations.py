import os
import sys
import logging
from pathlib import Path
from dotenv import load_dotenv
from log_messages import ERR_CANT_LOAD_ENV, ERR_INVALID_LANGUAGE

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    handlers=[
        logging.FileHandler("launcher.log", encoding="utf-8"),
        logging.StreamHandler(sys.stdout)
    ]
)

if not Path(".env").exists():
    logging.error(ERR_CANT_LOAD_ENV)
    sys.exit(1)

load_dotenv()

BASE_DIR = Path(__file__).resolve().parent.parent
TEMPORAL_DIR = BASE_DIR / "temporal"
FRONTEND_BUILD_DIR = TEMPORAL_DIR / "frontend"
PUBLIC_BACK_BUILD_DIR = TEMPORAL_DIR / "backend"


LANGUAGE = os.getenv("LANGUAGE", "ENG")
if LANGUAGE not in ["ENG", "ESP"]:
    logging.warning(ERR_INVALID_LANGUAGE(LANGUAGE))
    LANGUAGE = "ENG"

PROJECT_NAME = os.getenv("PROJECT_NAME", "my_project")

INFISICAL_PROJECT_ID= os.getenv("INFISICAL_PROJECT_ID")
ALIAS_SSH_CONECTION = os.getenv("ALIAS_SSH_CONECTION")

BACK_PROFILE= os.getenv("BACK_PROFILE", "prod")
BACK_DIR = Path(os.getenv("BACK_DIR", "backend"))
FRONT_DIR = Path(os.getenv("FRONT_DIR", "frontend"))

DEPLOYMENT_DIR = Path("/opt") / PROJECT_NAME

INFRAESTRUCTURE_DIR = DEPLOYMENT_DIR / "infraestructure"
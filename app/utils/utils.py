from pathlib import Path
from typing import Union

from dotenv import load_dotenv as _load_dotenv

PARENT_DIR = Path(__file__).resolve().parents[2]


def load_env(path: Union[str, Path] = ".env") -> None:
    _load_dotenv(dotenv_path=path)
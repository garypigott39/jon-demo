from abc import ABC, abstractmethod
from typing import Any, Optional

from .lib.db import Database


class BaseModel(ABC):
    table: str = ""
    label_name: str = ""
    foreign_keys: dict[str, type["BaseModel"]] = {}

    def __init__(self, **db_kwargs: Any):
        self.db = Database(**db_kwargs)
        self.db.connect()

    def __enter__(self) -> "BaseModel":
        return self

    def __exit__(self, exc_type, exc_val, exc_tb) -> None:
        self.close()

    def close(self) -> None:
        self.db.close()

    def create(self, data: dict[str, Any]) -> int:
        return self.db.insert(self.table, data)

    def find(self, row_id: int) -> Optional[dict[str, Any]]:
        return self.db.get_by_id(self.table, row_id)

    def all(self, filters: Optional[dict[str, Any]] = None) -> list[dict[str, Any]]:
        return self.db.get_all(self.table, filters)

    def update(self, row_id: int, data: dict[str, Any]) -> bool:
        return self.db.update(self.table, row_id, data)

    def delete(self, row_id: int) -> bool:
        return self.db.delete(self.table, row_id)

    def count(self, filters: Optional[dict[str, Any]] = None) -> int:
        return self.db.count(self.table, filters)

    @abstractmethod
    def label(self, row: dict[str, Any]) -> str:
        ...

    def resolve_foreign_keys(self, rows: list[dict[str, Any]]) -> list[dict[str, Any]]:
        if not self.foreign_keys or not rows:
            return rows
        for column, fk_model_cls in self.foreign_keys.items():
            with fk_model_cls() as fk_model:
                labels_by_id = {r["id"]: fk_model.label(r) for r in fk_model.all()}
            for row in rows:
                row[column] = labels_by_id.get(row[column], row[column])
        return rows
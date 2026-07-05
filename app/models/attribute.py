from typing import Any

from ._base import BaseModel
from .coordinate import Coordinate
from .lookup import Lookup


class Attribute(BaseModel):
    table = "c_attribute"
    label_name = "Attribute"
    foreign_keys = {"fk_coordinate": Coordinate, "fk_lookup": Lookup}

    def label(self, row: dict[str, Any]) -> str:
        return row["value"]

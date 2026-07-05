from typing import Any

from ._base import BaseModel
from .region import Region


class Coordinate(BaseModel):
    table = "c_coordinate"
    label_name = "Coordinate"
    foreign_keys = {"fk_region": Region}

    def label(self, row: dict[str, Any]) -> str:
        return f"({row['x']}, {row['y']})"

    def attribute_count(self, coordinate_id: int) -> int:
        from .attribute import Attribute

        with Attribute() as attribute:
            return attribute.count({"fk_coordinate": coordinate_id})

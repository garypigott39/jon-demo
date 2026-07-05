from typing import Any

from ._base import BaseModel


class Region(BaseModel):
    table = "l_region"
    label_name = "Region"

    def label(self, row: dict[str, Any]) -> str:
        return row["name"]

    def coordinate_count(self, region_id: int) -> int:
        from .coordinate import Coordinate

        with Coordinate() as coordinate:
            return coordinate.count({"fk_region": region_id})

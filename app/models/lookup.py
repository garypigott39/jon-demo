from typing import Any

from ._base import BaseModel


class Lookup(BaseModel):
    table = "l_lookup"
    label_name = "Lookup"

    def label(self, row: dict[str, Any]) -> str:
        return row["code"]

    def attribute_count(self, lookup_id: int) -> int:
        from .attribute import Attribute

        with Attribute() as attribute:
            return attribute.count({"fk_lookup": lookup_id})

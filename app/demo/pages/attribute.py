from app.models.attribute import Attribute

from ._base import BasePage


class AttributePage(BasePage):
    model_cls = Attribute
    route = "attributes"
    columns = {
        "id": {"label": "ID"},
        "fk_coordinate": {"label": "Coordinate"},
        "fk_lookup": {"label": "Lookup"},
        "value": {"label": "Value"},
        "updated_at": {"label": "Updated"},
    }

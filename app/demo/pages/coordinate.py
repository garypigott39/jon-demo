from app.models.coordinate import Coordinate

from ._base import BasePage
from .attribute import AttributePage


class CoordinatePage(BasePage):
    model_cls = Coordinate
    route = "coordinates"
    columns = {
        "id": {"label": "ID"},
        "x": {"label": "X"},
        "y": {"label": "Y"},
        "fk_region": {"label": "Region"},
        "notes": {"label": "Notes"},
        "updated_at": {"label": "Updated"},
        "count": {
            "label": "Attributes",
            "method": "attribute_count",
            "target_page": AttributePage,
            "fk": "fk_coordinate",
        },
    }

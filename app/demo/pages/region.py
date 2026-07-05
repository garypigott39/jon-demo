from app.models.region import Region

from ._base import BasePage
from .coordinate import CoordinatePage


class RegionPage(BasePage):
    model_cls = Region
    route = "regions"
    columns = {
        "id": {"label": "ID"},
        "name": {"label": "Region Name"},
        "description": {"label": "Description"},
        "updated_at": {"label": "Updated"},
        "count": {
            "label": "Coordinates",
            "method": "coordinate_count",
            "target_page": CoordinatePage,
            "fk": "fk_region",
        },
    }

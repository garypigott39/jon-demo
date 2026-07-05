from app.models.lookup import Lookup

from ._base import BasePage
from .attribute import AttributePage


class LookupPage(BasePage):
    model_cls = Lookup
    route = "lookups"
    columns = {
        "id": {"label": "ID"},
        "code": {"label": "Code"},
        "description": {"label": "Description"},
        "updated_at": {"label": "Updated"},
        "count": {
            "label": "Attributes",
            "method": "attribute_count",
            "target_page": AttributePage,
            "fk": "fk_lookup",
        },
    }

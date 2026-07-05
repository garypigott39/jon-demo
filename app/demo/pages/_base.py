from typing import Any

from flask import render_template, request

from app.models._base import BaseModel


class BasePage:
    model_cls: type[BaseModel]
    route: str
    template = "table.html"
    # Column name -> display properties, in display order. Every entry
    # carries "label"; the synthetic "count" column additionally carries
    # "method", "target_page", "fk".
    columns: dict[str, dict[str, Any]] = {}

    @classmethod
    def register(cls, app) -> None:
        app.add_url_rule(f"/{cls.route}", endpoint=cls.route, view_func=cls.view)

    @classmethod
    def view(cls):
        model_cls = cls.model_cls
        count_col = cls.columns.get("count")
        filters, filter_label = cls._parse_filter(model_cls)

        with model_cls() as model:
            rows = model.all(filters)
            if count_col:
                count_fn = getattr(model, count_col["method"])
                for row in rows:
                    row["count"] = count_fn(row["id"])
            rows = model.resolve_foreign_keys(rows)

        columns = [col for col in cls.columns if col != "count"]
        headers = {col: cls.columns[col]["label"] for col in columns}

        return render_template(
            cls.template,
            title=model_cls.label_name,
            route=cls.route,
            columns=columns,
            headers=headers,
            rows=rows,
            filter_label=filter_label,
            count_header=count_col["label"] if count_col else None,
            count_target=count_col["target_page"].route if count_col else None,
            count_fk=count_col["fk"] if count_col else None,
        )

    @staticmethod
    def _parse_filter(model_cls):
        for column, fk_model_cls in model_cls.foreign_keys.items():
            value = request.args.get(column, type=int)
            if value is None:
                continue
            with fk_model_cls() as fk_model:
                parent_row = fk_model.find(value)
                label = f"{fk_model_cls.label_name}: {fk_model.label(parent_row)}" if parent_row else None
            return {column: value}, label
        return None, None

# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A small demo project modelling water-company assets (pipes, valves, hydrants, leaks) across
Australian supply zones: a Postgres schema plus a minimal Flask UI for browsing it. See
`README.md` for full setup/run instructions (database creation, roles, `.env`, running the app).

## Commands

```bash
# Setup
python3 -m venv .venv
.venv/bin/pip install -r requirements.txt

# Database (run once, as postgres/superuser -- destructive, drops & recreates the `demo` schema)
sudo -u postgres psql -d demo -f sql/schema.sql
psql -d demo -f sql/demo_data.sql   # idempotent seed data, run as your own role

# Run the app
.venv/bin/python -m app.demo.index   # http://127.0.0.1:5000/
```

There is no test suite, linter, or build step configured in this repo.

**Run the app as a module (`-m app.demo.index`), not `python app/demo/index.py`.** Historically,
running `app/demo/app.py` directly caused a Python import collision (the script's own directory
lands on `sys.path`, and a file named `app.py` there shadowed the real top-level `app` package) —
that's why the entry point is named `index.py`, not `app.py`. Absolute imports plus the
`sys.path.insert` bootstrap at the top of `index.py` mean it now works either way, but `-m` is the
documented/expected form.

## Architecture

Everything lives under `app/`, an implicit namespace package (no `app/__init__.py`; some
subpackages have `__init__.py`, some don't — both are fine and already relied upon).

### Data layer: `app/models/`

- `_base.py` — abstract `BaseModel` (`abc.ABC`). Each concrete model sets `table` (the Postgres
  table name, schema-qualified via `Database`'s `search_path`), `label_name` (a human-readable
  display name), and optionally `foreign_keys` (`{column_name: ReferencedModelClass}`).
  Subclasses must implement `label(row) -> str`, which produces the display string for one row
  (e.g. `Region.label()` returns `row["name"]`; `Coordinate.label()` returns `f"({x}, {y})"`).
  `BaseModel` provides generic CRUD (`create`, `find`, `all`, `update`, `delete`, `count`) that
  all delegate to a per-instance `Database` object, plus `resolve_foreign_keys(rows)`, which
  replaces raw FK id values in a row list with the referenced entity's `label()`.
- `region.py`, `lookup.py`, `coordinate.py`, `attribute.py` — one class per table
  (`l_region`, `l_lookup`, `c_coordinate`, `c_attribute`). `Coordinate.foreign_keys = {"fk_region":
  Region}` and `Attribute.foreign_keys = {"fk_coordinate": Coordinate, "fk_lookup": Lookup}`
  define the FK graph. Each parent model also exposes a `*_count(id)` method for its children
  (e.g. `Region.coordinate_count`, `Coordinate.attribute_count`, `Lookup.attribute_count`) used to
  drive the drill-down counts in the UI.
  **Import order matters**: because `Coordinate`/`Attribute` import their parent models at module
  level (for `foreign_keys`), the reverse-direction `*_count` methods on `Region`/`Lookup`/
  `Coordinate` import their child model *inside the method body*, not at the top of the file — a
  top-level import there would create a circular import (e.g. `region.py` importing
  `coordinate.py` while `coordinate.py` imports `region.py`).
- `lib/db.py` — `Database`: thin `psycopg2` wrapper. Connects with `options=f"-c
  search_path={schema}"` (always over `host=localhost`/TCP, so it needs `PGPASSWORD`, not peer
  auth). All CRUD methods build queries with `psycopg2.sql.Identifier`/`sql.Placeholder` for safe
  dynamic table/column names and use **named placeholders** (`%(col)s`) so callers pass a plain
  dict straight to `cur.execute(query, data)`. Reads `PGUSER`/`PGPASSWORD` from the environment
  (loaded via `app/utils` at import time, see below).
- `lib/db.py`'s `insert`/`update`/`get_all` (with `filters`) all validate their `data`/`filters`
  argument is a non-empty `dict` via `Database._validate_data` before building SQL.

### `app/utils/`

`utils.py` defines `PARENT_DIR` (the project root, computed via `Path(__file__).resolve()`) and
`load_env(path)`, a thin wrapper around `python-dotenv`'s `load_dotenv`. `db.py` calls
`load_env(PARENT_DIR / ".env")` at import time, so a `.env` file at the repo root is picked up
automatically wherever `Database` is used.

### Web layer: `app/demo/`

- `index.py` — the only entry point. Creates the Flask `app`, imports each `Page` class, calls
  `page.register(app)` for each, and defines the `/` index route.
- `pages/_base.py` — `BasePage`. Each concrete page class sets `model_cls`, `route` (the URL
  path segment, also used as the Flask endpoint name), and `columns`: an explicit, ordered dict of
  `{column_name: {"label": str, ...}}` defining exactly what's displayed and in what order —
  **not derived from the model/table's actual columns**, so adding a DB column doesn't
  automatically show it. A page's `columns` may include a synthetic `"count"` entry (not a real
  DB column) with extra sub-properties `method` (a `*_count` method name on the model),
  `target_page` (the `Page` class to drill into), and `fk` (the FK column name to filter by on
  that target page) — this is what renders the clickable count-and-drill-down column.
  `BasePage.view()` is the single generic Flask view function shared by every page: it parses an
  optional FK filter from the query string (`_parse_filter`, using `model_cls.foreign_keys` to
  know which query params are valid), fetches rows, computes any count column, resolves FK labels,
  and renders `templates/table.html`.
- `pages/{region,coordinate,lookup,attribute}.py` — one `Page` subclass per table. Note the same
  import-cycle constraint as the models: `RegionPage` imports `CoordinatePage` (for its count's
  `target_page`), `CoordinatePage` imports `AttributePage`, `LookupPage` imports `AttributePage` —
  this only works because it's a linear chain (nothing imports back "up" the chain at module
  level).
- `templates/index.html` / `templates/table.html` — the only two templates, shared by all pages.
  `table.html` is fully generic: it renders whatever `columns`/`headers`/`rows` its page passes in,
  plus a disabled "+ Add" button and a disabled "Edit" button per row (no create/edit
  functionality is wired up — these are visual placeholders only). When `count_header` is set, it
  renders an extra column linking to `url_for(count_target, **{count_fk: row['id']})`; when
  `filter_label` is set (i.e. the page was reached via a drill-down link), it shows a "Filtered by
  ... — clear filter" banner above the table.

### Drill-down flow

Regions → Coordinates → Attributes is the intended browsing path: `/regions` shows a count of each
region's coordinates linking to `/coordinates?fk_region=<id>`; `/coordinates` links similarly to
`/attributes?fk_coordinate=<id>`; `/lookups` links directly to `/attributes?fk_lookup=<id>`. The
query-string parameter name is always the literal FK column name from `c_coordinate`/`c_attribute`.

## Database conventions (see `sql/schema.sql`)

- All tables live in the `demo` schema of the `demo` database (not `public`), owned by a
  `demo-owner` role — `schema.sql` runs `SET ROLE "demo-owner";` before `CREATE TABLE` so the
  tables themselves are owned by that role, not by whichever superuser ran the script. Login
  roles are granted membership of `demo-owner` (see README) rather than given individual
  per-table `GRANT`s.
- Table naming: `l_*` for lookup/reference tables (`l_region`, `l_lookup`), `c_*` for
  coordinate-linked/child tables (`c_coordinate`, `c_attribute`).
- Every table has a `SERIAL PRIMARY KEY id` and an `updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()`.
- Foreign key columns and their constraints are both named `fk_<referenced_concept>` (e.g.
  `fk_region`, `fk_coordinate`, `fk_lookup`) — this convention is intentionally **not** kept in
  sync with the `l_`/`c_` table prefixes (e.g. `fk_region` still points at `l_region`).
- `c_attribute` is an EAV-style table: `l_lookup` defines the set of possible attribute *types*
  (`ASSET_TYPE`, `PIPE_MATERIAL`, `LEAK_STATUS`, etc.), and each `c_attribute` row attaches one
  typed value to one `c_coordinate`.
- `sql/schema.sql` is destructive on every run (`DROP SCHEMA IF EXISTS demo CASCADE;`) — it's a
  full rebuild script, not a migration.

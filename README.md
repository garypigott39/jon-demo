# Demo

A small demo project modelling water-company assets (pipes, valves, hydrants, leaks) across Australian supply zones, backed by Postgres and a minimal Flask UI.

Tables (all in the `demo` schema of the `demo` database):

| Table           | Purpose                                                      |
|-----------------|--------------------------------------------------------------|
| `l_region`      | Water supply zones / district metered areas (DMAs)           |
| `l_lookup`      | Dictionary of possible asset/leak attribute types            |
| `c_coordinate`  | X/Y water asset locations, each belonging to a region        |
| `c_attribute`   | Lookup-typed values attached to a coordinate (EAV pattern)   |

## 1. Prerequisites

- PostgreSQL running locally
- Python 3.11+
- A superuser (or `CREATEROLE`) connection to Postgres to run the SQL

## 2. In SQL

1. Create a database called `demo`

2. Run the `sql/schema.sql` script as a superuser. It creates:
   - a `demo-owner` role that owns the `demo` schema and everything in it
   - a login role for you, granted membership of `demo-owner` (so you inherit its privileges without needing separate `GRANT`s)
   - the `demo` schema and its four tables
   - Replace `gary` in `sql/schema.sql` with your own OS/Postgres username

3. Run the `sql/demo_data.sql` script as your own role to insert sample data.

## 3. Python setup

```bash
python3 -m venv .venv
.venv/bin/pip install -r requirements.txt
```

## 4. The `.env` file

Create an `.env` file at the repo root (next to this README) with your Postgres credentials:

```
PGUSER=your_username
PGPASSWORD=your_password
```

In a live project the .env file should be ignored by git.

## 5. Run the demo

```bash
.venv/bin/python -m app.demo.index
```

Then open `http://127.0.0.1:5000/`.

## Notes on the `gary` username

Throughout `sql/schema.sql`, `gary` is a stand-in for whichever OS/Postgres role should own and use this demo. If you're not that user, replace it before running the script. `app/models/lib/db.py` doesn't hardcode a username itself - it reads `PGUSER`/`PGPASSWORD` from the environment (or `.env`), so once the role in `schema.sql` matches your `.env`, the Python side needs no changes.

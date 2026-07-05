import os
from typing import Any, Optional

import psycopg2
import psycopg2.extras
from psycopg2 import sql

from ...utils import PARENT_DIR, load_env

load_env(PARENT_DIR / ".env")


class Database:
    def __init__(
        self,
        dbname: str = "demo",
        schema: str = "demo",
        user: Optional[str] = None,
        password: Optional[str] = None,
        host: str = "localhost",
        port: int = 5432,
    ):
        self.dbname = dbname
        self.schema = schema
        self.user = user or os.environ.get("PGUSER")
        self.password = password or os.environ.get("PGPASSWORD")
        self.host = host
        self.port = port
        self.conn: Optional[psycopg2.extensions.connection] = None

    def connect(self) -> None:
        self.conn = psycopg2.connect(
            dbname=self.dbname,
            user=self.user,
            password=self.password,
            host=self.host,
            port=self.port,
            options=f"-c search_path={self.schema}",
        )

    def close(self) -> None:
        if self.conn is not None:
            self.conn.close()
            self.conn = None

    def __enter__(self) -> "Database":
        self.connect()
        return self

    def __exit__(self, exc_type, exc_val, exc_tb) -> None:
        self.close()

    # -- CRUD -----------------------------------------------------------

    @staticmethod
    def _validate_data(data: dict[str, Any]) -> None:
        if not isinstance(data, dict):
            raise TypeError(f"data must be a dict, got {type(data).__name__}")
        if not data:
            raise ValueError("data must not be empty")

    def insert(self, table: str, data: dict[str, Any]) -> int:
        self._validate_data(data)
        columns = list(data.keys())
        query = sql.SQL("INSERT INTO {table} ({columns}) VALUES ({values}) RETURNING id").format(
            table=sql.Identifier(table),
            columns=sql.SQL(", ").join(map(sql.Identifier, columns)),
            values=sql.SQL(", ").join(sql.Placeholder(col) for col in columns),
        )
        with self.conn.cursor() as cur:
            cur.execute(query, data)
            new_id = cur.fetchone()[0]
        self.conn.commit()
        return new_id

    def get_by_id(self, table: str, row_id: int) -> Optional[dict[str, Any]]:
        query = sql.SQL("SELECT * FROM {table} WHERE id = %(id)s").format(table=sql.Identifier(table))
        with self.conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
            cur.execute(query, {"id": row_id})
            row = cur.fetchone()
        return dict(row) if row else None

    @staticmethod
    def _where_clause(filters: dict[str, Any]) -> sql.Composable:
        return sql.SQL(" AND ").join(
            sql.SQL("{col} = {ph}").format(col=sql.Identifier(col), ph=sql.Placeholder(col))
            for col in filters
        )

    def get_all(self, table: str, filters: Optional[dict[str, Any]] = None) -> list[dict[str, Any]]:
        query = sql.SQL("SELECT * FROM {table}").format(table=sql.Identifier(table))
        params: dict[str, Any] = {}
        if filters:
            self._validate_data(filters)
            query = sql.SQL("{query} WHERE {conditions}").format(
                query=query, conditions=self._where_clause(filters)
            )
            params = filters
        with self.conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
            cur.execute(query, params)
            rows = cur.fetchall()
        return [dict(row) for row in rows]

    def count(self, table: str, filters: Optional[dict[str, Any]] = None) -> int:
        query = sql.SQL("SELECT COUNT(*) FROM {table}").format(table=sql.Identifier(table))
        params: dict[str, Any] = {}
        if filters:
            self._validate_data(filters)
            query = sql.SQL("{query} WHERE {conditions}").format(
                query=query, conditions=self._where_clause(filters)
            )
            params = filters
        with self.conn.cursor() as cur:
            cur.execute(query, params)
            return cur.fetchone()[0]

    def update(self, table: str, row_id: int, data: dict[str, Any]) -> bool:
        self._validate_data(data)
        if "id" in data:
            raise ValueError("data must not contain 'id'")
        assignments = sql.SQL(", ").join(
            sql.SQL("{col} = {ph}").format(col=sql.Identifier(col), ph=sql.Placeholder(col))
            for col in data
        )
        query = sql.SQL("UPDATE {table} SET {assignments}, updated_at = now() WHERE id = %(id)s").format(
            table=sql.Identifier(table),
            assignments=assignments,
        )
        with self.conn.cursor() as cur:
            cur.execute(query, {**data, "id": row_id})
            updated = cur.rowcount > 0
        self.conn.commit()
        return updated

    def delete(self, table: str, row_id: int) -> bool:
        query = sql.SQL("DELETE FROM {table} WHERE id = %s").format(table=sql.Identifier(table))
        with self.conn.cursor() as cur:
            cur.execute(query, [row_id])
            deleted = cur.rowcount > 0
        self.conn.commit()
        return deleted
-- Demo schema: water company assets (pipes/leaks) tracked by region and coordinate
-- Run once, connected as a superuser/owner of the target server:
-- CREATE DATABASE demo;

SET timezone TO 'UTC';

/**
 * Thoughts on using schemas:
 * - Schemas are a way to logically group database objects (tables, views, functions, etc) within a single database.
 * - Using schemas would give you the ability to split the database based on customer or country or whatever you want.
 * - For exmaple, you could have a schema for each water company, and then have the same tables in each schema.
 * - You control the structure of the database.
 */

-- ---------------------------------------------------------------------------
-- Roles: demo-owner owns the demo schema; gary is granted membership of it
-- ---------------------------------------------------------------------------
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'demo-owner') THEN
        CREATE ROLE "demo-owner" NOLOGIN;
    END IF;

    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'gary') THEN
        CREATE USER gary;
        -- Use:
        -- ALTER USER gary PASSWORD 'your_password_here';
    END IF;
END
$$;

GRANT "demo-owner" TO gary;

DROP SCHEMA IF EXISTS demo CASCADE;
CREATE SCHEMA IF NOT EXISTS demo AUTHORIZATION "demo-owner";

-- Objects created below are owned by demo-owner (not postgres), so that gary
-- inherits access to them via its "demo-owner" role membership above.
SET ROLE "demo-owner";

-- ---------------------------------------------------------------------------
-- l_region: a named water supply zone / service area, e.g. a district metered area (DMA)
-- ---------------------------------------------------------------------------
CREATE TABLE demo.l_region (
    id              SERIAL PRIMARY KEY,
    name            TEXT NOT NULL,
    description     TEXT,
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    UNIQUE(name)
);

COMMENT ON TABLE demo.l_region IS 'A named water supply zone / service area, e.g. a district metered area (DMA)';

-- ---------------------------------------------------------------------------
-- l_lookup: dictionary of possible asset/leak attribute types
-- ---------------------------------------------------------------------------
CREATE TABLE demo.l_lookup (
    id              SERIAL PRIMARY KEY,
    code            TEXT NOT NULL,
    description     TEXT,
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    UNIQUE(code)
);

COMMENT ON TABLE demo.l_lookup IS 'Dictionary of possible asset/leak attribute types';

-- ---------------------------------------------------------------------------
-- c_coordinate: an X/Y point (water asset location) that belongs to a region
-- ---------------------------------------------------------------------------
CREATE TABLE demo.c_coordinate (
    id              SERIAL PRIMARY KEY,
    x               DOUBLE PRECISION NOT NULL,
    y               DOUBLE PRECISION NOT NULL,
    fk_region       INTEGER NOT NULL,
    -- Optional notes about this coordinate, e.g. "Beneath arterial road - traffic management required for repairs"
    notes           TEXT,
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_region FOREIGN KEY (fk_region)
        REFERENCES demo.l_region (id)
        ON DELETE RESTRICT,

    UNIQUE(x, y)
);

-- Always create an index on foreign keys for performance
CREATE INDEX ix_c_coordinate_fk_region ON demo.c_coordinate (fk_region);

COMMENT ON TABLE demo.c_coordinate IS 'An X/Y point (water asset location) that belongs to a region';

-- ---------------------------------------------------------------------------
-- c_attribute: a lookup-typed asset/leak value attached to a coordinate
-- ---------------------------------------------------------------------------
CREATE TABLE demo.c_attribute (
    id              SERIAL PRIMARY KEY,
    fk_coordinate   INTEGER NOT NULL,
    fk_lookup       INTEGER NOT NULL,
    value           TEXT,
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_coordinate FOREIGN KEY (fk_coordinate)
        REFERENCES demo.c_coordinate (id)
        ON DELETE CASCADE,

    CONSTRAINT fk_lookup FOREIGN KEY (fk_lookup)
        REFERENCES demo.l_lookup (id)
        ON DELETE RESTRICT,

    UNIQUE(fk_coordinate, fk_lookup)
);

CREATE INDEX ix_c_attribute_fk_coordinate ON demo.c_attribute (fk_coordinate);
CREATE INDEX ix_c_attribute_fk_lookup ON demo.c_attribute (fk_lookup);

COMMENT ON TABLE demo.c_attribute IS 'A lookup-typed asset/leak value attached to a coordinate';

RESET ROLE;

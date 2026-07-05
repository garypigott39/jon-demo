-- Demo seed data: Australian water-company supply zones, pipe/asset coordinates,
-- leak/asset lookup types, and attributes
-- Target database: demo (schema: demo)
-- Idempotent: safe to re-run, uses ON CONFLICT DO NOTHING against the existing
-- UNIQUE constraints (l_region.name, c_coordinate(x,y), l_lookup.code, c_attribute(fk_coordinate, fk_lookup))

SET timezone TO 'UTC';

-- ---------------------------------------------------------------------------
-- l_region: water supply zones / district metered areas (DMAs)
-- ---------------------------------------------------------------------------
INSERT INTO demo.l_region (name, description) VALUES
    ('Sydney Water - CBD Zone',              'Sydney Water district metered area covering the Sydney CBD, New South Wales'),
    ('Melbourne Water - Inner Metro Zone',   'Melbourne Water supply zone covering inner Melbourne, Victoria'),
    ('Unitywater - Sunshine Coast Zone',     'Unitywater district metered area covering the Sunshine Coast, Queensland'),
    ('SA Water - Adelaide Hills Zone',       'SA Water supply zone covering the Adelaide Hills, South Australia'),
    ('Water Corporation - Perth Metro Zone', 'Water Corporation district metered area covering metropolitan Perth, Western Australia'),
    ('Power and Water - Alice Springs Zone', 'Power and Water Corporation supply zone covering Alice Springs, Northern Territory')
ON CONFLICT (name) DO NOTHING;

-- ---------------------------------------------------------------------------
-- l_lookup: possible water asset / leak attribute types
-- ---------------------------------------------------------------------------
INSERT INTO demo.l_lookup (code, description) VALUES
    ('ASSET_TYPE',               'Type of water asset (water main, service connection, valve, hydrant, meter, pump station)'),
    ('PIPE_MATERIAL',            'Material the pipe is constructed from (e.g. cast iron, PVC, ductile iron, asbestos cement, copper, HDPE)'),
    ('PIPE_DIAMETER_MM',         'Nominal pipe diameter, in millimetres'),
    ('PIPE_INSTALL_YEAR',        'Year the pipe or asset was installed'),
    ('OPERATING_PRESSURE_KPA',   'Typical operating pressure, in kilopascals'),
    ('LEAK_STATUS',              'Current leak status (active leak, repaired, under investigation, no leak detected)'),
    ('LEAK_SEVERITY',            'Severity of a detected leak (minor, moderate, major, burst)'),
    ('ESTIMATED_WATER_LOSS_LPD', 'Estimated water loss from a leak, in litres per day'),
    ('LAST_INSPECTION_DATE',     'Date the asset was last inspected'),
    ('SOIL_CORROSIVITY',         'Corrosivity of the surrounding soil (low, moderate, high)'),
    ('MAINTENANCE_STATUS',       'Current maintenance status (scheduled, overdue, completed, none required)'),
    ('OWNERSHIP',                'Ownership of the asset (utility-owned or private/customer-owned)')
ON CONFLICT (code) DO NOTHING;

-- ---------------------------------------------------------------------------
-- c_coordinate: water asset locations (x = longitude, y = latitude)
-- ---------------------------------------------------------------------------
INSERT INTO demo.c_coordinate (fk_region, x, y, notes)
SELECT r.id, v.x, v.y, v.notes
FROM (VALUES
    ('Sydney Water - CBD Zone',              151.2093, -33.8688, 'Water main beneath George St, outside town hall'),
    ('Sydney Water - CBD Zone',              151.0011, -33.8151, 'Service connection, Parramatta commercial strip'),
    ('Sydney Water - CBD Zone',              151.2743, -33.8908, 'Hydrant near Bondi Beach promenade, sandy backfill'),
    ('Melbourne Water - Inner Metro Zone',   144.9631, -37.8136, 'Trunk main beneath Swanston St, shared trench with tram infrastructure'),
    ('Melbourne Water - Inner Metro Zone',   144.9800, -37.8679, 'Service connection, St Kilda foreshore precinct'),
    ('Unitywater - Sunshine Coast Zone',     153.0666, -26.6500, 'Rising main crossing Maroochy River floodplain'),
    ('Unitywater - Sunshine Coast Zone',     153.1000, -26.8000, 'Valve chamber, Mooloolaba residential estate'),
    ('SA Water - Adelaide Hills Zone',       138.7480, -34.9720, 'Pump station supplying Stirling reservoir'),
    ('SA Water - Adelaide Hills Zone',       138.8020, -34.9330, 'Service connection, Mount Lofty ridge - steep grade access'),
    ('Water Corporation - Perth Metro Zone', 115.8605, -31.9505, 'Water main beneath St Georges Terrace, Perth CBD'),
    ('Water Corporation - Perth Metro Zone', 115.7440, -32.0569, 'Meter pit, Fremantle port precinct'),
    ('Power and Water - Alice Springs Zone', 133.8807, -23.6980, 'Bore-fed main, Alice Springs town basin'),
    ('Power and Water - Alice Springs Zone', 133.8560, -23.7020, 'Service connection, Todd River floodway crossing')
) AS v(region_name, x, y, notes)
JOIN demo.l_region r ON r.name = v.region_name
ON CONFLICT (x, y) DO NOTHING;

-- ---------------------------------------------------------------------------
-- c_attribute: a small, sparse subset of coordinate/lookup combinations
-- ---------------------------------------------------------------------------
INSERT INTO demo.c_attribute (fk_coordinate, fk_lookup, value)
SELECT c.id, l.id, v.value
FROM (VALUES
    -- Sydney Water - George St water main: aging cast iron main with an active leak
    (151.2093, -33.8688, 'ASSET_TYPE',               'Water Main'),
    (151.2093, -33.8688, 'PIPE_MATERIAL',            'Cast Iron'),
    (151.2093, -33.8688, 'PIPE_DIAMETER_MM',         '300'),
    (151.2093, -33.8688, 'PIPE_INSTALL_YEAR',        '1962'),
    (151.2093, -33.8688, 'LEAK_STATUS',              'Active Leak'),
    (151.2093, -33.8688, 'LEAK_SEVERITY',            'Moderate'),
    (151.2093, -33.8688, 'ESTIMATED_WATER_LOSS_LPD', '8500'),
    (151.2093, -33.8688, 'MAINTENANCE_STATUS',       'Overdue'),

    -- Bondi Beach hydrant: no leak, recently inspected
    (151.2743, -33.8908, 'ASSET_TYPE',               'Hydrant'),
    (151.2743, -33.8908, 'LEAK_STATUS',              'No Leak Detected'),
    (151.2743, -33.8908, 'LAST_INSPECTION_DATE',     '2026-04-12'),
    (151.2743, -33.8908, 'OWNERSHIP',                'Utility-owned'),

    -- Melbourne trunk main under Swanston St: ductile iron, under investigation
    (144.9631, -37.8136, 'ASSET_TYPE',               'Water Main'),
    (144.9631, -37.8136, 'PIPE_MATERIAL',            'Ductile Iron'),
    (144.9631, -37.8136, 'PIPE_DIAMETER_MM',         '450'),
    (144.9631, -37.8136, 'OPERATING_PRESSURE_KPA',   '620'),
    (144.9631, -37.8136, 'LEAK_STATUS',              'Under Investigation'),

    -- St Kilda service connection: private-side copper pipe
    (144.9800, -37.8679, 'ASSET_TYPE',               'Service Connection'),
    (144.9800, -37.8679, 'PIPE_MATERIAL',            'Copper'),
    (144.9800, -37.8679, 'OWNERSHIP',                'Private/Customer-owned'),

    -- Maroochy River rising main: HDPE, high corrosivity floodplain soil
    (153.0666, -26.6500, 'ASSET_TYPE',               'Water Main'),
    (153.0666, -26.6500, 'PIPE_MATERIAL',            'HDPE'),
    (153.0666, -26.6500, 'SOIL_CORROSIVITY',         'High'),
    (153.0666, -26.6500, 'LEAK_STATUS',              'No Leak Detected'),

    -- Mooloolaba valve chamber: scheduled maintenance
    (153.1000, -26.8000, 'ASSET_TYPE',               'Valve'),
    (153.1000, -26.8000, 'MAINTENANCE_STATUS',       'Scheduled'),
    (153.1000, -26.8000, 'LAST_INSPECTION_DATE',     '2026-02-01'),

    -- Stirling pump station: high pressure, major burst on asbestos cement main
    (138.7480, -34.9720, 'ASSET_TYPE',               'Pump Station'),
    (138.7480, -34.9720, 'PIPE_MATERIAL',            'Asbestos Cement'),
    (138.7480, -34.9720, 'OPERATING_PRESSURE_KPA',   '780'),
    (138.7480, -34.9720, 'LEAK_STATUS',              'Active Leak'),
    (138.7480, -34.9720, 'LEAK_SEVERITY',            'Burst'),
    (138.7480, -34.9720, 'ESTIMATED_WATER_LOSS_LPD', '42000'),
    (138.7480, -34.9720, 'MAINTENANCE_STATUS',       'Overdue'),

    -- Mount Lofty service connection: steep grade, PVC, repaired leak
    (138.8020, -34.9330, 'ASSET_TYPE',               'Service Connection'),
    (138.8020, -34.9330, 'PIPE_MATERIAL',            'PVC'),
    (138.8020, -34.9330, 'LEAK_STATUS',              'Repaired'),
    (138.8020, -34.9330, 'LAST_INSPECTION_DATE',     '2026-05-20'),

    -- Perth CBD water main: steel main, minor leak
    (115.8605, -31.9505, 'ASSET_TYPE',               'Water Main'),
    (115.8605, -31.9505, 'PIPE_MATERIAL',            'Steel'),
    (115.8605, -31.9505, 'PIPE_DIAMETER_MM',         '375'),
    (115.8605, -31.9505, 'PIPE_INSTALL_YEAR',        '1978'),
    (115.8605, -31.9505, 'LEAK_STATUS',              'Active Leak'),
    (115.8605, -31.9505, 'LEAK_SEVERITY',            'Minor'),
    (115.8605, -31.9505, 'ESTIMATED_WATER_LOSS_LPD', '1200'),

    -- Fremantle meter pit: utility-owned, no leak
    (115.7440, -32.0569, 'ASSET_TYPE',               'Meter'),
    (115.7440, -32.0569, 'OWNERSHIP',                'Utility-owned'),
    (115.7440, -32.0569, 'LEAK_STATUS',              'No Leak Detected'),

    -- Alice Springs bore-fed main: PVC, moderate soil corrosivity
    (133.8807, -23.6980, 'ASSET_TYPE',               'Water Main'),
    (133.8807, -23.6980, 'PIPE_MATERIAL',            'PVC'),
    (133.8807, -23.6980, 'SOIL_CORROSIVITY',         'Moderate'),
    (133.8807, -23.6980, 'MAINTENANCE_STATUS',       'Completed'),

    -- Todd River floodway service connection: ductile iron, under investigation
    (133.8560, -23.7020, 'ASSET_TYPE',               'Service Connection'),
    (133.8560, -23.7020, 'PIPE_MATERIAL',            'Ductile Iron'),
    (133.8560, -23.7020, 'LEAK_STATUS',              'Under Investigation')
) AS v(x, y, code, value)
JOIN demo.c_coordinate c ON c.x = v.x AND c.y = v.y
JOIN demo.l_lookup l ON l.code = v.code
ON CONFLICT (fk_coordinate, fk_lookup) DO NOTHING;
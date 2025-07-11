#!/usr/bin/env bash
set -euo pipefail

# Seed some test data

echo "Seeding test data..."

kubectl exec -i postgres-0 -- psql -U apiuser -d observations <<'EOF'
-- Insert some test observations
INSERT INTO observations (vessel_id, timestamp, metric_name, metric_value, unit, metadata) VALUES
    ('vessel-001', NOW() - INTERVAL '1 hour', 'speed.over.ground', 12.5, 'knots', '{"source": "gps"}'),
    ('vessel-001', NOW() - INTERVAL '50 minutes', 'speed.over.ground', 13.2, 'knots', '{"source": "gps"}'),
    ('vessel-001', NOW() - INTERVAL '40 minutes', 'speed.over.ground', 13.8, 'knots', '{"source": "gps"}'),
    ('vessel-001', NOW() - INTERVAL '30 minutes', 'speed.over.ground', 12.9, 'knots', '{"source": "gps"}'),
    ('vessel-001', NOW() - INTERVAL '20 minutes', 'speed.over.ground', 11.5, 'knots', '{"source": "gps"}'),
    ('vessel-001', NOW() - INTERVAL '10 minutes', 'speed.over.ground', 10.2, 'knots', '{"source": "gps"}'),
    ('vessel-001', NOW() - INTERVAL '1 hour', 'water.temperature', 18.5, 'celsius', '{"sensor": "temp-01"}'),
    ('vessel-001', NOW() - INTERVAL '30 minutes', 'water.temperature', 18.8, 'celsius', '{"sensor": "temp-01"}'),
    ('vessel-001', NOW(), 'water.temperature', 19.1, 'celsius', '{"sensor": "temp-01"}'),
    ('vessel-002', NOW() - INTERVAL '45 minutes', 'speed.over.ground', 8.5, 'knots', '{"source": "gps"}'),
    ('vessel-002', NOW() - INTERVAL '15 minutes', 'speed.over.ground', 9.2, 'knots', '{"source": "gps"}'),
    ('vessel-002', NOW(), 'speed.over.ground', 9.8, 'knots', '{"source": "gps"}');

-- Insert some test aggregations
INSERT INTO aggregations (vessel_id, metric_name, window_start, window_end, min_value, max_value, avg_value, count) VALUES
    ('vessel-001', 'speed.over.ground', NOW() - INTERVAL '1 hour', NOW(), 10.2, 13.8, 12.35, 6),
    ('vessel-001', 'water.temperature', NOW() - INTERVAL '1 hour', NOW(), 18.5, 19.1, 18.8, 3),
    ('vessel-002', 'speed.over.ground', NOW() - INTERVAL '1 hour', NOW(), 8.5, 9.8, 9.17, 3);

-- Show sample data
SELECT COUNT(*) as observation_count FROM observations;
SELECT COUNT(*) as aggregation_count FROM aggregations;
SELECT * FROM latest_observations;
EOF

echo "✓ Test data seeded successfully!"
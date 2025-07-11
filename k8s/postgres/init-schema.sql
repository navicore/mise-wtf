-- Initial schema for observations database
-- This will be applied manually after postgres is running

-- Table for raw observations from SignalK
CREATE TABLE IF NOT EXISTS observations (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    vessel_id VARCHAR(255) NOT NULL,
    timestamp TIMESTAMP WITH TIME ZONE NOT NULL,
    metric_name VARCHAR(255) NOT NULL,
    metric_value DOUBLE PRECISION NOT NULL,
    unit VARCHAR(50),
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Index for efficient time-series queries
CREATE INDEX idx_observations_vessel_time ON observations(vessel_id, timestamp DESC);
CREATE INDEX idx_observations_metric_time ON observations(metric_name, timestamp DESC);

-- Table for aggregated data
CREATE TABLE IF NOT EXISTS aggregations (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    vessel_id VARCHAR(255) NOT NULL,
    metric_name VARCHAR(255) NOT NULL,
    window_start TIMESTAMP WITH TIME ZONE NOT NULL,
    window_end TIMESTAMP WITH TIME ZONE NOT NULL,
    min_value DOUBLE PRECISION,
    max_value DOUBLE PRECISION,
    avg_value DOUBLE PRECISION,
    count INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(vessel_id, metric_name, window_start, window_end)
);

-- Index for aggregation queries
CREATE INDEX idx_aggregations_vessel_window ON aggregations(vessel_id, window_start DESC);

-- View for latest observations per vessel/metric
CREATE VIEW latest_observations AS
SELECT DISTINCT ON (vessel_id, metric_name) 
    vessel_id,
    metric_name,
    timestamp,
    metric_value,
    unit
FROM observations
ORDER BY vessel_id, metric_name, timestamp DESC;
const express = require('express');
const cors = require('cors');
const { Pool } = require('pg');

const app = express();
const port = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());

// Database connection
const pool = new Pool({
  connectionString: process.env.DATABASE_URL || 'postgresql://apiuser:localdevpassword@postgres:5432/observations'
});

// Health check endpoints
app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

app.get('/ready', async (req, res) => {
  try {
    await pool.query('SELECT 1');
    res.json({ status: 'ready', database: 'connected' });
  } catch (error) {
    res.status(503).json({ status: 'not ready', error: error.message });
  }
});

// API endpoints

// Get all observations (with pagination)
app.get('/api/observations', async (req, res) => {
  try {
    const limit = parseInt(req.query.limit) || 100;
    const offset = parseInt(req.query.offset) || 0;
    const vessel_id = req.query.vessel_id;
    const metric_name = req.query.metric_name;
    
    let query = 'SELECT * FROM observations WHERE 1=1';
    const params = [];
    
    if (vessel_id) {
      params.push(vessel_id);
      query += ` AND vessel_id = $${params.length}`;
    }
    
    if (metric_name) {
      params.push(metric_name);
      query += ` AND metric_name = $${params.length}`;
    }
    
    query += ' ORDER BY timestamp DESC';
    params.push(limit, offset);
    query += ` LIMIT $${params.length - 1} OFFSET $${params.length}`;
    
    const result = await pool.query(query, params);
    res.json({
      data: result.rows,
      pagination: {
        limit,
        offset,
        count: result.rows.length
      }
    });
  } catch (error) {
    console.error('Error fetching observations:', error);
    res.status(500).json({ error: error.message });
  }
});

// Create new observation
app.post('/api/observations', async (req, res) => {
  try {
    const { vessel_id, timestamp, metric_name, metric_value, unit, metadata } = req.body;
    
    const result = await pool.query(
      `INSERT INTO observations (vessel_id, timestamp, metric_name, metric_value, unit, metadata)
       VALUES ($1, $2, $3, $4, $5, $6)
       RETURNING *`,
      [vessel_id, timestamp || new Date(), metric_name, metric_value, unit, metadata || {}]
    );
    
    res.status(201).json(result.rows[0]);
  } catch (error) {
    console.error('Error creating observation:', error);
    res.status(500).json({ error: error.message });
  }
});

// Get latest observations
app.get('/api/observations/latest', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM latest_observations');
    res.json({ data: result.rows });
  } catch (error) {
    console.error('Error fetching latest observations:', error);
    res.status(500).json({ error: error.message });
  }
});

// Get aggregations
app.get('/api/aggregations', async (req, res) => {
  try {
    const vessel_id = req.query.vessel_id;
    const metric_name = req.query.metric_name;
    const start_time = req.query.start_time;
    const end_time = req.query.end_time;
    
    let query = 'SELECT * FROM aggregations WHERE 1=1';
    const params = [];
    
    if (vessel_id) {
      params.push(vessel_id);
      query += ` AND vessel_id = $${params.length}`;
    }
    
    if (metric_name) {
      params.push(metric_name);
      query += ` AND metric_name = $${params.length}`;
    }
    
    if (start_time) {
      params.push(start_time);
      query += ` AND window_end >= $${params.length}`;
    }
    
    if (end_time) {
      params.push(end_time);
      query += ` AND window_start <= $${params.length}`;
    }
    
    query += ' ORDER BY window_start DESC';
    
    const result = await pool.query(query, params);
    res.json({ data: result.rows });
  } catch (error) {
    console.error('Error fetching aggregations:', error);
    res.status(500).json({ error: error.message });
  }
});

// Create or update aggregation
app.post('/api/aggregations', async (req, res) => {
  try {
    const { vessel_id, metric_name, window_start, window_end, min_value, max_value, avg_value, count } = req.body;
    
    const result = await pool.query(
      `INSERT INTO aggregations (vessel_id, metric_name, window_start, window_end, min_value, max_value, avg_value, count)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
       ON CONFLICT (vessel_id, metric_name, window_start, window_end)
       DO UPDATE SET min_value = $5, max_value = $6, avg_value = $7, count = $8
       RETURNING *`,
      [vessel_id, metric_name, window_start, window_end, min_value, max_value, avg_value, count]
    );
    
    res.status(201).json(result.rows[0]);
  } catch (error) {
    console.error('Error creating aggregation:', error);
    res.status(500).json({ error: error.message });
  }
});

// Get vessels
app.get('/api/vessels', async (req, res) => {
  try {
    const result = await pool.query(
      'SELECT DISTINCT vessel_id FROM observations ORDER BY vessel_id'
    );
    res.json({ data: result.rows.map(row => row.vessel_id) });
  } catch (error) {
    console.error('Error fetching vessels:', error);
    res.status(500).json({ error: error.message });
  }
});

// Get metrics
app.get('/api/metrics', async (req, res) => {
  try {
    const result = await pool.query(
      'SELECT DISTINCT metric_name FROM observations ORDER BY metric_name'
    );
    res.json({ data: result.rows.map(row => row.metric_name) });
  } catch (error) {
    console.error('Error fetching metrics:', error);
    res.status(500).json({ error: error.message });
  }
});

// Start server
app.listen(port, () => {
  console.log(`REST API server listening at http://localhost:${port}`);
  console.log('Database URL:', process.env.DATABASE_URL || 'Using default local connection');
});

// Graceful shutdown
process.on('SIGTERM', async () => {
  console.log('SIGTERM received, closing connections...');
  await pool.end();
  process.exit(0);
});
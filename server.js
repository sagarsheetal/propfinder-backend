import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import pg from 'pg';
import propertyRoutes from './routes/properties.js';
import agentRoutes from './routes/agents.js';
import { errorHandler } from './middleware/errorHandler.js';

// Load environment variables
dotenv.config();

const app = express();
const PORT = process.env.PORT || 5000;

// PostgreSQL Connection Pool
const pool = new pg.Pool({
  host: process.env.DB_HOST || 'localhost',
  port: process.env.DB_PORT || 5432,
  database: process.env.DB_NAME || 'propfinder',
  user: process.env.DB_USER || 'propfinder_user',
  password: process.env.DB_PASSWORD || 'propfinder123',
ssl: {
    rejectUnauthorized: false
  }
});

// Test database connection
pool.on('connect', () => {
  console.log('✅ Database pool connected');
});

pool.on('error', (err) => {
  console.error('❌ Database pool error:', err);
});

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Make pool available to routes
app.locals.db = pool;

// Routes
app.use('/api/properties', propertyRoutes);
app.use('/api/agents', agentRoutes);

// Health check endpoint
app.get('/api/health', async (req, res) => {
  try {
    const result = await pool.query('SELECT NOW()');
    res.json({ 
      status: 'Backend is running! ✅',
      database: 'Connected ✅',
      timestamp: result.rows[0].now
    });
  } catch (error) {
    res.status(500).json({ 
      status: 'Backend is running! ✅',
      database: 'Connection failed ❌',
      error: error.message
    });
  }
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({ error: 'Route not found' });
});

// Error handler middleware
app.use(errorHandler);

// Start server
app.listen(PORT, () => {
  console.log(`\n✅ PropFinder Backend Running!`);
  console.log(`📍 Server: http://localhost:${PORT}`);
  console.log(`🗄️  Database: ${process.env.DB_NAME || 'propfinder'}`);
  console.log(`🏥 Health Check: http://localhost:${PORT}/api/health`);
  console.log(`📍 Properties: http://localhost:${PORT}/api/properties`);
  console.log(`\nPress Ctrl+C to stop\n`);
});

export default app;

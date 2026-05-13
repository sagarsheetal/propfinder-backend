# 🗄️ PostgreSQL Database Setup Guide

## 📋 Overview

This guide will help you:
1. Install PostgreSQL on your Mac
2. Create the PropFinder database
3. Import the schema
4. Connect your backend to the database

---

## 🚀 Step 1: Install PostgreSQL on Mac

### Option A: Using Homebrew (Recommended)

```bash
# Install Homebrew if not already installed
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install PostgreSQL
brew install postgresql@15

# Start PostgreSQL service
brew services start postgresql@15

# Verify installation
psql --version
```

### Option B: Download from Official Website

Visit: https://www.postgresql.org/download/macosx/
- Download PostgreSQL installer
- Run the installer
- Follow on-screen instructions

---

## 🔧 Step 2: Create Database & User

### Open PostgreSQL Terminal

```bash
psql -U postgres
```

You should see:
```
postgres=#
```

### Create Database

In the PostgreSQL terminal, run:

```sql
-- Create database
CREATE DATABASE propfinder;

-- Create user for backend
CREATE USER propfinder_user WITH PASSWORD 'your_secure_password';

-- Give permissions
ALTER ROLE propfinder_user SET client_encoding TO 'utf8';
ALTER ROLE propfinder_user SET default_transaction_isolation TO 'read committed';
ALTER ROLE propfinder_user SET default_transaction_deferrable TO on;
ALTER ROLE propfinder_user SET default_transaction_read_only TO off;

-- Grant all privileges
GRANT ALL PRIVILEGES ON DATABASE propfinder TO propfinder_user;

-- Exit PostgreSQL
\q
```

---

## 📂 Step 3: Import the Schema

### Option A: Using Command Line

```bash
# Navigate to your backend folder
cd propfinder-backend

# Import the schema
psql -U propfinder_user -d propfinder -f database/schema.sql
```

You should see:
```
CREATE TABLE
CREATE INDEX
INSERT 0 5
...
```

### Option B: Using pgAdmin (GUI)

1. Download pgAdmin: https://www.pgadmin.org/download/
2. Open pgAdmin
3. Connect to PostgreSQL
4. Right-click on "propfinder" database
5. Select "Query Tool"
6. Copy-paste the entire schema.sql content
7. Click "Execute"

---

## 🔐 Step 4: Update Backend Configuration

### Create .env file updates

Edit your `propfinder-backend/.env` file:

```env
# Server Configuration
PORT=5000
NODE_ENV=development

# Database Configuration
DB_HOST=localhost
DB_PORT=5432
DB_NAME=propfinder
DB_USER=propfinder_user
DB_PASSWORD=your_secure_password

# API Base URL
API_URL=http://localhost:5000
```

**Important:** Replace `your_secure_password` with the password you set above!

---

## 💾 Step 5: Connect Backend to Database

### Update Backend Code

You'll need to update your `server.js` to connect to PostgreSQL.

Here's the updated server.js with database connection:

```javascript
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
  host: process.env.DB_HOST,
  port: process.env.DB_PORT,
  database: process.env.DB_NAME,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
});

// Test database connection
pool.on('connect', () => {
  console.log('✅ Database connected!');
});

pool.on('error', (err) => {
  console.error('❌ Database connection error:', err);
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
app.get('/api/health', (req, res) => {
  res.json({ 
    status: 'Backend is running! ✅',
    database: 'Connected' 
  });
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
  console.log(`🗄️ Database: Connected to ${process.env.DB_NAME}`);
  console.log(`🏥 Health Check: http://localhost:${PORT}/api/health`);
  console.log(`📍 Properties: http://localhost:${PORT}/api/properties`);
  console.log(`\nPress Ctrl+C to stop\n`);
});

export default app;
```

---

## 📦 Step 6: Install Database Driver

### Install pg (PostgreSQL client for Node.js)

```bash
cd propfinder-backend
npm install pg
```

---

## 🧪 Step 7: Test Connection

### Verify Database is Set Up

In PostgreSQL terminal:

```bash
psql -U propfinder_user -d propfinder
```

Then run:

```sql
-- View all tables
\dt

-- You should see:
-- users
-- agents
-- locations
-- properties
-- property_images
-- property_features
-- inquiries
-- property_logs

-- Count records
SELECT COUNT(*) as total_users FROM users;
SELECT COUNT(*) as total_properties FROM properties;
SELECT COUNT(*) as total_inquiries FROM inquiries;

-- Exit
\q
```

### Test Backend Connection

```bash
# Start backend
npm run dev

# In another terminal, test API
curl http://localhost:5000/api/health
```

You should see:
```json
{
  "status": "Backend is running! ✅",
  "database": "Connected"
}
```

---

## 🔍 Useful PostgreSQL Commands

```sql
-- Connect to database
psql -U propfinder_user -d propfinder

-- List all databases
\l

-- Connect to specific database
\c propfinder

-- List all tables
\dt

-- Describe a table
\d properties

-- View all data in a table
SELECT * FROM users;

-- Count records
SELECT COUNT(*) FROM properties;

-- Exit PostgreSQL
\q
```

---

## 🐛 Troubleshooting

### Problem: "Connection refused"
**Solution:**
```bash
# Check if PostgreSQL is running
brew services list

# Restart if needed
brew services restart postgresql@15
```

### Problem: "Password authentication failed"
**Solution:**
- Check .env file has correct password
- Verify user was created with correct password
- Reset password if needed:
```sql
ALTER USER propfinder_user WITH PASSWORD 'new_password';
```

### Problem: "Database does not exist"
**Solution:**
```bash
# Re-import the schema
psql -U propfinder_user -d propfinder -f database/schema.sql
```

### Problem: Backend not connecting
**Solution:**
1. Verify PostgreSQL is running
2. Check .env file has all DB settings
3. Verify database user exists
4. Check port 5432 is available

---

## 📊 Database Structure Summary

| Table | Purpose | Rows |
|-------|---------|------|
| users | User accounts | 5 sample |
| agents | Agent details | 2 sample |
| locations | Cities/localities | 4 sample |
| properties | Property listings | 3 sample |
| property_images | Property photos | 6 sample |
| property_features | Amenities | 9 sample |
| inquiries | Lead tracking | 7 sample |
| property_logs | Change history | 5 sample |

---

## ✅ Verification Checklist

- [ ] PostgreSQL installed and running
- [ ] Database "propfinder" created
- [ ] User "propfinder_user" created
- [ ] Schema imported (8 tables created)
- [ ] Sample data inserted
- [ ] .env file updated with DB credentials
- [ ] pg package installed in backend
- [ ] Backend connects to database
- [ ] Health check returns "Connected"
- [ ] Can query data from tables

---

## 🎊 You're All Set!

Your database is now ready to use! 🎉

**Next Steps:**
1. Update API controllers to use database
2. Test all endpoints
3. Deploy to production

---

## 📞 Quick Reference

```bash
# Start PostgreSQL
brew services start postgresql@15

# Check if running
brew services list

# Access PostgreSQL
psql -U propfinder_user -d propfinder

# Start backend with database
npm run dev

# Stop backend
Ctrl + C

# Stop PostgreSQL
brew services stop postgresql@15
```

---

**You're ready to use PropFinder with PostgreSQL!** 🚀

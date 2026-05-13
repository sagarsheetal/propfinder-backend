-- PropFinder Database Schema
-- PostgreSQL SQL Script
-- Created: 2026-05-12

-- ============================================
-- DROP EXISTING TABLES (if needed)
-- ============================================
-- Uncomment to reset database (WARNING: deletes all data)
/*
DROP TABLE IF EXISTS property_logs CASCADE;
DROP TABLE IF EXISTS inquiries CASCADE;
DROP TABLE IF EXISTS property_features CASCADE;
DROP TABLE IF EXISTS property_images CASCADE;
DROP TABLE IF EXISTS properties CASCADE;
DROP TABLE IF EXISTS locations CASCADE;
DROP TABLE IF EXISTS agents CASCADE;
DROP TABLE IF EXISTS users CASCADE;
*/

-- ============================================
-- 1. USERS TABLE
-- ============================================
CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  email VARCHAR(255) UNIQUE NOT NULL,
  phone VARCHAR(20) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  user_type VARCHAR(50) NOT NULL CHECK (user_type IN ('buyer', 'seller', 'agent', 'admin')),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  is_active BOOLEAN DEFAULT true
);

-- Index for faster lookups
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_phone ON users(phone);
CREATE INDEX idx_users_user_type ON users(user_type);

-- ============================================
-- 2. AGENTS TABLE
-- ============================================
CREATE TABLE agents (
  id SERIAL PRIMARY KEY,
  user_id INTEGER UNIQUE NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  agent_type VARCHAR(50) NOT NULL CHECK (agent_type IN ('individual', 'company')),
  company_name VARCHAR(255),
  license_number VARCHAR(100),
  experience_years INTEGER,
  rating DECIMAL(3, 2) DEFAULT 0 CHECK (rating >= 0 AND rating <= 5),
  total_reviews INTEGER DEFAULT 0,
  last_active_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  is_verified BOOLEAN DEFAULT false,
  
  -- Validation: company_name mandatory for company agents
  CONSTRAINT company_name_required_for_company 
    CHECK (
      (agent_type = 'individual' AND company_name IS NULL) OR
      (agent_type = 'company' AND company_name IS NOT NULL)
    )
);

-- Index for faster lookups
CREATE INDEX idx_agents_user_id ON agents(user_id);
CREATE INDEX idx_agents_agent_type ON agents(agent_type);
CREATE INDEX idx_agents_is_verified ON agents(is_verified);

-- ============================================
-- 3. LOCATIONS TABLE
-- ============================================
CREATE TABLE locations (
  id SERIAL PRIMARY KEY,
  city VARCHAR(100) NOT NULL,
  locality VARCHAR(100) NOT NULL,
  sub_locality VARCHAR(100),
  latitude DECIMAL(10, 8),
  longitude DECIMAL(11, 8),
  area_code VARCHAR(10),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  -- Ensure unique combination
  UNIQUE(city, locality, sub_locality)
);

-- Index for faster searches
CREATE INDEX idx_locations_city ON locations(city);
CREATE INDEX idx_locations_city_locality ON locations(city, locality);
CREATE INDEX idx_locations_coordinates ON locations(latitude, longitude);

-- ============================================
-- 4. PROPERTIES TABLE
-- ============================================
CREATE TABLE properties (
  id SERIAL PRIMARY KEY,
  agent_id INTEGER NOT NULL REFERENCES agents(id) ON DELETE CASCADE,
  location_id INTEGER REFERENCES locations(id) ON DELETE SET NULL,
  
  -- Basic Info
  title VARCHAR(255) NOT NULL,
  description TEXT,
  property_type VARCHAR(50) NOT NULL CHECK (property_type IN ('flat', 'apartment', 'villa', 'house', 'land', 'commercial')),
  
  -- Location
  address VARCHAR(500) NOT NULL,
  city VARCHAR(100) NOT NULL,
  locality VARCHAR(100),
  sub_locality VARCHAR(100),
  latitude DECIMAL(10, 8),
  longitude DECIMAL(11, 8),
  
  -- Property Details
  bhk INTEGER NOT NULL CHECK (bhk > 0),
  bathrooms INTEGER CHECK (bathrooms >= 0),
  built_up_area DECIMAL(10, 2) CHECK (built_up_area > 0),
  carpet_area DECIMAL(10, 2) CHECK (carpet_area > 0),
  
  -- Transaction Type
  transaction_type VARCHAR(50) NOT NULL CHECK (transaction_type IN ('buy', 'rent', 'lease')),
  price DECIMAL(15, 2) CHECK (price > 0),
  price_per_sqft DECIMAL(10, 2),
  
  -- For Rentals
  rent_per_month DECIMAL(10, 2),
  lease_years INTEGER CHECK (lease_years > 0),
  
  -- Features
  furnishing VARCHAR(50) DEFAULT 'unfurnished' CHECK (furnishing IN ('unfurnished', 'semi-furnished', 'furnished')),
  balconies INTEGER DEFAULT 0 CHECK (balconies >= 0),
  parking_spaces INTEGER DEFAULT 0 CHECK (parking_spaces >= 0),
  
  -- Status
  status VARCHAR(50) DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'sold', 'rented')),
  posted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  -- Indexes for Performance
  CONSTRAINT check_price_for_transaction_type
    CHECK (
      (transaction_type = 'buy' AND price > 0) OR
      (transaction_type IN ('rent', 'lease') AND rent_per_month > 0)
    )
);

-- Indexes for faster queries
CREATE INDEX idx_properties_city_type ON properties(city, transaction_type);
CREATE INDEX idx_properties_bhk_price ON properties(bhk, price);
CREATE INDEX idx_properties_agent_id ON properties(agent_id);
CREATE INDEX idx_properties_status ON properties(status);
CREATE INDEX idx_properties_transaction_type ON properties(transaction_type);
CREATE INDEX idx_properties_location_id ON properties(location_id);

-- ============================================
-- 5. PROPERTY_IMAGES TABLE
-- ============================================
CREATE TABLE property_images (
  id SERIAL PRIMARY KEY,
  property_id INTEGER NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
  image_url VARCHAR(500) NOT NULL,
  image_type VARCHAR(50) DEFAULT 'full' CHECK (image_type IN ('thumbnail', 'full', 'floor_plan')),
  upload_order INTEGER,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Index for faster lookups
CREATE INDEX idx_property_images_property_id ON property_images(property_id);

-- ============================================
-- 6. PROPERTY_FEATURES TABLE
-- ============================================
CREATE TABLE property_features (
  id SERIAL PRIMARY KEY,
  property_id INTEGER NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
  feature_name VARCHAR(100) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Index for faster lookups
CREATE INDEX idx_property_features_property_id ON property_features(property_id);

-- ============================================
-- 7. INQUIRIES TABLE (Lead Tracking)
-- ============================================
CREATE TABLE inquiries (
  id SERIAL PRIMARY KEY,
  property_id INTEGER NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  
  inquiry_type VARCHAR(50) NOT NULL CHECK (inquiry_type IN ('call', 'whatsapp')),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for faster lookups
CREATE INDEX idx_inquiries_property_id ON inquiries(property_id);
CREATE INDEX idx_inquiries_user_id ON inquiries(user_id);
CREATE INDEX idx_inquiries_inquiry_type ON inquiries(inquiry_type);
CREATE INDEX idx_inquiries_created_at ON inquiries(created_at);
CREATE INDEX idx_inquiries_property_user ON inquiries(property_id, user_id);

-- ============================================
-- 8. PROPERTY_LOGS TABLE (Change History)
-- ============================================
CREATE TABLE property_logs (
  id SERIAL PRIMARY KEY,
  property_id INTEGER NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
  agent_id INTEGER REFERENCES agents(id) ON DELETE SET NULL,
  admin_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
  
  change_type VARCHAR(50) NOT NULL CHECK (change_type IN ('created', 'updated', 'deleted')),
  field_name VARCHAR(100),
  old_value TEXT,
  new_value TEXT,
  description TEXT,
  changed_by VARCHAR(50) NOT NULL CHECK (changed_by IN ('agent', 'admin')),
  changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for faster lookups
CREATE INDEX idx_property_logs_property_id ON property_logs(property_id);
CREATE INDEX idx_property_logs_agent_id ON property_logs(agent_id);
CREATE INDEX idx_property_logs_changed_at ON property_logs(changed_at);
CREATE INDEX idx_property_logs_changed_by ON property_logs(changed_by);

-- ============================================
-- VIEWS (Optional - for easier queries)
-- ============================================

-- View: Active Properties with Agent Info
CREATE VIEW active_properties_with_agents AS
SELECT 
  p.id,
  p.title,
  p.city,
  p.locality,
  p.bhk,
  p.price,
  p.status,
  u.name AS agent_name,
  u.phone AS agent_phone,
  a.agent_type,
  a.company_name,
  a.rating
FROM properties p
JOIN agents a ON p.agent_id = a.id
JOIN users u ON a.user_id = u.id
WHERE p.status = 'active';

-- View: Properties with Inquiry Count
CREATE VIEW properties_with_inquiry_count AS
SELECT 
  p.id,
  p.title,
  p.city,
  COUNT(i.id) AS total_inquiries,
  SUM(CASE WHEN i.inquiry_type = 'call' THEN 1 ELSE 0 END) AS call_inquiries,
  SUM(CASE WHEN i.inquiry_type = 'whatsapp' THEN 1 ELSE 0 END) AS whatsapp_inquiries
FROM properties p
LEFT JOIN inquiries i ON p.id = i.property_id
GROUP BY p.id, p.title, p.city;

-- View: Agent Performance
CREATE VIEW agent_performance AS
SELECT 
  a.id,
  u.name,
  a.agent_type,
  a.company_name,
  COUNT(DISTINCT p.id) AS total_properties,
  COUNT(DISTINCT i.id) AS total_inquiries,
  a.rating,
  a.last_active_at
FROM agents a
JOIN users u ON a.user_id = u.id
LEFT JOIN properties p ON a.id = p.agent_id
LEFT JOIN inquiries i ON p.id = i.property_id
GROUP BY a.id, u.name, a.agent_type, a.company_name, a.rating, a.last_active_at;

-- ============================================
-- SAMPLE DATA (Optional - for testing)
-- ============================================

-- Insert sample users
INSERT INTO users (name, email, phone, password_hash, user_type) VALUES
('Rajesh Kumar', 'rajesh@propfinder.com', '+91 98765 43210', 'hashed_password_1', 'agent'),
('Priya Sharma', 'priya@propfinder.com', '+91 87654 32109', 'hashed_password_2', 'agent'),
('John Buyer', 'john@gmail.com', '+91 99999 88888', 'hashed_password_3', 'buyer'),
('Jane Smith', 'jane@gmail.com', '+91 88888 77777', 'hashed_password_4', 'buyer'),
('Admin User', 'admin@propfinder.com', '+91 77777 66666', 'hashed_password_5', 'admin');

-- Insert sample agents
INSERT INTO agents (user_id, agent_type, company_name, license_number, experience_years, last_active_at, is_verified) VALUES
(1, 'individual', NULL, 'LIC001', 5, CURRENT_TIMESTAMP, true),
(2, 'company', 'PropMaster Realty', 'LIC002', 8, CURRENT_TIMESTAMP, true);

-- Insert sample locations
INSERT INTO locations (city, locality, sub_locality, latitude, longitude, area_code) VALUES
('Bangalore', 'Koramangala', 'Block 1', 12.9352, 77.6245, '560034'),
('Bangalore', 'Koramangala', 'Block 2', 12.9360, 77.6250, '560034'),
('Bangalore', 'Indiranagar', '100 Feet Road', 12.9716, 77.6412, '560038'),
('Bangalore', 'Whitefield', 'ITPL Road', 12.9698, 77.7499, '560066');

-- Insert sample properties
INSERT INTO properties (
  agent_id, location_id, title, description, property_type,
  address, city, locality, sub_locality, bhk, bathrooms,
  built_up_area, carpet_area, transaction_type, price,
  price_per_sqft, furnishing, balconies, parking_spaces,
  status, posted_at, updated_at
) VALUES
(
  1, 1,
  '3 BHK Flat for Sale in Koramangala',
  'Spacious 3BHK flat with modern amenities',
  'flat',
  '123 Main Street, Koramangala',
  'Bangalore', 'Koramangala', 'Block 1',
  3, 3, 1850.50, 1650.75,
  'buy', 2200000.00, 11891.00,
  'furnished', 2, 1,
  'active', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
),
(
  1, 3,
  '2 BHK Apartment for Rent in Indiranagar',
  'Well-maintained 2BHK with all amenities',
  'apartment',
  '456 Park Avenue, Indiranagar',
  'Bangalore', 'Indiranagar', '100 Feet Road',
  2, 2, 1200.00, 1000.00,
  'rent', NULL, NULL,
  'active', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
),
(
  2, 4,
  '4 BHK Villa for Sale in Whitefield',
  'Luxury villa with garden and pool',
  'villa',
  '789 Tech Park, Whitefield',
  'Bangalore', 'Whitefield', 'ITPL Road',
  4, 4, 3200.00, 2800.00,
  'buy', 3800000.00, 11875.00,
  'unfurnished', 3, 2,
  'active', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);

-- Insert sample property images
INSERT INTO property_images (property_id, image_url, image_type, upload_order) VALUES
(1, 'https://cloudinary.com/property1_img1.jpg', 'thumbnail', 1),
(1, 'https://cloudinary.com/property1_img2.jpg', 'full', 2),
(1, 'https://cloudinary.com/property1_img3.jpg', 'full', 3),
(2, 'https://cloudinary.com/property2_img1.jpg', 'thumbnail', 1),
(2, 'https://cloudinary.com/property2_img2.jpg', 'full', 2),
(3, 'https://cloudinary.com/property3_img1.jpg', 'thumbnail', 1);

-- Insert sample property features
INSERT INTO property_features (property_id, feature_name) VALUES
(1, 'Gym'),
(1, 'Swimming Pool'),
(1, 'Garden'),
(1, 'Security'),
(2, 'Parking'),
(2, 'Lift'),
(3, 'Pool'),
(3, 'Garden'),
(3, 'Security Guard');

-- Insert sample inquiries
INSERT INTO inquiries (property_id, user_id, inquiry_type) VALUES
(1, 3, 'call'),
(1, 3, 'whatsapp'),
(2, 4, 'call'),
(1, 4, 'whatsapp'),
(3, 3, 'call'),
(2, 3, 'whatsapp'),
(3, 4, 'call');

-- Insert sample property logs
INSERT INTO property_logs (
  property_id, agent_id, change_type, field_name,
  old_value, new_value, description, changed_by
) VALUES
(1, 1, 'created', NULL, NULL, NULL, 'Property created by agent', 'agent'),
(1, 1, 'updated', 'price', '2300000', '2200000', 'Price reduced', 'agent'),
(2, 1, 'created', NULL, NULL, NULL, 'Property created by agent', 'agent'),
(3, 2, 'created', NULL, NULL, NULL, 'Property created by agent', 'agent'),
(3, 2, 'updated', 'description', 'Old description', 'Luxury villa with garden and pool', 'Description updated', 'agent');

-- ============================================
-- FINAL VERIFICATION
-- ============================================
-- Run these queries to verify setup:
/*
SELECT COUNT(*) as total_users FROM users;
SELECT COUNT(*) as total_agents FROM agents;
SELECT COUNT(*) as total_properties FROM properties;
SELECT COUNT(*) as total_inquiries FROM inquiries;
SELECT COUNT(*) as total_logs FROM property_logs;

SELECT * FROM active_properties_with_agents;
SELECT * FROM properties_with_inquiry_count;
SELECT * FROM agent_performance;
*/

-- ============================================
-- END OF SCHEMA SETUP
-- ============================================

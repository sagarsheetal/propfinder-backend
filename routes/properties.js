import express from 'express';
import {
  getProperties,
  getPropertyById,
  addProperty,
} from '../controllers/propertyController.js';

const router = express.Router();

// GET all properties with optional filters
// Example: /api/properties?location=Bangalore&bhk=2%20BHK&type=buy&budget=40-80L
router.get('/', getProperties);

// GET single property by ID
// Example: /api/properties/1
router.get('/:id', getPropertyById);

// POST add new property (for agents)
// Body: { title, location, bhk, type, price, pricePerSqft, area, bathrooms, furnishing, balconies, agentId, images }
router.post('/', addProperty);

export default router;

import express from 'express';
import {
  getAgentById,
  getAllAgents,
} from '../controllers/agentController.js';

const router = express.Router();

// GET all agents
// Example: /api/agents
router.get('/', getAllAgents);

// GET single agent by ID
// Example: /api/agents/1
router.get('/:id', getAgentById);

export default router;

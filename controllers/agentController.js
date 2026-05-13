// Get all agents
export const getAllAgents = async (req, res) => {
  try {
    const result = await req.app.locals.db.query(
      `SELECT a.id, a.user_id, a.agent_type, a.company_name, a.license_number,
              a.experience_years, a.rating, a.total_reviews, a.last_active_at,
              u.name, u.phone, u.email
       FROM agents a
       JOIN users u ON a.user_id = u.id
       WHERE a.is_verified = true
       ORDER BY a.rating DESC`
    );

    res.json({
      success: true,
      count: result.rows.length,
      data: result.rows,
    });
  } catch (error) {
    console.error('❌ Error fetching agents:', error);
    res.status(500).json({ 
      success: false,
      error: error.message 
    });
  }
};

// Get agent details by ID with properties and inquiries
export const getAgentById = async (req, res) => {
  try {
    const { id } = req.params;

    // Get agent details
    const agentResult = await req.app.locals.db.query(
      `SELECT a.id, a.user_id, a.agent_type, a.company_name, a.license_number,
              a.experience_years, a.rating, a.total_reviews, a.last_active_at,
              a.created_at, u.name, u.phone, u.email
       FROM agents a
       JOIN users u ON a.user_id = u.id
       WHERE a.id = $1`,
      [id]
    );

    if (agentResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'Agent not found',
      });
    }

    const agent = agentResult.rows[0];

    // Get agent's properties
    const propertiesResult = await req.app.locals.db.query(
      `SELECT id, title, city, locality, bhk, price, transaction_type, status
       FROM properties
       WHERE agent_id = $1 AND status = 'active'
       ORDER BY posted_at DESC`,
      [id]
    );

    // Get inquiries for agent's properties
    const inquiriesResult = await req.app.locals.db.query(
      `SELECT COUNT(*) as total_inquiries,
              SUM(CASE WHEN inquiry_type = 'call' THEN 1 ELSE 0 END) as call_inquiries,
              SUM(CASE WHEN inquiry_type = 'whatsapp' THEN 1 ELSE 0 END) as whatsapp_inquiries
       FROM inquiries i
       JOIN properties p ON i.property_id = p.id
       WHERE p.agent_id = $1`,
      [id]
    );

    agent.properties = propertiesResult.rows;
    agent.inquiries = inquiriesResult.rows[0] || {
      total_inquiries: 0,
      call_inquiries: 0,
      whatsapp_inquiries: 0
    };

    res.json({
      success: true,
      data: agent,
    });
  } catch (error) {
    console.error('❌ Error fetching agent:', error);
    res.status(500).json({ 
      success: false,
      error: error.message 
    });
  }
};

// Update agent's last_active_at timestamp
export const updateAgentActivity = async (req, res) => {
  try {
    const { id } = req.params;

    const result = await req.app.locals.db.query(
      `UPDATE agents SET last_active_at = CURRENT_TIMESTAMP WHERE id = $1 RETURNING *`,
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'Agent not found',
      });
    }

    res.json({
      success: true,
      message: 'Agent activity updated',
      data: result.rows[0],
    });
  } catch (error) {
    console.error('❌ Error updating agent activity:', error);
    res.status(500).json({ 
      success: false,
      error: error.message 
    });
  }
};

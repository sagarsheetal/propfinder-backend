// Get all properties with filters
export const getProperties = async (req, res) => {
  try {
    const { location, bhk, budget, type } = req.query;

    let query = 'SELECT * FROM properties WHERE 1=1';
    const params = [];
    let paramCount = 1;

    // Filter by type
    if (type) {
      query += ` AND transaction_type = $${paramCount}`;
      params.push(type);
      paramCount++;
    }

    // Filter by location
    if (location) {
      query += ` AND city ILIKE $${paramCount}`;
      params.push(`%${location}%`);
      paramCount++;
    }

    // Filter by BHK
    if (bhk) {
      query += ` AND bhk = $${paramCount}`;
      params.push(parseInt(bhk));
      paramCount++;
    }

    // Filter by budget
    if (budget) {
      const buyRanges = {
        '0-40L': { min: 0, max: 4000000 },
        '40-80L': { min: 4000000, max: 8000000 },
        '80L-1.2Cr': { min: 8000000, max: 12000000 },
        '1.2-2Cr': { min: 12000000, max: 20000000 },
        '2-3Cr': { min: 20000000, max: 30000000 },
        '3Cr+': { min: 30000000, max: Infinity },
      };

      const rentRanges = {
        '0-20K': { min: 0, max: 20000 },
        '20-30K': { min: 20000, max: 30000 },
        '30-40K': { min: 30000, max: 40000 },
        '40-60K': { min: 40000, max: 60000 },
        '60K-1L': { min: 60000, max: 100000 },
        '1-1.5L': { min: 100000, max: 150000 },
        '1.5L+': { min: 150000, max: Infinity },
      };

      const ranges = type === 'rent' ? rentRanges : buyRanges;
      const range = ranges[budget];

      if (range) {
        if (type === 'rent') {
          query += ` AND rent_per_month >= $${paramCount} AND rent_per_month <= $${paramCount + 1}`;
        } else {
          query += ` AND price >= $${paramCount} AND price <= $${paramCount + 1}`;
        }
        params.push(range.min, range.max);
        paramCount += 2;
      }
    }

    query += ' ORDER BY posted_at DESC';

    const result = await req.app.locals.db.query(query, params);

    // For each property, fetch images and features
    const properties = await Promise.all(
      result.rows.map(async (property) => {
        const imagesResult = await req.app.locals.db.query(
          'SELECT * FROM property_images WHERE property_id = $1 ORDER BY upload_order',
          [property.id]
        );

        const featuresResult = await req.app.locals.db.query(
          'SELECT feature_name FROM property_features WHERE property_id = $1',
          [property.id]
        );

        const agentResult = await req.app.locals.db.query(
          `SELECT a.id, a.agent_type, a.company_name, u.name, u.phone 
           FROM agents a 
           JOIN users u ON a.user_id = u.id 
           WHERE a.id = $1`,
          [property.agent_id]
        );

        property.images = imagesResult.rows;
        property.features = featuresResult.rows.map(f => f.feature_name);
        property.agent = agentResult.rows[0] || null;

        return property;
      })
    );

    res.json({
      success: true,
      count: properties.length,
      data: properties,
    });
  } catch (error) {
    console.error('❌ Error fetching properties:', error);
    res.status(500).json({ 
      success: false,
      error: error.message 
    });
  }
};

// Get single property details
export const getPropertyById = async (req, res) => {
  try {
    const { id } = req.params;
    
    const propertyResult = await req.app.locals.db.query(
      'SELECT * FROM properties WHERE id = $1',
      [id]
    );

    if (propertyResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'Property not found',
      });
    }

    const property = propertyResult.rows[0];

    // Get images
    const imagesResult = await req.app.locals.db.query(
      'SELECT * FROM property_images WHERE property_id = $1 ORDER BY upload_order',
      [id]
    );

    // Get features
    const featuresResult = await req.app.locals.db.query(
      'SELECT feature_name FROM property_features WHERE property_id = $1',
      [id]
    );

    // Get agent info
    const agentResult = await req.app.locals.db.query(
      `SELECT a.id, a.agent_type, a.company_name, u.name, u.phone 
       FROM agents a 
       JOIN users u ON a.user_id = u.id 
       WHERE a.id = $1`,
      [property.agent_id]
    );

    property.images = imagesResult.rows;
    property.features = featuresResult.rows.map(f => f.feature_name);
    property.agent = agentResult.rows[0] || null;

    res.json({
      success: true,
      data: property,
    });
  } catch (error) {
    console.error('❌ Error fetching property:', error);
    res.status(500).json({ 
      success: false,
      error: error.message 
    });
  }
};

// Add new property (for agents)
export const addProperty = async (req, res) => {
  try {
    const {
      agent_id,
      location_id,
      title,
      description,
      property_type,
      address,
      city,
      locality,
      sub_locality,
      bhk,
      bathrooms,
      built_up_area,
      carpet_area,
      transaction_type,
      price,
      price_per_sqft,
      rent_per_month,
      furnishing,
      balconies,
      parking_spaces,
      images,
    } = req.body;

    // Validation
    if (!title || !address || !city || !bhk || !transaction_type || !agent_id) {
      return res.status(400).json({
        success: false,
        error: 'Missing required fields',
      });
    }

    // Insert property
    const result = await req.app.locals.db.query(
      `INSERT INTO properties (
        agent_id, location_id, title, description, property_type,
        address, city, locality, sub_locality, bhk, bathrooms,
        built_up_area, carpet_area, transaction_type, price,
        price_per_sqft, rent_per_month, furnishing, balconies,
        parking_spaces, status, posted_at, updated_at
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20, $21, $22, $23)
      RETURNING *`,
      [
        agent_id, location_id, title, description, property_type,
        address, city, locality, sub_locality, bhk, bathrooms,
        built_up_area || 0, carpet_area || 0, transaction_type, price || null,
        price_per_sqft || null, rent_per_month || null, furnishing || 'unfurnished',
        balconies || 0, parking_spaces || 0, 'active',
        new Date(), new Date()
      ]
    );

    const newProperty = result.rows[0];

    // Insert images if provided
    if (images && Array.isArray(images)) {
      for (let i = 0; i < images.length; i++) {
        await req.app.locals.db.query(
          `INSERT INTO property_images (property_id, image_url, image_type, upload_order)
           VALUES ($1, $2, $3, $4)`,
          [newProperty.id, images[i], 'full', i + 1]
        );
      }
    }

    // Log the creation
    await req.app.locals.db.query(
      `INSERT INTO property_logs (property_id, agent_id, change_type, description, changed_by)
       VALUES ($1, $2, $3, $4, $5)`,
      [newProperty.id, agent_id, 'created', 'Property created by agent', 'agent']
    );

    res.status(201).json({
      success: true,
      message: 'Property added successfully',
      data: newProperty,
    });
  } catch (error) {
    console.error('❌ Error adding property:', error);
    res.status(500).json({ 
      success: false,
      error: error.message 
    });
  }
};
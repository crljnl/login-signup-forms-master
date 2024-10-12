const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
const { Pool } = require('pg');

// Create an instance of Express
const app = express();
const port = 3000;

// Middleware setup
app.use(bodyParser.json());
app.use(cors());

// PostgreSQL connection pool setup
const pool = new Pool({
  user: 'postgres',
  host: 'localhost', // Update this as needed
  database: 'MTOP',
  password: 'password',
  port: 5432,
});

// Route to verify the server is running
app.get('/', (req, res) => {
  res.send('Server is running');
});

// Login route
app.post('/login', async (req, res) => {
  const { email, password } = req.body;

  try {
    const result = await pool.query('SELECT * FROM inspectors WHERE email = $1 AND password = $2', [email, password]);

    if (result.rows.length === 0) {
      return res.status(401).json({ message: 'Invalid credentials' });
    }

    const user = result.rows[0];
    return res.status(200).json({
      message: 'Login successful',
      user: {
        id: user.id,
        inspector_id: user.inspector_id,  // Return inspector_id for validation
        name: user.name,
        email: user.email,
      },
    });
  } catch (err) {
    console.error('Error during login process:', err);
    return res.status(500).json({ message: 'Internal server error' });
  }
});

// Register route
app.post('/register', async (req, res) => {
  const { email, password, name } = req.body;

  try {
    const result = await pool.query('SELECT * FROM inspectors WHERE email = $1', [email]);

    if (result.rows.length > 0) {
      return res.status(400).json({ message: 'User already exists' });
    }

    await pool.query('INSERT INTO inspectors (email, password, name) VALUES ($1, $2, $3)', [email, password, name]);
    return res.status(201).json({ message: 'User registered successfully' });
  } catch (err) {
    console.error('Error during registration process:', err);
    return res.status(500).json({ message: 'Internal server error' });
  }
});

// Route to fetch all valid inspector IDs
app.get('/inspectors', async (req, res) => {
  try {
    const result = await pool.query('SELECT inspector_id FROM inspectors');
    res.status(200).json(result.rows);  // Return the list of inspector IDs
  } catch (error) {
    console.error('Error fetching inspectors:', error);
    res.status(500).json({ message: 'Error fetching inspector data' });
  }
});

// Route to fetch inspection details for renewal
app.get('/inspection/:mtop_id', async (req, res) => {
  const { mtop_id } = req.params;

  try {
    const inspectionResult = await pool.query('SELECT * FROM inspections WHERE mtop_id = $1', [mtop_id]);

    if (inspectionResult.rows.length === 0) {
      return res.status(404).json({ message: 'Inspection not found' });
    }

    const inspection = inspectionResult.rows[0];
    res.status(200).json(inspection); // Return inspection details for renewal
  } catch (error) {
    console.error('Error fetching inspection:', error);
    res.status(500).json({ error: 'Failed to fetch inspection', details: error.message });
  }
});

// Route for adding or updating an inspection (new or renewal)
app.post('/add-inspection', async (req, res) => {
  const {
    inspector_id, applicant_name, mtop_id, vehicle_type, registration_type,
    side_mirror, signal_lights, taillights, motor_number, garbage_can,
    chassis_number, vehicle_registration, not_open_pipe, light_in_sidecar, inspection_status, reason_not_approved
  } = req.body;

  try {
    // Ensure MTOP ID is exactly 6 characters long
    if (mtop_id.length !== 6) {
      return res.status(400).json({ message: 'MTOP ID must be exactly 6 characters' });
    }

    // Check if the inspection already exists (for renewal)
    const existingInspection = await pool.query('SELECT * FROM inspections WHERE mtop_id = $1', [mtop_id]);

    if (existingInspection.rows.length > 0) {
      // Update existing inspection for renewal
      await pool.query(
        `UPDATE inspections 
        SET inspector_id = $1, applicant_name = $2, vehicle_type = $3, registration_type = $4, 
        side_mirror = $5, signal_lights = $6, taillights = $7, motor_number = $8, garbage_can = $9, 
        chassis_number = $10, vehicle_registration = $11, not_open_pipe = $12, light_in_sidecar = $13,
        inspection_status = $14, reason_not_approved = $15
        WHERE mtop_id = $16`,
        [
          inspector_id, applicant_name, vehicle_type, registration_type,
          side_mirror, signal_lights, taillights, motor_number, garbage_can,
          chassis_number, vehicle_registration, not_open_pipe, light_in_sidecar, inspection_status, reason_not_approved, mtop_id
        ]
      );
      res.status(200).json({ message: 'Inspection updated successfully' });
    } else {
      // Insert a new inspection
      const inspectionResult = await pool.query(
        `INSERT INTO inspections 
        (mtop_id, inspector_id, applicant_name, vehicle_type, registration_type, 
        side_mirror, signal_lights, taillights, motor_number, garbage_can, 
        chassis_number, vehicle_registration, not_open_pipe, light_in_sidecar, inspection_status, reason_not_approved)
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16)
        RETURNING mtop_id`,
        [
          mtop_id, inspector_id, applicant_name, vehicle_type, registration_type, 
          side_mirror, signal_lights, taillights, motor_number, garbage_can, 
          chassis_number, vehicle_registration, not_open_pipe, light_in_sidecar, inspection_status, reason_not_approved
        ]
      );

      res.status(200).json({ message: 'Inspection added successfully', mtop_id: inspectionResult.rows[0].mtop_id });
    }

  } catch (error) {
    console.error('Error adding or updating inspection:', error);
    res.status(500).json({ error: 'Failed to add or update inspection', details: error.message });
  }
});

// Start the server
app.listen(port, '0.0.0.0', () => {
  console.log(`Server running on port ${port}`);
});

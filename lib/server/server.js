const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
const { Pool } = require('pg');
const multer = require('multer');
const path = require('path');
const fs = require('fs');

// Create an instance of Express
const app = express();
const port = 3000;

// Define base uploads directory
const baseUploadDir = path.join(__dirname, 'uploads');

// Ensure the base uploads directory exists
if (!fs.existsSync(baseUploadDir)) {
  fs.mkdirSync(baseUploadDir, { recursive: true });
}

// Middleware setup
app.use(bodyParser.json());
app.use(cors());
app.use('/uploads', express.static(baseUploadDir));

// PostgreSQL connection pool setup
const pool = new Pool({
  user: 'postgres',
  host: 'localhost', // Update this as needed
  database: 'MTOP',
  password: 'password',
  port: 5432,
});

// Helper function to ensure directory existence
const ensureDirectoryExistence = (dir) => {
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
};

// Set up multer for file uploads with separate directories for each document type
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    const mtop_id = req.body.mtop_id;
    const documentType = file.fieldname; // e.g., barangay_clearance, police_clearance, etc.
    const uploadDir = path.join(baseUploadDir, documentType, mtop_id);

    ensureDirectoryExistence(uploadDir);
    cb(null, uploadDir); // Use the specific uploads directory for this document type
  },
  filename: function (req, file, cb) {
    const mtop_id = req.body.mtop_id;
    const ext = path.extname(file.originalname);
    cb(null, `${mtop_id}-${file.fieldname}-${Date.now()}${ext}`);
  }
});

const upload = multer({
  storage: storage,
  limits: { fileSize: 10 * 1024 * 1024 }, // Limit file size to 10MB
  fileFilter: (req, file, cb) => {
    const allowedTypes = ['image/jpeg', 'image/png', 'image/jpg'];
    if (!allowedTypes.includes(file.mimetype)) {
      return cb(new Error('Only JPEG and PNG files are allowed'));
    }
    cb(null, true);
  }
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
    const result = await pool.query('SELECT * FROM inspections WHERE mtop_id = $1', [mtop_id]);

    if (result.rows.length === 0) {
      return res.status(404).json({ message: 'MTOP ID not found' });
    }

    res.status(200).json(result.rows[0]); // Return inspection details if found
  } catch (error) {
    console.error('Error fetching MTOP ID:', error);
    res.status(500).json({ error: 'Failed to fetch MTOP ID' });
  }
});

// Route to check if documents for the MTOP ID are already submitted
app.get('/check-submission/:mtop_id', async (req, res) => {
  const { mtop_id } = req.params;

  try {
    const result = await pool.query('SELECT * FROM scandocuments WHERE mtop_id = $1', [mtop_id]);

    if (result.rows.length > 0) {
      return res.status(200).send('submitted');
    } else {
      return res.status(200).send('not submitted');
    }
  } catch (error) {
    console.error('Error checking document submission:', error);
    res.status(500).json({ error: 'Failed to check submission', details: error.message });
  }
});

// Route to upload images from ScanDocumentScreen
app.post('/upload-documents', upload.fields([
  { name: 'barangay_clearance', maxCount: 1 },
  { name: 'police_clearance', maxCount: 1 },
  { name: 'sss_certificate', maxCount: 1 },
  { name: 'philhealth_certificate', maxCount: 1 },
  { name: 'applicant_fee', maxCount: 1 },
  { name: 'certificate_of_registration', maxCount: 1 },
  { name: 'drivers_license', maxCount: 1 }
]), async (req, res) => {
  const { mtop_id } = req.body;

  try {
    const files = req.files;

    if (!files) {
      return res.status(400).json({ message: 'No files uploaded' });
    }

    // Insert the document paths into the scandocuments table
    await pool.query(
      `INSERT INTO scandocuments 
      (mtop_id, barangay_clearance, police_clearance, sss_certificate, philhealth_certificate, applicant_fee, certificate_of_registration, drivers_license) 
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
      [
        mtop_id,
        files.barangay_clearance ? files.barangay_clearance[0].path : null,
        files.police_clearance ? files.police_clearance[0].path : null,
        files.sss_certificate ? files.sss_certificate[0].path : null,
        files.philhealth_certificate ? files.philhealth_certificate[0].path : null,
        files.applicant_fee ? files.applicant_fee[0].path : null,
        files.certificate_of_registration ? files.certificate_of_registration[0].path : null,
        files.drivers_license ? files.drivers_license[0].path : null
      ]
    );
    
    res.status(200).json({ message: 'Documents uploaded successfully' });
  } catch (error) {
    console.error('Error uploading documents:', error);
    res.status(500).json({ message: 'Failed to upload documents', error: error.message });
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

// Route for generating reports
app.get('/reports', async (req, res) => {
  try {
    // Get total number of inspections
    const totalInspectionsResult = await pool.query('SELECT COUNT(DISTINCT mtop_id) AS count FROM inspections');
    const totalInspections = parseInt(totalInspectionsResult.rows[0].count, 10);

    // Get the count of Approved and Not Approved inspections
    const statusCountResult = await pool.query(`
      SELECT inspection_status, COUNT(DISTINCT mtop_id) AS count 
      FROM inspections 
      GROUP BY inspection_status
    `);

    const statusCounts = statusCountResult.rows.reduce((acc, row) => {
      acc[row.inspection_status] = parseInt(row.count, 10);
      return acc;
    }, {});

    const approvedCount = statusCounts['Approved'] || 0;
    const notApprovedCount = statusCounts['Not Approved'] || 0;

    // Get the most common reasons for not approved inspections
    const reasonResult = await pool.query(`
      SELECT unnest(string_to_array(reason_not_approved, ',')) AS reason, COUNT(*) AS count
      FROM inspections
      WHERE reason_not_approved IS NOT NULL
      GROUP BY reason
      ORDER BY count DESC
      LIMIT 5
    `);

    const mostCommonReasons = reasonResult.rows.map(row => ({
      reason: row.reason.trim(),
      count: row.count
    }));

    // Return the aggregated report data
    res.json({
      totalInspections,
      mostCommonReasons,  // Return the list of common reasons
      approvedCount,
      notApprovedCount,
    });
  } catch (error) {
    console.error('Error fetching report data:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
});


// Start the server
app.listen(port, '0.0.0.0', () => {
  console.log(`Server running on port ${port}`);
});

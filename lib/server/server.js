const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
const { Pool } = require('pg');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const sharp = require('sharp');



// Create an instance of Express
const app = express();
const port = 3000;

const baseUploadDir = 'C:\\Users\\Andrei Luna\\Documents\\MTOP Documents';
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
  user: 'MTOPandOccupationalPermit_owner',
  host: 'ep-crimson-mode-a5iqjgor.us-east-2.aws.neon.tech', // Update this as needed
  database: 'MTOPandOccupationalPermit',
  password: 'v3yCDOfH5mAG',
  port: 5432,
  ssl: {
    rejectUnauthorized: false, 
  }
});


// Set up multer for file uploads with separate directories for each document type
const ensureDirectoryExistence = (dirPath) => {
  if (!fs.existsSync(dirPath)) {
    fs.mkdirSync(dirPath, { recursive: true });
  }
};

// Function to compress images
const compressImage = async (filePath, maxSizeMB) => {
  const maxSizeBytes = maxSizeMB * 1024 * 1024; // Convert MB to bytes

  const compressedBuffer = await sharp(filePath)
    .resize({ width: 1024, height: 1024, fit: 'inside' }) // Resize the image if needed
    .toBuffer();

  // If the compressed image size is still larger than the limit, re-compress with lower quality
  if (compressedBuffer.length > maxSizeBytes) {
    return sharp(compressedBuffer)
      .jpeg({ quality: 80 }) // Adjust quality to reduce size
      .toBuffer();
  }

  return compressedBuffer;
};

// Function to process and compress each file
const processFile = async (file) => {
  if (!file) return { binary: null, filePath: null };

  const filePath = file.path;

  try {
    // Compress the image
    const compressedImage = await compressImage(filePath, 2); // Compress to max 2MB
    return { binary: compressedImage, filePath };
  } catch (error) {
    console.error(`Error compressing image ${filePath}:`, error);
    throw new Error(`Failed to process file: ${file.originalname}`);
  }
};

// Configure Multer storage
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    const mtop_id = req.body.mtop_id;
    const documentType = file.fieldname;

    // Create directory path: baseUploadDir/documentType/mtop_id
    const uploadDir = path.join(baseUploadDir, documentType, mtop_id);

    // Ensure the directory exists
    ensureDirectoryExistence(uploadDir);

    cb(null, uploadDir);
  },
  filename: function (req, file, cb) {
    const mtop_id = req.body.mtop_id;
    const ext = path.extname(file.originalname); // Get the file extension
    const timestamp = Date.now(); // Unique timestamp for filename

    cb(null, `${mtop_id}-${file.fieldname}-${timestamp}${ext}`);
  },
});

// Multer configuration
const upload = multer({
  storage: storage,
  limits: { fileSize: 10 * 1024 * 1024 }, // Limit file size to 10MB before processing
  fileFilter: (req, file, cb) => {
    const allowedTypes = ['image/jpeg', 'image/png', 'image/jpg'];
    if (!allowedTypes.includes(file.mimetype)) {
      return cb(new Error('Only JPEG and PNG files are allowed'));
    }
    cb(null, true);
  },
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

// Route to add a new inspection
app.post('/add-inspection', async (req, res) => {
  const {
    inspector_id,
    applicant_name,
    mtop_id,
    vehicle_type,
    registration_type,
    town,
    side_mirror,
    signal_lights,
    taillights,
    motor_number,
    garbage_can,
    chassis_number,
    vehicle_registration,
    not_open_pipe,
    light_in_sidecar,
    inspection_status,
    reason_not_approved,
  } = req.body;

  try {
    // Check if the mtop_id already exists
    const existingInspection = await pool.query(
      'SELECT * FROM inspections WHERE mtop_id = $1',
      [mtop_id]
    );

    if (existingInspection.rows.length > 0) {
      if (registration_type === 'New') {
        // If registration type is New and mtop_id exists, return an error
        return res.status(409).json({
          message: 'MTOP ID already exists. Please use a unique MTOP ID for new registrations.',
        });
      } else if (registration_type === 'Renewal') {
        // If registration type is Renewal, update the existing record
        await pool.query(
          `UPDATE inspections SET
            inspector_id = $1,
            applicant_name = $2,
            vehicle_type = $3,
            registration_type = $4,
            town = $5,
            side_mirror = $6,
            signal_lights = $7,
            taillights = $8,
            motor_number = $9,
            garbage_can = $10,
            chassis_number = $11,
            vehicle_registration = $12,
            not_open_pipe = $13,
            light_in_sidecar = $14,
            inspection_status = $15,
            reason_not_approved = $16
          WHERE mtop_id = $17`,
          [
            inspector_id,
            applicant_name,
            vehicle_type,
            registration_type,
            town,
            side_mirror,
            signal_lights,
            taillights,
            motor_number,
            garbage_can,
            chassis_number,
            vehicle_registration,
            not_open_pipe,
            light_in_sidecar,
            inspection_status,
            reason_not_approved,
            mtop_id,
          ]
        );

        return res.status(200).json({ message: 'Inspection updated successfully.' });
      }
    }

    // Insert a new record if mtop_id does not exist
    await pool.query(
      `INSERT INTO inspections (
        inspector_id, applicant_name, mtop_id, vehicle_type, 
        registration_type, town, side_mirror, signal_lights, 
        taillights, motor_number, garbage_can, chassis_number, 
        vehicle_registration, not_open_pipe, light_in_sidecar, 
        inspection_status, reason_not_approved
      ) VALUES (
        $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17
      )`,
      [
        inspector_id,
        applicant_name,
        mtop_id,
        vehicle_type,
        registration_type,
        town,
        side_mirror,
        signal_lights,
        taillights,
        motor_number,
        garbage_can,
        chassis_number,
        vehicle_registration,
        not_open_pipe,
        light_in_sidecar,
        inspection_status,
        reason_not_approved,
      ]
    );

    res.status(201).json({ message: 'Inspection added successfully.' });
  } catch (error) {
    console.error('Error adding or updating inspection:', error);
    res.status(500).json({ message: 'Failed to add or update inspection', error: error.message });
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
    const result = await pool.query('SELECT * FROM scandocu WHERE mtop_id = $1', [mtop_id]);

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

// Route to upload images from scandocucreen
app.get('/check-submission/:mtop_id', async (req, res) => {
  const { mtop_id } = req.params;

  try {
    const result = await pool.query('SELECT * FROM scandocu WHERE mtop_id = $1', [mtop_id]);

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

// Upload documents route
app.post(
  '/upload-documents',
  upload.fields([
    { name: 'barangay_clearance', maxCount: 1 },
    { name: 'police_clearance', maxCount: 1 },
    { name: 'sss_certificate', maxCount: 1 },
    { name: 'philhealth_certificate', maxCount: 1 },
    { name: 'applicant_fee', maxCount: 1 },
    { name: 'certificate_of_registration', maxCount: 1 },
    { name: 'drivers_license', maxCount: 1 },
  ]),
  async (req, res) => {
    const { mtop_id } = req.body;

    try {
      const files = req.files;

      if (!files) {
        return res.status(400).json({ message: 'No files uploaded' });
      }

      // Process each uploaded file
      const barangayClearance = await processFile(files.barangay_clearance ? files.barangay_clearance[0] : null);
      const policeClearance = await processFile(files.police_clearance ? files.police_clearance[0] : null);
      const sssCertificate = await processFile(files.sss_certificate ? files.sss_certificate[0] : null);
      const philhealthCertificate = await processFile(files.philhealth_certificate ? files.philhealth_certificate[0] : null);
      const applicantFee = await processFile(files.applicant_fee ? files.applicant_fee[0] : null);
      const certificateOfRegistration = await processFile(files.certificate_of_registration ? files.certificate_of_registration[0] : null);
      const driversLicense = await processFile(files.drivers_license ? files.drivers_license[0] : null);

      // Insert file paths and binary data into the database
      await pool.query(
        `INSERT INTO scandocu 
        (mtop_id, barangay_clearance, barangay_clearance_path, police_clearance, police_clearance_path, 
         sss_certificate, sss_certificate_path, philhealth_certificate, philhealth_certificate_path,
         applicant_fee, applicant_fee_path, certificate_of_registration, certificate_of_registration_path,
         drivers_license, drivers_license_path) 
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15)`,
        [
          mtop_id,
          barangayClearance.binary,
          barangayClearance.filePath,
          policeClearance.binary,
          policeClearance.filePath,
          sssCertificate.binary,
          sssCertificate.filePath,
          philhealthCertificate.binary,
          philhealthCertificate.filePath,
          applicantFee.binary,
          applicantFee.filePath,
          certificateOfRegistration.binary,
          certificateOfRegistration.filePath,
          driversLicense.binary,
          driversLicense.filePath,
        ]
      );

      res.status(200).json({ message: 'Documents uploaded and compressed successfully' });
    } catch (error) {
      console.error('Error uploading and compressing documents:', error);
      res.status(500).json({ message: 'Failed to upload and compress documents', error: error.message });
    }
  }
);

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

app.get('/inspections', async (req, res) => {
  console.log("GET /inspections route hit"); // Add this to log the request
  try {
    const result = await pool.query(
      `SELECT applicant_name, inspection_status, reason_not_approved 
       FROM inspections 
       ORDER BY applicant_name`
    );
    
    if (result.rows.length === 0) {
      return res.status(200).json({ inspections: [] });  // Return an empty array if no data
    }

    res.status(200).json({ inspections: result.rows });
  } catch (error) {
    console.error('Error fetching inspections data:', error);
    res.status(500).json({ message: 'Error fetching inspections data' });
  }
});


// Start the server
app.listen(port, '0.0.0.0', () => {
  console.log(`Server running on port ${port}`);
});

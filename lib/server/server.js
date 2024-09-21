const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
const { Pool } = require('pg');

const app = express();
const port = 3000;

const pool = new Pool({
  user: 'postgres',
  host: 'localhost',
  database: 'postgres',
  password: 'password',
  port: 5432,
});

app.use(bodyParser.json());
app.use(cors());

// GET route to verify the server is running
app.get('/', (req, res) => {
  res.send('Server is running');
});

// Login route
app.post('/login', async (req, res) => {
  const { email, password } = req.body;

  try {
    console.log('Login attempt:', email);

    // Query to check both email and password in a single query
    const result = await pool.query('SELECT * FROM users WHERE email = $1 AND password = $2', [email, password]);

    if (result.rows.length === 0) {
      console.log('Invalid email or password');
      return res.status(401).json({ message: 'Invalid credentials' });
    }

    const user = result.rows[0];
    console.log('User found:', user);

    // Successful login, return user information
    return res.status(200).json({
      message: 'Login successful',
      user: {
        id: user.id,  // Include user ID here
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
    console.log('Registration attempt:', email);

    // Fix the query by using the correct placeholder $1 for email
    const result = await pool.query('SELECT * FROM users WHERE email = $1', [email]);

    if (result.rows.length > 0) {
      console.log('User already exists');
      return res.status(400).json({ message: 'User already exists' });
    }

    // Insert the new user into the database
    await pool.query('INSERT INTO users (email, password, name) VALUES ($1, $2, $3)', [email, password, name]);
    console.log('User registered successfully');

    return res.status(201).json({ message: 'User registered successfully' });
  } catch (err) {
    console.error('Error during registration process:', err);
    return res.status(500).json({ message: 'Internal server error' });
  }
});

  // Start the server
  app.listen(port, '0.0.0.0', () => {
    console.log(`Server is running on:${port}`);
  });
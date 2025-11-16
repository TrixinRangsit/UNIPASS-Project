// routes/auth.js
const express = require('express');
const router = express.Router();
const db = require('../db');

// register
router.post('/register', async (req, res) => {
  try {
    const { id, name, password, role, major, department, photo_url } = req.body;
    if (!id || !name || !password || !role) return res.status(400).json({ error: 'Missing fields' });

    const [exists] = await db.query('SELECT id FROM users WHERE id = ?', [id]);
    if (exists.length) return res.status(400).json({ error: 'User already exists' });

    await db.query('INSERT INTO users (id,name,password,role,major,department,photo_url) VALUES (?,?,?,?,?,?,?)',
      [id, name, password, role, major || null, department || null, photo_url || null]);
    res.json({ ok: true, id });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});

// login
router.post('/login', async (req, res) => {
  try {
    const { id, password } = req.body;
    if (!id || !password) return res.status(400).json({ error: 'Missing fields' });
    const [rows] = await db.query('SELECT id,name,role,major,department,photo_url FROM users WHERE id = ? AND password = ?', [id, password]);
    if (!rows.length) return res.status(401).json({ error: 'Invalid credentials' });
    res.json(rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});

module.exports = router;
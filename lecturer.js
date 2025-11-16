// routes/lecturer.js
const express = require('express');
const router = express.Router();
const db = require('../db');

// profile + courses taught
router.get('/profile/:lecturer_id', async (req, res) => {
  const id = req.params.lecturer_id;
  try {
    const [u] = await db.query('SELECT id,name,department,photo_url FROM users WHERE id = ? AND role = "lecturer"', [id]);
    if (!u.length) return res.status(404).json({ error: 'Lecturer not found' });
    const [courses] = await db.query('SELECT course_id, course_name FROM courses WHERE lecturer_id = ?', [id]);
    res.json({ profile: u[0], courses });
  } catch (err) {
    console.error(err); res.status(500).json({ error: 'Server error' });
  }
});

// add a course (lecturer creates course and becomes owner)
router.post('/add-course', async (req, res) => {
  try {
    const { lecturer_id, course_id, course_name } = req.body;
    if (!lecturer_id || !course_id || !course_name) return res.status(400).json({ error: 'Missing' });
    await db.query('INSERT INTO courses (course_id, course_name, lecturer_id) VALUES (?,?,?) ON DUPLICATE KEY UPDATE lecturer_id = VALUES(lecturer_id), course_name = VALUES(course_name)', [course_id, course_name, lecturer_id]);
    res.json({ ok: true });
  } catch (err) {
    console.error(err); res.status(500).json({ error: 'Server error' });
  }
});

// delete course (remove lecturer assignment / delete course)
router.post('/delete-course', async (req, res) => {
  try {
    const { lecturer_id, course_id } = req.body;
    if (!lecturer_id || !course_id) return res.status(400).json({ error: 'Missing' });
    // Only delete if this lecturer owns it
    await db.query('DELETE FROM courses WHERE course_id = ? AND lecturer_id = ?', [course_id, lecturer_id]);
    res.json({ ok: true });
  } catch (err) {
    console.error(err); res.status(500).json({ error: 'Server error' });
  }
});

module.exports = router;
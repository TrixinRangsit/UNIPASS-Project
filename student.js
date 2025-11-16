// routes/student.js
const express = require('express');
const router = express.Router();
const db = require('../db');

// get student profile + enrolled courses
router.get('/profile/:student_id', async (req, res) => {
  const student_id = req.params.student_id;
  try {
    const [userRows] = await db.query('SELECT id,name,major,department,photo_url FROM users WHERE id = ? AND role = "student"', [student_id]);
    if (!userRows.length) return res.status(404).json({ error: 'Student not found' });

    const [courses] = await db.query(
      `SELECT c.course_id, c.course_name, c.lecturer_id
       FROM enrollments e
       JOIN courses c ON e.course_id = c.course_id
       WHERE e.student_id = ?`, [student_id]
    );
    res.json({ profile: userRows[0], courses });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});

// enroll in course
router.post('/enroll', async (req, res) => {
  try {
    const { student_id, course_id, course_name } = req.body;
    if (!student_id || !course_id || !course_name) return res.status(400).json({ error: 'Missing fields' });

    // ensure course exists
    await db.query('INSERT IGNORE INTO courses (course_id, course_name) VALUES (?,?)', [course_id, course_name]);

    // add enrollment
    await db.query('INSERT IGNORE INTO enrollments (student_id, course_id) VALUES (?,?)', [student_id, course_id]);
    res.json({ ok: true });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});

// unenroll
router.post('/unenroll', async (req, res) => {
  try {
    const { student_id, course_id } = req.body;
    if (!student_id || !course_id) return res.status(400).json({ error: 'Missing fields' });
    await db.query('DELETE FROM enrollments WHERE student_id = ? AND course_id = ?', [student_id, course_id]);
    res.json({ ok: true });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});

module.exports = router;
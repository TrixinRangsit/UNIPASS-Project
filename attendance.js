// routes/attendance.js
const express = require('express');
const router = express.Router();
const db = require('../db');
const ExcelJS = require('exceljs');

// generate code
router.post('/generate', async (req, res) => {
  try {
    const { lecturer_id, course_id } = req.body;
    if (!lecturer_id || !course_id) return res.status(400).json({ error: 'Missing fields' });

    // simple code: random 6-digit + timestamp
    const code = Math.random().toString(36).substr(2, 6).toUpperCase();
    const createdAt = new Date();
    const validUntil = new Date(createdAt.getTime() + 15*60*1000); // 15 minutes

    await db.query('INSERT INTO attendance_codes (course_id, code, created_by, valid_until) VALUES (?,?,?,?)', [course_id, code, lecturer_id, validUntil]);
    res.json({ code, valid_until: validUntil });
  } catch (err) {
    console.error(err); res.status(500).json({ error: 'Server error' });
  }
});

// submit attendance (student)
router.post('/submit', async (req, res) => {
  try {
    const { student_id, course_id, code } = req.body;
    if (!student_id || !course_id || !code) return res.status(400).json({ error: 'Missing' });

    // check code exists and valid
    const [codeRows] = await db.query('SELECT * FROM attendance_codes WHERE course_id = ? AND code = ? ORDER BY created_at DESC LIMIT 1', [course_id, code]);
    if (!codeRows.length) return res.status(400).json({ error: 'Invalid code' });
    const codeRow = codeRows[0];
    const now = new Date();
    if (now > new Date(codeRow.valid_until)) return res.status(400).json({ error: 'Code expired' });

    // fetch student info
    const [u] = await db.query('SELECT id,name FROM users WHERE id = ?', [student_id]);
    if (!u.length) return res.status(404).json({ error: 'Student not found' });

    // insert attendance (unique constraint prevents duplicates)
    try {
      await db.query('INSERT INTO attendance (student_id, student_name, course_id, code_used) VALUES (?,?,?,?)', [student_id, u[0].name, course_id, code]);
      res.json({ ok: true });
    } catch (err) {
      // likely duplicate
      return res.status(400).json({ error: 'Already submitted for today' });
    }

  } catch (err) {
    console.error(err); res.status(500).json({ error: 'Server error' });
  }
});

// view attendance (by course and date)
router.get('/view', async (req, res) => {
  try {
    const { course_id, date } = req.query; // date as YYYY-MM-DD
    if (!course_id || !date) return res.status(400).json({ error: 'Missing' });

    const [rows] = await db.query('SELECT student_id, student_name, submitted_at FROM attendance WHERE course_id = ? AND DATE(submitted_at) = ? ORDER BY submitted_at', [course_id, date]);
    const total = rows.length;
    res.json({ total, rows });
  } catch (err) {
    console.error(err); res.status(500).json({ error: 'Server error' });
  }
});

// export attendance to excel
router.get('/export', async (req, res) => {
  try {
    const { course_id, date } = req.query;
    if (!course_id || !date) return res.status(400).json({ error: 'Missing' });

    const [rows] = await db.query('SELECT student_id, student_name, submitted_at FROM attendance WHERE course_id = ? AND DATE(submitted_at) = ? ORDER BY submitted_at', [course_id, date]);

    const workbook = new ExcelJS.Workbook();
    const sheet = workbook.addWorksheet('Attendance');
    sheet.columns = [
      { header: 'Student ID', key: 'student_id', width: 20 },
      { header: 'Student Name', key: 'student_name', width: 30 },
      { header: 'Submitted At', key: 'submitted_at', width: 30 }
    ];
    rows.forEach(r => sheet.addRow({ student_id: r.student_id, student_name: r.student_name, submitted_at: r.submitted_at }));

    res.setHeader('Content-Type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
    res.setHeader('Content-Disposition', `attachment; filename=attendance_${course_id}_${date}.xlsx`);
    await workbook.xlsx.write(res);
    res.end();
  } catch (err) {
    console.error(err); res.status(500).json({ error: 'Server error' });
  }
});

module.exports = router;
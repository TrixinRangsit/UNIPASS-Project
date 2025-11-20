// routes/admin.js
const express = require("express");
const router = express.Router();
const db = require("../db");

// Allowed fields for editing
const allowedFields = ["name", "department", "major", "photo_url", "password"];

// GET user by id
router.get("/user/:id", async (req, res) => {
  try {
    const [rows] = await db.query("SELECT id, name, role, major, department, photo_url FROM users WHERE id = ?", [req.params.id]);
    if (!rows.length) return res.status(404).json({ success: false, message: "User not found" });
    res.json({ success: true, user: rows[0] });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: err.message });
  }
});

// CREATE user
router.post("/create-user", async (req, res) => {
  try {
    const { id, name, password, department, major, role, photo_url } = req.body;
    if (!id || !name || !password || !role) {
      return res.status(400).json({ success: false, message: "Missing required fields" });
    }

    await db.query(
      `INSERT INTO users (id, name, password, role, major, department, photo_url)
       VALUES (?, ?, ?, ?, ?, ?, ?)`,
      [id, name, password, role, major || null, department || null, photo_url || null]
    );

    res.json({ success: true, message: "User created successfully" });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: err.message });
  }
});

// UPDATE user
router.put("/user/:id", async (req, res) => {
  try {
    const updates = [];
    const values = [];

    for (const key of Object.keys(req.body)) {
      if (allowedFields.includes(key)) {
        updates.push(`${key} = ?`);
        values.push(req.body[key]);
      }
    }

    if (updates.length === 0) {
      return res.status(400).json({ success: false, message: "No valid fields to update" });
    }

    values.push(req.params.id);
    const sql = `UPDATE users SET ${updates.join(", ")} WHERE id = ?`;
    await db.query(sql, values);

    res.json({ success: true, message: "User updated successfully" });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: err.message });
  }
});

// RESET PASSWORD
router.put("/user/:id/reset-password", async (req, res) => {
  try {
    const { newPassword } = req.body;
    if (!newPassword) return res.status(400).json({ success: false, message: "New password is required" });

    await db.query("UPDATE users SET password = ? WHERE id = ?", [newPassword, req.params.id]);
    res.json({ success: true, message: "Password reset successfully" });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: err.message });
  }
});

// DELETE user
router.delete("/user/:id", async (req, res) => {
  try {
    await db.query("DELETE FROM users WHERE id = ?", [req.params.id]);
    res.json({ success: true, message: "User deleted successfully" });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: err.message });
  }
});

module.exports = router;
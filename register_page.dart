// lib/screens/register_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final idCtrl = TextEditingController();
  final nameCtrl = TextEditingController();
  final pwCtrl = TextEditingController();
  final majorCtrl = TextEditingController();
  final deptCtrl = TextEditingController();
  final photoCtrl = TextEditingController();
  String role = 'student';
  bool loading = false;

  Future<void> _register() async {
    final id = idCtrl.text.trim();
    if (id.isEmpty || pwCtrl.text.isEmpty || nameCtrl.text.isEmpty)
      return _show('Fill id/name/password');
    setState(() => loading = true);
    try {
      final res = await Api.post('/auth/register', {
        'id': id,
        'name': nameCtrl.text,
        'password': pwCtrl.text,
        'role': role,
        'major': majorCtrl.text,
        'department': deptCtrl.text,
        'photo_url': photoCtrl.text,
      });
      setState(() => loading = false);
      if (res.statusCode == 200) {
        _show('Registered — please login');
        Navigator.pop(context);
      } else {
        final err = res.body.isNotEmpty
            ? (jsonDecode(res.body)['error'] ?? res.body)
            : 'Error';
        _show(err);
      }
    } catch (e) {
      setState(() => loading = false);
      _show('Network error: $e');
    }
  }

  void _show(String s) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Register',
          style: TextStyle(color: Colors.black, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildTextField(controller: idCtrl, label: 'ID'),
            const SizedBox(height: 20),
            _buildTextField(controller: nameCtrl, label: 'Name'),
            const SizedBox(height: 20),
            _buildTextField(
              controller: pwCtrl,
              label: 'Password',
              obscureText: true,
            ),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Text(
                    'Role: ',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                  ),
                  Radio<String>(
                    value: 'student',
                    groupValue: role,
                    onChanged: (v) {
                      if (v != null) setState(() => role = v);
                    },
                    activeColor: const Color(0xFF0047AB),
                  ),
                  const Text('Student'),
                  const SizedBox(width: 10),
                  Radio<String>(
                    value: 'lecturer',
                    groupValue: role,
                    onChanged: (v) {
                      if (v != null) setState(() => role = v);
                    },
                    activeColor: const Color(0xFF0047AB),
                  ),
                  const Text('Lecturer'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (role == 'student')
              Column(
                children: [
                  _buildTextField(controller: majorCtrl, label: 'Major'),
                  const SizedBox(height: 20),
                ],
              ),
            _buildTextField(controller: deptCtrl, label: 'Department'),
            const SizedBox(height: 20),
            _buildTextField(
              controller: photoCtrl,
              label: 'Photo URL (optional)',
            ),
            const SizedBox(height: 30),
            const Text(
              'By continuing, you agree with our Term &',
              style: TextStyle(fontSize: 12, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
            const Text(
              'Conditions and Privacy Policy',
              style: TextStyle(fontSize: 12, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: loading ? null : _register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0047AB),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Register',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool obscureText = false,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey.shade600),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}

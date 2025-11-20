// lib/screens/login_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api.dart';
import 'register_page.dart';
import 'student_home.dart';
import 'lecturer_home.dart';
import 'admin_dashboard.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final idCtrl = TextEditingController();
  final pwCtrl = TextEditingController();
  bool loading = false;
  bool hidePassword = true;

  @override
  void initState() {
    super.initState();
    _tryAutoLogin();
  }

  Future<void> _tryAutoLogin() async {
    final sp = await SharedPreferences.getInstance();
    final id = sp.getString('id');
    final role = sp.getString('role');
    if (id != null && role != null && mounted) {
      if (role == 'student') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => StudentHome(id: id)),
        );
      } else if (role == 'lecturer') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => LecturerHome(id: id)),
        );
      } else if (role == 'admin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminDashboard()),
        );
      }
    }
  }

  Future<void> _login() async {
    final id = idCtrl.text.trim();
    final pw = pwCtrl.text;

    if (id.isEmpty || pw.isEmpty) return _show('Enter ID & password');

    // LOCAL ADMIN LOGIN (fallback option)
    if (id == "admin123" && pw == "pass123") {
      final sp = await SharedPreferences.getInstance();
      await sp.setString('id', id);
      await sp.setString('role', 'admin');
      await sp.setString('name', 'Administrator');

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AdminDashboard()),
        (route) => false,
      );
      return;
    }

    // NORMAL API LOGIN
    setState(() => loading = true);

    try {
      final res = await Api.post('/auth/login', {'id': id, 'password': pw});
      setState(() => loading = false);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final sp = await SharedPreferences.getInstance();
        await sp.setString('id', data['id']);
        await sp.setString('role', data['role']);
        await sp.setString('name', data['name'] ?? '');

        if (!mounted) return;

        if (data['role'] == 'student') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => StudentHome(id: data['id'])),
          );
        } else if (data['role'] == 'lecturer') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => LecturerHome(id: data['id'])),
          );
        } else if (data['role'] == 'admin') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const AdminDashboard()),
          );
        }
      } else {
        final err = res.body.isNotEmpty
            ? (jsonDecode(res.body)['error'] ?? res.body)
            : 'Login failed';
        _show(err);
      }
    } catch (e) {
      setState(() => loading = false);
      _show('Network error: $e');
    }
  }

  void _show(String s) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));
  }

  void _goRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegisterPage()),
    );
  }

  @override
  void dispose() {
    idCtrl.dispose();
    pwCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: const Color(0xFF1a1d2e),
        body: SafeArea(
          child: Column(
            children: [
              // Top decorative section with pattern
              Expanded(
                flex: 2,
                child: Stack(
                  children: [
                    // Pattern background
                    Container(
                      decoration: const BoxDecoration(color: Color(0xFF1a1d2e)),
                      child: CustomPaint(
                        painter: CirclePatternPainter(),
                        child: Container(),
                      ),
                    ),
                    // UniPass Title in center
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [
                                Color(0xFF1E88E5), // Blue
                                Color(0xFF5E35B1), // Purple
                                Color(0xFF8E24AA), // Deep purple
                              ],
                            ).createShader(bounds),
                            child: const Text(
                              'UNIPASS',
                              style: TextStyle(
                                fontSize: 56,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                          const SizedBox(height: 15),
                          Text(
                            'Your Digital Campus ID',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.8),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom white section with form
              Expanded(
                flex: 3,
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(30),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 20),

                        // Title
                        const Text(
                          "Login",
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Subtitle
                        Text(
                          "Sign in to continue.",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                        ),

                        const SizedBox(height: 40),

                        // ID label
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 8, bottom: 8),
                            child: Text(
                              "ID",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade400,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        ),

                        // ID field
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextField(
                            controller: idCtrl,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 18,
                              ),
                              hintText: "Enter your ID",
                              hintStyle: TextStyle(
                                color: Colors.black54,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 25),

                        // PASSWORD label
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 8, bottom: 8),
                            child: Text(
                              "PASSWORD",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade400,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        ),

                        // Password field
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextField(
                            controller: pwCtrl,
                            obscureText: hidePassword,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 18,
                              ),
                              hintText: "••••••",
                              hintStyle: const TextStyle(
                                color: Colors.black54,
                                fontSize: 16,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  hidePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: Colors.grey.shade600,
                                ),
                                onPressed: () {
                                  setState(() {
                                    hidePassword = !hidePassword;
                                  });
                                },
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 35),

                        // Login button
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: loading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1a1d2e),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: loading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    "Log In",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 25),

                        // Sign up
                        TextButton(
                          onPressed: _goRegister,
                          child: Text(
                            "Sign-up !",
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 14,
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Custom painter for the circular pattern background
class CirclePatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF2d3454).withOpacity(0.6)
      ..style = PaintingStyle.fill;

    // Draw multiple circles in a pattern
    final positions = [
      Offset(size.width * 0.15, size.height * 0.2),
      Offset(size.width * 0.85, size.height * 0.15),
      Offset(size.width * 0.1, size.height * 0.6),
      Offset(size.width * 0.75, size.height * 0.65),
      Offset(size.width * 0.5, size.height * 0.3),
      Offset(size.width * 0.3, size.height * 0.8),
      Offset(size.width * 0.9, size.height * 0.5),
    ];

    for (var pos in positions) {
      canvas.drawCircle(pos, 40, paint);
      canvas.drawCircle(
        pos,
        25,
        paint..color = const Color(0xFF3d4564).withOpacity(0.4),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

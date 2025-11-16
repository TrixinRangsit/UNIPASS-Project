// lib/screens/login_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api.dart';
import 'register_page.dart';
import 'student_home.dart';
import 'lecturer_home.dart';

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
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => LecturerHome(id: id)),
        );
      }
    }
  }

  Future<void> _login() async {
    final id = idCtrl.text.trim();
    final pw = pwCtrl.text;

    if (id.isEmpty || pw.isEmpty) return _show('Enter ID & password');

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
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => LecturerHome(id: data['id'])),
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));
  }

  void _goRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegisterPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                  // UniPass Logo in center
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CustomPaint(
                          size: const Size(120, 120),
                          painter: UniPassLogoPainter(),
                        ),
                        const SizedBox(height: 15),
                        const Text(
                          'UniPass',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 5),
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

// Custom painter for UniPass logo
class UniPassLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // Shield shape path
    final shieldPath = Path();
    shieldPath.moveTo(w * 0.5, 0);
    shieldPath.cubicTo(
      w * 0.2,
      h * 0.05,
      w * 0.05,
      h * 0.15,
      w * 0.05,
      h * 0.4,
    );
    shieldPath.cubicTo(w * 0.05, h * 0.7, w * 0.3, h * 0.9, w * 0.5, h);
    shieldPath.cubicTo(w * 0.7, h * 0.9, w * 0.95, h * 0.7, w * 0.95, h * 0.4);
    shieldPath.cubicTo(w * 0.95, h * 0.15, w * 0.8, h * 0.05, w * 0.5, 0);
    shieldPath.close();

    // Gradient for shield
    final shieldGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        const Color(0xFF1E88E5), // Blue
        const Color(0xFF5E35B1), // Purple
        const Color(0xFF8E24AA), // Deep purple
      ],
    );

    final shieldPaint = Paint()
      ..shader = shieldGradient.createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;

    canvas.drawPath(shieldPath, shieldPaint);

    // White inner section
    final whitePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final whiteRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.2, h * 0.45, w * 0.6, h * 0.35),
      const Radius.circular(8),
    );
    canvas.drawRRect(whiteRect, whitePaint);

    // Draw "U" shape with arrows
    final uPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.08
      ..strokeCap = StrokeCap.round;

    // Left arrow (blue)
    final leftArrowGradient = LinearGradient(
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
      colors: [const Color(0xFF1E88E5), const Color(0xFF42A5F5)],
    );
    uPaint.shader = leftArrowGradient.createShader(
      Rect.fromLTWH(w * 0.3, h * 0.25, w * 0.15, h * 0.4),
    );

    final leftPath = Path();
    leftPath.moveTo(w * 0.35, h * 0.55);
    leftPath.lineTo(w * 0.35, h * 0.35);
    leftPath.lineTo(w * 0.42, h * 0.35);
    canvas.drawPath(leftPath, uPaint);

    // Left arrow head
    final leftArrowHead = Path();
    leftArrowHead.moveTo(w * 0.32, h * 0.3);
    leftArrowHead.lineTo(w * 0.42, h * 0.2);
    leftArrowHead.lineTo(w * 0.52, h * 0.3);
    canvas.drawPath(leftArrowHead, uPaint);

    // Right arrow (purple)
    final rightArrowGradient = LinearGradient(
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
      colors: [const Color(0xFF8E24AA), const Color(0xFFAB47BC)],
    );
    uPaint.shader = rightArrowGradient.createShader(
      Rect.fromLTWH(w * 0.55, h * 0.25, w * 0.15, h * 0.4),
    );

    final rightPath = Path();
    rightPath.moveTo(w * 0.65, h * 0.55);
    rightPath.lineTo(w * 0.65, h * 0.35);
    rightPath.lineTo(w * 0.58, h * 0.35);
    canvas.drawPath(rightPath, uPaint);

    // Right arrow head
    final rightArrowHead = Path();
    rightArrowHead.moveTo(w * 0.68, h * 0.3);
    rightArrowHead.lineTo(w * 0.58, h * 0.2);
    rightArrowHead.lineTo(w * 0.48, h * 0.3);
    canvas.drawPath(rightArrowHead, uPaint);

    // Bottom U curve
    final bottomPaint = Paint()
      ..color = const Color(0xFF5E35B1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.08
      ..strokeCap = StrokeCap.round;

    final uCurve = Path();
    uCurve.moveTo(w * 0.35, h * 0.55);
    uCurve.quadraticBezierTo(w * 0.35, h * 0.7, w * 0.5, h * 0.7);
    uCurve.quadraticBezierTo(w * 0.65, h * 0.7, w * 0.65, h * 0.55);
    canvas.drawPath(uCurve, bottomPaint);

    // Draw dots (representing data/connectivity)
    final dotPaint = Paint()
      ..color = const Color(0xFF4CAF50)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(w * 0.2, h * 0.42), w * 0.025, dotPaint);
    canvas.drawCircle(Offset(w * 0.24, h * 0.42), w * 0.025, dotPaint);
    canvas.drawCircle(Offset(w * 0.28, h * 0.44), w * 0.02, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

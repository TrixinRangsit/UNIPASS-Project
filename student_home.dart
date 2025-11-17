// lib/screens/student_home.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api.dart';
import 'login_page.dart';

class StudentHome extends StatefulWidget {
  final String id;
  const StudentHome({super.key, required this.id});
  @override
  State<StudentHome> createState() => _StudentHomeState();
}

class _StudentHomeState extends State<StudentHome> {
  int index = 0;
  Map profile = {};
  List courses = [];
  final enrollCourseId = TextEditingController();
  final enrollCourseName = TextEditingController();
  final attendanceCourseId = TextEditingController();
  final attendanceCode = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final res = await Api.get('/student/profile/${widget.id}');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (mounted)
          setState(
            () => {
              profile = data['profile'] ?? {},
              courses = data['courses'] ?? [],
            },
          );
      } else {
        _show('Failed to load');
      }
    } catch (e) {
      _show('Network error');
    }
  }

  Future<void> _enroll() async {
    final cid = enrollCourseId.text.trim();
    final cname = enrollCourseName.text.trim();
    if (cid.isEmpty || cname.isEmpty) return _show('fill course id & name');
    try {
      final res = await Api.post('/student/enroll', {
        'student_id': widget.id,
        'course_id': cid,
        'course_name': cname,
      });
      if (res.statusCode == 200) {
        enrollCourseId.clear();
        enrollCourseName.clear();
        _loadProfile();
        _show('Enrolled');
      } else
        _show(res.body);
    } catch (e) {
      _show('Network error');
    }
  }

  Future<void> _unenroll(String cid) async {
    try {
      final res = await Api.post('/student/unenroll', {
        'student_id': widget.id,
        'course_id': cid,
      });
      if (res.statusCode == 200) {
        _show('Unenrolled');
        _loadProfile();
      } else
        _show(res.body);
    } catch (e) {
      _show('Network error');
    }
  }

  Future<void> _submitAttendance() async {
    final cid = attendanceCourseId.text.trim();
    final code = attendanceCode.text.trim();
    if (cid.isEmpty || code.isEmpty) return _show('fill course & code');
    try {
      final res = await Api.post('/attendance/submit', {
        'student_id': widget.id,
        'course_id': cid,
        'code': code,
      });
      if (res.statusCode == 200)
        _show('Attendance submitted');
      else {
        final err = res.body.isNotEmpty
            ? jsonDecode(res.body)['error'] ?? res.body
            : 'Error';
        _show(err);
      }
    } catch (e) {
      _show('Network error');
    }
  }

  Future<void> _logout() async {
    final sp = await SharedPreferences.getInstance();
    await sp.clear();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  void _show(String s) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));

  @override
  Widget build(BuildContext context) {
    final pages = [_profileTab(), _qrTab(), _attendanceTab(), _emergencyTab()];
    return Scaffold(
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF0052CC),
        unselectedItemColor: Colors.grey,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(icon: Icon(Icons.qr_code), label: 'QR'),
          BottomNavigationBarItem(icon: Icon(Icons.badge), label: 'Attendance'),
          BottomNavigationBarItem(
            icon: Icon(Icons.emergency),
            label: 'Emergency',
          ),
        ],
        onTap: (i) => setState(() => index = i),
      ),
    );
  }

  Widget _profileTab() => Container(
    color: const Color(0xFFF5F1E8),
    child: RefreshIndicator(
      onRefresh: () async => _loadProfile(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Container(
              width: 320,
              margin: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: const Color(0xFFEDE7DB),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Decorative circles
                  Positioned(
                    left: -50,
                    top: 50,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8C4A0).withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    right: -30,
                    bottom: 100,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8C4A0).withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  // Main content
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header with UNIPASS app name
                        Center(
                          child: Text(
                            'UNIPASS',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1E3A5F),
                              letterSpacing: 3,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Photo
                        Container(
                          width: 150,
                          height: 180,
                          decoration: BoxDecoration(
                            color: const Color(0xFFA39C8E),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child:
                              profile['photo_url'] != null &&
                                  (profile['photo_url'] as String).isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    profile['photo_url'],
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(
                                      Icons.person,
                                      size: 80,
                                      color: Colors.white,
                                    ),
                                  ),
                                )
                              : const Icon(
                                  Icons.person,
                                  size: 80,
                                  color: Colors.white,
                                ),
                        ),
                        const SizedBox(height: 20),
                        // Barcode design on the right
                        Align(
                          alignment: Alignment.centerRight,
                          child: Column(
                            children: List.generate(12, (index) {
                              final widths = [
                                3.0,
                                1.0,
                                4.0,
                                2.0,
                                1.0,
                                3.0,
                                2.0,
                                1.0,
                                4.0,
                                2.0,
                                3.0,
                                1.0,
                              ];
                              return Container(
                                width: widths[index] * 8,
                                height: 3,
                                margin: const EdgeInsets.only(bottom: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E3A5F),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              );
                            }),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Student info
                        _buildInfoRow('Name', profile['name'] ?? 'N/A'),
                        const SizedBox(height: 12),
                        _buildInfoRow('ID', profile['id'] ?? widget.id),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          'Department',
                          profile['department'] ?? 'N/A',
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow('Major', profile['major'] ?? 'N/A'),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Enrolled courses section
          const SizedBox(height: 20),
          const Text(
            'Enrolled courses',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          ...courses.map(
            (c) => Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                title: Text(c['course_name'] ?? ''),
                subtitle: Text(c['course_id'] ?? ''),
                trailing: IconButton(
                  icon: const Icon(
                    Icons.remove_circle_outline,
                    color: Colors.red,
                  ),
                  onPressed: () => _unenroll(c['course_id']),
                ),
              ),
            ),
          ),
          const Divider(height: 30),
          const Text(
            'Enroll in New Course',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          TextField(
            controller: enrollCourseId,
            decoration: InputDecoration(
              labelText: 'Course id',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: enrollCourseName,
            decoration: InputDecoration(
              labelText: 'Course name',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 15),
          ElevatedButton(
            onPressed: _enroll,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A5F),
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Enroll',
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout, size: 20),
            label: const Text(
              'Logout',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red, width: 2),
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    ),
  );

  Widget _qrTab() {
    final payload = jsonEncode({
      'id': profile['id'] ?? widget.id,
      'name': profile['name'] ?? '',
      'major': profile['major'] ?? '',
      'department': profile['department'] ?? '',
    });
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [const Color(0xFFF5F1E8), const Color(0xFFE8E3D8)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo/Icon
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFF1E3A5F),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.qr_code_2, color: Colors.white, size: 36),
            ),
            const SizedBox(height: 16),
            // App name
            const Text(
              'UNIPASS',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E3A5F),
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Student Identification',
              style: TextStyle(fontSize: 14, color: Color(0xFF666666)),
            ),
            const SizedBox(height: 32),
            // "SCAN HERE" header
            const Text(
              'SCAN HERE',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E3A5F),
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 12),
            // "FOR PROFILE DETAIL" button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFD32F2F),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'FOR PROFILE DETAIL',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Chevron down icons
            Column(
              children: [
                Icon(
                  Icons.keyboard_arrow_down,
                  color: const Color(0xFFD32F2F),
                  size: 24,
                ),
                Icon(
                  Icons.keyboard_arrow_down,
                  color: const Color(0xFFD32F2F),
                  size: 24,
                ),
              ],
            ),
            const SizedBox(height: 16),
            // QR Code container
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE0E0E0), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  QrImageView(
                    data: payload,
                    size: 220,
                    backgroundColor: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'QR CODE',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF666666),
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Info text
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'This QR contains your ID, name, major, and department',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: const Color(0xFF666666)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E3A5F),
            ),
          ),
        ),
        const Text(
          ': ',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14, color: Color(0xFF2C2C2C)),
          ),
        ),
      ],
    );
  }

  Widget _attendanceTab() {
    return Container(
      color: const Color(0xFFF5F1E8),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Container(
            width: 320,
            margin: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: const Color(0xFFEDE7DB),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Decorative circles
                Positioned(
                  left: -50,
                  top: 50,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8C4A0).withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Positioned(
                  right: -30,
                  bottom: 100,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8C4A0).withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                // Main content
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      const Text(
                        'UNIPASS',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E3A5F),
                          letterSpacing: 3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Submit Attendance',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF666666),
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 30),
                      // Attendance icon
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E3A5F),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.check_circle_outline,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 30),
                      // Course ID field
                      TextField(
                        controller: attendanceCourseId,
                        style: const TextStyle(fontSize: 14),
                        decoration: InputDecoration(
                          labelText: 'Course ID',
                          labelStyle: const TextStyle(
                            color: Color(0xFF666666),
                            fontSize: 13,
                          ),
                          floatingLabelStyle: const TextStyle(
                            color: Color(0xFF1E3A5F),
                            fontSize: 14,
                          ),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.7),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFF1E3A5F),
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Attendance code field
                      TextField(
                        controller: attendanceCode,
                        style: const TextStyle(fontSize: 14),
                        decoration: InputDecoration(
                          labelText: 'Attendance Code',
                          labelStyle: const TextStyle(
                            color: Color(0xFF666666),
                            fontSize: 13,
                          ),
                          floatingLabelStyle: const TextStyle(
                            color: Color(0xFF1E3A5F),
                            fontSize: 14,
                          ),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.7),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFF1E3A5F),
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Submit button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _submitAttendance,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E3A5F),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            shadowColor: Colors.black.withOpacity(0.3),
                          ),
                          child: const Text(
                            'Submit Attendance',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Helper text
                      const Text(
                        'Enter the code provided by your lecturer',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF666666),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _emergencyTab() {
    return Container(
      color: const Color(0xFFF5F1E8),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header Card
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 20, bottom: 20),
              decoration: BoxDecoration(
                color: const Color(0xFFEDE7DB),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Decorative circles
                  Positioned(
                    left: -50,
                    top: 50,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8C4A0).withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    right: -30,
                    bottom: 30,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8C4A0).withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  // Content
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header
                        const Text(
                          'UNIPASS',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E3A5F),
                            letterSpacing: 3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Emergency Contacts',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF666666),
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 30),
                        // Emergency Icon
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: const Color(0xFFD32F2F),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.emergency,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Quick access to emergency services',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF666666),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // University Emergency Contacts Section
            const Text(
              'University Emergency Contacts',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            _buildUniversityContact(
              'Campus Security Hotline',
              '+66 xxx xxx xxx',
              Icons.security,
              const Color(0xFFD32F2F),
            ),
            _buildUniversityContact(
              'Emergency Medical Unit',
              '+66 xxx xxx xxx',
              Icons.local_hospital,
              const Color(0xFFE53935),
            ),
            _buildUniversityContact(
              'Fire & Safety Department',
              '+66 xxx xxx xxx',
              Icons.fire_extinguisher,
              const Color(0xFFF44336),
            ),
            _buildUniversityContact(
              'Counseling & Student Support',
              '+66 xxx xxx xxx',
              Icons.psychology,
              const Color(0xFF1976D2),
            ),
            _buildUniversityContact(
              'IT Department (System Issues)',
              '+66 xxx xxx xxx',
              Icons.computer,
              const Color(0xFF0288D1),
            ),
            const SizedBox(height: 16),
            // Email Support Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE0E0E0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF757575).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.email,
                      color: Color(0xFF757575),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Email Support',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'helpdesk@youruniversity.edu',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUniversityContact(
    String title,
    String phone,
    IconData icon,
    Color color,
  ) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            phone,
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
        ),
        trailing: IconButton(
          icon: Icon(Icons.phone, color: color, size: 24),
          onPressed: () {
            final url = Uri.parse('tel:$phone');
            launchUrl(url);
          },
        ),
      ),
    );
  }
}

// lib/screens/lecturer_home.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api.dart';
import '../services/api.dart'; // contains API_BASE
import 'login_page.dart';

class LecturerHome extends StatefulWidget {
  final String id;
  const LecturerHome({super.key, required this.id});

  @override
  State<LecturerHome> createState() => _LecturerHomeState();
}

class _LecturerHomeState extends State<LecturerHome> {
  int index = 0;
  Map profile = {};
  List courses = [];

  final addCourseId = TextEditingController();
  final addCourseName = TextEditingController();
  final genCourseId = TextEditingController();
  String lastGenerated = '';
  final viewCourseId = TextEditingController();
  final viewDate = TextEditingController();
  List attendanceRows = [];
  int total = 0;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final res = await Api.get('/lecturer/profile/${widget.id}');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (!mounted) return;
        setState(() {
          profile = data['profile'] ?? {};
          courses = data['courses'] ?? [];
        });
      } else {
        _show('Failed to load profile');
      }
    } catch (e) {
      _show('Network error');
    }
  }

  Future<void> _addCourse() async {
    final cid = addCourseId.text.trim();
    final cname = addCourseName.text.trim();
    if (cid.isEmpty || cname.isEmpty) return _show('Fill all fields');

    try {
      final res = await Api.post('/lecturer/add-course', {
        'lecturer_id': widget.id,
        'course_id': cid,
        'course_name': cname,
      });

      if (res.statusCode == 200) {
        addCourseId.clear();
        addCourseName.clear();
        await _loadProfile();
        _show('Course added');
      } else {
        _show('Error: ${res.body}');
      }
    } catch (e) {
      _show('Network error');
    }
  }

  Future<void> _deleteCourse(String cid) async {
    try {
      final res = await Api.post('/lecturer/delete-course', {
        'lecturer_id': widget.id,
        'course_id': cid,
      });

      if (res.statusCode == 200) {
        await _loadProfile();
        _show('Deleted');
      } else {
        _show('Error: ${res.body}');
      }
    } catch (e) {
      _show('Network error');
    }
  }

  Future<void> _generateCode() async {
    final cid = genCourseId.text.trim();
    if (cid.isEmpty) return _show('Enter course ID');

    try {
      final res = await Api.post('/attendance/generate', {
        'lecturer_id': widget.id,
        'course_id': cid,
      });

      if (res.statusCode == 200) {
        final d = jsonDecode(res.body);
        setState(() => lastGenerated = d['code'] ?? '');
        _show('Code generated: $lastGenerated');
      } else {
        _show('Error generating code');
      }
    } catch (e) {
      _show('Network error');
    }
  }

  Future<void> _viewAttendance() async {
    final cid = viewCourseId.text.trim();
    final date = viewDate.text.trim();
    if (cid.isEmpty || date.isEmpty) return _show('Fill all fields');

    try {
      final res = await Api.get('/attendance/view?course_id=$cid&date=$date');
      if (res.statusCode == 200) {
        final d = jsonDecode(res.body);
        setState(() {
          attendanceRows = d['rows'] ?? [];
          total = d['total'] ?? attendanceRows.length;
        });
      } else {
        _show('Error loading attendance');
      }
    } catch (e) {
      _show('Network error');
    }
  }

  Future<void> _exportExcel() async {
    final cid = viewCourseId.text.trim();
    final date = viewDate.text.trim();
    if (cid.isEmpty || date.isEmpty) return _show('Fill all fields');

    final url = Uri.parse(
      '$API_BASE/attendance/export?course_id=$cid&date=$date',
    );

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        _show('Cannot launch export link');
      }
    } catch (e) {
      _show('Could not open URL');
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

  void _show(String s) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));
  }

  @override
  Widget build(BuildContext context) {
    final pages = [_profileTab(), _qrTab(), _genTab(), _viewTab()];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Lecturer — ${profile['name'] ?? widget.id}',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout, color: Colors.black),
          ),
        ],
      ),
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        onTap: (i) => setState(() => index = i),
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF0052CC),
        unselectedItemColor: Colors.grey,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(icon: Icon(Icons.qr_code), label: 'QR'),
          BottomNavigationBarItem(
            icon: Icon(Icons.lock_clock),
            label: 'Generate',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'View'),
        ],
      ),
    );
  }

  // ------------------ TABS ------------------

  Widget _profileTab() => Container(
        color: const Color(0xFFF5F1E8),
        child: RefreshIndicator(
          onRefresh: _loadProfile,
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
                            const Center(
                              child: Text(
                                'UNIPASS',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E3A5F),
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
                              child: profile['photo_url'] != null &&
                                      (profile['photo_url'] as String)
                                          .isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        profile['photo_url'],
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            const Icon(
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
                            // Lecturer info
                            _buildInfoRow('Name', profile['name'] ?? 'N/A'),
                            const SizedBox(height: 12),
                            _buildInfoRow('ID', profile['id'] ?? widget.id),
                            const SizedBox(height: 12),
                            _buildInfoRow(
                              'Department',
                              profile['department'] ?? 'N/A',
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Courses section
              const SizedBox(height: 20),
              const Text(
                'Enrolled courses',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              ...courses.map(
                (c) => Container(
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
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    title: Text(
                      c['course_name'] ?? '',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        c['course_id'] ?? '',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.remove_circle_outline,
                        color: Colors.red,
                        size: 24,
                      ),
                      onPressed: () => _deleteCourse(c['course_id']),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                'Enroll in New Course',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 15),
              TextField(
                controller: addCourseId,
                style: const TextStyle(fontSize: 16),
                decoration: InputDecoration(
                  labelText: 'Course id',
                  labelStyle: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 15,
                  ),
                  floatingLabelStyle: const TextStyle(
                    color: Color(0xFF0052CC),
                    fontSize: 16,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Color(0xFF0052CC),
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: addCourseName,
                style: const TextStyle(fontSize: 16),
                decoration: InputDecoration(
                  labelText: 'Course name',
                  labelStyle: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 15,
                  ),
                  floatingLabelStyle: const TextStyle(
                    color: Color(0xFF0052CC),
                    fontSize: 16,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Color(0xFF0052CC),
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _addCourse,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0052CC),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Enroll',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      );

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E3A5F),
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

  Widget _qrTab() {
    final payload = jsonEncode({
      'id': profile['id'] ?? widget.id,
      'name': profile['name'] ?? '',
      'department': profile['department'] ?? '',
    });

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          QrImageView(data: payload, size: 220),
          const SizedBox(height: 12),
          const Text('This QR contains lecturer id, name, department'),
        ],
      ),
    );
  }

  Widget _genTab() => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: genCourseId,
              decoration: const InputDecoration(labelText: 'Course ID'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _generateCode,
              child: const Text('Generate Attendance Code'),
            ),
            if (lastGenerated.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  'Last code: $lastGenerated',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      );

  Widget _viewTab() => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: viewCourseId,
              decoration: const InputDecoration(labelText: 'Course ID'),
            ),
            TextField(
              controller: viewDate,
              decoration: const InputDecoration(labelText: 'Date (YYYY-MM-DD)'),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _viewAttendance,
                  child: const Text('View'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _exportExcel,
                  child: const Text('Export Excel'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('Total: $total'),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                children: attendanceRows
                    .map(
                      (r) => ListTile(
                        title: Text(r['student_name'] ?? ''),
                        subtitle: Text(
                          '${r['student_id'] ?? ''} — ${r['submitted_at'] ?? ''}',
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      );
}
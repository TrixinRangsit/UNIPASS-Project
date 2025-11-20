// lib/screens/create_user_page.dart
import 'package:flutter/material.dart';
import '../services/api.dart';
import 'dart:convert';

class CreateUserPage extends StatefulWidget {
  const CreateUserPage({super.key});

  @override
  State<CreateUserPage> createState() => _CreateUserPageState();
}

class _CreateUserPageState extends State<CreateUserPage> {
  final id = TextEditingController();
  final name = TextEditingController();
  final password = TextEditingController();
  final department = TextEditingController();
  final major = TextEditingController();
  final photoUrl = TextEditingController();
  String role = "student";
  bool _loading = false;

  Future<void> createUser() async {
    final sId = id.text.trim();
    final sName = name.text.trim();
    final sPassword = password.text;
    final sDept = department.text.trim();
    final sMajor = major.text.trim();
    final sPhoto = photoUrl.text.trim();

    if (sId.isEmpty || sName.isEmpty || sPassword.isEmpty || role.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Please fill required fields (ID, Name, Password, Role)",
          ),
        ),
      );
      return;
    }

    setState(() => _loading = true);
    final res = await Api.post('/admin/create-user', {
      "id": sId,
      "name": sName,
      "password": sPassword,
      "department": sDept.isEmpty ? null : sDept,
      "major": sMajor.isEmpty ? null : sMajor,
      "photo_url": sPhoto.isEmpty ? null : sPhoto,
      "role": role,
    });
    setState(() => _loading = false);

    try {
      final body = json.decode(res.body);
      if (res.statusCode == 200 && body['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User created successfully")),
        );
        // Clear input
        id.clear();
        name.clear();
        password.clear();
        department.clear();
        major.clear();
        photoUrl.clear();
        setState(() => role = "student");
      } else {
        final msg = body['message'] ?? body['error'] ?? 'Failed to create user';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unexpected response: ${res.body}')),
      );
    }
  }

  @override
  void dispose() {
    id.dispose();
    name.dispose();
    password.dispose();
    department.dispose();
    major.dispose();
    photoUrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF4A90E2), Color(0xFF7B68EE)],
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, color: Colors.white),
            ),
            title: const Text(
              "Back",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      "Create new Account",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Fill in the details to create a new user",
                      style: TextStyle(fontSize: 14, color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    _buildInputField("ID", id, isRequired: true),
                    const SizedBox(height: 16),
                    _buildInputField("NAME", name, isRequired: true),
                    const SizedBox(height: 16),
                    _buildInputField(
                      "PASSWORD",
                      password,
                      isPassword: true,
                      isRequired: true,
                    ),
                    const SizedBox(height: 16),
                    _buildInputField("DEPARTMENT", department),
                    const SizedBox(height: 16),
                    _buildInputField("MAJOR", major),
                    const SizedBox(height: 16),
                    _buildInputField("PHOTO URL", photoUrl),
                    const SizedBox(height: 16),
                    _buildRoleDropdown(),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _loading ? null : createUser,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6B7FFF),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: _loading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                "Create User",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(
    String label,
    TextEditingController controller, {
    bool isPassword = false,
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
            if (isRequired)
              const Text(
                " *",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFE8F4F8),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: controller,
            obscureText: isPassword,
            decoration: InputDecoration(
              hintText: isRequired ? "Required" : "Optional",
              hintStyle: TextStyle(color: Colors.grey.shade400),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRoleDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              "ROLE",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
            const Text(
              " *",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFE8F4F8),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: role,
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down),
              items: const [
                DropdownMenuItem(value: "student", child: Text("Student")),
                DropdownMenuItem(value: "lecturer", child: Text("Lecturer")),
              ],
              onChanged: (v) => setState(() => role = v ?? "student"),
            ),
          ),
        ),
      ],
    );
  }
}

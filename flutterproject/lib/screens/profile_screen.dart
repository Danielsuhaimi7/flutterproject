import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../config.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool isEditing = false;
  bool isPasswordVisible = false;

  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController phoneController = TextEditingController();

  String studentId = "";
  String realPassword = "";
  File? profileImage;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    studentId = prefs.getString('studentId') ?? '';

    final imagePath = prefs.getString('profileImagePath');
    if (imagePath != null && File(imagePath).existsSync()) {
      setState(() => profileImage = File(imagePath));
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/get_user_info'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'student_id': studentId}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          nameController.text = data['name'] ?? '';
          emailController.text = data['email'] ?? '';
          phoneController.text = data['phone'] ?? '';
          realPassword = data['password'] ?? '';
          passwordController.text = '*' * realPassword.length;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load profile')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading profile: $e')),
      );
    }
  }

  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      try {
        final response = await http.post(
          Uri.parse('$baseUrl/update_user_info'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'student_id': studentId,
            'name': nameController.text,
            'email': emailController.text,
            'phone': phoneController.text,
            'password': passwordController.text == realPassword
                ? null
                : passwordController.text,
          }),
        );

        if (response.statusCode == 200) {
          final prefs = await SharedPreferences.getInstance();
          if (profileImage != null) {
            await prefs.setString('profileImagePath', profileImage!.path);
          }

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully')),
          );
          setState(() {
            isEditing = false;
            realPassword = passwordController.text;
            passwordController.text = '*' * realPassword.length;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to update profile')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Update error: $e')),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        profileImage = File(picked.path);
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profileImagePath', picked.path);
    }
  }

  Future<void> _removeImage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('profileImagePath');
    setState(() {
      profileImage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const SizedBox(height: 20),
              Center(
                child: Stack(
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.deepPurple,
                        backgroundImage: profileImage != null ? FileImage(profileImage!) : null,
                        child: profileImage == null
                            ? const Icon(Icons.person, size: 50, color: Colors.white)
                            : null,
                      ),
                    ),
                    if (profileImage != null)
                      Positioned(
                        right: -4,
                        top: -4,
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.red, size: 20),
                          onPressed: _removeImage,
                          splashRadius: 20,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  "Student ID: $studentId",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 24),
              _buildInput("Name", nameController, enabled: isEditing),
              _buildInput("Email", emailController,
                  type: TextInputType.emailAddress, enabled: isEditing),
              _buildPasswordInput(),
              _buildInput("Phone Number", phoneController,
                  type: TextInputType.phone, enabled: isEditing),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  if (isEditing) {
                    _saveChanges();
                  } else {
                    setState(() {
                      isEditing = true;
                      passwordController.text = realPassword;
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  isEditing ? "Save Changes" : "Edit Changes",
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInput(
    String label,
    TextEditingController controller, {
    TextInputType type = TextInputType.text,
    bool isPassword = false,
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        keyboardType: type,
        obscureText: isPassword,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: (value) {
          if (!enabled) return null;
          return value == null || value.isEmpty ? "Required" : null;
        },
      ),
    );
  }

  Widget _buildPasswordInput() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: passwordController,
        enabled: isEditing,
        obscureText: isEditing && !isPasswordVisible,
        decoration: InputDecoration(
          labelText: "Password",
          border: const OutlineInputBorder(),
          suffixIcon: isEditing
              ? IconButton(
                  icon: Icon(
                      isPasswordVisible ? Icons.visibility_off : Icons.visibility),
                  onPressed: () {
                    setState(() {
                      isPasswordVisible = !isPasswordVisible;
                    });
                  },
                )
              : null,
        ),
        validator: (value) {
          if (!isEditing) return null;
          return value == null || value.isEmpty ? "Required" : null;
        },
      ),
    );
  }
}

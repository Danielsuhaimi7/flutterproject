import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  final String userId;
  final String name;
  final String email;
  final String phone;
  final String dob;

  const ProfileScreen({
    super.key,
    required this.userId,
    required this.name,
    required this.email,
    required this.phone,
    required this.dob,
  });

  @override
  Widget build(BuildContext context) {
    final passwordController = TextEditingController(text: '********');

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(color: Colors.black),
        title: const Text('Edit Profile', style: TextStyle(color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Column(
          children: [
            const SizedBox(height: 20),
            CircleAvatar(
              radius: 60,
              backgroundColor: Colors.grey.shade200,
              child: Icon(Icons.camera_alt, size: 36, color: Colors.deepPurple),
            ),
            const SizedBox(height: 12),
            Text(userId, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

            const SizedBox(height: 24),
            buildTextField("Name", name),
            const SizedBox(height: 16),
            buildTextField("Email", email),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            buildDropdownField("Date of Birth", dob),
            const SizedBox(height: 16),
            buildDropdownField("Phone Number", phone),

            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text("Save changes", style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildTextField(String label, String value) {
    return TextField(
      decoration: InputDecoration(
        labelText: label,
        hintText: value,
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget buildDropdownField(String label, String value) {
    return TextField(
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        hintText: value,
        suffixIcon: const Icon(Icons.arrow_drop_down),
        border: const OutlineInputBorder(),
      ),
    );
  }
}

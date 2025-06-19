import 'package:flutter/material.dart';

class ManageUsersScreen extends StatelessWidget {
  const ManageUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Users"),
        backgroundColor: Colors.deepPurple,
      ),
      body: const Center(
        child: Text(
          "User management panel coming soon...",
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}

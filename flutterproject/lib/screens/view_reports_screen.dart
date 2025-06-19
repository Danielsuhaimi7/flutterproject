import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ViewReportsScreen extends StatefulWidget {
  const ViewReportsScreen({super.key});

  @override
  State<ViewReportsScreen> createState() => _ViewReportsScreenState();
}

class _ViewReportsScreenState extends State<ViewReportsScreen> {
  List<Map<String, dynamic>> reports = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchReports();
  }

  Future<void> fetchReports() async {
    try {
      final response = await http.get(Uri.parse('http://192.168.1.110:5000/all_reports'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          reports = List<Map<String, dynamic>>.from(data['reports']);
          isLoading = false;
        });
      } else {
        throw Exception("Failed to fetch reports");
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading reports: ${e.toString()}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("User Reports"),
        backgroundColor: Colors.deepPurple,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : reports.isEmpty
              ? const Center(child: Text("No reports available"))
              : ListView.builder(
                  itemCount: reports.length,
                  itemBuilder: (context, index) {
                    final report = reports[index];
                    return Card(
                      margin: const EdgeInsets.all(12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Name: ${report['name']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text("Student ID: ${report['student_id']}"),
                            Text("Parking: ${report['parking_location']}"),
                            Text("Slot: ${report['slot'] ?? 'N/A'}"),
                            Text("Report Type: ${report['report_type']}"),
                            if (report['image_url'] != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Image.network(
                                  report['image_url'],
                                  height: 160,
                                  fit: BoxFit.cover,
                                  errorBuilder: (ctx, _, __) => const Text("Image load error"),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

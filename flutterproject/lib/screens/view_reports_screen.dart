import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config.dart';

class ViewReportsScreen extends StatefulWidget {
  const ViewReportsScreen({super.key});

  @override
  State<ViewReportsScreen> createState() => _ViewReportsScreenState();
}

class _ViewReportsScreenState extends State<ViewReportsScreen> {
  List<Map<String, dynamic>> reports = [];
  Set<int> settledReportIds = {};
  Set<int> toggledSmallIcons = {}; // New: Track minimized icons
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchReports();
  }

  Future<void> fetchReports() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/all_reports'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final fetched = List<Map<String, dynamic>>.from(data['reports']);

        // Sort: unsettled (settled == 0) first, settled (== 1) last
        fetched.sort((a, b) => (a['settled'] as int).compareTo(b['settled'] as int));

        setState(() {
          reports = fetched;
          settledReportIds = fetched
              .where((r) => r['settled'] == 1)
              .map<int>((r) => r['id'] as int)
              .toSet();
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

  Future<void> markReportSettled(int id) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/mark_report_settled'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'report_id': id}),
      );

      if (response.statusCode == 200) {
        setState(() {
          settledReportIds.add(id);
          toggledSmallIcons.add(id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Report has been successfully resolved.")),
        );
      } else {
        throw Exception("Failed to mark settled");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    }
  }

  void toggleIconSize(int id) {
    setState(() {
      if (toggledSmallIcons.contains(id)) {
        toggledSmallIcons.remove(id);
      } else {
        toggledSmallIcons.add(id);
      }
    });
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
                    final int reportId = report['id'];
                    final bool isSettled = settledReportIds.contains(reportId);
                    final bool isSmall = toggledSmallIcons.contains(reportId);

                    return Card(
                      margin: const EdgeInsets.all(12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    "Name: ${report['name']}",
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    if (!isSettled) {
                                      markReportSettled(reportId);
                                    } else {
                                      toggleIconSize(reportId);
                                    }
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: isSmall ? 24 : 32,
                                    height: isSmall ? 24 : 32,
                                    child: Icon(
                                      isSettled
                                          ? Icons.check_circle
                                          : Icons.check_circle_outline,
                                      color: isSettled ? Colors.green : Colors.grey,
                                      size: isSmall ? 20 : 28,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
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
                                  errorBuilder: (ctx, _, __) =>
                                      const Text("Image load error"),
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

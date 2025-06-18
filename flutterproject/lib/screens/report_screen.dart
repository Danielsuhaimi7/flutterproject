import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as p;

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final nameController = TextEditingController();
  final idController = TextEditingController();
  String? selectedParking;
  String? selectedReport;
  File? selectedFile;

  List<String> parkingOptions = [];
  bool isLoadingParkingOptions = true;

  final List<String> reportTypes = [
    'Blocked Parking',
    'Unauthorized Parking',
    'Extreme Weather Condition',
    'Others',
  ];

  @override
  void initState() {
    super.initState();
    _fetchParkingLocations();
  }

  Future<void> _fetchParkingLocations() async {
    try {
      final response = await http.get(Uri.parse('http://192.168.1.110:5000/get_parkings'));

      if (response.statusCode == 200) {
        final data = Map<String, dynamic>.from(jsonDecode(response.body));
        final List<dynamic> parkings = data['parkings'];

        setState(() {
          parkingOptions = parkings.map((p) => p['name'].toString()).toList();
          isLoadingParkingOptions = false;
        });
      } else {
        throw Exception('Failed to load parking list');
      }
    } catch (e) {
      setState(() {
        isLoadingParkingOptions = false;
      });
      print('Error fetching parking options: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading parking list")),
      );
    }
  }

  Future<void> _pickFile() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        selectedFile = File(picked.path);
      });
    }
  }

  Future<void> _submitReport() async {
    if (selectedParking == null || selectedReport == null || nameController.text.isEmpty || idController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please complete all required fields.")),
      );
      return;
    }

    final uri = Uri.parse('http://192.168.1.110:5000/report');

    try {
      var request = http.MultipartRequest('POST', uri)
        ..fields['student_id'] = idController.text
        ..fields['name'] = nameController.text
        ..fields['parking_location'] = selectedParking!
        ..fields['report_type'] = selectedReport!;

      if (selectedFile != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'file',
          selectedFile!.path,
          contentType: MediaType('image', 'jpeg'),
        ));
      }

      final response = await request.send();

      if (response.statusCode == 200) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Report Submitted"),
            content: const Text("Your parking report has been submitted."),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              )
            ],
          ),
        );
        nameController.clear();
        idController.clear();
        setState(() {
          selectedParking = null;
          selectedReport = null;
          selectedFile = null;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to submit report.")),
        );
      }
    } catch (e) {
      print("Report error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Connection error: ${e.toString()}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Parking Report"),
        leading: const BackButton(color: Colors.black),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Name", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: idController,
              decoration: const InputDecoration(labelText: "Student ID", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),

            isLoadingParkingOptions
                ? const CircularProgressIndicator()
                : DropdownButtonFormField<String>(
                    value: selectedParking,
                    hint: const Text("Select Parking"),
                    items: parkingOptions.map((location) {
                      return DropdownMenuItem(value: location, child: Text(location));
                    }).toList(),
                    onChanged: (value) => setState(() => selectedParking = value),
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                  ),

            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedReport,
              hint: const Text("Type of Report"),
              items: reportTypes.map((type) {
                return DropdownMenuItem(value: type, child: Text(type));
              }).toList(),
              onChanged: (value) => setState(() => selectedReport = value),
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),

            GestureDetector(
              onTap: _pickFile,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.upload_file, size: 36, color: Colors.grey),
                    const SizedBox(height: 8),
                    const Text("Upload Additional file", style: TextStyle(color: Colors.grey)),
                    if (selectedFile != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          "Selected: ${p.basename(selectedFile!.path)}",
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _submitReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple.shade900,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text("SUBMIT", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }
}
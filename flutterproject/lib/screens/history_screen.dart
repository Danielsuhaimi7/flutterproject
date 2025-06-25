import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'navigation_screen.dart';

String studentName = "";

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> userReservations = [];
  bool isLoading = true;
  String studentId = "";
  File? profileImage;

  @override
  void initState() {
    super.initState();
    _fetchReservations();
  }

  Future<void> _fetchReservations() async {
    final prefs = await SharedPreferences.getInstance();
    studentId = prefs.getString('studentId') ?? "";
    studentName = prefs.getString('name') ?? "";

    final imagePath = prefs.getString('profileImagePath');
    if (imagePath != null && File(imagePath).existsSync()) {
      setState(() {
        profileImage = File(imagePath);
      });
    }

    if (studentId.isNotEmpty) {
      final reservations = await ApiService.getAllUserReservations(studentId);
      setState(() {
        userReservations = reservations;
        isLoading = false;
      });
    }
  }

  String _formatDate(dynamic dateValue) {
    try {
      if (dateValue == null) return "N/A";

      final raw = dateValue.toString().replaceAll('GMT', '').trim();
      final parsed = DateTime.tryParse(raw) ??
          DateTime.tryParse(DateTime.parse(raw).toIso8601String());

      if (parsed != null) {
        return "${parsed.day.toString().padLeft(2, '0')}-${parsed.month.toString().padLeft(2, '0')}-${parsed.year}";
      }

      return raw;
    } catch (e) {
      return dateValue.toString();
    }
  }

  String _formatTime(dynamic time) {
    try {
      if (time == null) return "N/A";

      if (time is int) {
        final t = TimeOfDay(hour: time, minute: 0);
        final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
        final period = t.period == DayPeriod.am ? "AM" : "PM";
        return "$hour:00 $period";
      }

      final timeStr = time.toString().split(" ").first; // strip off GMT
      final parsed = DateTime.tryParse("1970-01-01T$timeStr");
      if (parsed != null) {
        final t = TimeOfDay.fromDateTime(parsed);
        final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
        final period = t.period == DayPeriod.am ? "AM" : "PM";
        return "$hour:${t.minute.toString().padLeft(2, '0')} $period";
      }

      return time.toString();
    } catch (e) {
      return time.toString();
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Paid':
        return Colors.green;
      case 'Cancel':
        return Colors.red;
      case 'Reserved':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  void _showReservationDetails(BuildContext context, Map<String, dynamic> reservation) {
    final slotCode = reservation['slot_code'] ?? 'A${(reservation['slot_index'] ?? 0) + 1}';
    final parking = reservation['parking_name'] ?? 'Sky Park';
    final date = _formatDate(reservation['date']);
    final time = _formatTime(reservation['time']);
    final duration = reservation['duration'] ?? 'N/A';

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Reservation Details"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Parking: $parking", style: const TextStyle(fontWeight: FontWeight.bold)),
            Text("Slot: $slotCode"),
            Text("Date: $date"),
            Text("Time: $time"),
            Text("Duration: $duration hour(s)"),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => NavigationScreen(initialReservation: reservation),
                  ),
                );
              },
              child: const Center(
                child: Text(
                  "[ Tap to view map ]",
                  style: TextStyle(color: Colors.deepPurple, decoration: TextDecoration.underline),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Parking History", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
      ),
      backgroundColor: Colors.grey[100],
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.grey.shade300,
                            backgroundImage: profileImage != null ? FileImage(profileImage!) : null,
                            child: profileImage == null
                                ? const Icon(Icons.person, color: Colors.white)
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(studentName, style: const TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(studentId, style: const TextStyle(color: Colors.grey)),
                            ],
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text("📄 Parking History", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.builder(
                        itemCount: userReservations.length,
                        itemBuilder: (context, index) {
                          final res = userReservations[index];
                          final formattedDate = _formatDate(res['date']);
                          final formattedTime = _formatTime(res['time']);
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            child: ListTile(
                              leading: const Icon(Icons.calendar_today),
                              title: Text(
                                res['parking_name'] != null ? "${res['parking_name']}" : "Sky Park",
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(formattedDate),
                                  Text("Time: $formattedTime"),
                                ],
                              ),
                              trailing: Text(
                                "Reserved",
                                style: TextStyle(
                                  color: _getStatusColor("Reserved"),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              onTap: () => _showReservationDetails(context, res),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text("Back to Homepage", style: TextStyle(fontSize: 16)),
                      ),
                    )
                  ],
                ),
              ),
            ),
    );
  }
}

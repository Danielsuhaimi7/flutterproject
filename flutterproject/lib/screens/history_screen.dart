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

  @override
  void initState() {
    super.initState();
    _fetchReservations();
  }

  Future<void> _fetchReservations() async {
    final prefs = await SharedPreferences.getInstance();
    studentId = prefs.getString('studentId') ?? "";
    studentName = prefs.getString('name') ?? "";

    if (studentId.isNotEmpty) {
      final reservations = await ApiService.getUserReservationDetails(studentId);
      setState(() {
        userReservations = reservations;
        isLoading = false;
      });
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
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Reservation Details"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Slot: ${reservation['slot_code']}", style: const TextStyle(fontWeight: FontWeight.bold)),
            Text("Date: ${reservation['date']}"),
            Text("Time: ${_formatTime(reservation['time'])}"),
            Text("Duration: ${reservation['duration']} hour(s)"),
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

  String _formatTime(dynamic time) {
    try {
      String timeStr;

      // Convert int like 18 to '18:00'
      if (time is int) {
        timeStr = '${time.toString().padLeft(2, '0')}:00';
      } else {
        timeStr = time.toString();
      }

      final parsed = TimeOfDay.fromDateTime(DateTime.parse("1970-01-01T$timeStr"));
      final hour = parsed.hourOfPeriod == 0 ? 12 : parsed.hourOfPeriod;
      final period = parsed.period == DayPeriod.am ? "AM" : "PM";
      return "$hour:${parsed.minute.toString().padLeft(2, '0')} $period";
    } catch (e) {
      return time.toString();
    }
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
          : Padding(
              padding: const EdgeInsets.all(16),
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
                        const CircleAvatar(radius: 24, backgroundColor: Colors.grey),
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
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            leading: const Icon(Icons.calendar_today),
                            title: Text(res['date'] ?? ''),
                            subtitle: Text("Time: ${_formatTime(res['time'])}"),
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
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text("Back to Homepage", style: TextStyle(fontSize: 16)),
                    ),
                  )
                ],
              ),
            ),
    );
  }
}
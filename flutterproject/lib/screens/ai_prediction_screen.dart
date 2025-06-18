import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'weekly_summary_screen.dart';

class AIPredictionScreen extends StatefulWidget {
  const AIPredictionScreen({super.key});

  @override
  State<AIPredictionScreen> createState() => _AIPredictionScreenState();
}

class _AIPredictionScreenState extends State<AIPredictionScreen> {
  Map<int, Map<int, double>> availability = {}; // day -> hour -> probability
  bool isLoading = true;

  final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final hours = List.generate(11, (i) => i + 8); // 8 AM to 6 PM

  @override
  void initState() {
    super.initState();
    fetchWeeklyAvailability();
  }

  Future<void> fetchWeeklyAvailability() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(Uri.parse('http://10.0.2.2:5000/weekly_availability'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          availability = Map.fromIterable(
            List.generate(7, (i) => i + 1),
            value: (day) => Map<int, double>.from(
              Map.from(data['availability'][day.toString()] ?? {}),
            ),
          );
        });
      } else {
        print("Error: ${response.statusCode}");
      }
    } catch (e) {
      print("Exception: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Color getColorForAvailability(double value) {
    if (value > 0.8) return Colors.green;
    if (value > 0.5) return Colors.yellow;
    if (value > 0.2) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Parking Availability'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  const Text(
                    'Parking Availability Heatmap (This Week)',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const SizedBox(width: 40),
                              ...days.map((d) => Container(
                                    width: 50,
                                    alignment: Alignment.center,
                                    child: Text(d, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  )),
                            ],
                          ),
                          ...hours.map((hour) => Row(
                                children: [
                                  SizedBox(
                                    width: 40,
                                    child: Text('${hour}h', style: const TextStyle(fontSize: 12)),
                                  ),
                                  ...List.generate(7, (dayIndex) {
                                    final day = dayIndex + 1;
                                    final prob = availability[day]?[hour] ?? 1.0;
                                    return Container(
                                      width: 50,
                                      height: 30,
                                      margin: const EdgeInsets.all(1),
                                      color: getColorForAvailability(prob),
                                      child: Center(
                                        child: Text(
                                          '${(prob * 100).round()}%',
                                          style: const TextStyle(fontSize: 10, color: Colors.black),
                                        ),
                                      ),
                                    );
                                  }),
                                ],
                              )),
                        ],
                      ),
                    ),
                  ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const WeeklySummaryScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple.shade100,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text("View Weekly Summary"),
                    ),
                ],
              ),
            ),
    );
  }
}

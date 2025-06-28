import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'weekly_summary_screen.dart';
import '../config.dart';

class AIPredictionScreen extends StatefulWidget {
  const AIPredictionScreen({super.key});

  @override
  State<AIPredictionScreen> createState() => _AIPredictionScreenState();
}

class _AIPredictionScreenState extends State<AIPredictionScreen> {
  Map<int, Map<int, double>> availability = {};
  bool isLoading = true;

  List<String> locations = [];
  String? selectedLocation;

  final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final hours = List.generate(11, (i) => i + 8);

  @override
  void initState() {
    super.initState();
    loadLocationsAndFetch();
  }

  Future<void> loadLocationsAndFetch() async {
    await fetchLocations();
    if (selectedLocation != null) {
      await fetchAvailabilityForLocation(selectedLocation!);
    }
  }

  Future<void> fetchLocations() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/get_parking_locations'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          locations = List<String>.from(data['locations']);
          selectedLocation = locations.isNotEmpty ? locations[0] : null;
        });
      }
    } catch (_) {}
  }

  Future<void> fetchAvailabilityForLocation(String location) async {
    setState(() => isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/weekly_availability_by_location'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'location': selectedLocation}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          availability = Map.fromIterable(
            List.generate(7, (i) => i + 1),
            value: (day) {
              final raw = data['availability'][day.toString()] ?? {};
              return Map<int, double>.fromEntries(
                (raw as Map<String, dynamic>).entries.map(
                  (e) => MapEntry(int.parse(e.key), (e.value as num).toDouble()),
                ),
              );
            },
          );
        });
      }
    } catch (_) {} 
    finally {
      setState(() => isLoading = false);
    }
  }

  Color getColorForAvailability(double value) {
    if (value > 0.8) return Colors.green;
    if (value > 0.5) return Colors.yellow;
    if (value > 0.2) return Colors.orange;
    return Colors.red;
  }

  String formatHour(int hour) {
    final displayHour = hour <= 12 ? hour : hour - 12;
    final period = hour < 12 ? 'AM' : 'PM';
    return '$displayHour $period';
  }

  void showDayAvailabilitySheet(int dayIndex) {
    final day = (dayIndex + 1) % 7 + 1;
    final dayData = availability[day] ?? {};

    showModalBottomSheet(
      context: context,
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Availability on ${days[dayIndex]}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...hours.map((hour) {
                final prob = dayData[hour] ?? 1.0;
                return ListTile(
                  dense: true,
                  leading: Text(formatHour(hour)),
                  title: LinearProgressIndicator(
                    value: prob,
                    color: getColorForAvailability(prob),
                    backgroundColor: Colors.grey[300],
                  ),
                  trailing: Text('${(prob * 100).round()}%'),
                );
              }).toList(),
            ],
          ),
        );
      },
    );
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
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    const Text(
                      'Parking Availability Heatmap (This Week)',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    if (locations.isNotEmpty)
                      DropdownButton<String>(
                        value: selectedLocation,
                        items: locations.map((loc) => DropdownMenuItem(
                          value: loc,
                          child: Text(loc),
                        )).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => selectedLocation = val);
                            fetchAvailabilityForLocation(val);
                          }
                        },
                      ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const SizedBox(width: 48),
                                ...List.generate(days.length, (i) {
                                  return GestureDetector(
                                    onTap: () => showDayAvailabilitySheet(i),
                                    child: Container(
                                      width: 50,
                                      alignment: Alignment.center,
                                      child: Text(
                                        days[i],
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            ),
                            ...hours.map((hour) => Row(
                                  children: [
                                    SizedBox(
                                      width: 48,
                                      child: Text(formatHour(hour), style: const TextStyle(fontSize: 12)),
                                    ),
                                    ...List.generate(7, (dayIndex) {
                                      final day = (dayIndex + 1) % 7 + 1;
                                      final prob = availability[day]?[hour] ?? 1.0;
                                      return Container(
                                        width: 50,
                                        height: 32,
                                        margin: const EdgeInsets.symmetric(horizontal: 1, vertical: 2),
                                        color: getColorForAvailability(prob),
                                        child: Center(
                                          child: Text(
                                            '${(prob * 100).round()}%',
                                            style: const TextStyle(fontSize: 11),
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
                    const SizedBox(height: 16),
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
            ),
    );
  }
}

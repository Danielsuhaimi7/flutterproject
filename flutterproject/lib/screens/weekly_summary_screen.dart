import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import '../config.dart';
import 'package:flutterproject/screens/prediction_screen.dart';

class WeeklySummaryScreen extends StatefulWidget {
  const WeeklySummaryScreen({super.key});

  @override
  State<WeeklySummaryScreen> createState() => _WeeklySummaryScreenState();
}

class _WeeklySummaryScreenState extends State<WeeklySummaryScreen> {
  List<double> availabilities = List.filled(7, 1.0);
  double avg = 1.0;
  bool isLoading = true;

  final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(Uri.parse('$baseUrl/weekly_availability'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final raw = data['availability'] as Map<String, dynamic>;

        List<double> result = List.filled(7, 1.0);
        for (int i = 1; i <= 7; i++) {
          int index = (i == 1) ? 6 : i - 2;
          result[index] = (raw[i.toString()] ?? 1.0).toDouble();
        }

        setState(() {
          availabilities = result;
          avg = result.reduce((a, b) => a + b) / result.length;
        });
      }
    } catch (e) {
      print("Error: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  List<BarChartGroupData> getBarGroups() {
    return List.generate(7, (index) {
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: availabilities[index] * 100,
            width: 20,
            color: Colors.lightBlue,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Weekly Summary"),
        actions: [
          IconButton(
            icon: Icon(Icons.analytics_outlined),
            tooltip: 'Prediction',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PredictionScreen()),
              );
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      "Daily Availability",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: BarChart(
                        BarChartData(
                          maxY: 100,
                          barGroups: getBarGroups(),
                          titlesData: FlTitlesData(
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, _) => Text(days[value.toInt()]),
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                interval: 20,
                                reservedSize: 42, // Ensures enough space for "100%"
                                getTitlesWidget: (value, _) => SizedBox(
                                  width: 40,
                                  child: Text(
                                    '${value.toInt()}%',
                                    style: const TextStyle(fontSize: 12),
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                              ),
                            ),
                            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          gridData: FlGridData(show: true),
                          borderData: FlBorderData(show: false),
                          extraLinesData: ExtraLinesData(horizontalLines: [
                            HorizontalLine(
                              y: avg * 100,
                              color: Colors.green,
                              strokeWidth: 2,
                              dashArray: [5, 5],
                              label: HorizontalLineLabel(
                                show: true,
                                labelResolver: (_) => 'Avg',
                                style: const TextStyle(color: Colors.green),
                                alignment: Alignment.centerLeft,
                              ),
                            ),
                          ]),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: fetchData,
                      icon: const Icon(Icons.refresh),
                      label: const Text("Refresh Data"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
    );
  }
}

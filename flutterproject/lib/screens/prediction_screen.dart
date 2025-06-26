import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class PredictionScreen extends StatefulWidget {
  @override
  _PredictionScreenState createState() => _PredictionScreenState();
}

class _PredictionScreenState extends State<PredictionScreen> {
  String? selectedLocation;
  TimeOfDay selectedTime = TimeOfDay(hour: 11, minute: 0);
  String selectedDay = 'Tuesday';
  double? prediction;
  List<String> locations = [];

  final List<String> days = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  void _loadLocations() async {
    final locs = await ApiService.getParkingLocationNames();
    setState(() {
      locations = locs;
    });
  }

  void _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );
    if (picked != null && picked != selectedTime) {
      setState(() {
        selectedTime = picked;
      });
    }
  }

  void _fetchPrediction() async {
    if (selectedLocation == null) return;

    final hour = selectedTime.hour;
    final weekday = days.indexOf(selectedDay) + 1;

    final result = await ApiService.predictAvailability(
      location: selectedLocation!,
      hour: hour,
      weekday: weekday,
    );

    if (result != null) {
      setState(() {
        prediction = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Parking Prediction")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Parking location"),
            DropdownButtonFormField<String>(
              value: selectedLocation,
              hint: Text("Select location"),
              items: locations.map((loc) {
                return DropdownMenuItem(value: loc, child: Text(loc));
              }).toList(),
              onChanged: (val) {
                setState(() {
                  selectedLocation = val;
                });
              },
            ),
            SizedBox(height: 16),
            Text("Time"),
            InkWell(
              onTap: _pickTime,
              child: InputDecorator(
                decoration: InputDecoration(
                  hintText: 'Pick time',
                  suffixIcon: Icon(Icons.access_time),
                ),
                child: Text(selectedTime.format(context)),
              ),
            ),
            SizedBox(height: 16),
            Text("Day"),
            DropdownButtonFormField<String>(
              value: selectedDay,
              items: days.map((day) {
                return DropdownMenuItem(value: day, child: Text(day));
              }).toList(),
              onChanged: (val) {
                setState(() {
                  selectedDay = val!;
                });
              },
            ),
            SizedBox(height: 32),
            Center(
              child: ElevatedButton(
                onPressed: _fetchPrediction,
                child: Text("Get Prediction"),
              ),
            ),
            SizedBox(height: 32),
            if (prediction != null)
              Center(
                child: Text(
                  "Estimated chance of finding parking:\n${(prediction! * 100).toStringAsFixed(1)}%",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

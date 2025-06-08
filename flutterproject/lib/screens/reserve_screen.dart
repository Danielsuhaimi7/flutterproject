import 'package:flutter/material.dart';

class ReserveScreen extends StatefulWidget {
  const ReserveScreen({super.key});

  @override
  State<ReserveScreen> createState() => _ReserveScreenState();
}

class _ReserveScreenState extends State<ReserveScreen> {
  String? selectedSlot;
  String duration = "1 hour";

  final List<String> availableSlots = ["FCI-P1", "FCI-P2", "Library-1", "MainHall-2"];
  final List<String> durations = ["1 hour", "2 hours", "3 hours"];

  void confirmReservation() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Reserved $selectedSlot for $duration")),
    );
    // API call can be added here
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Reserve Parking")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField(
              hint: Text("Select Parking Slot"),
              items: availableSlots.map((slot) {
                return DropdownMenuItem(value: slot, child: Text(slot));
              }).toList(),
              onChanged: (value) => setState(() => selectedSlot = value),
            ),
            DropdownButtonFormField(
              value: duration,
              items: durations.map((d) {
                return DropdownMenuItem(value: d, child: Text(d));
              }).toList(),
              onChanged: (value) => setState(() => duration = value!),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: selectedSlot != null ? confirmReservation : null,
              child: Text("Confirm Reservation"),
            ),
          ],
        ),
      ),
    );
  }
}

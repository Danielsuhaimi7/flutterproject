import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutterproject/screens/parking_map_screen.dart';

class ReserveScreen extends StatefulWidget {
  const ReserveScreen({super.key});

  @override
  State<ReserveScreen> createState() => _ReserveScreenState();
}

class _ReserveScreenState extends State<ReserveScreen> {
  String? selectedSlot;
  String duration = "1 hour";

  final List<String> availableSlots = [
    "A1", "A2", "A3", "A4", "A5", "A6", "A7", "A8", "A9", "A10"
  ];
  final List<String> durations = ["1 hour", "2 hours", "3 hours"];

  void confirmReservation() async {
    if (selectedSlot == null) return;

    // Save the reserved slot locally
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('reservedSlot', selectedSlot!);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Reserved $selectedSlot for $duration")),
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ParkingMapScreen(slotToNavigate: selectedSlot!),
      ),
    );
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
              decoration: InputDecoration(labelText: "Select Duration"),
              items: durations.map((d) {
                return DropdownMenuItem(value: d, child: Text(d));
              }).toList(),
              onChanged: (value) => setState(() => duration = value!),
            ),
            const SizedBox(height: 20),
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

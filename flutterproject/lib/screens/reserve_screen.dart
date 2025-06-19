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
      appBar: AppBar(title: const Text("Reserve Parking")),
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  children: [
                    DropdownButtonFormField<String>(
                      hint: const Text("Select Parking Slot"),
                      value: selectedSlot,
                      items: availableSlots.map((slot) {
                        return DropdownMenuItem(
                          value: slot,
                          child: Text(slot),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() => selectedSlot = value),
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      value: duration,
                      decoration: const InputDecoration(labelText: "Select Duration"),
                      items: durations.map((d) {
                        return DropdownMenuItem(
                          value: d,
                          child: Text(d),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() => duration = value!),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: selectedSlot != null ? confirmReservation : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text("Confirm Reservation", style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

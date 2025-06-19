import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class ReserveCustomParkingScreen extends StatefulWidget {
  final String parkingName;

  const ReserveCustomParkingScreen({super.key, required this.parkingName});

  @override
  State<ReserveCustomParkingScreen> createState() => _ReserveCustomParkingScreenState();
}

class _ReserveCustomParkingScreenState extends State<ReserveCustomParkingScreen> {
  List<Map<String, dynamic>> layout = [];
  int? selectedSlotIndex;
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();
  String selectedDuration = '1 hour';
  final List<String> durations = ['1 hour', '2 hours', '3 hours'];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLayout();
  }

  Future<void> _loadLayout() async {
    final fetched = await ApiService.getCustomLayout(widget.parkingName);
    setState(() {
      layout = fetched;
      isLoading = false;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) setState(() => selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );
    if (picked != null) setState(() => selectedTime = picked);
  }

  void _confirmReservation() {
    if (selectedSlotIndex == null) return;

    final slot = layout[selectedSlotIndex!];
    final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
    final timeStr = selectedTime.format(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Reserved Slot A${slot['index'] + 1} on $dateStr at $timeStr for $selectedDuration')),
    );

    // TODO: Backend reservation API
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
    final timeStr = selectedTime.format(context);

    return Scaffold(
      appBar: AppBar(
        title: Text("Parking Layout"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    Expanded(
                      child: Stack(
                        children: layout.asMap().entries.map((entry) {
                          final index = entry.key;
                          final slot = entry.value;
                          final isSelected = selectedSlotIndex == index;
                          final dx = (slot['x'] ?? 0).toDouble();
                          final dy = (slot['y'] ?? 0).toDouble();
                          final isVertical = slot['vertical'] ?? true;

                          return Positioned(
                            left: dx,
                            top: dy,
                            child: GestureDetector(
                              onTap: () => setState(() => selectedSlotIndex = index),
                              child: RotatedBox(
                                quarterTurns: isVertical ? 0 : 1,
                                child: Container(
                                  width: 40,
                                  height: 60,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: isSelected ? Colors.deepPurple : Colors.green,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'A${slot['index'] + 1}',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: _pickDate,
                            child: Container(
                              height: 50,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.centerLeft,
                              child: Text(dateStr),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: _pickTime,
                            child: Container(
                              height: 50,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.centerLeft,
                              child: Text(timeStr),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedDuration,
                      decoration: const InputDecoration(
                        labelText: "Duration (hrs)",
                        border: OutlineInputBorder(),
                      ),
                      items: durations.map((d) {
                        return DropdownMenuItem(value: d, child: Text(d));
                      }).toList(),
                      onChanged: (val) => setState(() => selectedDuration = val!),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: selectedSlotIndex != null ? _confirmReservation : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: selectedSlotIndex != null ? Colors.deepPurple : Colors.grey.shade400,
                          foregroundColor: selectedSlotIndex != null ? Colors.white : Colors.black45,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text("Reserve Slot", style: TextStyle(fontSize: 16)),
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

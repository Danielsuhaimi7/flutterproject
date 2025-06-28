import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReserveCustomParkingScreen extends StatefulWidget {
  final String parkingName;

  const ReserveCustomParkingScreen({super.key, required this.parkingName});

  @override
  State<ReserveCustomParkingScreen> createState() => _ReserveCustomParkingScreenState();
}

class _ReserveCustomParkingScreenState extends State<ReserveCustomParkingScreen> {
  List<Map<String, dynamic>> layout = [];
  Set<int> bookedIndices = {};
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
    final layoutFetched = await ApiService.getCustomLayout(widget.parkingName);
    final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
    final timeStr = DateFormat('HH:mm:ss').format(
      DateTime(selectedDate.year, selectedDate.month, selectedDate.day, selectedTime.hour, selectedTime.minute),
    );

    final booked = await ApiService.getBookedCustomSlots(
      parkingName: widget.parkingName,
      date: dateStr,
      time: timeStr,
    );

    setState(() {
      layout = layoutFetched;
      bookedIndices = booked.toSet();
      selectedSlotIndex = null;
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
    if (picked != null) {
      setState(() => selectedDate = picked);
      _loadLayout(); 
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: selectedTime,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => selectedTime = picked);
      _loadLayout();
    }
  }

  void _confirmReservation() async {
    final prefs = await SharedPreferences.getInstance();
    final studentId = prefs.getString('studentId');

    if (studentId == null || selectedSlotIndex == null) return;

    final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
    final timeStr = DateFormat('HH:mm:ss').format(DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    ));

    final durationInt = int.parse(selectedDuration.split(" ")[0]);

    final success = await ApiService.reserveCustomSlot(
      studentId: studentId,
      parkingName: widget.parkingName,
      slotIndex: selectedSlotIndex!,
      date: dateStr,
      time: timeStr,
      duration: durationInt,
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reserved Slot A${selectedSlotIndex! + 1}')),
      );
      _loadLayout();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to reserve slot')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
    final timeStr = DateFormat('h:mm a').format(
      DateTime(0, 0, 0, selectedTime.hour, selectedTime.minute),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text("Parking Layout"),
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
                          final isBooked = bookedIndices.contains(index);
                          final dx = (slot['x'] ?? 0).toDouble();
                          final dy = (slot['y'] ?? 0).toDouble();
                          final isVertical = slot['vertical'] ?? true;

                          return Positioned(
                            left: dx,
                            top: dy,
                            child: GestureDetector(
                              onTap: isBooked
                                  ? null
                                  : () => setState(() => selectedSlotIndex = index),
                              child: RotatedBox(
                                quarterTurns: isVertical ? 0 : 1,
                                child: Container(
                                  width: 40,
                                  height: 60,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: isBooked
                                        ? Colors.red
                                        : (isSelected
                                            ? Colors.deepPurple
                                            : Colors.green),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'A${slot['index'] + 1}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
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
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
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
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
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
                        onPressed: selectedSlotIndex != null
                            ? _confirmReservation
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: selectedSlotIndex != null
                              ? Colors.deepPurple
                              : Colors.grey.shade400,
                          foregroundColor: selectedSlotIndex != null
                              ? Colors.white
                              : Colors.black45,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text("Reserve Slot",
                            style: TextStyle(fontSize: 16)),
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

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';

class ParkingMapScreen extends StatefulWidget {
  final String slotToNavigate;

  const ParkingMapScreen({super.key, required this.slotToNavigate});

  @override
  State<ParkingMapScreen> createState() => _ParkingMapScreenState();
}

class _ParkingMapScreenState extends State<ParkingMapScreen> {
  String? selectedSlot;
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();
  int selectedDuration = 1;
  final Set<String> takenSlots = {};

  final List<String> slots = [
    'A1', 'A2', 'A3', 'A4', 'A5', 'A6', 'A7', 'A8', 'A9', 'A10',
    'A11', 'A12', 'A13', 'A14', 'A15', 'A16', 'A17', 'A18', 'A19', 'A20'
  ];

  final Offset entrancePosition = Offset(160, 700);
  List<Offset> slotPositions = [];

  @override
  void initState() {
    super.initState();
    selectedSlot = widget.slotToNavigate;
    slotPositions = _generateSlotPositions();
    _loadTakenSlots();
  }

  Future<void> _loadTakenSlots() async {
    final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
    final timeStr = _convertTimeTo24Hour(selectedTime);
    final fetched = await ApiService.getBookedSlots(dateStr, timeStr);

    setState(() {
      takenSlots.clear();
      takenSlots.addAll(fetched);
      selectedSlot = null;
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
      _loadTakenSlots();
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
      _loadTakenSlots();
    }
  }

  String _convertTimeTo24Hour(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat('HH:mm:ss').format(dt);
  }

  bool get isReadyToReserve {
    return selectedSlot != null && selectedDuration > 0;
  }

  void _reserveSlot() async {
    final prefs = await SharedPreferences.getInstance();
    final studentId = prefs.getString('studentId');

    if (studentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User not logged in")),
      );
      return;
    }

    final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
    final timeStr = _convertTimeTo24Hour(selectedTime);

    final success = await ApiService.reserveSlot(
      studentId: studentId,
      slotCode: selectedSlot!,
      date: dateStr,
      time: timeStr,
      duration: selectedDuration,
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Reservation successful!")),
      );
      _loadTakenSlots();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to reserve slot")),
      );
    }
  }

  void _saveParkingToDatabase(String name, double lat, double lng) async {
    final uri = Uri.parse('http://192.168.1.110:5000/add_parking_location');

    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'latitude': lat,
          'longitude': lng,
        }),
      );

      final data = jsonDecode(response.body);
      if (data['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ "$name" added to database')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Failed to add parking: ${data['message']}')),
        );
      }
    } catch (e) {
      print('Error saving parking: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connection error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Offset? reservedOffset;
    if (selectedSlot != null) {
      final index = slots.indexOf(selectedSlot!);
      if (index != -1 && index < slotPositions.length) {
        reservedOffset = slotPositions[index];
      } else {
        reservedOffset = null;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Parking Layout", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: SizedBox(
                height: 800,
                child: Stack(
                  children: [
                    if (reservedOffset != null)
                      CustomPaint(
                        size: Size.infinite,
                        painter: DottedLinePainter(entrancePosition, reservedOffset),
                      ),
                    Positioned(
                      left: entrancePosition.dx,
                      top: entrancePosition.dy,
                      child: const Icon(Icons.directions_car, size: 36, color: Colors.black),
                    ),
                    for (int i = 0; i < slots.length; i++)
                      Positioned(
                        left: slotPositions[i].dx,
                        top: slotPositions[i].dy,
                        child: GestureDetector(
                          onTap: takenSlots.contains(slots[i])
                              ? null
                              : () => setState(() => selectedSlot = slots[i]),
                          child: takenSlots.contains(slots[i])
                              ? Image.asset(
                                  'assets/images/car_parked.png',
                                  width: 40,
                                  height: 60,
                                )
                              : Container(
                                  width: 40,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: selectedSlot == slots[i]
                                        ? Colors.deepPurple
                                        : Colors.green,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Text(
                                      slots[i],
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _pickDate,
                        child: Text(DateFormat('yyyy-MM-dd').format(selectedDate)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _pickTime,
                        child: Text(selectedTime.format(context)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  value: selectedDuration,
                  decoration: const InputDecoration(labelText: "Duration (hrs)"),
                  items: const [
                    DropdownMenuItem(value: 1, child: Text("1 hour")),
                    DropdownMenuItem(value: 2, child: Text("2 hours")),
                    DropdownMenuItem(value: 3, child: Text("3 hours")),
                  ],
                  onChanged: (value) => setState(() => selectedDuration = value!),
                ),
              ],
            ),
          ),
          SafeArea(
            minimum: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isReadyToReserve ? _reserveSlot : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isReadyToReserve ? Colors.deepPurple : Colors.grey.shade400,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  "Reserve Slot",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isReadyToReserve ? Colors.white : Colors.black45,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Offset> _generateSlotPositions() {
    List<Offset> positions = [];
    double startX = 60;
    double startY = 40;
    double xSpacing = 80;
    double ySpacing = 80;

    for (int i = 0; i < slots.length; i++) {
      double dx = startX + (i % 4) * xSpacing;
      double dy = startY + (i ~/ 4) * ySpacing;
      positions.add(Offset(dx, dy));
    }
    return positions;
  }
}

class DottedLinePainter extends CustomPainter {
  final Offset start;
  final Offset end;

  DottedLinePainter(this.start, this.end);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    const double dashWidth = 6;
    const double dashSpace = 4;
    double distance = (end - start).distance;
    final double dx = (end.dx - start.dx) / distance;
    final double dy = (end.dy - start.dy) / distance;

    double x = start.dx, y = start.dy;
    while ((end - Offset(x, y)).distance > dashWidth) {
      final nextX = x + dx * dashWidth;
      final nextY = y + dy * dashWidth;
      canvas.drawLine(Offset(x, y), Offset(nextX, nextY), paint);
      x += dx * (dashWidth + dashSpace);
      y += dy * (dashWidth + dashSpace);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
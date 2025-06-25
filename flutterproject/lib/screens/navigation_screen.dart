import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class NavigationScreen extends StatefulWidget {
  final Map<String, dynamic>? initialReservation;

  const NavigationScreen({super.key, this.initialReservation});

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  final Offset entrancePosition = Offset(160, 700);
  List<String> slots = List.generate(20, (i) => 'A${i + 1}');
  List<Offset> slotPositions = [];
  List<Map<String, dynamic>> userReservations = [];
  Map<String, dynamic>? selectedReservation;

  List<String> parkingNames = ['Sky Park'];
  String selectedParking = 'Sky Park';

  @override
  void initState() {
    super.initState();
    _loadParkingNames();
    if (widget.initialReservation != null) {
      selectedReservation = widget.initialReservation;
      userReservations = [widget.initialReservation!];
    }
  }

  Future<void> _loadParkingNames() async {
    final customs = await ApiService.getParkingLocations();
    setState(() {
      parkingNames = ['Sky Park', ...customs.map((e) => e['name'].toString())];
    });
    _loadReservationsAndLayout();
  }

  Future<void> _loadReservationsAndLayout() async {
    final prefs = await SharedPreferences.getInstance();
    final studentId = prefs.getString('studentId');
    if (studentId != null) {
      final all = await ApiService.getAllUserReservations(studentId);
      final relevant = all.where((r) =>
          (selectedParking == 'Sky Park' && r['type'] == 'standard') ||
          (selectedParking != 'Sky Park' && r['parking_name'] == selectedParking)
      ).toList();

      setState(() {
        userReservations = relevant;
        selectedReservation = relevant.isNotEmpty ? relevant.last : null;
      });

      if (selectedParking == 'Sky Park') {
        setState(() {
          slots = List.generate(20, (i) => 'A${i + 1}');
          slotPositions = _generateSlotPositions();
        });
      } else {
        final layout = await ApiService.getCustomLayout(selectedParking);
        setState(() {
          slots = List.generate(layout.length, (i) => 'A${i + 1}');
          slotPositions = layout.map<Offset>((slot) {
            return Offset(
              double.tryParse(slot['x'].toString()) ?? 0,
              double.tryParse(slot['y'].toString()) ?? 0,
            );
          }).toList();
        });
      }
    }
  }

  List<Offset> _generateSlotPositions([int count = 20]) {
    List<Offset> positions = [];
    double startX = 30, startY = 40, xSpacing = 80, ySpacing = 80;
    for (int i = 0; i < count; i++) {
      double dx = startX + (i % 4) * xSpacing;
      double dy = startY + (i ~/ 4) * ySpacing;
      positions.add(Offset(dx, dy));
    }
    return positions;
  }

  String _formatTime(dynamic timeData) {
    try {
      String timeString = timeData.toString();
      if (RegExp(r'^\d{1,2}$').hasMatch(timeString)) {
        timeString = '${timeString.padLeft(2, '0')}:00';
      } else if (RegExp(r'^\d{1,2}:\d{1,2}$').hasMatch(timeString)) {
        timeString = '$timeString:00';
      }
      final dateTime = DateTime.parse('2020-01-01T$timeString');
      final timeOfDay = TimeOfDay.fromDateTime(dateTime);
      return timeOfDay.format(context);
    } catch (e) {
      return timeData.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    String? selectedSlot = selectedReservation?['slot_code'];
    Offset? reservedOffset;
    if (selectedSlot != null && slots.isNotEmpty && slotPositions.isNotEmpty) {
      final index = slots.indexOf(selectedSlot);
      if (index != -1 && index < slotPositions.length) {
        reservedOffset = slotPositions[index];
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text("My Reservations")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: DropdownButtonFormField<String>(
              value: selectedParking,
              decoration: InputDecoration(
                labelText: 'Select Parking Area',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              items: parkingNames.map((name) => DropdownMenuItem(
                value: name,
                child: Text(name),
              )).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    selectedParking = value;
                  });
                  _loadReservationsAndLayout();
                }
              },
            ),
          ),
          if (userReservations.isNotEmpty)
            Column(
              children: [
                SizedBox(
                  height: 60,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: userReservations.length,
                    itemBuilder: (context, index) {
                      final reservation = userReservations[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: ChoiceChip(
                          label: Text(reservation['slot_code']),
                          selected: reservation == selectedReservation,
                          onSelected: (_) {
                            setState(() {
                              selectedReservation = reservation;
                            });
                          },
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
                if (selectedReservation != null)
                  Column(
                    children: [
                      Text("(${selectedParking})", style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text("Date: ${selectedReservation!['date']}"),
                      Text("Time: ${_formatTime(selectedReservation!['time'])}"),
                      Text("Duration: ${selectedReservation!['duration']} hour(s)"),
                      const SizedBox(height: 10),
                    ],
                  ),
              ],
            )
          else
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text("No reservations found."),
            ),
          Expanded(
            child: SingleChildScrollView(
              child: SizedBox(
                height: 900,
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
                    if (slotPositions.length >= slots.length)
                      for (int i = 0; i < slots.length; i++)
                        Positioned(
                          left: slotPositions[i].dx,
                          top: slotPositions[i].dy,
                          child: Container(
                            width: 40,
                            height: 60,
                            decoration: BoxDecoration(
                              color: slots[i] == selectedSlot ? Colors.deepPurple : Colors.green,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                slots[i],
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
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

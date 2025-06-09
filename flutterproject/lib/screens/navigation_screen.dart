import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class NavigationScreen extends StatefulWidget {
  const NavigationScreen({super.key});

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  final List<String> slots = List.generate(20, (i) => 'A${i + 1}');
  final Offset entrancePosition = Offset(160, 700);
  List<Map<String, dynamic>> userReservations = [];
  String? selectedSlot;
  late List<Offset> slotPositions;

  @override
  void initState() {
    super.initState();
    slotPositions = _generateSlotPositions();
    _fetchReservations();
  }

  Future<void> _fetchReservations() async {
    final prefs = await SharedPreferences.getInstance();
    final studentId = prefs.getString('studentId');
    if (studentId != null) {
      final reservations = await ApiService.getUserReservationDetails(studentId);
      setState(() {
        userReservations = reservations;
        if (reservations.isNotEmpty) {
          selectedSlot = reservations.last['slot_code'];
        }
      });
    }
  }

  List<Offset> _generateSlotPositions() {
    List<Offset> positions = [];
    double startX = 30;
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

  @override
  Widget build(BuildContext context) {
    Offset? reservedOffset;
    if (selectedSlot != null) {
      final index = slots.indexOf(selectedSlot!);
      if (index != -1 && index < slotPositions.length) {
        reservedOffset = slotPositions[index];
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text("My Reservations")),
      body: Column(
        children: [
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
                      final slot = reservation['slot_code'];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: ChoiceChip(
                          label: Text(slot),
                          selected: slot == selectedSlot,
                          onSelected: (_) {
                            setState(() {
                              selectedSlot = slot;
                            });
                          },
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                if (selectedSlot != null)
                  ...userReservations
                      .where((r) => r['slot_code'] == selectedSlot)
                      .map((r) => Column(
                            children: [
                              Text("Date: ${r['date']}"),
                              Text("Time: ${r['time']}"),
                              Text("Duration: ${r['duration']} hour(s)"),
                              const SizedBox(height: 10),
                            ],
                          ))
              ],
            )
          else
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text("No reservations found."),
            ),
          Expanded(
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
                  child:
                      const Icon(Icons.directions_car, size: 36, color: Colors.black),
                ),
                for (int i = 0; i < slots.length; i++)
                  Positioned(
                    left: slotPositions[i].dx,
                    top: slotPositions[i].dy,
                    child: Container(
                      width: 40,
                      height: 60,
                      decoration: BoxDecoration(
                        color: slots[i] == selectedSlot
                            ? Colors.deepPurple
                            : Colors.green,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          slots[i],
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
              ],
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
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
  final List<String> slots = List.generate(20, (i) => 'A${i + 1}');
  final Offset entrancePosition = Offset(160, 700);

  List<Map<String, dynamic>> userReservations = [];
  Map<String, dynamic>? selectedReservation;
  late List<Offset> slotPositions;

@override
void initState() {
  super.initState();
  slotPositions = _generateSlotPositions();

  if (widget.initialReservation != null) {
    selectedReservation = widget.initialReservation;
    userReservations = [widget.initialReservation!]; // Only show the tapped one
  } else {
    _fetchReservations();
  }
}

  Future<void> _fetchReservations() async {
    final prefs = await SharedPreferences.getInstance();
    final studentId = prefs.getString('studentId');
    if (studentId != null) {
      final reservations = await ApiService.getUserReservationDetails(studentId);
      setState(() {
        userReservations = reservations;
        if (reservations.isNotEmpty) {
          selectedReservation = reservations.last;
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
      return timeOfDay.format(context); // e.g., 6:00 PM
    } catch (e) {
      return timeData.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    String? selectedSlot = selectedReservation?['slot_code'];
    Offset? reservedOffset;

    if (selectedSlot != null) {
      final index = slots.indexOf(selectedSlot);
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
                            fontWeight: FontWeight.bold,
                          ),
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

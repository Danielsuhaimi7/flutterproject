// navigation_screen.dart
import 'package:flutter/material.dart';
import 'dart:math';

class NavigationScreen extends StatelessWidget {
  final String reservedSlot;

  NavigationScreen({super.key, required this.reservedSlot});

  final List<String> slots = List.generate(20, (i) => 'A${i + 1}');
  final Offset entrancePosition = Offset(160, 700);

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
    final slotPositions = _generateSlotPositions();
    Offset? reservedOffset;

    final index = slots.indexOf(reservedSlot);
    if (index != -1) reservedOffset = slotPositions[index];

    return Scaffold(
      appBar: AppBar(
        title: Text("Navigation to $reservedSlot"),
      ),
      body: Stack(
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
                  color: slots[i] == reservedSlot ? Colors.deepPurple : Colors.green,
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

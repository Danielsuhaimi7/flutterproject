import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ParkingCustomLayoutScreen extends StatefulWidget {
  final String parkingName;
  final int totalSlots;

  const ParkingCustomLayoutScreen({
    super.key,
    required this.parkingName,
    required this.totalSlots,
  });

  @override
  State<ParkingCustomLayoutScreen> createState() => _ParkingCustomLayoutScreenState();
}

class _ParkingCustomLayoutScreenState extends State<ParkingCustomLayoutScreen> {
  late List<bool> isVertical;
  late List<Offset> positions;

  final double slotWidth = 40;
  final double slotHeight = 60;

  @override
  void initState() {
    super.initState();
    isVertical = List.filled(widget.totalSlots, true);
    positions = List.generate(
      widget.totalSlots,
      (index) => Offset(30.0 + (index % 5) * 80, 30.0 + (index ~/ 5) * 100),
    );
  }

  void _saveLayout() async {
    final layoutData = List.generate(widget.totalSlots, (index) => {
      "index": index,
      "x": positions[index].dx,
      "y": positions[index].dy,
      "vertical": isVertical[index],
    });

    final success = await ApiService.saveCustomLayout(widget.parkingName, layoutData);

    if (success) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Layout saved successfully.")),
      );
      Navigator.pop(context);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to save layout.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Customize Layout - ${widget.parkingName}"),
        backgroundColor: Colors.deepPurple,
      ),
      body: Stack(
        children: [
          ...List.generate(widget.totalSlots, (index) {
            return Positioned(
              left: positions[index].dx,
              top: positions[index].dy,
              child: GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    positions[index] += details.delta;
                  });
                },
                onDoubleTap: () {
                  setState(() {
                    isVertical[index] = !isVertical[index];
                  });
                },
                child: RotatedBox(
                  quarterTurns: isVertical[index] ? 0 : 1,
                  child: Container(
                    width: slotWidth,
                    height: slotHeight,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.shade100,
                      border: Border.all(color: Colors.deepPurple, width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'A${index + 1}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _saveLayout,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text("Save Layout", style: TextStyle(fontSize: 16)),
          ),
        ),
      ),
    );
  }
}
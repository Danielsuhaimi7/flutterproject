// screen: parking_custom_layout_screen.dart
import 'package:flutter/material.dart';

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
  List<bool> verticalLayout = [];

  @override
  void initState() {
    super.initState();
    verticalLayout = List.generate(widget.totalSlots, (index) => true); // default: vertical
  }

  void _toggleOrientation(int index) {
    setState(() {
      verticalLayout[index] = !verticalLayout[index];
    });
  }

  void _saveLayout() {
    // Example stub: save to backend or local store
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Layout saved successfully.")),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Customize Layout - ${widget.parkingName}"),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text("Tap to toggle slot orientation"),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: widget.totalSlots,
                itemBuilder: (context, index) {
                  final vertical = verticalLayout[index];
                  return GestureDetector(
                    onTap: () => _toggleOrientation(index),
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.shade100,
                        border: Border.all(color: Colors.deepPurple, width: 2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: RotatedBox(
                        quarterTurns: vertical ? 0 : 1,
                        child: Text(
                          'Slot ${index + 1}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveLayout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text("Save Layout", style: TextStyle(color: Colors.white)),
              ),
            )
          ],
        ),
      ),
    );
  }
}

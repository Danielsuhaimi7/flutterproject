//can delete 
import 'dart:math';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ParkingLayoutEditorScreen extends StatefulWidget {
  final int parkingId;
  final String parkingName;
  final int totalSlots;

  const ParkingLayoutEditorScreen({
    super.key,
    required this.parkingId,
    required this.parkingName,
    required this.totalSlots,
  });

  @override
  State<ParkingLayoutEditorScreen> createState() => _ParkingLayoutEditorScreenState();
}

class _ParkingLayoutEditorScreenState extends State<ParkingLayoutEditorScreen> {
  late List<List<bool>> grid;
  late int rows;
  late int cols;

  @override
  void initState() {
    super.initState();

    assert(widget.totalSlots > 0, "totalSlots must be > 0");
    final side = sqrt(widget.totalSlots.toDouble()).ceil();
    rows = side;
    cols = side;

    grid = List.generate(rows, (_) => List.generate(cols, (_) => false));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Layout: ${widget.parkingName}')),
      body: Column(
        children: [
          Expanded(
            child: GridView.builder(
              itemCount: rows * cols,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: cols),
              itemBuilder: (_, index) {
                final r = index ~/ cols;
                final c = index % cols;
                return GestureDetector(
                  onTap: () {
                    setState(() => grid[r][c] = !grid[r][c]);
                  },
                  child: Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: grid[r][c] ? Colors.green : Colors.grey,
                      border: Border.all(color: Colors.black),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.save),
              label: const Text("Save Layout"),
              onPressed: () async {
                final layoutData = <Map<String, dynamic>>[];

                for (int r = 0; r < rows; r++) {
                  for (int c = 0; c < cols; c++) {
                    if (grid[r][c]) {
                      layoutData.add({"row": r, "col": c});
                    }
                  }
                }

                if (layoutData.length > widget.totalSlots) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("You selected more than the allowed number of slots.")),
                  );
                  return;
                }

                final success = await ApiService.saveParkingLayout(
                  parkingId: widget.parkingId,
                  slots: layoutData,
                );

                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Layout saved.")),
                  );
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Failed to save layout.")),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReserveCustomParkingScreen extends StatefulWidget {
  final String parkingName;

  const ReserveCustomParkingScreen({
    super.key,
    required this.parkingName,
  });

  @override
  State<ReserveCustomParkingScreen> createState() => _ReserveCustomParkingScreenState();
}

class _ReserveCustomParkingScreenState extends State<ReserveCustomParkingScreen> {
  List<bool> verticalLayout = [];
  int? selectedSlotIndex;
  String selectedDuration = '1 hour';
  final List<String> durations = ['1 hour', '2 hours', '3 hours'];

  @override
  void initState() {
    super.initState();
    _loadLayout();
  }

  Future<void> _loadLayout() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('custom_parking_layout');

    if (saved != null) {
      setState(() {
        verticalLayout = saved.map((e) => e == 'true').toList();
      });
    }
  }

  void _confirmReservation() {
    if (selectedSlotIndex == null) return;

    final slotLabel = 'Slot ${selectedSlotIndex! + 1}';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Reserved $slotLabel for $selectedDuration')),
    );

    // TODO: Send data to backend or navigate as needed
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Reserve - ${widget.parkingName}"),
        backgroundColor: Colors.deepPurple,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Column(
            children: [
              Expanded(
                child: GridView.builder(
                  itemCount: verticalLayout.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                  ),
                  itemBuilder: (context, index) {
                    final vertical = verticalLayout[index];
                    final isSelected = selectedSlotIndex == index;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedSlotIndex = index;
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.deepPurple : Colors.deepPurple.shade100,
                          border: Border.all(
                            color: isSelected ? Colors.black : Colors.deepPurple,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: RotatedBox(
                          quarterTurns: vertical ? 0 : 1,
                          child: Text(
                            'Slot ${index + 1}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedDuration,
                items: durations.map((d) {
                  return DropdownMenuItem(value: d, child: Text(d));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => selectedDuration = val);
                },
                decoration: const InputDecoration(labelText: "Select Duration"),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: selectedSlotIndex != null ? _confirmReservation : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text("Confirm Reservation", style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

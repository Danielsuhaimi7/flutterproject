import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutterproject/screens/parking_map_screen.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class ReserveScreen extends StatefulWidget {
  const ReserveScreen({super.key});

  @override
  State<ReserveScreen> createState() => _ReserveScreenState();
}

class _ReserveScreenState extends State<ReserveScreen> {
  String? selectedSlot;
  String duration = "1 hour";

  final List<String> availableSlots = [
    "A1", "A2", "A3", "A4", "A5", "A6", "A7", "A8", "A9", "A10"
  ];
  final List<String> durations = ["1 hour", "2 hours", "3 hours"];

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    tz.initializeTimeZones();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);

    await flutterLocalNotificationsPlugin.initialize(initSettings);
  }

  Future<void> scheduleReminderNotification(DateTime endTime) async {
    final reminderTime = endTime.subtract(const Duration(minutes: 15));

    await flutterLocalNotificationsPlugin.zonedSchedule(
      0,
      'Parking Reminder',
      'Your parking will expire in 15 minutes.',
      tz.TZDateTime.from(reminderTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'parking_channel',
          'Parking Reminders',
          channelDescription: 'Reminders for upcoming parking expirations',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
    );
  }

  void confirmReservation() async {
    if (selectedSlot == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('reservedSlot', selectedSlot!);

    final int hours = int.tryParse(duration.split(" ").first) ?? 1;

    final now = DateTime.now();
    final endTime = now.add(Duration(hours: hours));
    await scheduleReminderNotification(endTime);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Reserved $selectedSlot for $duration")),
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ParkingMapScreen(slotToNavigate: selectedSlot!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Reserve Parking")),
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  children: [
                    DropdownButtonFormField<String>(
                      hint: const Text("Select Parking Slot"),
                      value: selectedSlot,
                      items: availableSlots.map((slot) {
                        return DropdownMenuItem(
                          value: slot,
                          child: Text(slot),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() => selectedSlot = value),
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      value: duration,
                      decoration: const InputDecoration(labelText: "Select Duration"),
                      items: durations.map((d) {
                        return DropdownMenuItem(
                          value: d,
                          child: Text(d),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() => duration = value!),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: selectedSlot != null ? confirmReservation : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text("Confirm Reservation", style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
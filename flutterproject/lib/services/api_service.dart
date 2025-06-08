import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Use this if you're testing on Android emulator
  static const String baseUrl = "http://10.0.2.2:5000";

  // Use this if testing on real phone with local IP
  // static const String baseUrl = "http://YOUR_LAN_IP:5000";

  static Future<bool> loginUser(String studentId, String password) async {
    final response = await http.post(
      Uri.parse("$baseUrl/login"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "student_id": studentId,
        "password": password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["status"] == "success";
    } else {
      return false;
    }
  }

  static Future<bool> registerUser(Map<String, String> userData) async {
    final response = await http.post(
      Uri.parse("$baseUrl/register"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(userData),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["status"] == "success";
    } else {
      return false;
    }
  }

  static Future<bool> reserveSlot({
  required String studentId,
  required String slotCode,
  required String date,
  required String time,
  required int duration,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/reserve_slot'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'student_id': studentId,
        'slot_code': slotCode,
        'date': date,
        'time': time,
        'duration': duration,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['status'] == 'success';
    }
    return false;
  }

  static Future<List<String>> getBookedSlots(String date, String time) async {
  final response = await http.post(
    Uri.parse('$baseUrl/booked_slots'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'date': date, 'time': time}),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return List<String>.from(data['booked']);
  }
  return [];
}

}

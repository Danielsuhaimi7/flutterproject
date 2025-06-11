import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/reservation.dart';

class ApiService {
  static const String baseUrl = "http://10.0.2.2:5000";

  static Future<Map<String, dynamic>> loginUser(String studentId, String password) async {
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
      return data;
    } else {
      return {
        "status": "fail",
        "message": "Server error",
      };
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

  static Future<String?> getUserReservation(String studentId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/user_reservation'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'student_id': studentId}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['slot_code'];
    }
    return null;
  }

  static Future<List<Reservation>> getUserReservations(String studentId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/user_reservations'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'student_id': studentId}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> reservations = data['reservations'];
      return reservations.map((r) => Reservation.fromJson(r)).toList();
    }
    return [];
  }

  static Future<List<Map<String, dynamic>>> getUserReservationDetails(String studentId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/user_reservation_details'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'student_id': studentId}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['reservations']);
    }
    return [];
  }

  // ✅ NEW: Add Parking Location (admin)
  static Future<bool> addParkingLocation(double lat, double lng) async {
    final response = await http.post(
      Uri.parse('$baseUrl/add_parking'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'latitude': lat, 'longitude': lng}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['status'] == 'success';
    }
    return false;
  }

  // ✅ NEW: Get All Parking Locations (public view)
  static Future<List<Map<String, dynamic>>> getParkingLocations() async {
    final response = await http.get(Uri.parse('$baseUrl/get_parking_locations'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['locations']);
    }
    return [];
  }
}

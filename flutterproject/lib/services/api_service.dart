import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/reservation.dart';
import '../config.dart';

class ApiService {

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

  static Future<bool> addParkingLocation(double lat, double lng, {String name = "Unnamed"}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/add_parking_location'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'latitude': lat,
        'longitude': lng,
        'name': name,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['status'] == 'success';
    }
    return false;
  }

  static Future<List<Map<String, dynamic>>> getAllParkings() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/get_parkings'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['parkings']);
      } else {
        print("🚨 Server error while loading parkings: ${response.statusCode} - ${response.body}");
        return [];
      }
    } catch (e) {
      print("❌ Exception while fetching parkings: $e");
      return [];
    }
  }

  static Future<List<dynamic>> getParkingLocations() async {
    final response = await http.get(Uri.parse('$baseUrl/get_parkings'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['parkings']);
    } else {
      return [];
    }
  }

  static Future<bool> saveParkingLayout({
    required int parkingId,
    required List<Map<String, dynamic>> slots,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/save_layout'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'parking_id': parkingId,
        'slots': slots,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['status'] == 'success';
    }

    return false;
  }

  // ✅ NEW: Get AI parking availability prediction
  static Future<List<Map<String, dynamic>>> getAvailabilityGraph() async {
    final response = await http.get(Uri.parse('$baseUrl/availability_graph'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['predictions']);
    } else {
      throw Exception('Failed to load availability graph');
    }
  }

  static Future<List<Map<String, dynamic>>> getCustomLayout(String parkingName) async {
    final response = await http.post(
      Uri.parse('$baseUrl/get_custom_layout'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'parking_name': parkingName}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['layout']);
    } else {
      return [];
    }
  }

  static Future<bool> saveCustomLayout(String parkingName, List<Map<String, dynamic>> layoutData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/save_custom_layout'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'parking_name': parkingName,
          'layout': layoutData,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print("Error saving layout: $e");
      return false;
    }
  }

  static Future<bool> reserveCustomSlot({
  required String studentId,
  required String parkingName,
  required int slotIndex,
  required String date,
  required String time,
  required int duration,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/reserve_custom_slot'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'student_id': studentId,
        'parking_name': parkingName,
        'slot_index': slotIndex,
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

  static Future<List<int>> getBookedCustomSlots({
  required String parkingName,
  required String date,
  required String time,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/get_booked_custom_slots'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'parking_name': parkingName,
        'date': date,
        'time': time,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<int>.from(data['booked'] ?? []);
    }

    return [];
  }

  static Future<List<Map<String, dynamic>>> fetchAllUsers() async {
    final response = await http.get(Uri.parse('$baseUrl/users'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['users']);
    } else {
      return [];
    }
  }

  static Future<bool> deleteUser(String studentId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/delete_user'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'student_id': studentId}),
    );
    return response.statusCode == 200;
  }

  static Future<bool> updateUser(Map<String, String> userData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/edit_user'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(userData),
    );
    return response.statusCode == 200;
  }

  static Future<List<Map<String, dynamic>>> getAllUserReservations(String studentId) async {
    print("➡️ Calling /user_all_reservations for $studentId");

    final response = await http.post(
      Uri.parse('$baseUrl/user_all_reservations'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'student_id': studentId}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['reservations']);
    } else {
      return [];
    }
  }

  static Future<bool> deleteParkingLocation(String parkingName) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/delete_parking_location'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'parking_name': parkingName}),
      );

      final json = jsonDecode(response.body);
      return json['status'] == 'success';
    } catch (e) {
      print("Delete parking error: $e");
      return false;
    }
  }
}

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:geolocator/geolocator.dart';

class ApiService {
  // IMPORTANT: Replace with your computer's local network IP address.
  // Windows: ipconfig | macOS/Linux: ifconfig or hostname -I
  static const String _ipAddress = "10.100.159.54";
  static const String _port = "8000";
  static const String baseUrl = "http://$_ipAddress:$_port/api/v1";

  /// Handles user login by sending credentials to the backend.
  /// The backend expects `password` and `confirmPassword` to be the same.
  Future<Map<String, dynamic>> login(String email, String password, String role) async {
    final response = await http.post(
      Uri.parse('$baseUrl/user/login'),
      headers: <String, String>{'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode(<String, String>{
        'email': email,
        'password': password,
        'confirmPassword': password, // Backend schema requires this
        'role': role,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to login.');
    }
  }

  /// Handles new user registration.
  /// Sends user data and an avatar image as a multipart/form-data request.
  Future<Map<String, dynamic>> register({
    required String firstname,
    required String lastname,
    required String email,
    required String phone,
    required String password,
    required String role,
    required File avatarFile,
  }) async {
    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/user/register'));

    // Add text fields
    request.fields['firstname'] = firstname;
    request.fields['lastname'] = lastname;
    request.fields['email'] = email;
    request.fields['phone'] = phone;
    request.fields['password'] = password;
    request.fields['role'] = role;

    // Add the avatar file
    request.files.add(
      await http.MultipartFile.fromPath(
        'userAvatar', // This key must match the backend `req.files.userAvatar`
        avatarFile.path,
        contentType: MediaType('image', 'jpeg'),
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to register.');
    }
  }

  /// Fetches the current user's profile to validate an existing session token.
  Future<Map<String, dynamic>> getUserProfile(String token, String role) async {
    String endpoint = "/${role.toLowerCase()}/me";

    final response = await http.get(
      Uri.parse('$baseUrl/user$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        'Cookie': '${role.toLowerCase()}Token=$token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Session expired or invalid. Please login again.');
    }
  }

  /// Submits a new hazard report from a citizen.
  Future<Map<String, dynamic>> submitReport({
    required String text,
    required double lat,
    required double lon,
    required String token,
    required String userId, // <-- CHANGE 1: Added userId parameter
    File? mediaFile,
  }) async {
    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/report/citizen/report'));
    request.headers['Cookie'] = 'citizenToken=$token';

    // Add all required fields to the request body
    request.fields.addAll({
      'text': text,
      'lat': lat.toString(),
      'lon': lon.toString(),
      'source': 'citizen',
      'submittedBy': userId, // <-- CHANGE 2: Send the user's ID
    });

    if (mediaFile != null) {
      request.files.add(await http.MultipartFile.fromPath('media', mediaFile.path, contentType: MediaType('image', 'jpeg')));
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to submit report.');
    }
  }

  Future<List<dynamic>> listReports({
    required String token,
    required String role,
    String? status, // Only used for Analyst
  }) async {
    String endpoint;
    String cookieName = '${role.toLowerCase()}Token';

    if (role == 'Citizen') {
      // For Citizens, get their location and find nearby reports.
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      endpoint = '/report/citizen/nearby?lat=${position.latitude}&lon=${position.longitude}&radius=20'; // 20km radius
    } else {
      // For Analysts, list all reports, with an optional status filter.
      endpoint = '/report/analyst/reports';
      if (status != null && status != 'All') {
        endpoint += '?status=$status';
      }
    }

    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        'Cookie': '$cookieName=$token',
      },
    );

    if (response.statusCode == 200) {
      // The backend nests the list under a 'reports' key.
      return jsonDecode(response.body)['reports'];
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to load reports.');
    }
  }

  /// Allows an analyst to verify a report.
  Future<Map<String, dynamic>> verifyReport({
    required String reportId,
    required String token,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/report/analyst/verify/$reportId'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Cookie': 'analystToken=$token',
      },
      body: jsonEncode(<String, String>{'status': 'Verified'}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to verify report.');
    }
  }
}
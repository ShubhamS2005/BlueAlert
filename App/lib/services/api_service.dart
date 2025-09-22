import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:geolocator/geolocator.dart';

class ApiService {
  static const String _ipAddress = "10.100.159.54";//"10.206.2.54";
  static const String _port = "8000";
  static const String baseUrl = "http://$_ipAddress:$_port/api/v1";
  static const Duration _timeoutDuration = Duration(seconds: 10);
  static const Duration _uploadTimeoutDuration = Duration(seconds: 10);

  Future<Map<String, dynamic>> login(String email, String password, String role) async {
    final response = await http.post(
      Uri.parse('$baseUrl/user/login'),
      headers: <String, String>{'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode(<String, String>{
        'email': email, 'password': password, 'confirmPassword': password, 'role': role,
      }),
    ).timeout(_timeoutDuration); // <-- ADDED TIMEOUT

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to login.');
    }
  }

  Future<Map<String, dynamic>> register({
    required String firstname, required String lastname, required String email,
    required String phone, required String password, required String role,
    required File avatarFile,
  }) async {
    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/user/register'));
    request.fields.addAll({
      'firstname': firstname, 'lastname': lastname, 'email': email, 'phone': phone, 'password': password, 'role': role,
    });
    request.files.add(await http.MultipartFile.fromPath('userAvatar', avatarFile.path, contentType: MediaType('image', 'jpeg')));

    final streamedResponse = await request.send().timeout(_uploadTimeoutDuration); // <-- ADDED TIMEOUT
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to register.');
    }
  }

  Future<Map<String, dynamic>> getUserProfile(String token, String role) async {
    String endpoint = "/${role.toLowerCase()}/me";
    final response = await http.get(
      Uri.parse('$baseUrl/user$endpoint'),
      headers: {'Content-Type': 'application/json', 'Cookie': '${role.toLowerCase()}Token=$token'},
    ).timeout(_timeoutDuration); // <-- ADDED TIMEOUT

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Session expired or invalid.');
    }
  }

  Future<Map<String, dynamic>> submitReport({
    required String text, required double lat, required double lon,
    required String token, required String userId, File? mediaFile,
  }) async {
    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/report/citizen/report'));
    request.headers['Cookie'] = 'citizenToken=$token';
    request.fields.addAll({'text': text, 'lat': lat.toString(), 'lon': lon.toString(), 'source': 'citizen', 'submittedBy': userId});
    if (mediaFile != null) {
      request.files.add(await http.MultipartFile.fromPath('media', mediaFile.path, contentType: MediaType('image', 'jpeg')));
    }

    final streamedResponse = await request.send().timeout(_uploadTimeoutDuration); // <-- ADDED TIMEOUT
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to submit report.');
    }
  }

  Future<List<dynamic>> listReports({
    required String token, required String role, String? status,
  }) async {
    String endpoint;
    String cookieName = '${role.toLowerCase()}Token';
    if (role == 'Citizen') {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      endpoint = '/report/citizen/nearby?lat=${position.latitude}&lon=${position.longitude}&radius=20';
    } else {
      endpoint = '/report/analyst/reports';
      if (status != null && status != 'All') {
        endpoint += '?status=$status';
      }
    }
    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: {'Content-Type': 'application/json', 'Cookie': '$cookieName=$token'},
    ).timeout(_timeoutDuration); // <-- ADDED TIMEOUT

    if (response.statusCode == 200) {
      return jsonDecode(response.body)['reports'];
    } else {
      throw Exception('Failed to load reports.');
    }
  }

  Future<Map<String, dynamic>> verifyReport({
    required String reportId, required String token,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/report/analyst/verify/$reportId'),
      headers: {'Content-Type': 'application/json; charset=UTF-8', 'Cookie': 'analystToken=$token'},
      body: jsonEncode(<String, String>{'status': 'Verified'}),
    ).timeout(_timeoutDuration); // <-- ADDED TIMEOUT

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to verify report.');
    }
  }
}
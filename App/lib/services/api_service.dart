import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class ApiService {
  // IMPORTANT: Replace with your computer's local network IP address.
  // Windows: ipconfig | macOS/Linux: ifconfig or hostname -I
  static const String _ipAddress = "10.100.159.54";
  static const String _port = "8000";
  static const String baseUrl = "http://$_ipAddress:$_port/api/v1";

  /// Handles user login by sending credentials to the backend.
  ///
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
  ///
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
        contentType: MediaType('image', 'jpeg'), // Or 'png', etc.
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
  ///
  /// The JWT token is passed in a `Cookie` header, which the backend's
  /// authentication middleware is configured to read.
  Future<Map<String, dynamic>> getUserProfile(String token, String role) async {
    String endpoint = "";
    if (role == "Admin") endpoint = "/admin/me";
    if (role == "Citizen") endpoint = "/citizen/me";
    if (role == "Analyst") endpoint = "/analyst/me";

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
  ///
  /// This is a multipart request because it can optionally include a media file.
  /// The JWT token is passed via a Cookie header for authentication.
  Future<Map<String, dynamic>> submitReport({
    required String text,
    required double lat,
    required double lon,
    required String token,
    File? mediaFile,
  }) async {
    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/report/citizen/report'));

    // The backend's `isCitizenAuthenticated` middleware reads the token from a cookie
    request.headers['Cookie'] = 'citizenToken=$token';

    // Add text fields required by the backend's `createReport` controller
    request.fields['text'] = text;
    request.fields['lat'] = lat.toString();
    request.fields['lon'] = lon.toString();
    request.fields['source'] = 'citizen'; // As defined in the report schema

    // Add the media file if it was provided
    if (mediaFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'media', // This key must match `req.files.media` in the backend controller
          mediaFile.path,
          contentType: MediaType('image', 'jpeg'),
        ),
      );
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    // A successful creation typically returns a 201 status code
    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to submit report.');
    }
  }
}
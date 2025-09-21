import 'dart:convert';
import 'dart:io';
import 'package:bluealert/models/user_model.dart';
import 'package:bluealert/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  User? _user;
  String? _token;
  bool _isOffline = false;

  User? get user => _user;
  String? get token => _token;
  bool get isAuthenticated => _token != null;
  bool get isOffline => _isOffline;

  Future<void> login(String email, String password) async {
    // List of roles to attempt to log in with.
    const List<String> rolesToTry = ['Citizen', 'Analyst'];
    Exception? lastError;

    for (String role in rolesToTry) {
      try {
        final response = await _apiService.login(email, password, role);
        _user = User.fromJson(response['user']);
        _token = response['token'];

        final prefs = await SharedPreferences.getInstance();
        prefs.setString('token', _token!);
        prefs.setString('userData', jsonEncode(_user!.toJson()));

        _isOffline = false;
        notifyListeners();
        return; // Success! Exit the function.
      } catch (e) {
        // Store the error and try the next role.
        lastError = e as Exception?;
        // If the error message is "User with this role not found", we continue silently.
        // Otherwise, it might be a different error (e.g., wrong password), but we'll still try other roles.
      }
    }

    // If the loop completes without success, throw the last error encountered.
    throw lastError ?? Exception('Invalid credentials or user not found.');
  }

  Future<void> register({
    required String firstname,
    required String lastname,
    required String email,
    required String phone,
    required String password,
    required String role,
    required File avatarFile,
  }) async {
    try {
      await _apiService.register(
        firstname: firstname,
        lastname: lastname,
        email: email,
        phone: phone,
        password: password,
        role: role,
        avatarFile: avatarFile,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('token') || !prefs.containsKey('userData')) {
      _isOffline = false;
      return false;
    }

    final storedToken = prefs.getString('token')!;
    final userData = jsonDecode(prefs.getString('userData')!);
    final storedUser = User.fromJson(userData);

    try {
      await _apiService.getUserProfile(storedToken, storedUser.role);
      _token = storedToken;
      _user = storedUser;
      _isOffline = false;
      notifyListeners();
      return true;
    } catch (e) {
      if (e is SocketException || e.toString().contains('Failed host lookup') || e.toString().contains('Connection failed')) {
        _token = storedToken;
        _user = storedUser;
        _isOffline = true;
        notifyListeners();
        return true;
      } else {
        await logout();
        return false;
      }
    }
  }

  Future<void> logout() async {
    _user = null;
    _token = null;
    _isOffline = false;
    final prefs = await SharedPreferences.getInstance();

    // --- FIX: Only remove auth keys instead of clearing everything ---
    await prefs.remove('token');
    await prefs.remove('userData');
    // --- END FIX ---

    notifyListeners();
  }
}
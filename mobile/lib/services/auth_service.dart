import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:lokal/models/models.dart';
import 'package:lokal/services/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService extends ChangeNotifier {
  AuthService(this._api);

  final ApiClient _api;
  User? user;
  bool ready = false;

  bool get isLoggedIn => user != null && _api.token != null;
  bool get isProducer => user?.isProducer ?? false;

  Future<void> bootstrap() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('lokal_token');
    final rawUser = prefs.getString('lokal_user');
    if (token != null && rawUser != null) {
      _api.token = token;
      user = User.fromJson(jsonDecode(rawUser) as Map<String, dynamic>);
      try {
        await refreshMe();
      } catch (_) {
        await logout();
      }
    }
    ready = true;
    notifyListeners();
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    double? latitude,
    double? longitude,
    String? city,
  }) async {
    final res = await _api.request<Map<String, dynamic>>(
      'POST',
      '/api/auth/register',
      auth: false,
      body: {
        'name': name,
        'email': email,
        'password': password,
        'role': roleApi(role),
        'latitude': latitude,
        'longitude': longitude,
        'city': city,
      },
    );
    await _persist(res);
  }

  Future<void> login(String email, String password) async {
    final res = await _api.request<Map<String, dynamic>>(
      'POST',
      '/api/auth/login',
      auth: false,
      body: {'email': email, 'password': password},
    );
    await _persist(res);
  }

  Future<void> googleDemo() async {
    final res = await _api.request<Map<String, dynamic>>(
      'POST',
      '/api/auth/google',
      auth: false,
      body: {
        'idToken': 'demo-google-token',
        'email': 'google.user.${DateTime.now().millisecondsSinceEpoch}@gmail.com',
        'name': 'Google Kasutaja',
        'role': 'BUYER',
      },
    );
    await _persist(res);
  }

  Future<void> refreshMe() async {
    final json = await _api.request<Map<String, dynamic>>('GET', '/api/auth/me');
    user = User.fromJson(json);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lokal_user', jsonEncode(json));
    notifyListeners();
  }

  Future<void> updateProfile(Map<String, dynamic> body) async {
    final json = await _api.request<Map<String, dynamic>>('PUT', '/api/auth/me', body: body);
    user = User.fromJson(json);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lokal_user', jsonEncode(json));
    notifyListeners();
  }

  Future<void> logout() async {
    _api.token = null;
    user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('lokal_token');
    await prefs.remove('lokal_user');
    notifyListeners();
  }

  Future<void> _persist(Map<String, dynamic> res) async {
    final token = res['token'] as String;
    final userJson = res['user'] as Map<String, dynamic>;
    _api.token = token;
    user = User.fromJson(userJson);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lokal_token', token);
    await prefs.setString('lokal_user', jsonEncode(userJson));
    notifyListeners();
  }
}

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import 'api_service.dart';

class AuthService extends ChangeNotifier {
  final _storage = const FlutterSecureStorage();

  String? _token;
  AppUser? _user;

  String? get token => _token;
  AppUser? get user => _user;
  bool get isConnecte => _token != null;

  Future<void> restaurerSession() async {
    _token = await _storage.read(key: 'auth_token');
    final userJson = await _storage.read(key: 'auth_user');
    if (userJson != null) _user = AppUser.fromJson(jsonDecode(userJson));
    notifyListeners();
  }

  Future<String?> login(String email, String password) async {
    final res = await http.post(
      Uri.parse('$apiBaseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      return jsonDecode(res.body)['message'] ?? 'Connexion impossible';
    }
    await _enregistrerSession(jsonDecode(res.body));
    return null;
  }

  Future<String?> register(String email, String password) async {
    final res = await http.post(
      Uri.parse('$apiBaseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      return jsonDecode(res.body)['message'] ?? 'Inscription impossible';
    }
    await _enregistrerSession(jsonDecode(res.body));
    return null;
  }

  Future<void> _enregistrerSession(Map<String, dynamic> data) async {
    _token = data['access_token'];
    _user = AppUser.fromJson(data['user']);
    await _storage.write(key: 'auth_token', value: _token);
    await _storage.write(key: 'auth_user', value: jsonEncode(data['user']));
    notifyListeners();
  }

  Future<String?> loginOAuthGoogle(String subject, String email) async {
    final res = await http.post(
      Uri.parse('$apiBaseUrl/auth/login/google'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'subject': subject, 'email': email}),
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      return jsonDecode(res.body)['message'] ?? 'Connexion Google impossible';
    }
    await _enregistrerSession(jsonDecode(res.body));
    return null;
  }

  Future<String?> loginOAuthApple(String subject, String email) async {
    final res = await http.post(
      Uri.parse('$apiBaseUrl/auth/login/apple'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'subject': subject, 'email': email}),
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      return jsonDecode(res.body)['message'] ?? 'Connexion Apple impossible';
    }
    await _enregistrerSession(jsonDecode(res.body));
    return null;
  }

  Future<void> deconnexion() async {
    _token = null;
    _user = null;
    await _storage.deleteAll();
    notifyListeners();
  }
}

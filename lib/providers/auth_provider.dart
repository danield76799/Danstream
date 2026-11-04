import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

enum LoginType { m3u, xtream }

class ServerCredentials {
  final LoginType type;
  final String? m3uUrl;
  final String? xtreamServer;
  final String? xtreamUsername;
  final String? xtreamPassword;

  ServerCredentials({
    required this.type,
    this.m3uUrl,
    this.xtreamServer,
    this.xtreamUsername,
    this.xtreamPassword,
  });

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'm3uUrl': m3uUrl,
    'xtreamServer': xtreamServer,
    'xtreamUsername': xtreamUsername,
    'xtreamPassword': xtreamPassword,
  };

  factory ServerCredentials.fromJson(Map<String, dynamic> json) {
    return ServerCredentials(
      type: LoginType.values.byName(json['type'] as String),
      m3uUrl: json['m3uUrl'] as String?,
      xtreamServer: json['xtreamServer'] as String?,
      xtreamUsername: json['xtreamUsername'] as String?,
      xtreamPassword: json['xtreamPassword'] as String?,
    );
  }
}

class AuthProvider extends ChangeNotifier {
  final _storage = const FlutterSecureStorage();

  ServerCredentials? _credentials;
  bool _loading = false;
  String? _error;

  ServerCredentials? get credentials => _credentials;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadSavedCredentials() async {
    try {
      final json = await _storage.read(key: 'danstream_credentials');
      if (json != null && json.isNotEmpty) {
        _credentials = ServerCredentials.fromJson(jsonDecode(json));
      }
    } catch (e) {
      _error = 'Opgeslagen inloggegevens konden niet worden geladen.';
    }
    notifyListeners();
  }

  Future<void> saveCredentials(ServerCredentials credentials) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await _storage.write(
        key: 'danstream_credentials',
        value: jsonEncode(credentials.toJson()),
      );
      _credentials = credentials;
    } catch (e) {
      _error = 'Inloggegevens konden niet worden opgeslagen.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: 'danstream_credentials');
    _credentials = null;
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

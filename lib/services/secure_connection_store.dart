import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureConnectionStore {
  SecureConnectionStore({FlutterSecureStorage? storage})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(encryptedSharedPreferences: true),
          );

  static const String _prefix = 'cloudparty.connection.';

  final FlutterSecureStorage _storage;

  String _keyFor(String connectionId) => '$_prefix$connectionId';

  Future<void> write(String connectionId, Map<String, dynamic> data) async {
    await _storage.write(key: _keyFor(connectionId), value: jsonEncode(data));
  }

  Future<Map<String, dynamic>?> read(String connectionId) async {
    final String? raw = await _storage.read(key: _keyFor(connectionId));
    if (raw == null || raw.isEmpty) {
      return null;
    }

    final Object? decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      return null;
    }
    return decoded;
  }

  Future<void> delete(String connectionId) async {
    await _storage.delete(key: _keyFor(connectionId));
  }
}

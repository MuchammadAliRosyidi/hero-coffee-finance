import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_user.dart';

class AuthService {
  const AuthService();

  static const Map<String, Map<String, Object>> _accounts = {
    'owner': {
      'password': 'owner123',
      'displayName': 'Owner Hero Coffee',
      'role': 'Owner',
      'outlets': <String>['main'],
    },
    'admin': {
      'password': 'admin123',
      'displayName': 'Admin Keuangan',
      'role': 'Admin',
      'outlets': <String>['main'],
    },
  };

  static const String _sessionUsernameKey = 'session_username';

  Future<AppUser?> login(String username, String password) async {
    final key = username.trim().toLowerCase();
    final account = _accounts[key];
    if (account == null) {
      return null;
    }

    if (account['password'] != password) {
      return null;
    }

    final user = _userFromAccount(key, account);

    await saveSession(user);
    return user;
  }

  Future<void> saveSession(AppUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionUsernameKey, user.username);
  }

  Future<AppUser?> getSavedSession() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString(_sessionUsernameKey);
    if (username == null) {
      return null;
    }

    final account = _accounts[username];
    if (account == null) {
      return null;
    }

    return _userFromAccount(username, account);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionUsernameKey);
  }

  AppUser _userFromAccount(String username, Map<String, Object> account) {
    final outlets = account['outlets'];
    return AppUser(
      username: username,
      displayName: account['displayName']! as String,
      role: account['role']! as String,
      assignedOutletIds: outlets is List<String> ? outlets : const ['main'],
    );
  }
}

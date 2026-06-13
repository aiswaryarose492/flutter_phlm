import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/database_helper.dart';
import '../models/models.dart';
import '../services/biometric_service.dart';
import '../services/offline_service.dart';

class AuthProvider extends ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  bool _darkMode = false;
  String? _lastError;

  User? get currentUser => _currentUser;
  UserRole get currentRole => _currentUser?.role ?? UserRole.guest;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;
  String? get loginError => _lastError;
  bool get darkMode => _darkMode;
  bool get offline => OfflineService.instance.isOffline;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _darkMode = prefs.getBool('dark_mode') ?? false;
    notifyListeners();
  }

  Future<void> toggleDarkMode() async {
    _darkMode = !_darkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', _darkMode);
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      final normalizedUsername = username.trim();
      if (normalizedUsername.isEmpty || password.isEmpty) {
        _lastError = 'Username and password are required.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final db = await DatabaseHelper().database;
      final result = await db.query(
        'users',
        where: 'LOWER(username) = LOWER(?) AND password = ?',
        whereArgs: [normalizedUsername, password],
        limit: 1,
      );

      if (result.isEmpty) {
        _lastError = 'Invalid username or password.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final user = User.fromMap(result.first);
      if (!user.hasDashboardRole) {
        _lastError = 'This account does not have dashboard access.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _currentUser = user;
      await SharedPreferences.getInstance().then(
        (prefs) => prefs.setString(_lastUsernameKey, user.username ?? ''),
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (_) {
      _lastError = 'Login failed. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signIn(String username, String password) =>
      login(username, password);

  static const _lastUsernameKey = 'last_biometric_username';

  Future<bool> tryBiometricLogin() async {
    final service = BiometricService.instance;
    if (!await service.isBiometricLoginEnabled()) return false;
    return await loginWithBiometrics();
  }

  Future<bool> loginWithBiometrics() async {
    final service = BiometricService.instance;
    if (!await service.canCheckBiometrics()) return false;
    final authenticated = await service.authenticate();
    if (!authenticated) return false;
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString(_lastUsernameKey);
    if (username == null || username.trim().isEmpty) return false;

    try {
      final db = await DatabaseHelper().database;
      final result = await db.query(
        'users',
        where: 'LOWER(username) = LOWER(?)',
        whereArgs: [username.trim()],
        limit: 1,
      );
      if (result.isEmpty) return false;
      final user = User.fromMap(result.first);
      if (!user.hasDashboardRole) return false;
      _currentUser = user;
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    _lastError = null;
    notifyListeners();
  }

  String get userDisplayName =>
      '${_currentUser?.firstName ?? ''} ${_currentUser?.lastName ?? ''}'.trim();

  String get userRole {
    if (_currentUser == null) return 'Guest';
    if (_currentUser!.isHospitalAdmin) return 'Admin';
    if (_currentUser!.isDoctor) return 'Doctor';
    if (_currentUser!.isPatient) return 'Patient';
    if (_currentUser!.isLab) return 'Lab';
    if (_currentUser!.isPharmacy) return 'Pharmacy';
    if (_currentUser!.isStaffMember) return 'Staff';
    return 'Unknown';
  }
}

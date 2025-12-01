import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _service = AuthService();
  UserModel? _user;

  UserModel? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isAdmin => _user?.role == UserRole.admin;
  bool get isDriver => _user?.role == UserRole.driver;
  bool get isClient => _user?.role == UserRole.client;

  // Inicializar estado de autenticación y usuarios por defecto
  Future<void> initializeAuth() async {
    await _service.initializeDefaultUsers();

    final isLoggedIn = await _service.isLoggedIn();
    if (isLoggedIn) {
      final current = await _service.getCurrentUser();
      _user = current;
      notifyListeners();
    }
  }

  Future<bool> login({required String identifier, required String password}) async {
    try {
      final result = await _service.login(identifier: identifier, password: password);
      if (result != null) {
        _user = result;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> register({required String name, required String email, required String phone, required String password}) async {
    try {
      final result = await _service.register(name: name, email: email, phone: phone, password: password);
      if (result != null) {
        _user = result;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<void> logout() async {
    await _service.logout();
    _user = null;
    notifyListeners();
  }

  // Métodos para administración (solo admin)
  Future<List<UserModel>> getAllUsers() async {
    if (!isAdmin) throw Exception('Acceso denegado');
    return _service.getAllUsers();
  }

  Future<UserModel?> createDriver({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    if (!isAdmin) throw Exception('Acceso denegado');
    return _service.createDriver(
      name: name,
      email: email,
      phone: phone,
      password: password,
    );
  }

  Future<void> deleteUser(String userId) async {
    if (!isAdmin) throw Exception('Acceso denegado');
    await _service.deleteUser(userId);
  }
}

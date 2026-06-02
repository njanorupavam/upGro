import 'package:dayforge/features/auth/data/auth_models.dart';
import 'package:dayforge/features/auth/data/auth_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _tokenStorageKey = 'dayforge_auth_token';

final authControllerProvider = ChangeNotifierProvider<AuthController>((ref) {
  final controller = AuthController(const AuthRepository());
  controller.restoreSession();
  return controller;
});

class AuthController extends ChangeNotifier {
  AuthController(this._repository);

  final AuthRepository _repository;

  AppUser? user;
  String? token;
  String? errorMessage;
  bool isInitialized = false;
  bool isLoading = false;

  bool get isAuthenticated => token != null && user != null;

  Future<void> restoreSession() async {
    final preferences = await SharedPreferences.getInstance();
    final storedToken = preferences.getString(_tokenStorageKey);

    if (storedToken == null) {
      isInitialized = true;
      notifyListeners();
      return;
    }

    try {
      user = await _repository.profile(storedToken);
      token = storedToken;
    } catch (_) {
      await preferences.remove(_tokenStorageKey);
    } finally {
      isInitialized = true;
      notifyListeners();
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    return _authenticate(
      () => _repository.register(
        name: name,
        email: email,
        password: password,
      ),
    );
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    return _authenticate(
      () => _repository.login(
        email: email,
        password: password,
      ),
    );
  }

  Future<void> logout() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_tokenStorageKey);
    token = null;
    user = null;
    errorMessage = null;
    notifyListeners();
  }

  Future<bool> _authenticate(Future<AuthResult> Function() action) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final result = await action();
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(_tokenStorageKey, result.token);
      token = result.token;
      user = result.user;
      return true;
    } catch (error) {
      errorMessage = _readErrorMessage(error);
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  String _readErrorMessage(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map<String, dynamic> && data['message'] is String) {
        return data['message'] as String;
      }
    }

    return 'Authentication failed. Please try again.';
  }
}

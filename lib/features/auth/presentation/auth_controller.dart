import 'dart:async';

import 'package:dayforge/features/auth/data/auth_models.dart';
import 'package:dayforge/features/auth/data/auth_repository.dart';
import 'package:dayforge/features/auth/data/google_sign_in_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _tokenStorageKey = 'dayforge_auth_token';

class AuthState {
  final AppUser? user;
  final String? token;
  final String? errorMessage;
  final bool isInitialized;
  final bool isLoading;

  AuthState({
    this.user,
    this.token,
    this.errorMessage,
    this.isInitialized = false,
    this.isLoading = false,
  });

  bool get isAuthenticated => token != null && user != null;

  AuthState copyWith({
    AppUser? Function()? user,
    String? Function()? token,
    String? Function()? errorMessage,
    bool? isInitialized,
    bool? isLoading,
  }) {
    return AuthState(
      user: user != null ? user() : this.user,
      token: token != null ? token() : this.token,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      isInitialized: isInitialized ?? this.isInitialized,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  late final AuthRepository _repository;
  late final GoogleSignInService _googleSignInService;
  StreamSubscription<GoogleSignInAuthenticationEvent>? _googleAuthSubscription;

  @override
  AuthState build() {
    _repository = ref.watch(authRepositoryProvider);
    _googleSignInService = ref.watch(googleSignInServiceProvider);
    _googleAuthSubscription ??= _googleSignInService.authenticationEvents.listen(
      _handleGoogleAuthenticationEvent,
      onError: (Object error) {
        state = state.copyWith(errorMessage: () => _readErrorMessage(error));
      },
    );
    ref.onDispose(() => _googleAuthSubscription?.cancel());
    unawaited(_googleSignInService.ensureInitialized());
    restoreSession();
    return AuthState();
  }

  Future<void> restoreSession() async {
    final preferences = await SharedPreferences.getInstance();
    final storedToken = preferences.getString(_tokenStorageKey);

    if (storedToken == null) {
      state = state.copyWith(isInitialized: true);
      return;
    }

    try {
      final user = await _repository.profile(storedToken);
      state = state.copyWith(
        user: () => user,
        token: () => storedToken,
        isInitialized: true,
      );
    } catch (_) {
      await preferences.remove(_tokenStorageKey);
      state = state.copyWith(isInitialized: true);
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

  Future<void> startGoogleSignIn() async {
    if (!_googleSignInService.isConfigured) {
      state = state.copyWith(
        errorMessage: () => 'Google Sign-In is not configured yet.',
      );
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: () => null);

    try {
      await _googleSignInService.authenticate();
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: () => _readErrorMessage(error),
      );
    }
  }

  Future<void> logout() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_tokenStorageKey);
    if (_googleSignInService.isConfigured) {
      await _googleSignInService.signOut();
    }
    state = AuthState(isInitialized: true);
  }

  Future<void> _handleGoogleAuthenticationEvent(
    GoogleSignInAuthenticationEvent event,
  ) async {
    if (event is! GoogleSignInAuthenticationEventSignIn) {
      return;
    }

    final authentication = event.user.authentication;
    final idToken = authentication.idToken;

    if (idToken == null || idToken.isEmpty) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: () => 'Google did not return an ID token.',
      );
      return;
    }

    await _authenticate(
      () => _repository.googleLogin(idToken: idToken),
    );
  }

  Future<bool> _authenticate(Future<AuthResult> Function() action) async {
    state = state.copyWith(isLoading: true, errorMessage: () => null);

    try {
      final result = await action();
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(_tokenStorageKey, result.token);
      state = state.copyWith(
        token: () => result.token,
        user: () => result.user,
      );
      return true;
    } catch (error) {
      state = state.copyWith(errorMessage: () => _readErrorMessage(error));
      return false;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  String _readErrorMessage(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map<String, dynamic> && data['message'] is String) {
        return data['message'] as String;
      }
    }

    if (error is GoogleSignInException) {
      return error.description ?? 'Google Sign-In failed. Please try again.';
    }

    return 'Authentication failed. Please try again.';
  }
}

final authControllerProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

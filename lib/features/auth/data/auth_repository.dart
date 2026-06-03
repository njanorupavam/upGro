import 'package:dayforge/core/network/api_client.dart';
import 'package:dayforge/features/auth/data/auth_models.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(dioProvider));
});

class AuthRepository {
  const AuthRepository(this._dio);

  final Dio _dio;

  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/register',
      data: {
        'name': name,
        'email': email,
        'password': password,
      },
    );

    return AuthResult.fromJson(response.data!);
  }

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/login',
      data: {
        'email': email,
        'password': password,
      },
    );

    return AuthResult.fromJson(response.data!);
  }

  Future<AuthResult> googleLogin({
    required String email,
    required String name,
    required String googleId,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/google',
      data: {
        'email': email,
        'name': name,
        'googleId': googleId,
      },
    );

    return AuthResult.fromJson(response.data!);
  }

  Future<AppUser> profile(String token) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/auth/profile',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return AppUser.fromJson(response.data!['user'] as Map<String, dynamic>);
  }
}

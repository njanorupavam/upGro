import 'package:dayforge/core/network/api_client.dart';
import 'package:dayforge/features/auth/data/auth_models.dart';
import 'package:dio/dio.dart';

class AuthRepository {
  const AuthRepository();

  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await dio.post<Map<String, dynamic>>(
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
    final response = await dio.post<Map<String, dynamic>>(
      '/auth/login',
      data: {
        'email': email,
        'password': password,
      },
    );

    return AuthResult.fromJson(response.data!);
  }

  Future<AppUser> profile(String token) async {
    final response = await dio.get<Map<String, dynamic>>(
      '/auth/profile',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return AppUser.fromJson(response.data!['user'] as Map<String, dynamic>);
  }
}

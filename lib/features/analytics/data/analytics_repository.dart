import 'package:dayforge/core/network/api_client.dart';
import 'package:dayforge/features/analytics/data/analytics_models.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  return AnalyticsRepository(ref.watch(dioProvider));
});

class AnalyticsRepository {
  const AnalyticsRepository(this._dio);

  final Dio _dio;

  Future<DashboardAnalytics> dashboard(String token) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/analytics/dashboard',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return DashboardAnalytics.fromJson(
      response.data!['analytics'] as Map<String, dynamic>,
    );
  }
}

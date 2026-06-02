import 'package:dayforge/core/network/api_client.dart';
import 'package:dayforge/features/analytics/data/analytics_models.dart';
import 'package:dio/dio.dart';

class AnalyticsRepository {
  const AnalyticsRepository();

  Future<DashboardAnalytics> dashboard(String token) async {
    final response = await dio.get<Map<String, dynamic>>(
      '/analytics/dashboard',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return DashboardAnalytics.fromJson(
      response.data!['analytics'] as Map<String, dynamic>,
    );
  }
}

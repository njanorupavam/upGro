import 'package:dayforge/features/analytics/data/analytics_models.dart';
import 'package:dayforge/features/analytics/data/analytics_repository.dart';
import 'package:dayforge/features/auth/presentation/auth_controller.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart';

final analyticsControllerProvider =
    ChangeNotifierProvider<AnalyticsController>((ref) {
  final auth = ref.watch(authControllerProvider);
  final controller = AnalyticsController(
    const AnalyticsRepository(),
    auth.token,
  );
  controller.loadAnalytics();
  return controller;
});

class AnalyticsController extends ChangeNotifier {
  AnalyticsController(this._repository, this._token);

  final AnalyticsRepository _repository;
  final String? _token;

  DashboardAnalytics? analytics;
  String? errorMessage;
  bool isLoading = false;

  Future<void> loadAnalytics() async {
    if (_token == null) {
      return;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      analytics = await _repository.dashboard(_token);
    } catch (error) {
      errorMessage = _readError(error);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  String _readError(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map<String, dynamic> && data['message'] is String) {
        return data['message'] as String;
      }
    }

    return 'Analytics failed to load.';
  }
}

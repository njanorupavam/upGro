import 'package:dayforge/features/analytics/data/analytics_models.dart';
import 'package:dayforge/features/analytics/data/analytics_repository.dart';
import 'package:dayforge/features/auth/presentation/auth_controller.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AnalyticsState {
  final DashboardAnalytics? analytics;
  final String? errorMessage;
  final bool isLoading;

  AnalyticsState({
    this.analytics,
    this.errorMessage,
    this.isLoading = false,
  });

  AnalyticsState copyWith({
    DashboardAnalytics? Function()? analytics,
    String? Function()? errorMessage,
    bool? isLoading,
  }) {
    return AnalyticsState(
      analytics: analytics != null ? analytics() : this.analytics,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class AnalyticsNotifier extends Notifier<AnalyticsState> {
  late final AnalyticsRepository _repository;
  String? _token;

  @override
  AnalyticsState build() {
    _repository = ref.watch(analyticsRepositoryProvider);
    _token = ref.watch(authControllerProvider.select((auth) => auth.token));
    if (_token != null) {
      Future.microtask(() => loadAnalytics());
    }
    return AnalyticsState();
  }

  Future<void> loadAnalytics() async {
    if (_token == null) {
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: () => null);

    try {
      final analytics = await _repository.dashboard(_token!);
      state = state.copyWith(analytics: () => analytics);
    } catch (error) {
      state = state.copyWith(errorMessage: () => _readError(error));
    } finally {
      state = state.copyWith(isLoading: false);
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

final analyticsControllerProvider =
    NotifierProvider<AnalyticsNotifier, AnalyticsState>(AnalyticsNotifier.new);

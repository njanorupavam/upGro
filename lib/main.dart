import 'package:dayforge/core/presentation/dayforge_ui.dart';
import 'package:dayforge/features/analytics/presentation/analytics_screen.dart';
import 'package:dayforge/features/auth/presentation/auth_controller.dart';
import 'package:dayforge/features/auth/presentation/auth_screens.dart';
import 'package:dayforge/features/dashboard/presentation/dashboard_screen.dart';
import 'package:dayforge/features/focus/presentation/focus_mode_screen.dart';
import 'package:dayforge/features/goals/presentation/goals_screen.dart';
import 'package:dayforge/features/habits/presentation/habits_screen.dart';
import 'package:dayforge/features/profile/presentation/profile_screen.dart';
import 'package:dayforge/features/shell/presentation/app_shell.dart';
import 'package:dayforge/features/tasks/presentation/tasks_screen.dart';
import 'package:dayforge/core/presentation/theme_controller.dart';
import 'package:dayforge/core/presentation/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init();
  runApp(const ProviderScope(child: DayForgeApp()));
}

class NotifierListenable extends ChangeNotifier {
  NotifierListenable(Ref ref, dynamic provider) {
    ref.listen(provider, (_, __) => notifyListeners());
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);

  return GoRouter(
    refreshListenable: NotifierListenable(ref, authControllerProvider),
    initialLocation: '/login',
    redirect: (context, state) {
      if (!authState.isInitialized) {
        return state.matchedLocation == '/loading' ? null : '/loading';
      }

      final isAuthRoute =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      if (!authState.isAuthenticated) {
        return isAuthRoute ? null : '/login';
      }

      if (isAuthRoute || state.matchedLocation == '/loading') {
        return '/dashboard';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/loading',
        builder: (context, state) => const LoadingScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/tasks',
            builder: (context, state) => const TasksScreen(),
          ),
          GoRoute(
            path: '/focus',
            builder: (context, state) => const FocusModeScreen(),
          ),
          GoRoute(
            path: '/habits',
            builder: (context, state) => const HabitsScreen(),
          ),
          GoRoute(
            path: '/goals',
            builder: (context, state) => const GoalsScreen(),
          ),
          GoRoute(
            path: '/analytics',
            builder: (context, state) => const AnalyticsScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
    ],
  );
});

ThemeData _buildTheme(Brightness brightness) {
  final colors = brightness == Brightness.dark
      ? (
          surface: const Color(0xFF0F172A),
          surfaceDim: const Color(0xFF0F172A),
          surfaceBright: const Color(0xFF1E293B),
          surfaceContainerLowest: const Color(0xFF020617),
          surfaceContainerLow: const Color(0xFF0F172A),
          surfaceContainer: const Color(0xFF1E293B),
          surfaceContainerHigh: const Color(0xFF334155),
          surfaceContainerHighest: const Color(0xFF475569),
          onSurface: const Color(0xFFF8FAFC),
          onSurfaceVariant: const Color(0xFF94A3B8),
          inverseSurface: const Color(0xFFF8FAFC),
          inverseOnSurface: const Color(0xFF0F172A),
          outline: const Color(0xFF64748B),
          outlineVariant: const Color(0xFF334155),
          surfaceTint: const Color(0xFF3B82F6),
          primary: const Color(0xFF3B82F6),
          onPrimary: const Color(0xFFFFFFFF),
          primaryContainer: const Color(0xFF1E3A8A),
          onPrimaryContainer: const Color(0xFFDBEAFE),
          inversePrimary: const Color(0xFF004AC6),
          secondary: const Color(0xFF10B981),
          onSecondary: const Color(0xFFFFFFFF),
          secondaryContainer: const Color(0xFF064E3B),
          onSecondaryContainer: const Color(0xFFD1FAE5),
          tertiary: const Color(0xFFF59E0B),
          onTertiary: const Color(0xFFFFFFFF),
          tertiaryContainer: const Color(0xFF78350F),
          onTertiaryContainer: const Color(0xFFFEF3C7),
          error: const Color(0xFFEF4444),
          onError: const Color(0xFFFFFFFF),
          errorContainer: const Color(0xFF450A0A),
          onErrorContainer: const Color(0xFFFCA5A5),
          primaryFixed: const Color(0xFFDBEAFE),
          primaryFixedDim: const Color(0xFF93C5FD),
          onPrimaryFixed: const Color(0xFF1E3A8A),
          onPrimaryFixedVariant: const Color(0xFF1D4ED8),
          secondaryFixed: const Color(0xFFD1FAE5),
          secondaryFixedDim: const Color(0xFF6EE7B7),
          onSecondaryFixed: const Color(0xFF064E3B),
          onSecondaryFixedVariant: const Color(0xFF047857),
          tertiaryFixed: const Color(0xFFFEF3C7),
          tertiaryFixedDim: const Color(0xFFFCD34D),
          onTertiaryFixed: const Color(0xFF78350F),
          onTertiaryFixedVariant: const Color(0xFFB45309),
          background: const Color(0xFF0F172A),
          onBackground: const Color(0xFFF8FAFC),
          surfaceVariant: const Color(0xFF1E293B),
        )
      : (
          surface: const Color(0xFFF8F9FF),
          surfaceDim: const Color(0xFFCBDBF5),
          surfaceBright: const Color(0xFFF8F9FF),
          surfaceContainerLowest: const Color(0xFFFFFFFF),
          surfaceContainerLow: const Color(0xFFEFF4FF),
          surfaceContainer: const Color(0xFFE5EEFF),
          surfaceContainerHigh: const Color(0xFFDCE9FF),
          surfaceContainerHighest: const Color(0xFFD3E4FE),
          onSurface: const Color(0xFF0B1C30),
          onSurfaceVariant: const Color(0xFF434655),
          inverseSurface: const Color(0xFF213145),
          inverseOnSurface: const Color(0xFFEAF1FF),
          outline: const Color(0xFF737686),
          outlineVariant: const Color(0xFFC3C6D7),
          surfaceTint: const Color(0xFF0053DB),
          primary: const Color(0xFF004AC6),
          onPrimary: const Color(0xFFFFFFFF),
          primaryContainer: const Color(0xFF2563EB),
          onPrimaryContainer: const Color(0xFFEEEFFF),
          inversePrimary: const Color(0xFFB4C5FF),
          secondary: const Color(0xFF006C49),
          onSecondary: const Color(0xFFFFFFFF),
          secondaryContainer: const Color(0xFF6CF8BB),
          onSecondaryContainer: const Color(0xFF00714D),
          tertiary: const Color(0xFF784B00),
          onTertiary: const Color(0xFFFFFFFF),
          tertiaryContainer: const Color(0xFF996100),
          onTertiaryContainer: const Color(0xFFFFEEDD),
          error: const Color(0xFFBA1A1A),
          onError: const Color(0xFFFFFFFF),
          errorContainer: const Color(0xFFFFDAD6),
          onErrorContainer: const Color(0xFF93000a),
          primaryFixed: const Color(0xFFDBE1FF),
          primaryFixedDim: const Color(0xFFB4C5FF),
          onPrimaryFixed: const Color(0xFF00174B),
          onPrimaryFixedVariant: const Color(0xFF003EA8),
          secondaryFixed: const Color(0xFF6FFBCE),
          secondaryFixedDim: const Color(0xFF4EDEA3),
          onSecondaryFixed: const Color(0xFF002113),
          onSecondaryFixedVariant: const Color(0xFF005236),
          tertiaryFixed: const Color(0xFFFFDDB8),
          tertiaryFixedDim: const Color(0xFFFFB95F),
          onTertiaryFixed: const Color(0xFF2A1700),
          onTertiaryFixedVariant: const Color(0xFF653E00),
          background: const Color(0xFFF8F9FF),
          onBackground: const Color(0xFF0B1C30),
          surfaceVariant: const Color(0xFFE5EEFF),
        );

  final base = ThemeData(
    brightness: brightness,
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: colors.primary,
      brightness: brightness,
      primary: colors.primary,
      onPrimary: colors.onPrimary,
      primaryContainer: colors.primaryContainer,
      onPrimaryContainer: colors.onPrimaryContainer,
      secondary: colors.secondary,
      onSecondary: colors.onSecondary,
      secondaryContainer: colors.secondaryContainer,
      onSecondaryContainer: colors.onSecondaryContainer,
      tertiary: colors.tertiary,
      onTertiary: colors.onTertiary,
      tertiaryContainer: colors.tertiaryContainer,
      onTertiaryContainer: colors.onTertiaryContainer,
      error: colors.error,
      onError: colors.onError,
      errorContainer: colors.errorContainer,
      onErrorContainer: colors.onErrorContainer,
      background: colors.background,
      onBackground: colors.onBackground,
      surface: colors.surface,
      onSurface: colors.onSurface,
      surfaceVariant: colors.surfaceVariant,
      onSurfaceVariant: colors.onSurfaceVariant,
      outline: colors.outline,
      outlineVariant: colors.outlineVariant,
      inverseSurface: colors.inverseSurface,
      onInverseSurface: colors.inverseOnSurface,
      inversePrimary: colors.inversePrimary,
      surfaceTint: colors.surfaceTint,
    ),
  );
  final textTheme = GoogleFonts.geistTextTheme(
    base.textTheme,
  ).apply(bodyColor: colors.onSurface, displayColor: colors.onSurface);

  return base.copyWith(
    scaffoldBackgroundColor: colors.background,
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      foregroundColor: colors.onSurface,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: colors.surfaceContainer,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        side: BorderSide(color: colors.outlineVariant),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: colors.surfaceBright,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),
    chipTheme: ChipThemeData(
      shape: const StadiumBorder(),
      backgroundColor: colors.surfaceContainerLow,
      selectedColor: colors.primaryContainer,
      labelStyle:
          TextStyle(color: colors.onSurface, fontWeight: FontWeight.w600, fontFamily: 'Geist'),
      side: BorderSide(color: colors.outlineVariant),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colors.surfaceContainerLow,
      hintStyle: TextStyle(color: colors.onSurfaceVariant.withOpacity(0.6), fontFamily: 'Geist'),
      labelStyle: TextStyle(color: colors.onSurfaceVariant, fontFamily: 'Geist'),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colors.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colors.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colors.primary, width: 2.0),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontFamily: 'Geist'),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: colors.primary,
        side: BorderSide(color: colors.primary.withOpacity(0.4), width: 1),
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontFamily: 'Geist'),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: colors.primary,
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontFamily: 'Geist'),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: colors.primary,
      foregroundColor: colors.onPrimary,
      shape: const CircleBorder(),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: colors.surfaceContainerHighest,
      indicatorColor: colors.primaryContainer,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return IconThemeData(color: colors.onPrimaryContainer);
        }
        return IconThemeData(color: colors.onSurfaceVariant);
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          color: selected
              ? colors.onPrimaryContainer
              : colors.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        );
      }),
    ),
  );
}

class DayForgeApp extends ConsumerWidget {
  const DayForgeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Upgro',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: SizedBox(
          width: 180,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.trending_up, size: 42, color: focusFlowBlue),
              SizedBox(height: 18),
              CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}

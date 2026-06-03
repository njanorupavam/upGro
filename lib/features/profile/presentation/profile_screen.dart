import 'package:dayforge/core/presentation/dayforge_ui.dart';
import 'package:dayforge/core/presentation/theme_controller.dart';
import 'package:dayforge/core/presentation/badge_provider.dart';
import 'package:dayforge/core/presentation/notification_service.dart';
import 'package:dayforge/features/auth/presentation/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final user = auth.user;
    final themeMode = ref.watch(themeModeProvider);
    final isLightMode = themeMode == ThemeMode.light;
    final badgeState = ref.watch(badgeProvider);
    final hasNotificationPermission = ref.watch(notificationPermissionProvider);

    return DayForgePage(
      title: 'Profile',
      subtitle: 'Your DayForge account.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DayForgeCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const IconBubble(icon: Icons.person_outline),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.name ?? 'Loading',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: context.dayforgeText,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                          Text(
                            user?.email ?? '',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: context.dayforgeMuted,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: isLightMode,
                  onChanged: (value) {
                    ref.read(themeModeProvider.notifier).setThemeMode(
                          value ? ThemeMode.light : ThemeMode.dark,
                        );
                  },
                  title: Text(
                    'Light mode',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: context.dayforgeText,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  subtitle: Text(
                    'Switch between light and dark themes.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: context.dayforgeMuted,
                        ),
                  ),
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: hasNotificationPermission,
                  onChanged: (value) {
                    ref
                        .read(notificationPermissionProvider.notifier)
                        .togglePermission();
                  },
                  title: Text(
                    'Desktop notifications',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: context.dayforgeText,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  subtitle: Text(
                    'Receive alerts for timers and reminders.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: context.dayforgeMuted,
                        ),
                  ),
                ),
                const SizedBox(height: 22),
                OutlinedButton.icon(
                  onPressed: () async {
                    await ref.read(authControllerProvider.notifier).logout();
                    if (context.mounted) {
                      context.go('/login');
                    }
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Sign out'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _TrophyCabinetCard(badgeState: badgeState),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _TrophyCabinetCard extends StatelessWidget {
  const _TrophyCabinetCard({required this.badgeState});

  final BadgeState badgeState;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return DayForgeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              DayForgeBadge(
                'Trophy Cabinet',
                color: theme.colorScheme.primary.withOpacity(0.12),
                textColor: theme.colorScheme.primary,
              ),
              Text(
                'Unlocked: ${badgeState.unlockedIds.length}/${kAllBadges.length}',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Milestone Badges',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Track your progress through the 21-day transformation challenge.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 150,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.0,
            ),
            itemCount: kAllBadges.length,
            itemBuilder: (context, index) {
              final badge = kAllBadges[index];
              final isUnlocked = badgeState.unlockedIds.contains(badge.id);

              return GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        backgroundColor: theme.colorScheme.surface,
                        surfaceTintColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        title: Row(
                          children: [
                            Icon(
                              isUnlocked ? badge.icon : Icons.lock,
                              color: isUnlocked ? badge.color : theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              badge.title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        content: Text(
                          badge.description,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Close'),
                          ),
                        ],
                      );
                    },
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isUnlocked
                        ? badge.color.withOpacity(0.08)
                        : (isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.015)),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isUnlocked
                          ? badge.color.withOpacity(0.3)
                          : theme.colorScheme.outlineVariant.withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isUnlocked ? badge.icon : Icons.lock_outline,
                        size: 32,
                        color: isUnlocked ? badge.color : theme.colorScheme.onSurfaceVariant.withOpacity(0.3),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          badge.title,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isUnlocked ? theme.colorScheme.onSurface : theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}


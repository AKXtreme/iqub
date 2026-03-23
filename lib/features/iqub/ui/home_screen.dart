import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../../../app/theme_provider.dart';
import '../../../core/widgets/error_view.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../providers/iqub_provider.dart';
import 'widgets/iqub_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final iqubsAsync = ref.watch(myIqubsProvider);
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Iqub Manager', style: Theme.of(context).textTheme.titleLarge),
            userAsync.whenOrNull(
                  data: (user) => Text(
                    user?.name ?? '',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(fontSize: 12),
                  ),
                ) ??
                const SizedBox.shrink(),
          ],
        ),
        actions: [
          // Dark mode toggle
          Consumer(
            builder: (context, ref, _) {
              final isDark = ref.watch(themeModeProvider);
              return IconButton(
                icon: Icon(
                  isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                ),
                tooltip: isDark ? 'Light mode' : 'Dark mode',
                onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
              );
            },
          ),
          // Sign out
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign out',
            onPressed: () async {
              final confirmed = await _confirmSignOut(context);
              if (confirmed && context.mounted) {
                await ref.read(authNotifierProvider.notifier).signOut();
              }
            },
          ),
        ],
      ),
      body: iqubsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
          message: 'Failed to load your Iqub groups.',
          onRetry: () => ref.invalidate(myIqubsProvider),
        ),
        data: (iqubs) {
          if (iqubs.isEmpty) {
            return _EmptyState(
              onCreateTap: () => context.push(AppRoutes.createIqub),
            );
          }

          return CustomScrollView(
            slivers: [
              // Summary banner
              SliverToBoxAdapter(
                child: _SummaryBanner(totalGroups: iqubs.length),
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                sliver: SliverList.separated(
                  itemCount: iqubs.length,
                  separatorBuilder: (ctx, _) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final iqub = iqubs[i];
                    return IqubCard(
                      iqub: iqub,
                      onTap: () => context.push(
                        AppRoutes.iqubDetail.replaceFirst(':id', iqub.id),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.createIqub),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Iqub'),
      ),
    );
  }

  Future<bool> _confirmSignOut(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Sign out?'),
            content: const Text('You will be returned to the login screen.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Sign out',
                  style: TextStyle(color: AppColors.error),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }
}

class _SummaryBanner extends StatelessWidget {
  const _SummaryBanner({required this.totalGroups});
  final int totalGroups;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(Icons.savings_rounded, color: Colors.white, size: 36),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$totalGroups Active Group${totalGroups == 1 ? '' : 's'}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Tap a group to view details',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreateTap});
  final VoidCallback onCreateTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.savings_rounded,
                color: AppColors.primary,
                size: 40,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Iqub groups yet',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first Iqub group to start\nmanaging your savings rotation.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: onCreateTap,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Create Iqub Group'),
            ),
          ],
        ),
      ),
    );
  }
}

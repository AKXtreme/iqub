import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/error_view.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../domain/iqub_model.dart';
import '../domain/member_model.dart';
import '../providers/iqub_provider.dart';
import 'widgets/member_tile.dart';
import 'widgets/stats_card.dart';

class IqubDetailScreen extends ConsumerWidget {
  const IqubDetailScreen({super.key, required this.iqubId});

  final String iqubId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final iqubAsync = ref.watch(iqubProvider(iqubId));
    final membersAsync = ref.watch(membersProvider(iqubId));
    final currentUserId = ref.watch(authStateProvider).valueOrNull?.uid ?? '';

    return iqubAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: ErrorView(message: 'Failed to load Iqub details.'),
      ),
      data: (iqub) {
        if (iqub == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const ErrorView(message: 'Iqub not found.'),
          );
        }

        final isAdmin = iqub.adminId == currentUserId;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: CustomScrollView(
            slivers: [
              // ── App Bar ──────────────────────────────────────────────────
              SliverAppBar(
                expandedHeight: 160,
                pinned: true,
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    iqub.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primary, Color(0xFF1E40AF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.savings_rounded,
                        color: Colors.white30,
                        size: 80,
                      ),
                    ),
                  ),
                ),
                actions: [
                  if (isAdmin)
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.white),
                      onSelected: (v) => _handleMenu(
                        context,
                        ref,
                        v,
                        iqub,
                        membersAsync.valueOrNull ?? [],
                      ),
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'members',
                          child: ListTile(
                            leading: Icon(Icons.group_outlined),
                            title: Text('Manage Members'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'history',
                          child: ListTile(
                            leading: Icon(Icons.history_rounded),
                            title: Text('View History'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        if (iqub.status == IqubStatus.active)
                          const PopupMenuItem(
                            value: 'payments',
                            child: ListTile(
                              leading: Icon(Icons.payment_rounded),
                              title: Text('Track Payments'),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                      ],
                    ),
                ],
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Status chip ───────────────────────────────────
                      _StatusChip(status: iqub.status),
                      const SizedBox(height: 20),

                      // ── Stats grid ────────────────────────────────────
                      _StatsGrid(iqub: iqub),
                      const SizedBox(height: 20),

                      // ── Current round card ────────────────────────────
                      _CurrentRoundCard(
                        iqub: iqub,
                        members: membersAsync.valueOrNull ?? [],
                        isAdmin: isAdmin,
                        onTrackPayments: () => context.push(
                          AppRoutes.payments
                              .replaceFirst(':id', iqubId)
                              .replaceFirst(':round', '${iqub.currentRound}'),
                        ),
                        onRecordPayout: () => _recordPayout(
                          context,
                          ref,
                          iqub,
                          membersAsync.valueOrNull ?? [],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── Members section ───────────────────────────────
                      _SectionHeader(
                        title: 'Members (${iqub.memberIds.length})',
                        action: isAdmin
                            ? TextButton.icon(
                                onPressed: () => context.push(
                                  AppRoutes.members.replaceFirst(':id', iqubId),
                                ),
                                icon: const Icon(Icons.edit_outlined, size: 16),
                                label: const Text('Manage'),
                              )
                            : null,
                      ),
                      const SizedBox(height: 8),

                      membersAsync.when(
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (e, _) => const ErrorView(
                          message: 'Failed to load members.',
                          compact: true,
                        ),
                        data: (members) => Column(
                          children: members
                              .map(
                                (m) => MemberTile(
                                  member: m,
                                  isCurrentPayout:
                                      m.id == iqub.currentPayoutMemberId,
                                ),
                              )
                              .toList(),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ── Action buttons ────────────────────────────────
                      Row(
                        children: [
                          Expanded(
                            child: CustomButton(
                              label: 'Payment History',
                              variant: ButtonVariant.outlined,
                              onPressed: () => context.push(
                                AppRoutes.history.replaceFirst(':id', iqubId),
                              ),
                              icon: Icons.history_rounded,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // FAB only for admins to add members
          floatingActionButton: isAdmin && iqub.status == IqubStatus.active
              ? FloatingActionButton.extended(
                  onPressed: () => context.push(
                    AppRoutes.members.replaceFirst(':id', iqubId),
                  ),
                  icon: const Icon(Icons.person_add_outlined),
                  label: const Text('Add Member'),
                )
              : null,
        );
      },
    );
  }

  void _handleMenu(
    BuildContext context,
    WidgetRef ref,
    String action,
    IqubModel iqub,
    List<MemberModel> members,
  ) {
    switch (action) {
      case 'members':
        context.push(AppRoutes.members.replaceFirst(':id', iqubId));
        break;
      case 'history':
        context.push(AppRoutes.history.replaceFirst(':id', iqubId));
        break;
      case 'payments':
        context.push(
          AppRoutes.payments
              .replaceFirst(':id', iqubId)
              .replaceFirst(':round', '${iqub.currentRound}'),
        );
        break;
    }
  }

  Future<void> _recordPayout(
    BuildContext context,
    WidgetRef ref,
    IqubModel iqub,
    List<MemberModel> members,
  ) async {
    final recipient = members.firstWhere(
      (m) => m.id == iqub.currentPayoutMemberId,
      orElse: () => members.first,
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Record Payout'),
        content: Text(
          'Confirm payout of ETB ${NumberFormat('#,###').format(iqub.totalPerRound)} '
          'to ${recipient.name} for Round ${iqub.currentRound}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm Payout'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final success = await ref
        .read(iqubActionsProvider.notifier)
        .recordPayoutAndAdvance(iqub: iqub, recipient: recipient);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Payout recorded! Round ${iqub.currentRound + 1} started.'
                : 'Failed to record payout.',
          ),
          backgroundColor: success ? AppColors.success : AppColors.error,
        ),
      );
    }
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final IqubStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      IqubStatus.active => AppColors.success,
      IqubStatus.paused => AppColors.warning,
      IqubStatus.completed => AppColors.textSecondary,
    };
    final label = switch (status) {
      IqubStatus.active => 'Active',
      IqubStatus.paused => 'Paused',
      IqubStatus.completed => 'Completed',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.iqub});
  final IqubModel iqub;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat('#,###');

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 2.2,
      children: [
        StatsCard(
          label: 'Contribution',
          value: 'ETB ${currency.format(iqub.contributionAmount)}',
          icon: Icons.attach_money_rounded,
          color: AppColors.primary,
        ),
        StatsCard(
          label: 'Pot per Round',
          value: 'ETB ${currency.format(iqub.totalPerRound)}',
          icon: Icons.account_balance_wallet_rounded,
          color: AppColors.success,
        ),
        StatsCard(
          label: 'Current Round',
          value: '${iqub.currentRound} / ${iqub.totalRounds}',
          icon: Icons.rotate_right_rounded,
          color: AppColors.secondary,
        ),
        StatsCard(
          label: 'Members',
          value: '${iqub.memberIds.length}',
          icon: Icons.group_rounded,
          color: AppColors.warning,
          subtitle: iqub.frequency.label,
        ),
      ],
    );
  }
}

class _CurrentRoundCard extends StatelessWidget {
  const _CurrentRoundCard({
    required this.iqub,
    required this.members,
    required this.isAdmin,
    required this.onTrackPayments,
    required this.onRecordPayout,
  });

  final IqubModel iqub;
  final List<MemberModel> members;
  final bool isAdmin;
  final VoidCallback onTrackPayments;
  final VoidCallback onRecordPayout;

  @override
  Widget build(BuildContext context) {
    if (iqub.status == IqubStatus.completed) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
        ),
        child: const Row(
          children: [
            Icon(
              Icons.check_circle_rounded,
              color: AppColors.success,
              size: 32,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'This Iqub has completed all rounds!',
                style: TextStyle(
                  color: AppColors.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final payoutMember = members.isEmpty
        ? null
        : members.where((m) => m.id == iqub.currentPayoutMemberId).firstOrNull;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.08),
            AppColors.secondary.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Round ${iqub.currentRound}',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: AppColors.primary),
          ),
          const SizedBox(height: 4),
          Text(
            'Next payout: ${payoutMember?.name ?? 'TBD'}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (payoutMember != null) ...[
            const SizedBox(height: 4),
            Text(
              'Amount: ETB ${NumberFormat('#,###').format(iqub.totalPerRound)}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
          if (isAdmin) ...[
            const SizedBox(height: 16),
            CustomButton(
              label: 'Track Payments',
              variant: ButtonVariant.outlined,
              onPressed: onTrackPayments,
              icon: Icons.payment_rounded,
            ),
            const SizedBox(height: 10),
            CustomButton(
              label: 'Record Payout',
              onPressed: payoutMember != null ? onRecordPayout : null,
              icon: Icons.send_rounded,
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.action});
  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        ?action,
      ],
    );
  }
}

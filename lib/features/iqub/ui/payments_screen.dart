import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/error_view.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../domain/member_model.dart';
import '../providers/iqub_provider.dart';
import 'widgets/payment_tile.dart';
import 'widgets/stats_card.dart';

class PaymentsScreen extends ConsumerWidget {
  const PaymentsScreen({super.key, required this.iqubId, required this.round});

  final String iqubId;
  final int round;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final iqubAsync = ref.watch(iqubProvider(iqubId));
    final paymentsAsync = ref.watch(
      paymentsForRoundProvider((iqubId: iqubId, round: round)),
    );
    final membersAsync = ref.watch(membersProvider(iqubId));
    final currentUserId = ref.watch(authStateProvider).valueOrNull?.uid ?? '';

    return Scaffold(
      appBar: AppBar(title: Text('Round $round Payments')),
      body: iqubAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const ErrorView(message: 'Failed to load data.'),
        data: (iqub) {
          if (iqub == null) {
            return const ErrorView(message: 'Iqub not found.');
          }

          final isAdmin = iqub.adminId == currentUserId;

          return paymentsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) =>
                const ErrorView(message: 'Failed to load payments.'),
            data: (payments) {
              // Show "generate" button if no payments exist yet for this round
              if (payments.isEmpty) {
                return _GeneratePaymentsView(
                  iqubId: iqubId,
                  round: round,
                  isAdmin: isAdmin,
                  members: membersAsync.valueOrNull ?? [],
                  contributionAmount: iqub.contributionAmount,
                );
              }

              final paidCount = payments.where((p) => p.isPaid).length;
              final unpaidCount = payments.length - paidCount;
              final totalCollected = paidCount * iqub.contributionAmount;

              return Column(
                children: [
                  // ── Summary strip ───────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: AppColors.surface,
                    child: Row(
                      children: [
                        Expanded(
                          child: StatsCard(
                            label: 'Collected',
                            value: 'ETB ${totalCollected.toStringAsFixed(0)}',
                            icon: Icons.check_circle_rounded,
                            color: AppColors.success,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: StatsCard(
                            label: 'Pending',
                            value: '$unpaidCount members',
                            icon: Icons.pending_rounded,
                            color: AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Payments list ────────────────────────────────
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                      itemCount: payments.length,
                      itemBuilder: (context, i) {
                        final payment = payments[i];
                        return PaymentTile(
                          payment: payment,
                          isAdmin: isAdmin,
                          onToggle: isAdmin
                              ? () => _togglePayment(
                                  context,
                                  ref,
                                  payment.isPaid,
                                  payment.id,
                                )
                              : null,
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _togglePayment(
    BuildContext context,
    WidgetRef ref,
    bool currentlyPaid,
    String paymentId,
  ) async {
    bool success;
    if (currentlyPaid) {
      success = await ref
          .read(iqubActionsProvider.notifier)
          .markPaymentUnpaid(iqubId, paymentId);
    } else {
      success = await ref
          .read(iqubActionsProvider.notifier)
          .markPaymentPaid(iqubId, paymentId);
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? currentlyPaid
                      ? 'Marked as unpaid.'
                      : 'Payment confirmed!'
                : 'Action failed.',
          ),
          backgroundColor: success ? AppColors.success : AppColors.error,
        ),
      );
    }
  }
}

/// Shown when payments haven't been generated for this round yet
class _GeneratePaymentsView extends ConsumerWidget {
  const _GeneratePaymentsView({
    required this.iqubId,
    required this.round,
    required this.isAdmin,
    required this.members,
    required this.contributionAmount,
  });

  final String iqubId;
  final int round;
  final bool isAdmin;
  final List<MemberModel> members;
  final double contributionAmount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(iqubActionsProvider).isLoading;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.payment_rounded,
                color: AppColors.primary,
                size: 36,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No payments yet for Round $round',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Generate payment records for all ${members.length} members.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (isAdmin) ...[
              const SizedBox(height: 28),
              CustomButton(
                label: 'Generate Payments',
                isLoading: isLoading,
                icon: Icons.auto_fix_high_rounded,
                onPressed: members.isEmpty
                    ? null
                    : () async {
                        final success = await ref
                            .read(iqubActionsProvider.notifier)
                            .generatePayments(
                              iqubId: iqubId,
                              roundNumber: round,
                              members: members,
                              amount: contributionAmount,
                              dueDate: DateTime.now().add(
                                const Duration(days: 7),
                              ),
                            );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                success
                                    ? 'Payment records created!'
                                    : 'Failed to generate payments.',
                              ),
                              backgroundColor: success
                                  ? AppColors.success
                                  : AppColors.error,
                            ),
                          );
                        }
                      },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/theme.dart';
import '../../../core/extensions/datetime_ext.dart';
import '../../../core/widgets/error_view.dart';
import '../domain/payment_model.dart';
import '../domain/payout_model.dart';
import '../providers/iqub_provider.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key, required this.iqubId});

  final String iqubId;

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Payments'),
            Tab(text: 'Payouts'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _PaymentsHistoryTab(iqubId: widget.iqubId),
          _PayoutsHistoryTab(iqubId: widget.iqubId),
        ],
      ),
    );
  }
}

// ── Payments history tab ──────────────────────────────────────────────────────

class _PaymentsHistoryTab extends ConsumerWidget {
  const _PaymentsHistoryTab({required this.iqubId});
  final String iqubId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(allPaymentsProvider(iqubId));

    return paymentsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) =>
          const ErrorView(message: 'Failed to load payment history.'),
      data: (payments) {
        if (payments.isEmpty) {
          return const _EmptyHistory(
            icon: Icons.payment_rounded,
            message: 'No payment records yet.',
          );
        }

        // Group payments by round number
        final grouped = <int, List<PaymentModel>>{};
        for (final p in payments) {
          grouped.putIfAbsent(p.roundNumber, () => []).add(p);
        }
        final rounds = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: rounds.length,
          itemBuilder: (context, i) {
            final round = rounds[i];
            final roundPayments = grouped[round]!;
            final paid = roundPayments.where((p) => p.isPaid).length;

            return _RoundGroup(
              round: round,
              payments: roundPayments,
              paidCount: paid,
            );
          },
        );
      },
    );
  }
}

class _RoundGroup extends StatefulWidget {
  const _RoundGroup({
    required this.round,
    required this.payments,
    required this.paidCount,
  });

  final int round;
  final List<PaymentModel> payments;
  final int paidCount;

  @override
  State<_RoundGroup> createState() => _RoundGroupState();
}

class _RoundGroupState extends State<_RoundGroup> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final allPaid = widget.paidCount == widget.payments.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          // Header
          ListTile(
            onTap: () => setState(() => _expanded = !_expanded),
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: allPaid
                    ? AppColors.success.withValues(alpha: 0.12)
                    : AppColors.warning.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  '${widget.round}',
                  style: TextStyle(
                    color: allPaid ? AppColors.success : AppColors.warning,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            title: Text('Round ${widget.round}',
                style: Theme.of(context).textTheme.titleMedium),
            subtitle: Text(
              '${widget.paidCount}/${widget.payments.length} paid',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: allPaid ? AppColors.success : AppColors.warning,
                  ),
            ),
            trailing: Icon(
              _expanded
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              color: AppColors.textSecondary,
            ),
          ),

          // Expandable payment rows
          if (_expanded) ...[
            const Divider(height: 1),
            ...widget.payments.map(
              (p) => ListTile(
                dense: true,
                leading: Icon(
                  p.isPaid
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: p.isPaid ? AppColors.success : AppColors.error,
                  size: 20,
                ),
                title: Text(p.memberName,
                    style: Theme.of(context).textTheme.bodyLarge),
                subtitle: p.isPaid && p.paidAt != null
                    ? Text(p.paidAt!.relative,
                        style: Theme.of(context).textTheme.bodyMedium)
                    : null,
                trailing: Text(
                  'ETB ${p.amount.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: p.isPaid
                            ? AppColors.success
                            : AppColors.textPrimary,
                      ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Payouts history tab ───────────────────────────────────────────────────────

class _PayoutsHistoryTab extends ConsumerWidget {
  const _PayoutsHistoryTab({required this.iqubId});
  final String iqubId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payoutsAsync = ref.watch(payoutsProvider(iqubId));

    return payoutsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) =>
          const ErrorView(message: 'Failed to load payout history.'),
      data: (payouts) {
        if (payouts.isEmpty) {
          return const _EmptyHistory(
            icon: Icons.account_balance_wallet_outlined,
            message: 'No payouts recorded yet.',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: payouts.length,
          itemBuilder: (context, i) =>
              _PayoutCard(payout: payouts[i]),
        );
      },
    );
  }
}

class _PayoutCard extends StatelessWidget {
  const _PayoutCard({required this.payout});
  final PayoutModel payout;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.account_balance_wallet_rounded,
                color: AppColors.success, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(payout.memberName,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(
                  'Round ${payout.roundNumber} • ${payout.payoutDate.formatted}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          Text(
            'ETB ${NumberFormat('#,###').format(payout.amount)}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory({required this.icon, required this.message});
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: AppColors.textSecondary),
          const SizedBox(height: 12),
          Text(message, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}

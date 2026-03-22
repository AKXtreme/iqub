import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../core/extensions/datetime_ext.dart';
import '../../domain/iqub_model.dart';

/// Card displayed in the home screen list for each Iqub group
class IqubCard extends StatelessWidget {
  const IqubCard({super.key, required this.iqub, required this.onTap});

  final IqubModel iqub;
  final VoidCallback onTap;

  Color get _statusColor {
    switch (iqub.status) {
      case IqubStatus.active:
        return AppColors.success;
      case IqubStatus.paused:
        return AppColors.warning;
      case IqubStatus.completed:
        return AppColors.textSecondary;
    }
  }

  String get _statusLabel {
    switch (iqub.status) {
      case IqubStatus.active:
        return 'Active';
      case IqubStatus.paused:
        return 'Paused';
      case IqubStatus.completed:
        return 'Completed';
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = iqub.totalRounds == 0
        ? 0.0
        : (iqub.currentRound - 1) / iqub.totalRounds;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
          boxShadow: const [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                // Icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.savings_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                // Name + status
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        iqub.name,
                        style: Theme.of(context).textTheme.titleLarge,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: _statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _statusLabel,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: _statusColor, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textSecondary,
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // Stats row
            Row(
              children: [
                _StatItem(
                  label: 'Contribution',
                  value: 'ETB ${iqub.contributionAmount.toStringAsFixed(0)}',
                ),
                const _Divider(),
                _StatItem(label: 'Members', value: '${iqub.memberIds.length}'),
                const _Divider(),
                _StatItem(
                  label: 'Round',
                  value: '${iqub.currentRound} / ${iqub.totalRounds}',
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Progress bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progress',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      '${(progress * 100).toStringAsFixed(0)}%',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: AppColors.divider,
                    valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Start date
            Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 13,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  'Started ${iqub.startDate.formatted}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontSize: 12),
                ),
                const SizedBox(width: 12),
                const Icon(
                  Icons.repeat_rounded,
                  size: 13,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  iqub.frequency.label,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 32, color: AppColors.divider);
  }
}

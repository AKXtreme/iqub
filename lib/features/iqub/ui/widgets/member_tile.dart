import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../domain/member_model.dart';

/// List tile for a single Iqub member
class MemberTile extends StatelessWidget {
  const MemberTile({
    super.key,
    required this.member,
    required this.isCurrentPayout,
    this.onRemove,
    this.showRemove = false,
  });

  final MemberModel member;

  /// Highlight if this member receives the payout this round
  final bool isCurrentPayout;

  final VoidCallback? onRemove;
  final bool showRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isCurrentPayout
            ? AppColors.primary.withValues(alpha: 0.06)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrentPayout ? AppColors.primary : AppColors.divider,
          width: isCurrentPayout ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          // Avatar with position number
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isCurrentPayout
                  ? AppColors.primary
                  : AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${member.payoutPosition}',
                style: TextStyle(
                  color: isCurrentPayout ? Colors.white : AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Name + phone
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        member.name,
                        style: Theme.of(context).textTheme.titleMedium,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    if (isCurrentPayout) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Next payout',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                    if (member.hasReceivedPayout) ...[
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.success,
                        size: 16,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  member.phone,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),

          // Remove button
          if (showRemove && onRemove != null)
            IconButton(
              icon: const Icon(
                Icons.remove_circle_outline,
                color: AppColors.error,
                size: 20,
              ),
              onPressed: onRemove,
              tooltip: 'Remove member',
            ),
        ],
      ),
    );
  }
}

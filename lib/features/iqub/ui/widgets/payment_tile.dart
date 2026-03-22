import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../core/extensions/datetime_ext.dart';
import '../../domain/payment_model.dart';

/// List tile for a single payment record
class PaymentTile extends StatelessWidget {
  const PaymentTile({
    super.key,
    required this.payment,
    this.onToggle,
    this.isAdmin = false,
  });

  final PaymentModel payment;
  final VoidCallback? onToggle;
  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    final isPaid = payment.isPaid;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          // Status icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isPaid
                  ? AppColors.success.withValues(alpha: 0.12)
                  : AppColors.error.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPaid ? Icons.check_rounded : Icons.close_rounded,
              color: isPaid ? AppColors.success : AppColors.error,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),

          // Member name + details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payment.memberName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  isPaid
                      ? 'Paid ${payment.paidAt?.relative ?? ''}'
                      : 'Due ${payment.dueDate.formatted}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isPaid ? AppColors.success : AppColors.error,
                        fontSize: 12,
                      ),
                ),
              ],
            ),
          ),

          // Amount
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'ETB ${payment.amount.toStringAsFixed(0)}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color:
                          isPaid ? AppColors.success : AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              // Toggle paid/unpaid (admin only)
              if (isAdmin && onToggle != null)
                GestureDetector(
                  onTap: onToggle,
                  child: Text(
                    isPaid ? 'Mark unpaid' : 'Mark paid',
                    style: TextStyle(
                      fontSize: 11,
                      color: isPaid ? AppColors.error : AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

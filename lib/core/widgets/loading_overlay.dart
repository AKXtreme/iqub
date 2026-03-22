import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// Full-screen loading overlay shown during async operations
class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const ModalBarrier(dismissible: false, color: Colors.black26),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.cardShadow,
                  blurRadius: 20,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                if (message != null) ...[
                  const SizedBox(height: 16),
                  Text(message!, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

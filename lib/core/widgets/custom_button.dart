import 'package:flutter/material.dart';

/// A full-width primary button with loading state support
class CustomButton extends StatelessWidget {
  const CustomButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.variant = ButtonVariant.primary,
    this.fullWidth = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final ButtonVariant variant;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final child = isLoading
        ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18),
                const SizedBox(width: 8),
              ],
              Text(label),
            ],
          );

    final button = switch (variant) {
      ButtonVariant.primary => ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        child: child,
      ),
      ButtonVariant.outlined => OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        child: child,
      ),
      ButtonVariant.text => TextButton(
        onPressed: isLoading ? null : onPressed,
        child: child,
      ),
    };

    if (fullWidth) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }
}

enum ButtonVariant { primary, outlined, text }

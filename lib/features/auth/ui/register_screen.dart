import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    await ref
        .read(authNotifierProvider.notifier)
        .register(
          name: _nameCtrl.text,
          email: _emailCtrl.text,
          password: _passCtrl.text,
          phone: _phoneCtrl.text.isEmpty ? null : _phoneCtrl.text,
        );

    if (!mounted) return;
    final state = ref.read(authNotifierProvider);
    state.whenOrNull(
      error: (e, _) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_friendlyError(e.toString())),
          backgroundColor: AppColors.error,
        ),
      ),
    );
  }

  String _friendlyError(String raw) {
    if (raw.contains('email-already-in-use')) {
      return 'An account already exists with this email.';
    }
    if (raw.contains('weak-password')) return 'Password is too weak.';
    if (raw.contains('invalid-email')) return 'Invalid email address.';
    return 'Registration failed. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authNotifierProvider).isLoading;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),

                // Back button
                IconButton(
                  onPressed: () => context.go(AppRoutes.login),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(height: 16),

                Text(
                  'Create Account',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  'Join Iqub to manage your savings groups',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 32),

                // Full Name
                CustomTextField(
                  label: 'Full Name',
                  controller: _nameCtrl,
                  hint: 'Abebe Kebede',
                  textCapitalization: TextCapitalization.words,
                  validator: (v) => Validators.required(v, label: 'Name'),
                  prefixIcon: const Icon(Icons.person_outline),
                ),
                const SizedBox(height: 16),

                // Email
                CustomTextField(
                  label: 'Email',
                  controller: _emailCtrl,
                  hint: 'you@example.com',
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.email,
                  prefixIcon: const Icon(Icons.email_outlined),
                ),
                const SizedBox(height: 16),

                // Phone (optional)
                CustomTextField(
                  label: 'Phone (optional)',
                  controller: _phoneCtrl,
                  hint: '+251 9XX XXX XXX',
                  keyboardType: TextInputType.phone,
                  prefixIcon: const Icon(Icons.phone_outlined),
                ),
                const SizedBox(height: 16),

                // Password
                CustomTextField(
                  label: 'Password',
                  controller: _passCtrl,
                  obscureText: _obscurePass,
                  validator: Validators.password,
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePass
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePass = !_obscurePass),
                  ),
                ),
                const SizedBox(height: 16),

                // Confirm Password
                CustomTextField(
                  label: 'Confirm Password',
                  controller: _confirmPassCtrl,
                  obscureText: _obscureConfirm,
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirm
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Confirm your password';
                    if (v != _passCtrl.text) return 'Passwords do not match';
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                CustomButton(
                  label: 'Create Account',
                  isLoading: isLoading,
                  onPressed: _submit,
                ),
                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    TextButton(
                      onPressed: () => context.go(AppRoutes.login),
                      child: const Text('Sign In'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

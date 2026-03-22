import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    await ref
        .read(authNotifierProvider.notifier)
        .signIn(email: _emailCtrl.text, password: _passCtrl.text);

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
    if (raw.contains('user-not-found') || raw.contains('wrong-password')) {
      return 'Incorrect email or password.';
    }
    if (raw.contains('invalid-email')) return 'Invalid email address.';
    if (raw.contains('too-many-requests')) {
      return 'Too many attempts. Please try again later.';
    }
    return 'Login failed. Please try again.';
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
                const SizedBox(height: 40),

                // Logo / Header
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.savings_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Welcome back',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  'Sign in to manage your Iqub groups',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 40),

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

                // Password
                CustomTextField(
                  label: 'Password',
                  controller: _passCtrl,
                  obscureText: _obscurePassword,
                  validator: Validators.password,
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                const SizedBox(height: 32),

                // Sign In button
                CustomButton(
                  label: 'Sign In',
                  isLoading: isLoading,
                  onPressed: _submit,
                ),
                const SizedBox(height: 16),

                // Register link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    TextButton(
                      onPressed: () => context.go(AppRoutes.register),
                      child: const Text('Register'),
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

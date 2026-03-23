import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/providers/auth_provider.dart';
import '../features/auth/ui/login_screen.dart';
import '../features/auth/ui/profile_screen.dart';
import '../features/auth/ui/register_screen.dart';
import '../features/iqub/ui/create_iqub_screen.dart';
import '../features/iqub/ui/history_screen.dart';
import '../features/iqub/ui/home_screen.dart';
import '../features/iqub/ui/iqub_detail_screen.dart';
import '../features/iqub/ui/members_screen.dart';
import '../features/iqub/ui/payments_screen.dart';

/// Named routes for type-safe navigation
class AppRoutes {
  AppRoutes._();
  static const login = '/login';
  static const register = '/register';
  static const home = '/home';
  static const createIqub = '/iqub/create';
  static const iqubDetail = '/iqub/:id';
  static const members = '/iqub/:id/members';
  static const payments = '/iqub/:id/payments/:round';
  static const history = '/iqub/:id/history';
  static const profile = '/profile';
}

final routerProvider = Provider<GoRouter>((ref) {
  // Listen to auth state to redirect accordingly
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: AppRoutes.home,
    redirect: (context, state) {
      final isLoggedIn = authState.valueOrNull != null;
      final isAuthRoute =
          state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.register;

      if (!isLoggedIn && !isAuthRoute) return AppRoutes.login;
      if (isLoggedIn && isAuthRoute) return AppRoutes.home;
      return null;
    },
    routes: [
      GoRoute(path: AppRoutes.login, builder: (ctx, _) => const LoginScreen()),
      GoRoute(
        path: AppRoutes.register,
        builder: (ctx, _) => const RegisterScreen(),
      ),
      GoRoute(path: AppRoutes.home, builder: (ctx, _) => const HomeScreen()),
      GoRoute(
        path: AppRoutes.createIqub,
        builder: (ctx, _) => const CreateIqubScreen(),
      ),
      GoRoute(
        path: AppRoutes.iqubDetail,
        builder: (_, state) =>
            IqubDetailScreen(iqubId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoutes.members,
        builder: (_, state) =>
            MembersScreen(iqubId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoutes.payments,
        builder: (_, state) => PaymentsScreen(
          iqubId: state.pathParameters['id']!,
          round: int.parse(state.pathParameters['round']!),
        ),
      ),
      GoRoute(
        path: AppRoutes.history,
        builder: (_, state) =>
            HistoryScreen(iqubId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (ctx, _) => const ProfileScreen(),
      ),
    ],
    errorBuilder: (context, state) =>
        Scaffold(body: Center(child: Text('Page not found: ${state.error}'))),
  );
});

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/iqub_repository.dart';
import '../domain/iqub_model.dart';
import '../domain/member_model.dart';
import '../domain/payment_model.dart';
import '../domain/payout_model.dart';

// ── Stream Providers (real-time Firestore listeners) ───────────────────────────

/// All Iqub groups the current user belongs to
final myIqubsProvider = StreamProvider<List<IqubModel>>((ref) {
  return ref.watch(iqubRepositoryProvider).watchMyIqubs();
});

/// Single Iqub by ID
final iqubProvider = StreamProvider.family<IqubModel?, String>((ref, iqubId) {
  return ref.watch(iqubRepositoryProvider).watchIqub(iqubId);
});

/// Members of a specific Iqub
final membersProvider = StreamProvider.family<List<MemberModel>, String>((
  ref,
  iqubId,
) {
  return ref.watch(iqubRepositoryProvider).watchMembers(iqubId);
});

/// Payments for a specific round  ({iqubId, round} tuple)
final paymentsForRoundProvider =
    StreamProvider.family<List<PaymentModel>, ({String iqubId, int round})>((
      ref,
      args,
    ) {
      return ref
          .watch(iqubRepositoryProvider)
          .watchPaymentsForRound(args.iqubId, args.round);
    });

/// All payments for an Iqub (history)
final allPaymentsProvider = StreamProvider.family<List<PaymentModel>, String>((
  ref,
  iqubId,
) {
  return ref.watch(iqubRepositoryProvider).watchAllPayments(iqubId);
});

/// All payouts for an Iqub (history)
final payoutsProvider = StreamProvider.family<List<PayoutModel>, String>((
  ref,
  iqubId,
) {
  return ref.watch(iqubRepositoryProvider).watchPayouts(iqubId);
});

// ── Action Notifiers ──────────────────────────────────────────────────────────

/// Notifier for create / update / delete Iqub actions
class IqubActionsNotifier extends StateNotifier<AsyncValue<void>> {
  IqubActionsNotifier(this._repo) : super(const AsyncValue.data(null));

  final IqubRepository _repo;

  Future<IqubModel?> createIqub({
    required String name,
    required double contributionAmount,
    required IqubFrequency frequency,
    required DateTime startDate,
    String? description,
  }) async {
    state = const AsyncValue.loading();
    IqubModel? result;
    state = await AsyncValue.guard(() async {
      result = await _repo.createIqub(
        name: name,
        contributionAmount: contributionAmount,
        frequency: frequency,
        startDate: startDate,
        description: description,
      );
    });
    if (state.hasError) {
      // ignore: avoid_print
      print('[IqubActions] createIqub error: ${state.error}\n${state.stackTrace}');
    }
    return result;
  }

  Future<bool> addMember({
    required String iqubId,
    required String name,
    required String phone,
    String? userId,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _repo.addMember(
        iqubId: iqubId,
        name: name,
        phone: phone,
        userId: userId,
      ),
    );
    return !state.hasError;
  }

  Future<bool> removeMember(String iqubId, MemberModel member) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repo.removeMember(iqubId, member));
    return !state.hasError;
  }

  Future<bool> markPaymentPaid(String iqubId, String paymentId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _repo.markPaymentPaid(iqubId, paymentId),
    );
    return !state.hasError;
  }

  Future<bool> markPaymentUnpaid(String iqubId, String paymentId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _repo.markPaymentUnpaid(iqubId, paymentId),
    );
    return !state.hasError;
  }

  Future<bool> generatePayments({
    required String iqubId,
    required int roundNumber,
    required List<MemberModel> members,
    required double amount,
    required DateTime dueDate,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _repo.generatePaymentsForRound(
        iqubId: iqubId,
        roundNumber: roundNumber,
        members: members,
        amount: amount,
        dueDate: dueDate,
      ),
    );
    return !state.hasError;
  }

  Future<bool> recordPayoutAndAdvance({
    required IqubModel iqub,
    required MemberModel recipient,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _repo.recordPayoutAndAdvanceRound(iqub: iqub, recipient: recipient),
    );
    return !state.hasError;
  }
}

final iqubActionsProvider =
    StateNotifierProvider<IqubActionsNotifier, AsyncValue<void>>((ref) {
      return IqubActionsNotifier(ref.watch(iqubRepositoryProvider));
    });

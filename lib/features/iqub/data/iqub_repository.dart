import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../domain/iqub_model.dart';
import '../domain/member_model.dart';
import '../domain/payment_model.dart';
import '../domain/payout_model.dart';

/// All Firestore CRUD operations for Iqub groups, members, payments, payouts
class IqubRepository {
  IqubRepository(this._db, this._auth);

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  final _uuid = const Uuid();

  String get _uid => _auth.currentUser!.uid;

  // ── Collection helpers ──────────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> get _iqubs =>
      _db.collection('iqubs');

  CollectionReference<Map<String, dynamic>> _members(String iqubId) =>
      _iqubs.doc(iqubId).collection('members');

  CollectionReference<Map<String, dynamic>> _payments(String iqubId) =>
      _iqubs.doc(iqubId).collection('payments');

  CollectionReference<Map<String, dynamic>> _payouts(String iqubId) =>
      _iqubs.doc(iqubId).collection('payouts');

  // ── Iqub CRUD ───────────────────────────────────────────────────────────────

  /// Stream of all Iqub groups where the current user is admin or member
  Stream<List<IqubModel>> watchMyIqubs() {
    return _iqubs
        .where('memberIds', arrayContains: _uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(IqubModel.fromDoc).toList());
  }

  /// Stream of a single Iqub group
  Stream<IqubModel?> watchIqub(String iqubId) {
    return _iqubs
        .doc(iqubId)
        .snapshots()
        .map((doc) => doc.exists ? IqubModel.fromDoc(doc) : null);
  }

  /// Create a new Iqub group. The creator is added as the first member.
  Future<IqubModel> createIqub({
    required String name,
    required double contributionAmount,
    required IqubFrequency frequency,
    required DateTime startDate,
    String? description,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();

    final iqub = IqubModel(
      id: id,
      name: name,
      adminId: _uid,
      contributionAmount: contributionAmount,
      frequency: frequency,
      totalRounds: 0, // grows as members are added
      currentRound: 1,
      memberIds: [_uid],
      payoutOrder: [],
      status: IqubStatus.active,
      startDate: startDate,
      createdAt: now,
      description: description,
    );

    await _iqubs.doc(id).set(iqub.toMap());
    return iqub;
  }

  /// Update basic Iqub info (admin only)
  Future<void> updateIqub(
    String iqubId, {
    String? name,
    double? contributionAmount,
    IqubFrequency? frequency,
    String? description,
    IqubStatus? status,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (contributionAmount != null) {
      updates['contributionAmount'] = contributionAmount;
    }
    if (frequency != null) updates['frequency'] = frequency.name;
    if (description != null) updates['description'] = description;
    if (status != null) updates['status'] = status.name;
    await _iqubs.doc(iqubId).update(updates);
  }

  /// Delete an Iqub and all its subcollections (admin only)
  Future<void> deleteIqub(String iqubId) async {
    // Firestore does not auto-delete subcollections; batch-delete all docs
    final batch = _db.batch();
    batch.delete(_iqubs.doc(iqubId));
    await batch.commit();
  }

  // ── Member operations ────────────────────────────────────────────────────────

  /// Stream of all members in an Iqub
  Stream<List<MemberModel>> watchMembers(String iqubId) {
    return _members(iqubId)
        .orderBy('payoutPosition')
        .snapshots()
        .map((snap) => snap.docs.map(MemberModel.fromDoc).toList());
  }

  /// Add a new member to the Iqub and update the rotation order
  Future<void> addMember({
    required String iqubId,
    required String name,
    required String phone,
    String? userId,
  }) async {
    // Get current member count to determine position
    final existingSnap = await _members(iqubId).get();
    final position = existingSnap.docs.length + 1;
    final memberId = _uuid.v4();

    final member = MemberModel(
      id: memberId,
      iqubId: iqubId,
      userId:
          userId ?? memberId, // fallback to memberId if not a registered user
      name: name,
      phone: phone,
      payoutPosition: position,
      hasReceivedPayout: false,
      joinedAt: DateTime.now(),
    );

    final batch = _db.batch();

    // Add member document
    batch.set(_members(iqubId).doc(memberId), member.toMap());

    // Update Iqub: add to memberIds, payoutOrder, and increment totalRounds
    batch.update(_iqubs.doc(iqubId), {
      'memberIds': FieldValue.arrayUnion([member.userId]),
      'payoutOrder': FieldValue.arrayUnion([memberId]),
      'totalRounds': FieldValue.increment(1),
    });

    await batch.commit();
  }

  /// Remove a member from the Iqub (admin only, before Iqub starts)
  Future<void> removeMember(String iqubId, MemberModel member) async {
    final batch = _db.batch();

    batch.delete(_members(iqubId).doc(member.id));

    batch.update(_iqubs.doc(iqubId), {
      'memberIds': FieldValue.arrayRemove([member.userId]),
      'payoutOrder': FieldValue.arrayRemove([member.id]),
      'totalRounds': FieldValue.increment(-1),
    });

    await batch.commit();
  }

  // ── Payment operations ───────────────────────────────────────────────────────

  /// Stream of all payments for a specific round
  Stream<List<PaymentModel>> watchPaymentsForRound(
    String iqubId,
    int roundNumber,
  ) {
    return _payments(iqubId)
        .where('roundNumber', isEqualTo: roundNumber)
        .snapshots()
        .map((snap) => snap.docs.map(PaymentModel.fromDoc).toList());
  }

  /// Stream of ALL payments for an Iqub (for history)
  Stream<List<PaymentModel>> watchAllPayments(String iqubId) {
    return _payments(iqubId)
        .orderBy('roundNumber', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(PaymentModel.fromDoc).toList());
  }

  /// Generate payment records for all members for a new round
  Future<void> generatePaymentsForRound({
    required String iqubId,
    required int roundNumber,
    required List<MemberModel> members,
    required double amount,
    required DateTime dueDate,
  }) async {
    final batch = _db.batch();

    for (final member in members) {
      final paymentId = _uuid.v4();
      final payment = PaymentModel(
        id: paymentId,
        iqubId: iqubId,
        memberId: member.id,
        memberName: member.name,
        roundNumber: roundNumber,
        amount: amount,
        isPaid: false,
        dueDate: dueDate,
      );
      batch.set(_payments(iqubId).doc(paymentId), payment.toMap());
    }

    await batch.commit();
  }

  /// Mark a payment as paid
  Future<void> markPaymentPaid(String iqubId, String paymentId) async {
    await _payments(iqubId).doc(paymentId).update({
      'isPaid': true,
      'paidAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Mark a payment as unpaid (undo)
  Future<void> markPaymentUnpaid(String iqubId, String paymentId) async {
    await _payments(
      iqubId,
    ).doc(paymentId).update({'isPaid': false, 'paidAt': null});
  }

  // ── Payout operations ─────────────────────────────────────────────────────────

  /// Stream of all payouts (history)
  Stream<List<PayoutModel>> watchPayouts(String iqubId) {
    return _payouts(iqubId)
        .orderBy('roundNumber', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(PayoutModel.fromDoc).toList());
  }

  /// Record a payout and advance the Iqub to the next round
  Future<void> recordPayoutAndAdvanceRound({
    required IqubModel iqub,
    required MemberModel recipient,
  }) async {
    final payoutId = _uuid.v4();
    final payout = PayoutModel(
      id: payoutId,
      iqubId: iqub.id,
      memberId: recipient.id,
      memberName: recipient.name,
      roundNumber: iqub.currentRound,
      amount: iqub.totalPerRound,
      payoutDate: DateTime.now(),
      createdAt: DateTime.now(),
    );

    final batch = _db.batch();

    // Record payout
    batch.set(_payouts(iqub.id).doc(payoutId), payout.toMap());

    // Mark member as having received payout
    batch.update(_members(iqub.id).doc(recipient.id), {
      'hasReceivedPayout': true,
    });

    // Advance round; mark completed if this was the last round
    final nextRound = iqub.currentRound + 1;
    final newStatus = nextRound > iqub.totalRounds
        ? IqubStatus.completed
        : IqubStatus.active;

    batch.update(_iqubs.doc(iqub.id), {
      'currentRound': nextRound,
      'status': newStatus.name,
    });

    await batch.commit();
  }
}

final iqubRepositoryProvider = Provider<IqubRepository>((ref) {
  return IqubRepository(FirebaseFirestore.instance, FirebaseAuth.instance);
});

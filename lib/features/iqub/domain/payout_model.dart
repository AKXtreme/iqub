import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Records that a payout was made to a member for a given round.
/// Stored at /iqubs/{iqubId}/payouts/{payoutId}
class PayoutModel extends Equatable {
  const PayoutModel({
    required this.id,
    required this.iqubId,
    required this.memberId,
    required this.memberName,
    required this.roundNumber,
    required this.amount,
    required this.payoutDate,
    required this.createdAt,
  });

  final String id;
  final String iqubId;
  final String memberId;
  final String memberName;
  final int roundNumber;

  /// Total payout = contributionAmount × totalMembers
  final double amount;

  final DateTime payoutDate;
  final DateTime createdAt;

  factory PayoutModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PayoutModel(
      id: doc.id,
      iqubId: data['iqubId'] as String? ?? '',
      memberId: data['memberId'] as String? ?? '',
      memberName: data['memberName'] as String? ?? '',
      roundNumber: data['roundNumber'] as int? ?? 0,
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      payoutDate:
          (data['payoutDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'iqubId': iqubId,
    'memberId': memberId,
    'memberName': memberName,
    'roundNumber': roundNumber,
    'amount': amount,
    'payoutDate': Timestamp.fromDate(payoutDate),
    'createdAt': Timestamp.fromDate(createdAt),
  };

  @override
  List<Object?> get props => [
    id,
    iqubId,
    memberId,
    roundNumber,
    amount,
    payoutDate,
  ];
}

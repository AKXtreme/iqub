import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Tracks whether a member has paid their contribution for a given round.
/// Stored at /iqubs/{iqubId}/payments/{paymentId}
class PaymentModel extends Equatable {
  const PaymentModel({
    required this.id,
    required this.iqubId,
    required this.memberId,
    required this.memberName,
    required this.roundNumber,
    required this.amount,
    required this.isPaid,
    required this.dueDate,
    this.paidAt,
    this.note,
  });

  final String id;
  final String iqubId;
  final String memberId;
  final String memberName;
  final int roundNumber;
  final double amount;
  final bool isPaid;
  final DateTime dueDate;
  final DateTime? paidAt;
  final String? note;

  factory PaymentModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PaymentModel(
      id: doc.id,
      iqubId: data['iqubId'] as String? ?? '',
      memberId: data['memberId'] as String? ?? '',
      memberName: data['memberName'] as String? ?? '',
      roundNumber: data['roundNumber'] as int? ?? 0,
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      isPaid: data['isPaid'] as bool? ?? false,
      dueDate: (data['dueDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      paidAt: (data['paidAt'] as Timestamp?)?.toDate(),
      note: data['note'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'iqubId': iqubId,
        'memberId': memberId,
        'memberName': memberName,
        'roundNumber': roundNumber,
        'amount': amount,
        'isPaid': isPaid,
        'dueDate': Timestamp.fromDate(dueDate),
        'paidAt': paidAt != null ? Timestamp.fromDate(paidAt!) : null,
        'note': note,
      };

  PaymentModel copyWith({
    bool? isPaid,
    DateTime? paidAt,
    String? note,
  }) =>
      PaymentModel(
        id: id,
        iqubId: iqubId,
        memberId: memberId,
        memberName: memberName,
        roundNumber: roundNumber,
        amount: amount,
        isPaid: isPaid ?? this.isPaid,
        dueDate: dueDate,
        paidAt: paidAt ?? this.paidAt,
        note: note ?? this.note,
      );

  @override
  List<Object?> get props =>
      [id, iqubId, memberId, roundNumber, amount, isPaid, dueDate, paidAt];
}

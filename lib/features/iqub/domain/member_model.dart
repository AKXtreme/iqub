import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// A member of an Iqub group, stored at /iqubs/{iqubId}/members/{memberId}
class MemberModel extends Equatable {
  const MemberModel({
    required this.id,
    required this.iqubId,
    required this.userId,
    required this.name,
    required this.phone,
    required this.payoutPosition,
    required this.hasReceivedPayout,
    required this.joinedAt,
  });

  final String id;
  final String iqubId;

  /// Firebase Auth UID (may differ from member id if added manually)
  final String userId;

  final String name;
  final String phone;

  /// 1-based position in the payout rotation
  final int payoutPosition;

  final bool hasReceivedPayout;
  final DateTime joinedAt;

  factory MemberModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MemberModel(
      id: doc.id,
      iqubId: data['iqubId'] as String? ?? '',
      userId: data['userId'] as String? ?? '',
      name: data['name'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      payoutPosition: data['payoutPosition'] as int? ?? 0,
      hasReceivedPayout: data['hasReceivedPayout'] as bool? ?? false,
      joinedAt: (data['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'iqubId': iqubId,
    'userId': userId,
    'name': name,
    'phone': phone,
    'payoutPosition': payoutPosition,
    'hasReceivedPayout': hasReceivedPayout,
    'joinedAt': Timestamp.fromDate(joinedAt),
  };

  MemberModel copyWith({
    String? name,
    String? phone,
    int? payoutPosition,
    bool? hasReceivedPayout,
  }) => MemberModel(
    id: id,
    iqubId: iqubId,
    userId: userId,
    name: name ?? this.name,
    phone: phone ?? this.phone,
    payoutPosition: payoutPosition ?? this.payoutPosition,
    hasReceivedPayout: hasReceivedPayout ?? this.hasReceivedPayout,
    joinedAt: joinedAt,
  );

  @override
  List<Object?> get props => [
    id,
    iqubId,
    userId,
    name,
    phone,
    payoutPosition,
    hasReceivedPayout,
    joinedAt,
  ];
}

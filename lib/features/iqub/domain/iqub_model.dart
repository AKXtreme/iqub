import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// The status of an Iqub group
enum IqubStatus { active, paused, completed }

/// The payout rotation frequency
enum IqubFrequency { weekly, biweekly, monthly }

extension IqubFrequencyExt on IqubFrequency {
  String get label {
    switch (this) {
      case IqubFrequency.weekly:
        return 'Weekly';
      case IqubFrequency.biweekly:
        return 'Bi-weekly';
      case IqubFrequency.monthly:
        return 'Monthly';
    }
  }
}

/// Represents a single Iqub savings group stored at /iqubs/{iqubId}
class IqubModel extends Equatable {
  const IqubModel({
    required this.id,
    required this.name,
    required this.adminId,
    required this.contributionAmount,
    required this.frequency,
    required this.totalRounds,
    required this.currentRound,
    required this.memberIds,
    required this.payoutOrder,
    required this.status,
    required this.startDate,
    required this.createdAt,
    this.description,
  });

  final String id;
  final String name;
  final String adminId;

  /// Amount each member contributes per round (in ETB or local currency)
  final double contributionAmount;

  final IqubFrequency frequency;

  /// Total number of rounds = total number of members
  final int totalRounds;

  /// 1-based current round number
  final int currentRound;

  /// List of user IDs who are members
  final List<String> memberIds;

  /// Ordered list of member IDs defining payout rotation
  final List<String> payoutOrder;

  final IqubStatus status;
  final DateTime startDate;
  final DateTime createdAt;
  final String? description;

  /// Total amount collected in the current round
  double get totalPerRound => contributionAmount * memberIds.length;

  /// Member ID who receives the payout in the current round (0-indexed)
  String? get currentPayoutMemberId {
    if (payoutOrder.isEmpty || currentRound < 1) return null;
    final index = currentRound - 1;
    if (index >= payoutOrder.length) return null;
    return payoutOrder[index];
  }

  /// True if all rounds are complete
  bool get isCompleted => currentRound > totalRounds;

  factory IqubModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return IqubModel(
      id: doc.id,
      name: data['name'] as String? ?? '',
      adminId: data['adminId'] as String? ?? '',
      contributionAmount: (data['contributionAmount'] as num?)?.toDouble() ?? 0,
      frequency: IqubFrequency.values.firstWhere(
        (f) => f.name == data['frequency'],
        orElse: () => IqubFrequency.monthly,
      ),
      totalRounds: data['totalRounds'] as int? ?? 0,
      currentRound: data['currentRound'] as int? ?? 1,
      memberIds: List<String>.from(data['memberIds'] as List? ?? []),
      payoutOrder: List<String>.from(data['payoutOrder'] as List? ?? []),
      status: IqubStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => IqubStatus.active,
      ),
      startDate:
          (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      description: data['description'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'adminId': adminId,
        'contributionAmount': contributionAmount,
        'frequency': frequency.name,
        'totalRounds': totalRounds,
        'currentRound': currentRound,
        'memberIds': memberIds,
        'payoutOrder': payoutOrder,
        'status': status.name,
        'startDate': Timestamp.fromDate(startDate),
        'createdAt': Timestamp.fromDate(createdAt),
        'description': description,
      };

  IqubModel copyWith({
    String? name,
    double? contributionAmount,
    IqubFrequency? frequency,
    int? totalRounds,
    int? currentRound,
    List<String>? memberIds,
    List<String>? payoutOrder,
    IqubStatus? status,
    DateTime? startDate,
    String? description,
  }) =>
      IqubModel(
        id: id,
        name: name ?? this.name,
        adminId: adminId,
        contributionAmount: contributionAmount ?? this.contributionAmount,
        frequency: frequency ?? this.frequency,
        totalRounds: totalRounds ?? this.totalRounds,
        currentRound: currentRound ?? this.currentRound,
        memberIds: memberIds ?? this.memberIds,
        payoutOrder: payoutOrder ?? this.payoutOrder,
        status: status ?? this.status,
        startDate: startDate ?? this.startDate,
        createdAt: createdAt,
        description: description ?? this.description,
      );

  @override
  List<Object?> get props => [
        id, name, adminId, contributionAmount, frequency,
        totalRounds, currentRound, memberIds, payoutOrder,
        status, startDate, createdAt, description,
      ];
}

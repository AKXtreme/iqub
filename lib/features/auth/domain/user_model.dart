import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Represents an authenticated user stored in Firestore under /users/{uid}
class UserModel extends Equatable {
  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.photoUrl,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? photoUrl;
  final DateTime createdAt;

  factory UserModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      phone: data['phone'] as String?,
      photoUrl: data['photoUrl'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'email': email,
    'phone': phone,
    'photoUrl': photoUrl,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  UserModel copyWith({
    String? name,
    String? email,
    String? phone,
    String? photoUrl,
  }) => UserModel(
    id: id,
    name: name ?? this.name,
    email: email ?? this.email,
    phone: phone ?? this.phone,
    photoUrl: photoUrl ?? this.photoUrl,
    createdAt: createdAt,
  );

  @override
  List<Object?> get props => [id, name, email, phone, photoUrl, createdAt];
}

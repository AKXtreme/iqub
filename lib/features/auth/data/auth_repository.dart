import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/user_model.dart';

/// Handles all Firebase Auth and user Firestore operations
class AuthRepository {
  AuthRepository(this._auth, this._firestore);

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  /// Stream of Firebase auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Currently signed-in Firebase user
  User? get currentUser => _auth.currentUser;

  /// Register with email and password, then save profile to Firestore
  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    await credential.user!.updateDisplayName(name.trim());

    final user = UserModel(
      id: credential.user!.uid,
      name: name.trim(),
      email: email.trim(),
      phone: phone?.trim(),
      createdAt: DateTime.now(),
    );

    await _users.doc(user.id).set(user.toMap());
    return user;
  }

  /// Sign in with email and password
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Sign out the current user
  Future<void> signOut() => _auth.signOut();

  /// Fetch the current user's Firestore profile
  Future<UserModel?> fetchCurrentUser() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    final doc = await _users.doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromDoc(doc);
  }

  /// Stream of the current user's Firestore profile
  Stream<UserModel?> watchCurrentUser() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream.empty();
    return _users.doc(uid).snapshots().map(
          (doc) => doc.exists ? UserModel.fromDoc(doc) : null,
        );
  }
}

/// Provider for AuthRepository
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(FirebaseAuth.instance, FirebaseFirestore.instance);
});

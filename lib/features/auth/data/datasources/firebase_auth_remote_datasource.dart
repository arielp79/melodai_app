import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/entities/app_user.dart';
import '../models/app_user_model.dart';
import 'auth_remote_datasource.dart';

class FirebaseAuthRemoteDataSource implements AuthRemoteDataSource {
  FirebaseAuthRemoteDataSource(this._firebaseAuth);

  final FirebaseAuth _firebaseAuth;

  @override
  AppUser? get currentUser {
    final user = _firebaseAuth.currentUser;
    if (user == null) return null;
    return AppUserModel.fromFirebaseUser(user);
  }

  @override
  Stream<AppUser?> get authStateChanges {
    return _firebaseAuth.authStateChanges().map((user) {
      if (user == null) return null;
      return AppUserModel.fromFirebaseUser(user);
    });
  }

  @override
  Future<AppUser> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    final credential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    return _requireUser(credential.user);
  }

  @override
  Future<AppUser> signUpWithEmailPassword({
    required String email,
    required String password,
  }) async {
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    return _requireUser(credential.user);
  }

  @override
  Future<void> signOut() => _firebaseAuth.signOut();

  AppUser _requireUser(User? user) {
    if (user == null) {
      throw StateError('No se pudo obtener el usuario autenticado.');
    }
    return AppUserModel.fromFirebaseUser(user);
  }
}

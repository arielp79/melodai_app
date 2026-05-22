import '../../domain/entities/app_user.dart';

abstract class AuthRemoteDataSource {
  AppUser? get currentUser;

  Stream<AppUser?> get authStateChanges;

  Future<AppUser> signInWithEmailPassword({
    required String email,
    required String password,
  });

  Future<AppUser> signUpWithEmailPassword({
    required String email,
    required String password,
  });

  Future<void> signOut();
}

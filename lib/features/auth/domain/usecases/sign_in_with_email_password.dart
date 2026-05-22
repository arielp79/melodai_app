import '../entities/app_user.dart';
import '../repositories/auth_repository.dart';

class SignInWithEmailPassword {
  const SignInWithEmailPassword(this._repository);

  final AuthRepository _repository;

  Future<AppUser> call({
    required String email,
    required String password,
  }) {
    return _repository.signInWithEmailPassword(
      email: email,
      password: password,
    );
  }
}

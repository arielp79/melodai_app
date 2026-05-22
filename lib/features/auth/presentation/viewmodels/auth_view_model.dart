import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/errors/auth_exception.dart';
import '../../data/mappers/firebase_auth_exception_mapper.dart';
import '../../domain/usecases/sign_in_with_email_password.dart';
import '../../domain/usecases/sign_out.dart';
import '../../domain/usecases/sign_up_with_email_password.dart';

class AuthViewModel extends ChangeNotifier {
  AuthViewModel({
    required SignInWithEmailPassword signIn,
    required SignUpWithEmailPassword signUp,
    required SignOut signOut,
  })  : _signIn = signIn,
        _signUp = signUp,
        _signOut = signOut;

  final SignInWithEmailPassword _signIn;
  final SignUpWithEmailPassword _signUp;
  final SignOut _signOut;

  bool isLoading = false;
  String? errorMessage;

  Future<void> submit({
    required String email,
    required String password,
    required bool isSignUp,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      if (isSignUp) {
        await _signUp(email: email, password: password);
      } else {
        await _signIn(email: email, password: password);
      }
    } on AuthException catch (e) {
      errorMessage = e.message;
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException: code=${e.code} message=${e.message}');
      errorMessage = mapFirebaseAuthException(e).message;
    } catch (e, stack) {
      debugPrint('Auth submit error: $e');
      debugPrint('$stack');
      errorMessage = kDebugMode
          ? 'Error inesperado: $e'
          : 'Ocurrió un error inesperado. Inténtalo de nuevo.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _signOut();
    } on AuthException catch (e) {
      errorMessage = e.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    if (errorMessage == null) return;
    errorMessage = null;
    notifyListeners();
  }
}

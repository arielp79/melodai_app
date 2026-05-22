import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:melodai_app/features/auth/domain/entities/app_user.dart';
import 'package:melodai_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:melodai_app/features/auth/domain/usecases/sign_in_with_email_password.dart';
import 'package:melodai_app/features/auth/domain/usecases/sign_out.dart';
import 'package:melodai_app/features/auth/domain/usecases/sign_up_with_email_password.dart';
import 'package:melodai_app/features/auth/presentation/pages/login_page.dart';
import 'package:melodai_app/features/auth/presentation/viewmodels/auth_view_model.dart';

void main() {
  testWidgets('LoginPage muestra el formulario de acceso', (tester) async {
    final viewModel = AuthViewModel(
      signIn: SignInWithEmailPassword(_FakeAuthRepository()),
      signUp: SignUpWithEmailPassword(_FakeAuthRepository()),
      signOut: SignOut(_FakeAuthRepository()),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: LoginPage(viewModel: viewModel),
      ),
    );

    expect(find.text('MelodAI'), findsOneWidget);
    expect(find.text('Iniciar sesión'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
  });
}

class _FakeAuthRepository implements AuthRepository {
  @override
  AppUser? get currentUser => null;

  @override
  Stream<AppUser?> get authStateChanges => const Stream.empty();

  @override
  Future<AppUser> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    return AppUser(id: 'test', email: email);
  }

  @override
  Future<AppUser> signUpWithEmailPassword({
    required String email,
    required String password,
  }) async {
    return AppUser(id: 'test', email: email);
  }

  @override
  Future<void> signOut() async {}
}

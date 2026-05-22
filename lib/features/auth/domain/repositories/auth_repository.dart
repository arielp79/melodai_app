import '../entities/app_user.dart';



abstract class AuthRepository {

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


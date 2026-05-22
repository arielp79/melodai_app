import 'package:firebase_auth/firebase_auth.dart';



import '../../../../core/errors/auth_exception.dart';

import '../../domain/entities/app_user.dart';

import '../../domain/repositories/auth_repository.dart';

import '../datasources/auth_remote_datasource.dart';

import '../mappers/firebase_auth_exception_mapper.dart';



class AuthRepositoryImpl implements AuthRepository {

  AuthRepositoryImpl(this._remote);



  final AuthRemoteDataSource _remote;



  @override

  AppUser? get currentUser => _remote.currentUser;



  @override

  Stream<AppUser?> get authStateChanges => _remote.authStateChanges;



  @override

  Future<AppUser> signInWithEmailPassword({

    required String email,

    required String password,

  }) async {

    try {

      return await _remote.signInWithEmailPassword(

        email: email,

        password: password,

      );

    } on AuthException {

      rethrow;

    } on FirebaseAuthException catch (e) {

      throw mapFirebaseAuthException(e);

    }

  }



  @override

  Future<AppUser> signUpWithEmailPassword({

    required String email,

    required String password,

  }) async {

    try {

      return await _remote.signUpWithEmailPassword(

        email: email,

        password: password,

      );

    } on AuthException {

      rethrow;

    } on FirebaseAuthException catch (e) {

      throw mapFirebaseAuthException(e);

    }

  }



  @override

  Future<void> signOut() => _remote.signOut();

}


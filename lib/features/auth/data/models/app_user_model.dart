import 'package:firebase_auth/firebase_auth.dart' as firebase;

import '../../domain/entities/app_user.dart';

class AppUserModel extends AppUser {
  const AppUserModel({
    required super.id,
    super.email,
    super.displayName,
  });

  factory AppUserModel.fromFirebaseUser(firebase.User user) {
    return AppUserModel(
      id: user.uid,
      email: user.email,
      displayName: user.displayName,
    );
  }
}

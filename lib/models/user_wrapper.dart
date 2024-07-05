import 'package:ceta/models/db_user.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserWrapper {
  final User firebaseUser;
  final DbUser dbUser;

  UserWrapper({
    required this.firebaseUser,
    required this.dbUser,
  });
}

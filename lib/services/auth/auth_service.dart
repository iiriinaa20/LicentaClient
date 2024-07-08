import 'package:ceta/utils/env.dart';
import 'package:ceta/models/db_user.dart';
import 'package:ceta/models/user_wrapper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:ceta/services/api/api_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final ApiService _apiService = ApiService(baseUrl: SERVER_URL);

  Future<UserWrapper?> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      return null; // The user canceled the sign-in
    }

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final UserCredential userCredential = await _auth.signInWithCredential(credential);

    final User? user = userCredential.user;
    final String? jwtToken = await user?.getIdToken();

    if (user == null) {
      await _signOut();
      throw Exception('Internal error had occured.');
    }

    if (!_isAllowedDomain(user.email!)) {
      await _signOut();
      throw Exception('You are not allowed to sign in with this email domain.');
    }

    try {
      final DbUser dbUser = await _loginToServer(jwtToken);
      return UserWrapper(firebaseUser: user, dbUser: dbUser);
    } catch (e) {
      await _signOut();
      throw Exception('Server login failed');
    }
  }

  Future<void> _signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
  }

  bool _isAllowedDomain(String email) {
    const allowedDomain = '@ulbsibiu.ro';
    return email.endsWith(allowedDomain) || email == "imihaela2001@gmail.com";
  }

  Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
  }

  Future<DbUser> _loginToServer(String? idToken) async {
    if (idToken == null) throw Exception('Invalid idToken');

    final response = await _apiService.post('/login', {'idToken': idToken});
    Map<String, dynamic> dbUserData = response['user'];
    return DbUser.fromJson(dbUserData);
  }
}

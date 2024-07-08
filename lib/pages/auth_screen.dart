import 'package:flutter/material.dart';
import 'package:ceta/models/user_wrapper.dart';
import 'package:ceta/components/custom_app_bar.dart';
import 'package:ceta/pages/student/student_page.dart';
import 'package:ceta/pages/teacher/teacher_page.dart';
import 'package:ceta/services/auth/auth_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.authService});
  final AuthService authService;
  @override
  AuthScreenState createState() => AuthScreenState();
}

class AuthScreenState extends State<AuthScreen> {
  String _errorMessage = '';

  void handleOnPress() async {
    // Clear any previous error message
    if (mounted) {
      setState(() => _errorMessage = "");
    }

    try {
      UserWrapper? user = await widget.authService.signInWithGoogle();

      if (mounted && user != null) {
        Widget nextPage = user.dbUser.type
            ? TeacherPage(user: user, authService: widget.authService)
            : StudentPage(user: user, authService: widget.authService);

        await Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => nextPage),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.toString().split(":")[1]);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
          title: 'Sign In', authService: widget.authService, user: null),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Container(
              margin: const EdgeInsets.only(bottom: 40, top: 200),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(40.0),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(40.0),
                child: Image.asset('lib/assets/linkface.gif', width: 200),
              ),
            ),
            ElevatedButton(
              onPressed: handleOnPress,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: const Text(
                'Sign in with Google',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                ),
              ),
            ),
            if (_errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

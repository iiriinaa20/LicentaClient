import 'package:flutter/material.dart';
import 'package:ceta/pages/student_page.dart';
import 'package:ceta/pages/teacher_page.dart';
import 'package:ceta/models/user_wrapper.dart';
import 'package:ceta/services/auth/auth_service.dart';
// import 'package:ceta/pages/home_screen.dart';
// import 'package:ceta/utils/functions.dart';
// import 'dart:js_interop';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.authService});
  final AuthService authService;
  @override
  AuthScreenState createState() => AuthScreenState();
}

class AuthScreenState extends State<AuthScreen> {
  String _errorMessage = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign In'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: () async {
                try {
                  UserWrapper? user =
                      await widget.authService.signInWithGoogle();
                  if (user != null) {
                    Widget nextPage;
                    bool userType = user.dbUser.type;

                    if (userType) {
                      nextPage = TeacherPage(
                        user: user,
                        authService: widget.authService,
                      );
                    } else {
                      nextPage = StudentPage(
                        user: user,
                        authService: widget.authService,
                      );
                    }

                    setState(() {_errorMessage = "";});
                    await Navigator.pushReplacement(context,
                        MaterialPageRoute(builder: (context) => nextPage));

                    // await Navigator.pushReplacement(
                    //     context,
                    //     MaterialPageRoute(
                    //         builder: (context) => HomeScreen(user: user)));
                    // await navigateToScreen(context, HomeScreen(user: user));
                  }
                } catch (e) {
                  setState(() {
                    _errorMessage = e.toString().split(":")[1];
                  });
                }
              },
              child: const Text('Sign in with Google'),
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

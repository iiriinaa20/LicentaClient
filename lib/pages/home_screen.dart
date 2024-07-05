import 'package:flutter/material.dart';
import 'package:ceta/models/user_wrapper.dart';
// import 'teacher_page.dart';
// import 'student_page.dart';
// import 'package:ceta/utils/functions.dart';

// import 'package:firebase_auth/firebase_auth.dart';

class HomeScreen extends StatefulWidget {
  final UserWrapper user;

  const HomeScreen({super.key, required this.user});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToUserPage();
  }

  // @override
  // void didChangeDependencies() {
  //   super.didChangeDependencies();
  //   if (_isLoading) {
  //     _navigateToUserPage();
  //     setState(() {
  //       _isLoading = false;
  //     });
  //   }
  // }

  void _navigateToUserPage() async {
    // bool userType = widget.user.dbUser.type;
    // Widget nextPage;

    // if (userType) {
    //   nextPage = TeacherPage(
    //     displayName: widget.user.firebaseUser.displayName ?? "",
    //   );
    // } else {
    //   nextPage = StudentPage(
    //     displayName: widget.user.firebaseUser.displayName ?? "",
    //     userId: widget.user.dbUser?.id ?? "",
    //     user: widget.user,
    //   );
    // }

    // await Navigator.pushReplacement(context,MaterialPageRoute(builder: (context) =>  nextPage));
    // await Navigator.of(context)
    //     .push(MaterialPageRoute(builder: (context) => nextPage));
    // // await navigateToScreen(context, nextPage);
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

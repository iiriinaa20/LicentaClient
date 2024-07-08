import 'package:flutter/material.dart';
import 'package:ceta/models/user_wrapper.dart';
import 'package:ceta/pages/teacher/teacher_page.dart';
import 'package:ceta/pages/student/student_page.dart';
import 'package:ceta/services/auth/auth_service.dart';
import 'package:ceta/pages/teacher/teacher_calendar.dart';
import 'package:ceta/pages/student/student_future_courses.dart';

class CustomBottomNavigationBar extends StatefulWidget {
  final AuthService authService;
  final UserWrapper user;
  final int currentIndex;
  int lastIndex;
  CustomBottomNavigationBar({
    super.key,
    required this.authService,
    required this.user,
    required this.currentIndex,
  }) : lastIndex = currentIndex;

  @override
  State<CustomBottomNavigationBar> createState() =>
      _CustomBottomNavigationBarState();
}

class _CustomBottomNavigationBarState extends State<CustomBottomNavigationBar> {
  void _onNavBarTapped(int index, BuildContext context) {
    bool isStudent = !widget.user.dbUser.type;
    PageRouteBuilder? route;

    var routes = {
      0: {
        0: (BuildContext context) =>
            TeacherPage(user: widget.user, authService: widget.authService),
        2: (BuildContext context) => TeacherCalendarPage(
            user: widget.user, authService: widget.authService),
      },
      1: {
        0: (BuildContext context) =>
            StudentPage(user: widget.user, authService: widget.authService),
        1: (BuildContext context) => StudentFutureCoursesPage(
            user: widget.user, authService: widget.authService),
      },
    };

    if (index == widget.lastIndex) {
      return;
    }

    var routeBuilder = routes[isStudent ? 1 : 0]?[index];

    if (routeBuilder != null) {
      Offset begin;
      Offset end;

      if (index > widget.lastIndex) {
        begin = const Offset(1.0, 0.0);
        end = Offset.zero;
      } else {
        begin = const Offset(-1.0, 0.0);
        end = Offset.zero;
      }

      route = PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            routeBuilder(context),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          var tween = Tween(begin: begin, end: end)
              .chain(CurveTween(curve: Curves.easeInOut));

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      );

      widget.lastIndex = index;
    }

    if (route != null) {
      Navigator.pushReplacement(context, route);
    } else {
      print('No route found for the given index');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isStudent = !widget.user.dbUser.type;
    final items = [
      const BottomNavigationBarItem(
        icon: Icon(Icons.home),
        label: 'Home',
      ),
      if (isStudent) ...[
        const BottomNavigationBarItem(
          icon: Icon(Icons.schedule),
          label: 'Future Courses',
        ),
      ] else ...[
        const BottomNavigationBarItem(
          icon: Icon(Icons.video_call),
          label: 'Start attending',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.class_),
          label: 'Courses',
        ),
      ],
      // const BottomNavigationBarItem(
      //   icon: Icon(Icons.person),
      //   label: 'Profile',
      // ),
    ];

    return BottomNavigationBar(
      currentIndex: widget.currentIndex,
      onTap: (index) => _onNavBarTapped(index, context),
      items: items,
    );
  }
}

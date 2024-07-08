import 'package:intl/intl.dart';
// import 'dart:convert';

class Attendance {
  final DateTime dateTime;
  Attendance(this.dateTime);
}

class User {
  final String email;
  final String id;
  final String name;
  final String type;
  User({required this.email, required this.id, required this.name, required this.type});
}

class AttendanceData {
  final List<Attendance> attendance;
  final String courseId;
  final String id;
  final User user;
  final String userId;
  AttendanceData({required this.attendance, required this.courseId, required this.id, required this.user, required this.userId});

  factory AttendanceData.fromJson(Map<String, dynamic> json) {
    List<Attendance> attendance = (json['attendance'] as List).map((date) {
      return Attendance(parseDate(date));
    }).toList();

    User user = User(
      email: json['user']['email'],
      id: json['user']['id'],
      name: json['user']['name'],
      type: json['user']['type'],
    );

    return AttendanceData(
      attendance: attendance,
      courseId: json['course_id'],
      id: json['id'],
      user: user,
      userId: json['user_id'],
    );
  }
}

DateTime parseDate(String date) {
  List<String> formats = [
    "yyyy-MM-ddTHH:mm",          // ISO format without seconds
    "EEE, dd MMM yyyy HH:mm:ss 'GMT'", // Format with day name and GMT
    "yyyy-MM-dd HH:mm:ss",       // ISO format with seconds
    "yyyy-MM-dd",                // ISO format date only
  ];

  for (String format in formats) {
    try {
      return DateFormat(format).parse(date, true).toUtc();
    } catch (e) {
      // Ignore and try next format
    }
  }

  throw FormatException("Invalid date format", date);
}
import 'package:ceta/utils/env.dart';
import 'package:flutter/material.dart';
import 'package:ceta/models/user_wrapper.dart';
import 'package:ceta/services/api/api_service.dart';
import 'package:ceta/services/auth/auth_service.dart';

// redo
class CourseAttendancePage extends StatefulWidget {
  final UserWrapper user;
  final AuthService authService;
  final String courseId;

  const CourseAttendancePage({
    super.key,
    required this.user,
    required this.authService,
    required this.courseId,
  });

  @override
  _CourseAttendancePageState createState() => _CourseAttendancePageState();
}

class _CourseAttendancePageState extends State<CourseAttendancePage> {
  late ApiService apiService;
  late Future<List<Map<String, dynamic>>> attendanceData;

  @override
  void initState() {
    super.initState();
    apiService = ApiService(baseUrl: SERVER_URL);
    attendanceData = fetchAttendanceData();
  }

  Future<List<Map<String, dynamic>>> fetchAttendanceData() async {
    try {
      var attendanceData = await apiService.getAttendancesByCourseId(widget.courseId);
      List<Map<String, dynamic>> studentList = [];

      for (var attendance in attendanceData) {
        var userData = await apiService.getUserDataById(attendance['user_id']);
        studentList.add({
          'name': userData['name'],
          'attendance_count': attendance['attendance_count'],
        });
      }

      return studentList;
    } catch (e) {
      throw Exception('Failed to load attendance data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Attendance for Course ${widget.courseId}'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: attendanceData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No data found'));
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                var attendance = snapshot.data![index];
                var userName = attendance['name'] ?? 'Unknown User';
                var attendanceCount = attendance['attendance_count'] ?? 0;

                return ListTile(
                  title: Text(userName),
                  subtitle: Text('Attendance Count: $attendanceCount'),
                );
              },
            );
          }
        },
      ),
    );
  }
}

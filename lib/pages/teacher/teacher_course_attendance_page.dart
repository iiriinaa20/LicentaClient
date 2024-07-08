import 'package:intl/intl.dart';
import 'package:ceta/utils/env.dart';
import 'package:flutter/material.dart';
import 'package:ceta/models/user_wrapper.dart';
import 'package:ceta/models/attendace_groups.dart';
import 'package:ceta/services/api/api_service.dart';
import 'package:ceta/services/auth/auth_service.dart';

class TeacherCourseAttendancePage extends StatefulWidget {
  final UserWrapper user;
  final AuthService authService;
  final String courseId;
  final String planificationDate;

  const TeacherCourseAttendancePage({
    super.key,
    required this.user,
    required this.authService,
    required this.courseId,
    required this.planificationDate,
  });

  @override
  TeacherCourseAttendancePageState createState() =>
      TeacherCourseAttendancePageState();
}

class TeacherCourseAttendancePageState
    extends State<TeacherCourseAttendancePage> {
  late ApiService apiService;
  late Future<Map<String, List<AttendanceData>>> attendances;
  late Future<String> courseName;

  @override
  void initState() {
    super.initState();
    apiService =
        ApiService(baseUrl: SERVER_URL); // Ensure apiService is initialized
    attendances = fetchAttendanceData();
    courseName = fetchCourseName(); // Fetch course name
  }

  Future<Map<String, List<AttendanceData>>> fetchAttendanceData() async {
    try {
      final fetchedAttendances =
          await apiService.getAttendancesByCourseIdForDate(widget.courseId,
              widget.planificationDate != "" ? widget.planificationDate : null);

      List<AttendanceData> attendanceDataList = fetchedAttendances
          .map((json) => AttendanceData.fromJson(json))
          .toList();

      Map<String, List<AttendanceData>> groupedByUserId = {};
      for (var data in attendanceDataList) {
        if (groupedByUserId.containsKey(data.userId)) {
          groupedByUserId[data.userId]!.add(data);
        } else {
          groupedByUserId[data.userId] = [data];
        }
      }
      print(groupedByUserId);

      return groupedByUserId;
    } catch (e) {
      // Handle errors if necessary
      throw ('Failed to load attendances: $e');
    }
  }

  Future<String> fetchCourseName() async {
    try {
      var courseData = await apiService.getCourseById(widget.courseId);
      return courseData['name'];
    } catch (e) {
      throw ('Failed to load course name: $e');
    }
  }

  String formatDate(String dateTimeStr) {
    DateTime dateTime = DateTime.parse(dateTimeStr);
    return DateFormat('dd-MM-yyyy').format(dateTime);
  }

  String formatTime(String dateTimeStr) {
    DateTime dateTime = DateTime.parse(dateTimeStr);
    return DateFormat('HH:mm').format(dateTime);
  }

  DateTime parseDateTime(String dateTimeStr) {
    if (dateTimeStr.startsWith('202')) {
      return DateTime.parse(dateTimeStr);
    } else {
      var a = DateFormat("EEE, dd MMM yyyy HH:mm:ss 'GMT'");
      return a.parse(dateTimeStr);
    }
  }

  AnimatedContainer showAttendances(BuildContext context, String userId,
      Map<String, List<AttendanceData>> attendancesForCourse) {
    List<AttendanceData> attendanceDataList =
        attendancesForCourse[userId] ?? [];

    if (attendanceDataList.isEmpty) {
      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'No attendance data available.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Use the first AttendanceData object to get the student name (assuming all have the same student)
    AttendanceData attendanceData = attendanceDataList.first;
    String studentName = attendanceData.user.name;

    // Flatten the list of attendance dates
    List<Attendance> attendance =
        attendanceDataList.expand((data) => data.attendance).toList();
    String attendanceCount = attendance.length.toString();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display student name
            Text(
              studentName,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),

            // Display attendance count
            Text(
              'Attendance count: $attendanceCount',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 10),

            // Display list of attendance dates
            Expanded(
              child: ListView.builder(
                itemCount: attendance.length,
                itemBuilder: (context, index) {
                  Attendance att = attendance[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      DateFormat('yyyy-MM-dd HH:mm').format(att.dateTime),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[800],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder<String>(
          future: courseName,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Text('Loading...');
            } else if (snapshot.hasError) {
              return const Text('Error');
            } else {
              return Text(snapshot.data ?? 'Course');
            }
          },
        ),
      ),
      body: FutureBuilder<Map<String, List<AttendanceData>>>(
        future: attendances,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No attendance data found'));
          } else {
            var attendancesForCourse = snapshot.data!;

            return ListView.builder(
                itemCount: attendancesForCourse.length,
                itemBuilder: (context, index) {
                  String userId = attendancesForCourse.keys.elementAt(index);
                  return showAttendances(context, userId, attendancesForCourse);
                });
          }
        },
      ),
    );
  }
}

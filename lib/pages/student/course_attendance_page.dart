import 'package:intl/intl.dart';
import 'package:ceta/utils/env.dart';
import 'package:flutter/material.dart';
import 'package:ceta/models/user_wrapper.dart';
import 'package:ceta/services/api/api_service.dart';
import 'package:ceta/services/auth/auth_service.dart';

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
  CourseAttendancePageState createState() => CourseAttendancePageState();
}

class CourseAttendancePageState extends State<CourseAttendancePage> {
  late ApiService apiService;
  late Future<List<Map<String, dynamic>>> attendances;
  late Future<String> courseName;

  @override
  void initState() {
    super.initState();
    apiService =
        ApiService(baseUrl: SERVER_URL); // Ensure apiService is initialized
    attendances = fetchAttendanceData();
    courseName = fetchCourseName(); // Fetch course name
  }

  Future<List<Map<String, dynamic>>> fetchAttendanceData() async {
    try {
      // var userData =
      //     await apiService.getUserDataByEmail(widget.user.dbUser.email);
      // var userId = userData['id'];
      final fetchedAttendances =
          await apiService.getAttendancesByUserId(widget.user.dbUser.id);
      // await apiService.getAttendancesByUserId(userId);

      List<Map<String, dynamic>> attendancesForCourse = [];

      for (var attendance in fetchedAttendances) {
        if (attendance['course_id'] == widget.courseId) {
          attendancesForCourse.add(attendance);
        }
      }

      return attendancesForCourse;
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

  AnimatedContainer showAttendaces(BuildContext context, int index,
      List<Map<String, dynamic>> attendancesForCourse) {
    var attendance = attendancesForCourse[index];

    String formatDateTime(String dateTimeStr) {
      var dateTime = parseDateTime(dateTimeStr);
      return DateFormat('yyyy-MM-dd HH:mm:ss').format(dateTime);
    }

    var formattedDateTime = formatDateTime(attendance['attendance'][0]);
    var date = DateTime.parse(formattedDateTime);
    var formattedDate = formatDate(date.toString());
    var formattedTime = formatTime(date.toString());

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
            Row(
              children: [
                const Icon(Icons.calendar_today, color: Colors.blue),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    'Date: $formattedDate',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.access_time, color: Colors.green),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    'Time: $formattedTime',
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.green,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
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
      body: FutureBuilder<List<Map<String, dynamic>>>(
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
                  return showAttendaces(context, index, attendancesForCourse);
                });
          }
        },
      ),
    );
  }
}

import 'package:ceta/utils/env.dart';
import 'package:flutter/material.dart';
import 'package:ceta/models/user_wrapper.dart';
import 'package:ceta/services/api/api_service.dart';
import 'package:ceta/components/custom_app_bar.dart';
import 'package:ceta/services/auth/auth_service.dart';
import 'package:ceta/components/custom_navigation_bar.dart';
import 'package:ceta/pages/student/course_attendance_page.dart';

class StudentPage extends StatefulWidget {
  final AuthService authService;
  final UserWrapper user;

  const StudentPage({super.key, required this.user, required this.authService});

  @override
  StudentPageState createState() => StudentPageState();
}

class StudentPageState extends State<StudentPage> {
  late ApiService apiService;
  late Future<List<Map<String, dynamic>>> attendances;
  String displayName = '';
  TextEditingController searchController = TextEditingController();
  List<Map<String, dynamic>> filteredAttendances = [];
  List<String> courseNames = [];
  String? selectedCourseName;

  @override
  void initState() {
    super.initState();
    apiService = ApiService(baseUrl: SERVER_URL);
    displayName = widget.user.firebaseUser.displayName ?? '';
    attendances = fetchAttendances();
  }

  Future<List<Map<String, dynamic>>> fetchAttendances() async {
    try {
      // var userData =
      //     await apiService.getUserDataByEmail(widget.user.dbUser.email);
      // var userId = userData['id'];

      final fetchedAttendances =
          // await apiService.getAttendancesByUserId(userId);
          await apiService.getAttendancesByUserId(widget.user.dbUser.id);
      Map<String, int> attendanceCount = {};

      for (var attendance in fetchedAttendances) {
        var courseId = attendance['course_id'];
        attendanceCount.update(courseId, (value) => value + 1,
            ifAbsent: () => 1);
      }

      List<Map<String, dynamic>> attendanceList = [];

      for (var courseId in attendanceCount.keys) {
        try {
          var courseData = await apiService.getCourseById(courseId);
          var planificationData =
              await apiService.getPlanificationByCourseId(courseId);
          var teacherData =
              await apiService.getUserDataById(planificationData[0]['user_id']);
          attendanceList.add({
            'teacher_name': teacherData['name'],
            'course_name': courseData['name'],
            'attendance_count': attendanceCount[courseId],
            'course_id': courseId,
          });
          courseNames.add(courseData['name']);
        } catch (e) {
          print('Error fetching course details: $e');
        }
      }

      filteredAttendances = attendanceList;
      courseNames = courseNames.toSet().toList(); // Remove duplicates
      return attendanceList;
    } catch (e) {
      throw ('Failed to load attendances');
    }
  }

  void filterSearchResults(String query) {
    if (query.isNotEmpty) {
      List<Map<String, dynamic>> dummyListData = [];
      attendances.then((attendanceList) {
        for (var item in attendanceList) {
          if (item['course_name'].toLowerCase().contains(query.toLowerCase())) {
            dummyListData.add(item);
          }
        }
        setState(() {
          filteredAttendances = dummyListData;
        });
      });
    } else {
      setState(() {
        attendances.then((attendanceList) {
          filteredAttendances = attendanceList;
        });
      });
    }
  }

  Iterable<String> generateOptionBuilderForAutocomplete(
      TextEditingValue textEditingValue) {
    final lowercaseText = textEditingValue.text.toLowerCase();

    return courseNames.where((String courseName) {
      return courseName.contains(lowercaseText);
    }).take(5);
  }

  void onAutocompleteSelect(String selection) {
    searchController.text = selection;
    filterSearchResults(selection);
  }

  ListView getListView() {
    return ListView.builder(
      itemCount: filteredAttendances.length,
      itemBuilder: (context, index) {
        var attendance = filteredAttendances[index];
        var teacherName = attendance['teacher_name'] ?? 'Unknown Teacher';
        var courseName = attendance['course_name'] ?? 'Unknown Course';
        var attendanceCount = attendance['attendance_count'] ?? 'No attendance';
        var courseId = attendance['course_id'];

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Card(
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CourseAttendancePage(
                      user: widget.user,
                      authService: widget.authService,
                      courseId: courseId,
                    ),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      courseName,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.person, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                '$teacherName',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[700],
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.green),
                            const SizedBox(width: 4),
                            Text(
                              '$attendanceCount',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: CustomAppBar(
        title: 'Welcome, $displayName',
        authService: widget.authService,
        user: widget.user,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 2,
                    blurRadius: 3,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 2.0),
                child: Autocomplete<String>(
                  optionsBuilder: generateOptionBuilderForAutocomplete,
                  onSelected: onAutocompleteSelect,
                  fieldViewBuilder: (BuildContext context,
                      TextEditingController fieldTextEditingController,
                      FocusNode fieldFocusNode,
                      VoidCallback onFieldSubmitted) {
                    searchController = fieldTextEditingController;
                    return TextField(
                      controller: fieldTextEditingController,
                      focusNode: fieldFocusNode,
                      onChanged: (value) {
                        filterSearchResults(value);
                      },
                      decoration: const InputDecoration(
                        hintText: 'Search by course name',
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        prefixIcon: Icon(Icons.search, color: Colors.grey),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: attendances,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No attendance data found'));
                } else {
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: getListView(),
                  );
                }
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        authService: widget.authService,
        user: widget.user,
        currentIndex: 0,
      ),
    );
  }
}

import 'package:ceta/utils/env.dart';
import 'package:flutter/material.dart';
import 'package:ceta/pages/auth_screen.dart';
import 'package:ceta/models/user_wrapper.dart';
import 'package:ceta/services/api/api_service.dart';
import 'package:ceta/services/auth/auth_service.dart';
import 'package:ceta/pages/student_future_courses.dart';
import 'package:ceta/pages/course_attendance_page.dart';

class StudentPage extends StatefulWidget {
  final AuthService authService;
  final UserWrapper user;

  const StudentPage({Key? key, required this.user, required this.authService}) : super(key: key);

  @override
  _StudentPageState createState() => _StudentPageState();
}

class _StudentPageState extends State<StudentPage> {
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
      var userData = await apiService.getUserDataByEmail(widget.user.dbUser.email);
      var userId = userData['id'];

      final fetchedAttendances = await apiService.getAttendancesByUserId(userId);
      Map<String, int> attendanceCount = {};

      for (var attendance in fetchedAttendances) {
        var courseId = attendance['course_id'];
        attendanceCount.update(courseId, (value) => value + 1, ifAbsent: () => 1);
      }

      List<Map<String, dynamic>> attendanceList = [];

      for (var courseId in attendanceCount.keys) {
        try {
          var courseData = await apiService.getCourseById(courseId);
          var planificationData = await apiService.getPlanificationByCourseId(courseId);
          var teacherData = await apiService.getUserDataById(planificationData[0]['user_id']);
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
        attendanceList.forEach((item) {
          if (item['course_name'].toLowerCase().contains(query.toLowerCase())) {
            dummyListData.add(item);
          }
        });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(
                widget.user.firebaseUser.photoURL ?? 'https://via.placeholder.com/150',
              ),
              radius: 20,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Welcome, $displayName',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,

                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await widget.authService.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => AuthScreen(authService: widget.authService),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0), // Adjusted padding for a smaller search bar
            child: Container(
              height: 40, // Adjusted height for a smaller search bar
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 2,
                    blurRadius: 3,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 2.0),
                child: Autocomplete<String>(
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text.isEmpty) {
                      return const Iterable<String>.empty();
                    }
                    return courseNames.where((String courseName) {
                      return courseName.toLowerCase().contains(textEditingValue.text.toLowerCase());
                    });
                  },
                  onSelected: (String selection) {
                    searchController.text = selection;
                    filterSearchResults(selection);
                  },
                  fieldViewBuilder: (BuildContext context, TextEditingController fieldTextEditingController, FocusNode fieldFocusNode, VoidCallback onFieldSubmitted) {
                    searchController = fieldTextEditingController;
                    return TextField(
                      controller: fieldTextEditingController,
                      focusNode: fieldFocusNode,
                      onChanged: (value) {
                        filterSearchResults(value);
                      },
                      decoration: InputDecoration(
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
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No attendance data found'));
                } else {
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ListView.builder(
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
                                            SizedBox(width: 4),
                                            Text(
                                              '$teacherName',
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: Colors.grey[700],
                                              ),
                                            ),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            Icon(Icons.check_circle, color: Colors.green),
                                            SizedBox(width: 4),
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
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
     bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (index) {
          MaterialPageRoute? route;
          if (index == 1) {
            route = MaterialPageRoute(
                builder: (context) => StudentFutureCoursesPage(
                  user: widget.user,
                  authService: widget.authService,
                ),
              
            );
          }
          else if (index == 0) {
            route = MaterialPageRoute(
                builder: (context) => StudentPage(
                  user: widget.user,
                  authService: widget.authService,
                ),
            );
          }
          Navigator.pushReplacement(context,route!);
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

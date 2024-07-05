import 'package:ceta/utils/env.dart';
import 'package:flutter/material.dart';
import 'package:ceta/pages/auth_screen.dart';
import 'package:ceta/models/user_wrapper.dart';
import 'package:ceta/services/api/api_service.dart';
import 'package:ceta/services/auth/auth_service.dart';
import 'package:ceta/pages/student_future_courses.dart';
import 'package:ceta/pages/course_attendance_page.dart';

class TeacherPage extends StatefulWidget {
  final AuthService authService;
  final UserWrapper user;

  const TeacherPage({Key? key, required this.user, required this.authService}) : super(key: key);

  @override
  _TeacherPageState createState() => _TeacherPageState();
}

class _TeacherPageState extends State<TeacherPage> {
  late ApiService apiService;
  late Future<List<Map<String, dynamic>>> courses;
  String displayName = '';
  TextEditingController searchController = TextEditingController();
  List<Map<String, dynamic>> filteredCourses = [];
  List<String> courseNames = [];
  String? selectedCourseName;

  @override
  void initState() {
    super.initState();
    apiService = ApiService(baseUrl: SERVER_URL);
    displayName = widget.user.firebaseUser.displayName ?? '';
    courses = fetchCourses();
  }

  Future<List<Map<String, dynamic>>> fetchCourses() async {
    try {
      final fetchedCourses = await apiService.getAllCourses();
      List<Map<String, dynamic>> courseList = [];

      for (var course in fetchedCourses) {
        try {
          var courseData = await apiService.getCourseById(course['id']);
          var planificationData = await apiService.getPlanificationByCourseId(course['id']);
          List<String> studentNames = [];

          for (var planification in planificationData) {
            var studentData = await apiService.getUserDataById(planification['user_id']);
            studentNames.add(studentData['name']);
          }

          courseList.add({
            'course_name': courseData['name'],
            'student_names': studentNames,
            'course_id': course['id'],
          });
          courseNames.add(courseData['name']);
        } catch (e) {
          print('Error fetching course details: $e');
        }
      }

      filteredCourses = courseList;
      courseNames = courseNames.toSet().toList(); // Remove duplicates
      return courseList;
    } catch (e) {
      throw ('Failed to load courses');
    }
  }

  void filterSearchResults(String query) {
    if (query.isNotEmpty) {
      List<Map<String, dynamic>> dummyListData = [];
      courses.then((courseList) {
        courseList.forEach((item) {
          if (item['course_name'].toLowerCase().contains(query.toLowerCase())) {
            dummyListData.add(item);
          }
        });
        setState(() {
          filteredCourses = dummyListData;
        });
      });
    } else {
      setState(() {
        courses.then((courseList) {
          filteredCourses = courseList;
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
              future: courses,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No course data found'));
                } else {
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ListView.builder(
                      itemCount: filteredCourses.length,
                      itemBuilder: (context, index) {
                        var course = filteredCourses[index];
                        var courseName = course['course_name'] ?? 'Unknown Course';
                        var studentNames = course['student_names'].join(', ') ?? 'No students';
                        var courseId = course['course_id'];

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
                                              'aa',
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: Colors.grey[700],
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
                builder: (context) => TeacherPage(
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

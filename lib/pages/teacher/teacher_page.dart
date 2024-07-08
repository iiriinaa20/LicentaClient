import 'package:ceta/utils/env.dart';
import 'package:flutter/material.dart';
import 'package:ceta/models/user_wrapper.dart';
import 'package:ceta/services/api/api_service.dart';
import 'package:ceta/components/custom_app_bar.dart';
import 'package:ceta/services/auth/auth_service.dart';
import 'package:ceta/components/custom_navigation_bar.dart';
import 'package:ceta/pages/teacher/teacher_course_attendance_page.dart';

class TeacherPage extends StatefulWidget {
  final AuthService authService;
  final UserWrapper user;

  const TeacherPage({super.key, required this.user, required this.authService});

  @override
  TeacherPageState createState() => TeacherPageState();
}

class TeacherPageState extends State<TeacherPage> {
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
      print(widget.user.dbUser.id);
      var coursesDataList =
          await apiService.getPlanificationByUserId(widget.user.dbUser.id);

      List<Map<String, dynamic>> courseList = [];
      Set<String> courseNamesSet = {};

      for (var courseData in coursesDataList) {
        try {
          var courseDetails = await apiService.getCourseById(courseData['id']);
          courseList.add({
            'course_name': courseDetails['name'] ?? 'Unknown Course Name',
            'course_year': courseData['year'] ?? 'Unknown Course Year',
            'course_semester':
                courseData['semester'] ?? 'Unknown Course Semester',
            'course_id': courseData['id'] ?? 'Unknown Course ID',
            'teacher_name': widget.user.dbUser.name,
          });
          courseNamesSet.add(courseDetails['name']);
        } catch (e) {
          print('Error fetching course details: $e');
        }
      }

      courseNames = courseNamesSet.toList();
      filteredCourses = courseList;
      return courseList;
    } catch (e) {
      throw ('Failed to load courses: $e');
    }
  }

  void filterSearchResults(String query) {
    final lowercaseQuery = query.toLowerCase();
    final filteredCourses = courses.then((courseList) {
      return courseList
          .where((item) =>
              item['course_name'].toLowerCase().contains(lowercaseQuery))
          .toList();
    });

    setState(() async {
      this.filteredCourses = await filteredCourses;
    });
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
      itemCount: filteredCourses.length,
      itemBuilder: (context, index) {
        var course = filteredCourses[index];
        var courseName = course['course_name'] ?? 'Unknown Course';
        var courseYear = course['course_year'] ?? 'Unknown Year';
        var courseSemester = course['course_semester'] ?? 'Unknown Semester';
        var courseId = course['course_id'] ?? '1';
        // var teacherName = course['teacher_name'] ?? 'Unknown Teacher';

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
                    builder: (context) => TeacherCourseAttendancePage(
                      user: widget.user,
                      authService: widget.authService,
                      courseId: courseId,
                      planificationDate: "",
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
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.person, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Anul $courseYear, Semestrul $courseSemester',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[700],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
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
              future: courses,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No courses found'));
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
          authService: widget.authService, user: widget.user, currentIndex: 0),
    );
  }
}

import 'package:intl/intl.dart';
import 'package:ceta/utils/env.dart';
import 'package:flutter/material.dart';
import 'package:ceta/pages/auth_screen.dart';
import 'package:ceta/pages/student_page.dart';
import 'package:ceta/models/user_wrapper.dart';
import 'package:ceta/services/api/api_service.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:ceta/services/auth/auth_service.dart';
import 'package:ceta/pages/course_attendance_page.dart';

class StudentFutureCoursesPage extends StatefulWidget {
  final AuthService authService;
  final UserWrapper user;

  const StudentFutureCoursesPage(
      {super.key, required this.user, required this.authService});

  @override
  _StudentFutureCoursesPageState createState() =>
      _StudentFutureCoursesPageState();
}

class _StudentFutureCoursesPageState extends State<StudentFutureCoursesPage> {
  late ApiService apiService;
  late Future<List<Map<String, dynamic>>> futureCourses;
  String displayName = '';

  // Calendar variables
  late CalendarFormat _calendarFormat;
  late DateTime _focusedDay;
  late DateTime _selectedDay;

  // Dates with courses
  Set<DateTime> courseDates = {};

  @override
  void initState() {
    super.initState();
    apiService = ApiService(baseUrl: SERVER_URL);
    displayName = widget.user.firebaseUser.displayName ?? '';
    futureCourses = fetchFutureCourses();

    // Initialize calendar variables
    _calendarFormat = CalendarFormat.month;
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
  }

  Future<List<Map<String, dynamic>>> fetchFutureCourses() async {
    try {
      List<Map<String, dynamic>> planificationsList = [];
      var courseData = await apiService.getAllCourses();
      var planificationData = await apiService.getAllCoursesPlanifications();

      if (courseData == null || planificationData == null) {
        throw ('Course data or planification data is null');
      }

      for (var planification in planificationData) {
        for (var course in courseData) {
          if (planification['course_id'] == course['id']) {
            DateTime courseDate =
                DateFormat('yyyy-MM-dd').parse(planification['date']);
            courseDates.add(courseDate);
            var teacherData =
                await apiService.getUserDataById(planification['user_id']);
            planificationsList.add({
              'course_name': course['name'],
              'course_id': course['id'],
              'course_year': course['year'],
              'start_time': planification['start_time'],
              'end_time': planification['end_time'],
              'date': planification['date'],
              'teacher_name': teacherData['name'],
            });
          }
        }
      }

      return planificationsList;
    } catch (e) {
      print('Error fetching future courses: $e');
      throw ('Failed to load future courses');
    }
  }

  List<Map<String, dynamic>> _filterCoursesBySelectedDate(
      List<Map<String, dynamic>> planifications) {
    return planifications.where((planification) {
      DateTime courseDate =
          DateFormat('yyyy-MM-dd').parse(planification['date']);
      return isSameDay(courseDate, _selectedDay);
    }).toList();
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
                widget.user.firebaseUser.photoURL ??
                    'https://via.placeholder.com/150',
              ),
              radius: 20,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Future Courses for $displayName',
                style: TextStyle(
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
                  builder: (context) =>
                      AuthScreen(authService: widget.authService),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Calendar widget
          TableCalendar(
            firstDay: DateTime.utc(2023, 1, 1),
            lastDay: DateTime.utc(2024, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay; // update `_focusedDay` as well
              });
              // Handle day selection
              print('Selected: $_selectedDay');
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
              // Handle page change
              print('Focused day: $_focusedDay');
            },
            onFormatChanged: (format) {
              if (_calendarFormat != format) {
                setState(() {
                  _calendarFormat = format;
                });
              }
            },
            // onDayLongPressed: (selectedDay, focusedDay) => {
            //   setState(() {
            //     _selectedDay = selectedDay;
            //     _focusedDay = focusedDay;
            //   })
            // },
            startingDayOfWeek: StartingDayOfWeek.monday,
            daysOfWeekStyle: const DaysOfWeekStyle(
              weekdayStyle: TextStyle(color: Colors.black),
              weekendStyle: TextStyle(color: Color.fromARGB(255, 249, 23, 7)),
            ),
            headerStyle: const HeaderStyle(
              titleCentered: true,
              formatButtonVisible: false,
              leftChevronIcon: Icon(Icons.chevron_left),
              rightChevronIcon: Icon(Icons.chevron_right),
              headerMargin: EdgeInsets.only(bottom: 10),
              leftChevronMargin: EdgeInsets.only(left: 10),
              rightChevronMargin: EdgeInsets.only(right: 10),
            ),
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, focusedDay) {
                if (courseDates
                    .any((courseDate) => isSameDay(courseDate, day))) {
                  return Container(
                    margin: EdgeInsets.all(4.0),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${day.day}',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  );
                }
                return null;
              },
              selectedBuilder: (context, day, focusedDay) {
                return Container(
                  margin: EdgeInsets.all(4.0),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${day.day}',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                );
              },
              todayBuilder: (context, day, focusedDay) {
                return Container(
                  margin: EdgeInsets.all(4.0),
                  decoration: BoxDecoration(
                    color: Colors.orangeAccent,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${day.day}',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 20),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: futureCourses,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(child: Text('No future courses found'));
                  } else {
                    var filteredCourses =
                        _filterCoursesBySelectedDate(snapshot.data!);
                    if (filteredCourses.isEmpty) {
                      return Center(child: Text('No courses on this date'));
                    }
                    return ListView.builder(
                      itemCount: filteredCourses.length,
                      itemBuilder: (context, index) {
                        var course = filteredCourses[index];
                        var teacherName =
                            course['teacher_name'] ?? 'Unknown Teacher';
                        var courseName =
                            course['course_name'] ?? 'Unknown Course';
                        var courseId = course['course_id'];
                        var startTime = course['start_time'];
                        var endTime = course['end_time'];
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(Icons.person,
                                                color: Colors.grey[600]),
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
                                        Text(
                                          '$startTime - $endTime',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                        Icon(Icons.arrow_forward,
                                            color: Colors.blueAccent),
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
                },
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
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

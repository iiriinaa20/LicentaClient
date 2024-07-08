import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  String baseUrl = "";
  static final ApiService _singleton = ApiService._internal();

  factory ApiService({required String baseUrl}) {
    return _singleton..baseUrl = baseUrl;
  }

  ApiService._internal();

  String getBaseUrl() {
    return baseUrl;
  }
  Future<dynamic> get(String endpoint) async {
    final response = await http.get(Uri.parse('$baseUrl/$endpoint'));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load data');
    }
  }
  
   Future<dynamic> getUserDataByEmail(String email) async {
    final response = await http.get(Uri.parse('$baseUrl/user?email=$email'));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load user data');
    }
  }

   Future<List<dynamic>> getAttendancesByUserId(String userId) async {
    final response = await http.get(Uri.parse('$baseUrl/attendances_by_user?user_id=$userId'));

    if (response.statusCode == 200) {
      return List<dynamic>.from(json.decode(response.body));
    } else {
      throw Exception('Failed to load attendances');
    }
  }

   Future<List<dynamic>> getAttendancesByCourseId(String courseId) async {
    final response = await http.get(Uri.parse('$baseUrl/attendances/$courseId/by_course'));
    if (response.statusCode == 200) {
      return List<dynamic>.from(json.decode(response.body));
    } else {
      throw Exception('Failed to load attendances');
    }
  }
   Future<List<dynamic>> getAttendancesByCourseIdForDate(String courseId, String? date) async {
    final response = await http.get(Uri.parse('$baseUrl/attendances/$courseId/by_course?date=$date'));
    if (response.statusCode == 200) {
      return List<dynamic>.from(json.decode(response.body));
    } else {
      throw Exception('Failed to load attendances');
    }
  }

Future<dynamic> getUserDataById(String userId) async {
  final response = await http.get(Uri.parse('$baseUrl/users/$userId'));

  if (response.statusCode == 200) {
    return json.decode(response.body);
  } else {
    throw Exception('Failed to find user');
  }
}
Future<dynamic> getCourseById(String courseId) async {
  final response = await http.get(Uri.parse('$baseUrl/courses/$courseId'));

  if (response.statusCode == 200) {
    return json.decode(response.body);
  } else {
    throw Exception('Failed to load course data');
  }
}

Future<dynamic> getCourseByUserId(String userId) async {
  final response = await http.get(Uri.parse('$baseUrl/courses/$userId/by_user'));

  if (response.statusCode == 200) {
    return json.decode(response.body);
  } else {
    throw Exception('Failed to load course data');
  }
}


Future<dynamic> getAllCourses() async {
  final response = await http.get(Uri.parse('$baseUrl/courses'));
  if (response.statusCode == 200) {
    return json.decode(response.body);
  } else {
    throw Exception('Failed to load course data');
  }
}


Future<dynamic> getPlanificationById(String courseId) async {
  final response = await http.get(Uri.parse('$baseUrl/courses_planification/$courseId'));

  if (response.statusCode == 200) {
    return json.decode(response.body);
  } else {
    throw Exception('Failed to load course data');
  }
}

Future<dynamic> getAllCoursesPlanifications() async {
  final response = await http.get(Uri.parse('$baseUrl/courses_planifications'));
  if (response.statusCode == 200) {
    return json.decode(response.body);
  } else {
    throw Exception('Failed to load planifications data');
  }
}

Future<dynamic> getPlanificationByCourseId(String courseId) async {
  final response = await http.get(Uri.parse('$baseUrl/courses_planification/$courseId/by_course'));
  if (response.statusCode == 200) {
    return json.decode(response.body);
  } else {
    throw Exception('Failed to load course data');
  }
}

Future<dynamic> getPlanificationByUserId(String userId) async {
  final response = await http.get(Uri.parse('$baseUrl/courses_planification/$userId/by_teacher'));
  if (response.statusCode == 200) {
    return json.decode(response.body);
  } else {
    throw Exception('Failed to load course data');
  }
}
  Future<dynamic> post(String endpoint, Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode(data),
    );
    return _processResponse(response);
  }

  Future<dynamic> put(String endpoint, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl$endpoint'),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode(data),
    );
    return _processResponse(response);
  }

  Future<dynamic> delete(String endpoint) async {
    final response = await http.delete(Uri.parse('$baseUrl$endpoint'));
    return _processResponse(response);
  }

  dynamic _processResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load data: ${response.statusCode}');
    }
  }

  
}

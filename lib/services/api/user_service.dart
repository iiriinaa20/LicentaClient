// lib/services/user_service.dart
import 'api_service.dart';

class UserService {
  final ApiService apiService;

  UserService({required this.apiService});

  Future<List<dynamic>> fetchUsers() async {
    return await apiService.get('/users');
  }

  Future<dynamic> fetchUserById(int id) async {
    return await apiService.get('/users/$id');
  }

  Future<dynamic> createUser(Map<String, dynamic> data) async {
    return await apiService.post('/users', data);
  }

  Future<dynamic> updateUser(int id, Map<String, dynamic> data) async {
    return await apiService.put('/users/$id', data);
  }

  Future<void> deleteUser(int id) async {
    await apiService.delete('/users/$id');
  }
}

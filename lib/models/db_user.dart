class DbUser {
  final String id;
  final String name;
  final String email;
  final bool type;

  DbUser({
    required this.id,
    required this.name,
    required this.email,
    required this.type,
  });

  // Factory method to create DbUser from a Map
  factory DbUser.fromJson(Map<String, dynamic> json) {
    return DbUser(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      type: json['type'] == "teacher" ,
    );
  }
}

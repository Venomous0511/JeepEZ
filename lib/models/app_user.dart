class AppUser {
  final String uid;
  final String employeeId;
  final String email;
  final String role;
  final String? name;
  final bool status;

  AppUser({
    required this.uid,
    required this.employeeId,
    required this.email,
    required this.role,
    required this.status,
    this.name,
  });

  factory AppUser.fromMap(String uid, Map<String, dynamic> data) {
    return AppUser(
      uid: uid,
      employeeId: data['employeeId']?.toString() ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? '',
      status: data['status'],
      name: data['name'],
    );
  }

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'employeeId': employeeId,
    'email': email,
    'role': role,
    'status': status,
    if (name != null) 'name': name,
  };
}

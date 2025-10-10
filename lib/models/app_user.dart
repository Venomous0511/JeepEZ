class AppUser {
  final String uid;
  final String employeeId;
  final String email;
  final String role;
  final String? name;
  final bool status;
  final int assignedVehicle;

  AppUser({
    required this.uid,
    required this.employeeId,
    required this.email,
    required this.role,
    required this.status,
    this.name,
    required this.assignedVehicle,
  });

  factory AppUser.fromMap(String uid, Map<String, dynamic> data) {
    return AppUser(
      uid: uid,
      employeeId: data['employeeId']?.toString() ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? '',
      status: data['status'] ?? false,
      name: data['name'],
      assignedVehicle: data['assignedVehicle'] != null
          ? data['assignedVehicle'] as int
          : 0,
    );
  }

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'employeeId': employeeId,
    'email': email,
    'role': role,
    'status': status,
    'assignedVehicle': assignedVehicle,
    if (name != null) 'name': name,
  };
}

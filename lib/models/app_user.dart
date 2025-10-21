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
    // Helper function to safely parse assignedVehicle
    int parseAssignedVehicle(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return AppUser(
      uid: uid,
      employeeId: data['employeeId']?.toString() ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? '',
      status: data['status'] ?? false,
      name: data['name'],
      assignedVehicle: parseAssignedVehicle(data['assignedVehicle']),
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
import 'dart:convert';
import 'package:http/http.dart' as http;

const apiUrl = 'http://192.168.1.2:8080/users';

Future<void> addUser(String name, String email) async {
  final response = await http.post(
    Uri.parse(apiUrl),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({"name": name, "email": email}),
  );

  if (response.statusCode == 200) {
    print("User added successfully");
  } else {
    print("Failed to add user");
  }
}

Future<void> fetchUsers() async {
  final response = await http.get(Uri.parse(apiUrl));

  if (response.statusCode == 200) {
    final List users = jsonDecode(response.body);
    print("Users: $users");
  } else {
    print("Failed to fetch users");
  }
}

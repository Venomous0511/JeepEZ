import 'package:http/http.dart' as http;
import 'dart:convert';

const String baseUrl = 'http://<your-ip>:5000/api/users';

Future<List<Map<String, dynamic>>> fetchUsers() async {
  final response = await http.get(Uri.parse(baseUrl));
  if (response.statusCode == 200) {
    final List data = jsonDecode(response.body);
    return data.cast<Map<String, dynamic>>();
  } else {
    throw Exception('Failed to load users');
  }
}

Future<void> changePassword(String email, String newPassword) async {
  final response = await http.post(
    Uri.parse('$baseUrl/change-password'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'email': email, 'newPassword': newPassword}),
  );

  if (response.statusCode != 200) {
    throw Exception('Failed to update password');
  }
}

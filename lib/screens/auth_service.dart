import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static Future<Map<String, String>> getAuthHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken') ?? '';

    return {
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    };
  }

  static Future<Map<String, String>> getAuthHeadersMultipart() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken') ?? '';

    return {"Authorization": "Bearer $token"};
  }
}

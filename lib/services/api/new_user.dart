import 'package:imgrep/app_state.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:imgrep/utils/debug_logger.dart';
import 'package:imgrep/utils/settings.dart';

Future<void> createNewUser() async {
  try {
    final prefs = await SharedPreferences.getInstance();

    // Check if user_id is already saved
    final savedUserId = prefs.getString('user_id');
    if (savedUserId != null) AppState().setUserResponse(savedUserId);

    // No saved user_id, create new user
    final String apiUrl = Settings.serverIp;
    final response = await http.post(Uri.parse('$apiUrl/api/user/new'), headers: {'Content-Type': 'application/json'});

    if (response.statusCode == 200 || response.statusCode == 201) {
      final Map<String, dynamic> responseData = jsonDecode(response.body);
      final userId = responseData["user_id"];

      await prefs.setString('user_id', userId);

      AppState().setUserResponse(userId);
      Dbg.i('User created and stored successfully: $userId');
      return userId;
    } else {
      Dbg.e('Failed to create user: ${response.statusCode}, Body: ${response.body}');
    }
  } catch (e) {
    Dbg.e('Error creating user: $e');
  }
}

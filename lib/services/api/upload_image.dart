import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:imgrep/services/api/user.dart';
import 'package:imgrep/utils/debug_logger.dart';
import 'package:imgrep/utils/settings.dart';

Future<Map<String, dynamic>?> uploadImage(
  String imagePath,
  String userId,
  String
  serverIp, // because bg process cant load serverip from .env or from static class
) async {
  try {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$serverIp/api/upload-image'),
    );
    request.fields['user_id'] = userId;
    request.files.add(await http.MultipartFile.fromPath('image', imagePath));
    request.headers['Content-Type'] = 'multipart/form-data';

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();
    Map<String, dynamic> data = jsonDecode(responseBody);
    return data;
  } catch (e) {
    Dbg.crash('Error: $e');
    return null;
  }
}

Future<Map<String, dynamic>?> searchImage(String query, int amount) async {
  try {
    final userId = await UserManager.getUserId();

    if (userId == null) {
      Dbg.crash("userid is not defined");
      return null;
    }
    final apiUrl = Settings.serverIp;
    final response = await http.post(
      Uri.parse('$apiUrl/api/search'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'user_id': userId, 'query': query, 'amount': amount}),
    );

    Map<String, dynamic> data = jsonDecode(response.body);
    return data;
  } catch (e) {
    Dbg.e('Error: $e');
    return null;
  }
}

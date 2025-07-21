import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:imgrep/services/api/user.dart';
import 'package:imgrep/utils/debug_logger.dart';
import 'package:imgrep/utils/settings.dart';

Future<void> uploadImage(
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

    if (response.statusCode == 200) {
      Dbg.i('Success: $responseBody');
    } else {
      Dbg.e('Error: Status ${response.statusCode}, Body: $responseBody');
    }
  } catch (e) {
    Dbg.crash('Error: $e');
  }
}

Future<void> searchImage(String query, int amount) async {
  try {
    final userId = await UserManager.getUserId();

    if (userId == null) {
      Dbg.crash("userid is not defined");
      return;
    }
    final apiUrl = Settings.serverIp;
    final response = await http.post(
      Uri.parse('$apiUrl/api/search'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'user_id': userId, 'query': query, 'amount': amount}),
    );

    if (response.statusCode == 200) {
      Dbg.i('Success: ${response.body}');
    } else {
      Dbg.e('Error: Status ${response.statusCode}, Body: ${response.body}');
    }
  } catch (e) {
    Dbg.e('Error: $e');
  }
}

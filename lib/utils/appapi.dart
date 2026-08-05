import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cafa_boardgame/config/app_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppAPI {
  // GET Method
  static Future<http.Response> get(String uri) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    print("GET: ${AppConfig.apiBaseUri}$uri");

    final response = await http.get(
      Uri.parse("${AppConfig.apiBaseUri}$uri"),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': 'application/json',
        'Authorization': 'Bearer ${prefs.getString('token')}',
      },
    );

    return response;
  }

  static Future<http.Response> post(String uri, Object body) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    print("POST: ${AppConfig.apiBaseUri}$uri");

    final response = await http.post(
      Uri.parse("${AppConfig.apiBaseUri}$uri"),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': 'application/json',
        'Authorization': 'Bearer ${prefs.getString('token')}',
      },
      body: jsonEncode(body),
    );

    return response;
  }
}
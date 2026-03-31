import 'dart:convert';
import 'dart:io';

Future<String> getCityFromCookie() async {
  final file = File('config/auth.json');

  if (!await file.exists()) {
    return 'auth.json не найден';
  }

  final jsonData = jsonDecode(await file.readAsString());
  final cookie = jsonData['cookie'] as String;

  final cityPathMatch = RegExp(r'city_path=([^;]+)').firstMatch(cookie);

  if (cityPathMatch != null) {
    return cityPathMatch.group(1)!;
  }

  return 'Город не найден';
}
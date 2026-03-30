import 'dart:convert';
import 'dart:io';

Future<String> getCityFromCookie() async {
  final file = File('config/auth.json');

  if (!await file.exists()) {
    return '❌ auth.json не найден';
  }

  final jsonData = jsonDecode(await file.readAsString());
  final cookie = jsonData['cookie'] as String;

  // ===== 1. Пытаемся через current_path (основной способ) =====
  final currentMatch = RegExp(r'current_path=([^;]+)').firstMatch(cookie);

  if (currentMatch != null) {
    try {
      final decoded = Uri.decodeComponent(currentMatch.group(1)!);

      final jsonMatch = RegExp(r'\{.*\}').firstMatch(decoded);
      if (jsonMatch != null) {
        final cityData = jsonDecode(jsonMatch.group(0)!);
        return cityData['cityName'] ?? '❌ неизвестный город';
      }
    } catch (_) {
      // игнорируем и идём дальше
    }
  }

  // ===== 2. fallback через city_path =====
  final cityPathMatch = RegExp(r'city_path=([^;]+)').firstMatch(cookie);

  if (cityPathMatch != null) {
    return cityPathMatch.group(1)!; // просто "moscow"
  }

  return '❌ город не найден';
}
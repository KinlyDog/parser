/// Extracts `city_path` from the cookie string.
/// Returns decoded value or `null` when the cookie doesn't contain it.
String? extractCityPathFromCookie(String cookie) {
  final match = RegExp(r'city_path=([^;]+)').firstMatch(cookie);
  if (match == null) return null;

  final raw = match.group(1);
  if (raw == null || raw.isEmpty) return null;

  // Value may be percent-encoded depending on how the cookie was built.
  try {
    return Uri.decodeComponent(raw);
  } catch (_) {
    return raw;
  }
}

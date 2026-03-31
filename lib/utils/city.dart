String getCityFromCookie(String cookie) {
  final cityPathMatch = RegExp(r'city_path=([^;]+)').firstMatch(cookie);

  if (cityPathMatch != null) {
    return 'Город: ${cityPathMatch.group(1)}\n'
        '============================\n';
  }

  return 'Город не найден';
}

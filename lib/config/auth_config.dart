import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;

class AuthConfig {
  final String cookie;
  final String csrfToken;

  AuthConfig._(this.cookie, this.csrfToken);

  static Future<AuthConfig> load({Directory? configDir}) async {
    final dir =
        configDir ?? Directory(p.join(Directory.current.path, 'config'));

    final cookieFromEnv = const String.fromEnvironment(
      'AUTH_COOKIE',
      defaultValue: '',
    ).trim();
    final csrfFromEnv = const String.fromEnvironment(
      'AUTH_CSRF_TOKEN',
      defaultValue: '',
    ).trim();

    final authFile = _resolveAuthFile(dir);
    final authJson = jsonDecode(await authFile.readAsString());

    if (authJson is! Map) {
      throw FormatException('config auth JSON must be an object');
    }

    final cookie = cookieFromEnv.isNotEmpty
        ? cookieFromEnv
        : (authJson['cookie'] is String ? authJson['cookie'] as String : '');
    final csrf = csrfFromEnv.isNotEmpty
        ? csrfFromEnv
        : (authJson['csrfToken'] is String
              ? authJson['csrfToken'] as String
              : '');

    if (cookie.isEmpty || csrf.isEmpty) {
      throw StateError(
        'Missing auth cookie/CSRF. Fill `auth.local.json` (or `auth.json`) '
        'or pass `-D AUTH_COOKIE=... -D AUTH_CSRF_TOKEN=...`.',
      );
    }

    return AuthConfig._(cookie, csrf);
  }

  static File _resolveAuthFile(Directory configDir) {
    final local = File(p.join(configDir.path, 'auth.local.json'));
    if (local.existsSync()) return local;
    return File(p.join(configDir.path, 'auth.json'));
  }
}

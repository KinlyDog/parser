import 'dart:convert';
import 'dart:io';

import 'package:apple_world/api_client.dart';
import 'package:apple_world/models.dart';
import 'package:apple_world/parser.dart';
import 'package:apple_world/utils/city.dart';
import 'package:path/path.dart' as p;

Future<void> main() async {
  try {
    final projectRoot = _resolveProjectRoot();
    final configDir = Directory(p.join(projectRoot.path, 'config'));

    final cookieFromEnv = const String.fromEnvironment(
      'AUTH_COOKIE',
      defaultValue: '',
    ).trim();
    final csrfFromEnv = const String.fromEnvironment(
      'AUTH_CSRF_TOKEN',
      defaultValue: '',
    ).trim();

    final authFile = _resolveAuthFile(configDir);
    final authJsonDecoded = jsonDecode(await authFile.readAsString());
    if (authJsonDecoded is! Map) {
      throw FormatException('config auth JSON must be an object');
    }

    final cookie = cookieFromEnv.isNotEmpty
        ? cookieFromEnv
        : (authJsonDecoded['cookie'] is String
            ? (authJsonDecoded['cookie'] as String)
            : '');

    final csrf = csrfFromEnv.isNotEmpty
        ? csrfFromEnv
        : (authJsonDecoded['csrfToken'] is String
            ? (authJsonDecoded['csrfToken'] as String)
            : '');

    if (cookie.isEmpty || csrf.isEmpty) {
      throw StateError(
        'Missing auth cookie/CSRF. Fill `config/auth.local.json` (or `config/auth.json`) '
        'or pass `-D AUTH_COOKIE=... -D AUTH_CSRF_TOKEN=...`.',
      );
    }

    final api = ApiClient(cookie, csrf);
    print(getCityFromCookie(cookie));

    final productsFile = File(p.join(configDir.path, 'products.json'));
    final productsJsonDecoded = jsonDecode(await productsFile.readAsString());
    if (productsJsonDecoded is! List) {
      throw FormatException('config/products.json must be an array');
    }

    final products = productsJsonDecoded.map((e) {
      if (e is! Map) {
        throw FormatException('Invalid product entry in products.json');
      }
      return Product.fromJson(e.cast<String, dynamic>());
    }).toList();

    // 🔁 Проходим по всем товарам
    for (final product in products) {
      try {
        final response = await api.getProduct(product.id, product.referer);

        if (response.statusCode == 200) {
          final parsed = parseProductPrice(response.data);
          print('📱 ${parsed.name}');
          print('💰 Цена: ${parsed.price} ₽');
          print('------------------------');
        } else {
          print('Ошибка ${response.statusCode} для ${product.name}');
        }
      } catch (e, st) {
        print('Ошибка для ${product.name} (${product.id}): $e');
        // stacktrace полезен при отладке структуры ответа
        print(st);
      }
    }
  } catch (e, st) {
    print('Ошибка запуска: $e');
    print(st);
  }
}

Directory _resolveProjectRoot() {
  try {
    final scriptPath = Platform.script.toFilePath();
    final binDir = File(scriptPath).parent;
    return binDir.parent;
  } catch (_) {
    return Directory.current;
  }
}

File _resolveAuthFile(Directory configDir) {
  final local = File(p.join(configDir.path, 'auth.local.json'));
  if (local.existsSync()) return local;
  return File(p.join(configDir.path, 'auth.json'));
}

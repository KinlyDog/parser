import 'dart:convert';
import 'dart:io';

import 'package:apple_world/api_client.dart';
import 'package:apple_world/parser.dart';
import 'package:apple_world/utils/city.dart';
import 'package:path/path.dart' as p;

Future<void> main() async {
  try {
    final debug = const bool.fromEnvironment('DEBUG', defaultValue: false);
    final configDir = _resolveConfigDir();

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
    final city = extractCityPathFromCookie(cookie);
    if (city == null) {
      print('Город не найден');
    } else {
      print('Город: $city');
      print('===============================================');
    }

    final refererFromEnv = const String.fromEnvironment(
      'REFERER',
      defaultValue: '',
    ).trim();
    var referer = refererFromEnv;

    final jsonFile = File(p.join(configDir.path, 'products.json'));
    final txtFile = File(p.join(configDir.path, 'products.txt'));
    final ids = <String>[];

    if (jsonFile.existsSync()) {
      final decoded = jsonDecode(await jsonFile.readAsString());

      if (decoded is! List) {
        throw FormatException('config/products.json must be an array');
      }

      for (final entry in decoded) {
        if (entry is String) {
          final id = entry.trim();
          if (id.isNotEmpty) ids.add(id);
          continue;
        }

        if (entry is Map) {
          final id = entry['id'];
          if (id is! String || id.isEmpty) {
            throw FormatException('Invalid product.id in products.json');
          }
          ids.add(id);

          final entryReferer = entry['referer'];
          if (referer.isEmpty &&
              entryReferer is String &&
              entryReferer.isNotEmpty) {
            referer = entryReferer;
          }
          continue;
        }

        throw FormatException(
          'Invalid item in products.json. Expected string id or object.',
        );
      }
    } else if (txtFile.existsSync()) {
      final content = await txtFile.readAsString();
      ids.addAll(
        content
            .split(RegExp(r'[,\s\n]+'))
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty),
      );
    } else {
      throw FileSystemException(
        'No products.json or products.txt found',
        configDir.path,
      );
    }

    if (ids.isEmpty) {
      throw StateError('No product ids provided');
    }

    final response = await api.getProducts(
      ids,
      referer: referer.isEmpty ? null : referer,
    );

    if (debug) {
      print('DEBUG status=${response.statusCode}');
      try {
        final raw = jsonEncode(response.data);
        final preview = raw.length > 4000 ? raw.substring(0, 4000) : raw;
        print('DEBUG response preview (first ${preview.length} chars):');
        print(preview);
        if (raw.length > preview.length) print('DEBUG ... truncated ...');
      } catch (e) {
        print('DEBUG unable to jsonEncode response.data: $e');
        print('DEBUG response.data runtimeType=${response.data.runtimeType}');
      }
    }

    if (response.statusCode != 200) {
      throw HttpException('Unexpected status: ${response.statusCode}');
    }

    final parsedById = parseProductPrices(response.data, requestIds: ids);

    // --- CSV Export ---
    final exportDir = Directory(p.join(Directory.current.path, 'export'));
    if (!exportDir.existsSync()) exportDir.createSync(recursive: true);

    // Текущая дата в формате YYYYMMDD
    final now = DateTime.now();
    final formattedDate =
        '${now.year.toString().padLeft(4, '0')}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';

    final csvFile = File(p.join(exportDir.path, 'DNS_$formattedDate.csv'));
    final csvRows = <String>[];
    csvRows.add('Артикул,Название,Цена'); // Заголовки CSV

    for (final id in ids) {
      final parsed = parsedById[id];

      if (parsed == null) {
        print(
          'Нет данных по id=$id (parsed keys: ${parsedById.keys.take(10).toList()}${parsedById.length > 10 ? '...' : ''})',
        );
        continue;
      }

      // --- Консольный вывод (старый формат) ---
      print(parsed.name);
      final cleanPrice = parsed.price.toString().replaceAll(RegExp(r'\D'), '');
      print('Цена: $cleanPrice ₽');
      print('--------------------------------------');

      // --- CSV Export ---
      final safeName = parsed.name.replaceAll('"', '""');
      csvRows.add('$id,"$safeName",$cleanPrice');
    }

    await csvFile.writeAsString(csvRows.join('\n'));
    print('CSV сохранен: ${csvFile.path}');
  } catch (e, st) {
    print('Ошибка запуска: $e');
    print(st);
  }
}

Directory _resolveConfigDir() {
  final fromEnv = const String.fromEnvironment(
    'CONFIG_DIR',
    defaultValue: '',
  ).trim();
  if (fromEnv.isNotEmpty) return Directory(fromEnv);
  return Directory(p.join(Directory.current.path, 'config'));
}

File _resolveAuthFile(Directory configDir) {
  final local = File(p.join(configDir.path, 'auth.local.json'));
  if (local.existsSync()) return local;
  return File(p.join(configDir.path, 'auth.json'));
}

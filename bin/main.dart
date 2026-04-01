import 'dart:io';
import 'dart:convert';
import 'package:apple_world/models/product_entry.dart';
import 'package:path/path.dart' as p;

import 'package:apple_world/config/auth_config.dart';
import 'package:apple_world/utils/logger.dart';
import 'package:apple_world/utils/city.dart';
import 'package:apple_world/services/product_loader.dart';
import 'package:apple_world/services/csv_exporter.dart';
import 'package:apple_world/services/product_service.dart';
import 'package:apple_world/api_client.dart';

Future<void> main() async {
  // --- Настройка логгера ---
  final debug = const bool.fromEnvironment('DEBUG', defaultValue: false);
  setupLogging(debug: debug);

  try {
    await runApp(debug: debug);
  } catch (e, st) {
    logger.severe('Ошибка запуска приложения: $e');
    logger.severe(st);
  }
}

/// Основной запуск приложения
Future<void> runApp({required bool debug}) async {
  logger.info('Запуск приложения...');

  // --- Конфигурация и авторизация ---
  final configDir = Directory(p.join(Directory.current.path, 'config'));
  final authConfig = await loadAuthConfig(configDir);
  final api = ApiClient(authConfig.cookie, authConfig.csrfToken);

  logCity(extractCityPathFromCookie(authConfig.cookie));

  // --- Загрузка списка продуктов ---
  final entries = await loadProducts(configDir);

  // --- Получение данных и парсинг ---
  final parsedById = await fetchAndParse(entries, api, debug: debug);

  // --- Вывод в консоль ---
  printProducts(parsedById, entries);

  // --- Экспорт в CSV ---
  await exportCsv(parsedById, entries);
}

/// Загружает конфигурацию авторизации
Future<AuthConfig> loadAuthConfig(Directory configDir) async {
  return AuthConfig.load(configDir: configDir);
}

/// Логирует город
void logCity(String? city) {
  if (city == null) {
    logger.info('Город не найден');
  } else {
    logger.info('Город: $city');
  }
  logger.info('===============================================');
}

/// Загружает список продуктов
Future<List<ProductEntry>> loadProducts(Directory configDir) async {
  final loader = ProductLoader(configDir);
  return loader.load();
}

/// Получает данные с API и парсит их
Future<Map<String, dynamic>> fetchAndParse(
  List<ProductEntry> entries,
  ApiClient api, {
  required bool debug,
}) async {
  final service = ProductService(api);
  final parsed = await service.fetchAndParseProducts(entries);

  if (debug) {
    try {
      final raw = jsonEncode(parsed);
      final preview = raw.length > 4000 ? raw.substring(0, 4000) : raw;
      logger.fine(
        'DEBUG response preview (first ${preview.length} chars): $preview',
      );
      if (raw.length > preview.length) logger.fine('DEBUG ... truncated ...');
    } catch (e) {
      logger.fine('DEBUG unable to jsonEncode parsed response: $e');
      logger.fine('DEBUG parsed runtimeType=${parsed.runtimeType}');
    }
  }

  return parsed;
}

/// Выводит продукты в консоль
void printProducts(
  Map<String, dynamic> parsedById,
  List<ProductEntry> entries,
) {
  for (final id in entries.map((e) => e.id)) {
    final parsed = parsedById[id];
    if (parsed == null) {
      logger.warning('Нет данных по id=$id');
      continue;
    }
    logger.info(parsed.name);
    final cleanPrice = parsed.price.toString().replaceAll(RegExp(r'\D'), '');
    logger.info('Цена: $cleanPrice ₽');
    logger.info('--------------------------------------');
  }
}

/// Экспортирует данные в CSV
Future<void> exportCsv(
  Map<String, dynamic> parsedById,
  List<ProductEntry> entries,
) async {
  final exporter = CsvExporter();
  final csvFile = await exporter.export(
    parsedById,
    entries.map((e) => e.id).toList(),
  );
  logger.info('CSV сохранен: ${csvFile.path}');
}

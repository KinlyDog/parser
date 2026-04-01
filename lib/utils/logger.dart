// lib/utils/logger.dart
import 'package:logging/logging.dart';

final logger = Logger('AppLogger');

void setupLogging({bool debug = false}) {
  // Уровень логирования
  Logger.root.level = debug ? Level.ALL : Level.INFO;

  // Подписка на события логера
  Logger.root.onRecord.listen((record) {
    final levelName = record.level.name;
    print('[$levelName] ${record.time.toIso8601String()}: ${record.message}');
  });
}

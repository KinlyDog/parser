import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as p;
import '../models/product_entry.dart';
import '../utils/logger.dart';

class ProductLoader {
  final Directory configDir;
  DateTime? _lastModified;
  List<ProductEntry>? _cache;

  ProductLoader(this.configDir);

  Future<List<ProductEntry>> load() async {
    final jsonFile = File(p.join(configDir.path, 'products.json'));
    final txtFile = File(p.join(configDir.path, 'products.txt'));
    File? fileToRead;

    if (jsonFile.existsSync()) {
      fileToRead = jsonFile;
    } else if (txtFile.existsSync()) {
      fileToRead = txtFile;
    } else {
      throw FileSystemException(
        'No products.json or products.txt found',
        configDir.path,
      );
    }

    final lastModified = fileToRead.lastModifiedSync();

    // Используем кэш, если файл не изменился
    if (_cache != null &&
        _lastModified != null &&
        _lastModified == lastModified) {
      logger.fine('Используем кэш продуктов, файл не изменялся.');
      return _cache!;
    }

    final content = await fileToRead.readAsString();
    final entries = <ProductEntry>[];

    if (fileToRead.path.endsWith('.json')) {
      final decoded = jsonDecode(content);
      if (decoded is! List) {
        throw FormatException('config/products.json must be an array');
      }

      for (final entry in decoded) {
        if (entry is String) {
          final id = entry.trim();
          if (id.isNotEmpty) entries.add(ProductEntry(id: id));
          continue;
        }

        if (entry is Map) {
          final id = entry['id'];
          if (id is! String || id.isEmpty) {
            throw FormatException('Invalid product.id in products.json');
          }
          final referer =
              entry['referer'] is String &&
                  (entry['referer'] as String).isNotEmpty
              ? entry['referer'] as String
              : null;
          entries.add(ProductEntry(id: id, referer: referer));
          continue;
        }

        throw FormatException(
          'Invalid item in products.json. Expected string or object.',
        );
      }
    } else {
      // txt
      final ids = content
          .split(RegExp(r'[,\s\n]+'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty);
      entries.addAll(ids.map((id) => ProductEntry(id: id)));
    }

    // обновляем кэш
    _cache = entries;
    _lastModified = lastModified;

    logger.fine('Продукты загружены: ${entries.length} шт.');
    return entries;
  }
}

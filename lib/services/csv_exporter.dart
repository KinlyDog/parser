import 'dart:io';
import 'package:path/path.dart' as p;

class CsvExporter {
  final String exportDirPath;

  CsvExporter({String? exportDir})
    : exportDirPath = exportDir ?? p.join(Directory.current.path, 'export');

  Future<File> export(Map<String, dynamic> parsedById, List<String> ids) async {
    final dir = Directory(exportDirPath);
    if (!dir.existsSync()) dir.createSync(recursive: true);

    final now = DateTime.now();
    final formattedDate =
        '${now.year.toString().padLeft(4, '0')}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final csvFile = File(p.join(dir.path, 'DNS_$formattedDate.csv'));

    final csvRows = <String>[];
    csvRows.add('Артикул,Название,Цена');

    for (final id in ids) {
      final parsed = parsedById[id];
      if (parsed == null) continue;

      final safeName = parsed.name.replaceAll('"', '""');
      final cleanPrice = parsed.price.toString().replaceAll(RegExp(r'\D'), '');
      csvRows.add('$id,"$safeName",$cleanPrice');
    }

    await csvFile.writeAsString(csvRows.join('\n'));
    return csvFile;
  }
}

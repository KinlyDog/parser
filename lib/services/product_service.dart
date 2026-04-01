import '../api_client.dart';
import '../models/product_entry.dart';
import '../parser.dart';
import 'product_loader.dart';

class ProductService {
  final ApiClient api;

  ProductService(this.api);

  Future<Map<String, dynamic>> fetchAndParseProducts(
    List<ProductEntry> entries, {
    String? referer,
  }) async {
    final ids = entries.map((e) => e.id).toList();
    var finalReferer = referer;
    if (finalReferer == null || finalReferer.isEmpty) {
      final entryReferer = entries.firstWhere(
        (e) => e.referer != null,
        orElse: () => entries.first,
      );
      finalReferer = entryReferer.referer;
    }

    final response = await api.getProducts(
      ids,
      referer: finalReferer?.isEmpty ?? true ? null : finalReferer,
    );

    if (response.statusCode != 200) {
      throw Exception('Unexpected status code: ${response.statusCode}');
    }

    return parseProductPrices(response.data, requestIds: ids);
  }
}

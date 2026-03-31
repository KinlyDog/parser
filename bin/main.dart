import 'dart:convert';
import 'dart:io';

import 'package:apple_world/api_client.dart';
import 'package:apple_world/models.dart';
import 'package:apple_world/parser.dart';
import 'package:apple_world/utils/city.dart';

Future<void> main() async {
  final city = await getCityFromCookie();

  print('📍 Город: $city');
  print('========================\n');

  final authFile = File('config/auth.json');
  final authJson = jsonDecode(await authFile.readAsString());

  final cookie = authJson['cookie'];
  final csrf = authJson['csrfToken'];

  final api = ApiClient(cookie, csrf);

  // 📦 Загружаем товары
  final productsFile = File('config/products.json');
  final List productsJson = jsonDecode(await productsFile.readAsString());

  final products = productsJson.map((e) => Product.fromJson(e)).toList();

  // 🔁 Проходим по всем товарам
  for (final product in products) {
    try {
      final response = await api.getProduct(product.id, product.referer);

      if (response.statusCode == 200) {
        parseAndPrint(response.data);
      } else {
        print('Ошибка ${response.statusCode} для ${product.name}');
      }
    } catch (e) {
      print('Ошибка запроса: $e');
    }
  }
}

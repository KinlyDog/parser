import 'dart:convert';
import 'package:dio/dio.dart';

class ApiClient {
  final Dio dio;

  ApiClient(String cookie, String csrf)
      : dio = Dio(BaseOptions(
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
      'Accept': '*/*',
      'X-Requested-With': 'XMLHttpRequest',
      'Cookie': cookie,
      'X-CSRF-Token': csrf,
      'Origin': 'https://www.dns-shop.ru',
      'User-Agent':
      'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15',
    },
  )) {
    dio.options.validateStatus = (status) => true;
  }

  Future<Response> getProduct(String id, String referer) {
    return dio.post(
      'https://www.dns-shop.ru/ajax-state/product-buy/',
      data: {
        'data': jsonEncode({
          "type": "product-buy",
          "containers": [
            {
              "id": "as-$id",
              "data": {
                "id": id,
                "params": {"showOneClick": true, "isCard": true}
              }
            }
          ]
        })
      },
      options: Options(headers: {
        'Referer': referer,
      }),
    );
  }
}
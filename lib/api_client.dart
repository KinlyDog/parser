import 'dart:convert';
import 'package:dio/dio.dart';

class ApiClient {
  final Dio dio;

  ApiClient(String cookie, String csrf)
      : dio = Dio(BaseOptions(
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
      'Accept': '*/*',
      'Accept-Language': 'ru',
      'Cache-Control': 'max-age=0',
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

  Future<Response> getProducts(List<String> ids, {String? referer}) {
    final containers = ids.map((id) {
      // Важно: делаем id контейнера детерминированным, чтобы в ответе `states[i].id`
      // можно было однозначно сопоставить с запрошенным "человеческим" id.
      return {
        'id': 'as-$id',
        // В devtools/curl обычно отправляется как строка.
        'data': {'id': id},
      };
    }).toList();

    final payload = {
      'type': 'product-buy',
      'containers': containers,
    };

    // Важно: сервер ожидает form-urlencoded: data=<json>
    final body = 'data=${Uri.encodeQueryComponent(jsonEncode(payload))}';

    return dio.post(
      'https://www.dns-shop.ru/ajax-state/product-buy/',
      data: body,
      options: Options(
        contentType: Headers.formUrlEncodedContentType,
        headers: referer == null || referer.isEmpty
            ? null
            : {
                'Referer': referer,
              },
      ),
    );
  }
}
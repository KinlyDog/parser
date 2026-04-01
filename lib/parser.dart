import 'dart:convert';
import 'package:apple_world/utils/logger.dart';

typedef ParsedProduct = ({String name, num price});

/// Парсит ответ API и возвращает Map[id] = ParsedProduct
Map<String, ParsedProduct> parseProductPrices(
  dynamic data, {
  required List<String> requestIds,
}) {
  if (data is! Map) {
    throw FormatException('Unexpected response root type: ${data.runtimeType}');
  }

  final dataNode = data['data'];
  if (dataNode is! Map) {
    throw FormatException('Missing/invalid "data" node in response');
  }

  final states = dataNode['states'];
  final result = <String, ParsedProduct>{};

  if (states is List && states.isNotEmpty) {
    for (var i = 0; i < states.length; i++) {
      final parsed = _parseStateItem(states[i], i, requestIds);
      if (parsed != null) {
        result[parsed.key] = parsed.value;
      }
    }
  }

  if (result.isEmpty) {
    logger.warning('Unable to parse any product prices from response');
  }

  return result;
}

/// Разбирает отдельный элемент states и возвращает id + ParsedProduct
MapEntry<String, ParsedProduct>? _parseStateItem(
  dynamic stateItem,
  int index,
  List<String> requestIds,
) {
  if (stateItem is! Map) return null;

  final containerId = stateItem['id'] as String?;
  String? requestedId;
  if (containerId != null && containerId.startsWith('as-')) {
    requestedId = containerId.substring(3);
  }

  final productNode = stateItem['data'];
  final parsed = _tryParseProductFromNode(productNode);
  if (parsed == null) return null;

  final id =
      requestedId ?? (index < requestIds.length ? requestIds[index] : null);
  if (id == null || id.isEmpty) return null;

  return MapEntry(id, parsed);
}

/// Парсинг отдельного продукта из узла
ParsedProduct? _tryParseProductFromNode(dynamic node) {
  if (node is! Map) return null;

  final name = node['name'] as String?;
  if (name == null || name.isEmpty) return null;

  final priceData = node['price'] as Map?;
  if (priceData == null || !priceData.containsKey('current')) return null;

  final current = _parseNum(priceData['current'], 'price.current');
  final minPrice = priceData.containsKey('min')
      ? _parseNullableNum(priceData['min'], 'price.min')
      : null;

  final actualPrice = (minPrice != null && minPrice > 0) ? minPrice : current;

  return (name: name, price: actualPrice);
}

/// Парсинг обязательного числа
num _parseNum(dynamic value, String fieldName) {
  final parsed = _tryParseNum(value, fieldName);
  if (parsed == null) {
    throw FormatException('Missing or invalid numeric value for $fieldName');
  }
  return parsed;
}

/// Парсинг необязательного числа
num? _parseNullableNum(dynamic value, String fieldName) {
  return _tryParseNum(value, fieldName);
}

num? _tryParseNum(dynamic value, String fieldName) {
  if (value == null) return null;
  if (value is num) return value;
  if (value is String) {
    final normalized = value.replaceAll(',', '.');
    return num.tryParse(normalized);
  }
  return null;
}

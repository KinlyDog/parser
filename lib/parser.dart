Map<String, ({String name, num price})> parseProductPrices(
  dynamic data, {
  required List<String> requestIds,
}) {
  if (data is! Map) {
    throw FormatException('Unexpected response root type: ${data.runtimeType}');
  }

  final root = data;
  final dataNode = root['data'];
  if (dataNode is! Map) {
    throw FormatException('Missing/invalid "data" node in response');
  }

  // Основной (и фактический для DNS ajax-state) путь: data.states[].
  final states = dataNode['states'];
  final result = <String, ({String name, num price})>{};

  if (states is List && states.isNotEmpty) {
    for (var i = 0; i < states.length; i++) {
      final stateItem = states[i];
      if (stateItem is! Map) continue;

      String? requestedId;
      final containerId = stateItem['id'];
      if (containerId is String && containerId.startsWith('as-')) {
        requestedId = containerId.substring(3);
      }

      final productNode = stateItem['data'];
      if (productNode is! Map) continue;

      final parsed = _tryParseProductFromNode(productNode);
      if (parsed == null) continue;

      final id = requestedId ?? (i < requestIds.length ? requestIds[i] : null);
      if (id == null || id.isEmpty) continue;

      result[id] = (name: parsed.name, price: parsed.price);
    }

    if (result.isNotEmpty) return result;
  }

  if (result.isEmpty) {
    throw FormatException('Unable to parse product prices from response');
  }

  return result;
}

({String name, num price})? _tryParseProductFromNode(dynamic node) {
  if (node is! Map) return null;

  final name = node['name'];
  if (name is! String || name.isEmpty) return null;

  final priceData = node['price'];
  if (priceData is! Map) return null;

  if (!priceData.containsKey('current')) return null;
  final current = _parseNum(priceData['current'], 'price.current');

  num? min;
  if (priceData.containsKey('min')) {
    final rawMin = priceData['min'];
    if (rawMin != null) {
      min = _parseNum(rawMin, 'price.min');
    }
  }

  final actualPrice = (min != null && min > 0) ? min : current;
  return (name: name, price: actualPrice);
}

num _parseNum(dynamic value, String fieldName) {
  if (value == null) {
    throw FormatException('Missing required numeric field: $fieldName');
  }

  if (value is num) return value;

  if (value is String) {
    final normalized = value.replaceAll(',', '.');
    final parsed = num.tryParse(normalized);
    if (parsed != null) return parsed;
  }

  throw FormatException(
    'Invalid numeric value for $fieldName: ${value.runtimeType}=$value',
  );
}

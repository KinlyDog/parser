({String name, num price}) parseProductPrice(dynamic data) {
  if (data is! Map) {
    throw FormatException('Unexpected response root type: ${data.runtimeType}');
  }

  final root = data;
  final dataNode = root['data'];
  if (dataNode is! Map) {
    throw FormatException('Missing/invalid "data" node in response');
  }

  final states = dataNode['states'];
  if (states is! List || states.isEmpty) {
    throw FormatException('Missing/invalid "states" list in response');
  }

  final firstState = states.first;
  if (firstState is! Map) {
    throw FormatException('Unexpected state item type: ${firstState.runtimeType}');
  }

  final product = firstState['data'];
  if (product is! Map) {
    throw FormatException('Missing/invalid "data" product node in first state');
  }

  final name = product['name'];
  if (name is! String || name.isEmpty) {
    throw FormatException('Missing/invalid product "name"');
  }

  final priceData = product['price'];
  if (priceData is! Map) {
    throw FormatException('Missing/invalid "price" node');
  }

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

  throw FormatException('Invalid numeric value for $fieldName: ${value.runtimeType}=$value');
}

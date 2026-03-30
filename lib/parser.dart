void parseAndPrint(dynamic data) {
  try {
    final product = data['data']['states'][0]['data'];

    final name = product['name'];
    final priceData = product['price'];

    final current = priceData['current'];

    // ✅ проверяем, есть ли ключ min
    final hasMin = priceData.containsKey('min');
    final min = hasMin ? priceData['min'] : null;

    final actualPrice = (hasMin && min != null && min > 0) ? min : current;

    print('📱 $name');
    print('💰 Цена: $actualPrice ₽');
    print('------------------------');
  } catch (e) {
    print('Ошибка парсинга: $e');
  }
}

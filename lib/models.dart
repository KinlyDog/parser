class Product {
  final String id;
  final String name;
  final String referer;

  Product({
    required this.id,
    required this.name,
    required this.referer,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final name = json['name'];
    final referer = json['referer'];

    if (id is! String || id.isEmpty) {
      throw FormatException('Invalid product.id');
    }
    if (name is! String || name.isEmpty) {
      throw FormatException('Invalid product.name');
    }
    if (referer is! String || referer.isEmpty) {
      throw FormatException('Invalid product.referer');
    }

    return Product(
      id: id,
      name: name,
      referer: referer,
    );
  }
}
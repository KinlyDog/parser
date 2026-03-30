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
    return Product(
      id: json['id'],
      name: json['name'],
      referer: json['referer'],
    );
  }
}
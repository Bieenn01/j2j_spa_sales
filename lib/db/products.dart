class Product {
  final String name;
  final double price;

  Product({required this.name, required this.price});

  // Factory method to create a Product from Firestore data
  factory Product.fromMap(Map<String, dynamic> data) {
    return Product(
      name: data['name'] ?? '',
      price: data['price'] ?? 0.0,
    );
  }

  // Convert Product to a map for Firestore storage
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
    };
  }
}

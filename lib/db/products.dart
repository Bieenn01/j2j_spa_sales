import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  String id; // Firestore document ID
  late final String name;
  late final double price;

  Product({required this.name, required this.price, this.id = ''});

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
  
  factory Product.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Product(
      id: doc.id,
      name: data['name'],
      price: (data['price'] as num).toDouble(),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  String id; // Firestore document ID
  String name; // Product name
  double price; // Product price

  Product({required this.name, required this.price, this.id = ''});

  // Factory constructor to create a Product from a Firestore document snapshot
  factory Product.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Product(
      id: doc.id, // Automatically assigns the Firestore document ID
      name: data['name'] ?? '', // Default to an empty string if name is missing
      price: (data['price'] ?? 0).toDouble(), // Ensure price is a double
    );
  }

  // Factory constructor to create a Product from a map (non-Firestore use case)
  factory Product.fromMap(Map<String, dynamic> data, {String id = ''}) {
    return Product(
      id: id, // Optional ID assignment for non-Firestore use
      name: data['name'] ?? '', // Default to empty string if name is missing
      price: (data['price'] ?? 0).toDouble(), // Ensure price is a double
    );
  }

  // Convert Product to a map for Firestore storage
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'price': price,
    };
  }
}

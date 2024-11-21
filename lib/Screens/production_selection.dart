import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:j2j_spa_sales/db/products.dart';


class ProductSelectionScreen extends StatefulWidget {
  @override
  _ProductSelectionScreenState createState() => _ProductSelectionScreenState();
}

class _ProductSelectionScreenState extends State<ProductSelectionScreen> {
  // List of products that will be displayed on the UI
  final List<Product> productList = [
    Product(name: "Hifu Face", price: 2500),
    Product(name: "Hifu Body", price: 3000),
    Product(name: "Basic Facial", price: 350),
    Product(name: "Facial with Dia Peel", price: 499),
    Product(name: "BB Glow Facial", price: 499),
    Product(name: "Black Doll Facial", price: 999),
    Product(name: "Pico Laser Facial", price: 1399),
    Product(name: "Vampire/PRP Facial", price: 1500),
    Product(name: "Whole Body Massage 9am-11am/hr", price: 200),
    Product(name: "Whole Body Massage 11am-2pm/hr", price: 250),
    Product(name: "Whole Body Massage 2pm-6pm/hr", price: 350),
    Product(name: "Vintosa Add-on", price: 100),
    Product(name: "Hot Stone Add-on", price: 100),
    Product(name: "Earcandle Add-on", price: 100),
    Product(name: "Foot Massage 30 min", price: 150),
    Product(name: "Foot Massage 1 hour", price: 250),
    Product(name: "Foot Spa", price: 200),
    Product(name: "RF Face", price: 200),
    Product(name: "RF Back", price: 350),
    Product(name: "RF Arms", price: 350),
    Product(name: "RF Thigh", price: 400),
    Product(name: "RF Tummy", price: 500),
    Product(name: "10+2 RF Package", price: 12000),
    Product(name: "Muscle Stimul", price: 500),
    Product(name: "Manicure Regular", price: 80),
    Product(name: "Pedicure Regular", price: 85),
    Product(name: "Manicure Gel Polish", price: 199),
    Product(name: "Pedicure Gel Polish", price: 199),
    Product(name: "Eyelash Extension", price: 350),
    Product(name: "Soft Nail Ext. w/ Gel", price: 499),
    Product(name: "Upper Lip Laser", price: 200),
    Product(name: "Lower Lip Laser", price: 200),
    Product(name: "Under Arm Laser", price: 350),
    Product(name: "Brazilian Laser", price: 850),
    Product(name: "Beard", price: 399),
    Product(name: "Wart Removal (Face & Neck)", price: 1500),
  ];

  // Method to add the selected product to Firebase
  Future<void> addProductToFirebase(Product product) async {
    FirebaseFirestore.instance.collection('sales').add({
      'product_name': product.name,
      'price': product.price,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Select Products')),
      body: ListView.builder(
        itemCount: productList.length,
        itemBuilder: (context, index) {
          final product = productList[index];
          return Card(
            margin: EdgeInsets.all(8),
            child: ListTile(
              title: Text(product.name),
              trailing: Text('\$${product.price}'),
              onTap: () {
                // On tap, add product to Firebase
                addProductToFirebase(product);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${product.name} added to sales!')),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

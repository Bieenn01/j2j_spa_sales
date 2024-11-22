import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class TotalSalesScreen extends StatelessWidget {
  // Method to get total sales from Firebase
Future<Map<String, double>> getSalesData() async {
    double totalSales = 0.0;
    double todaySales = 0.0;

    String today =
        "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}";

    // Get all documents from the 'sales' collection
    QuerySnapshot snapshot =
        await FirebaseFirestore.instance.collection('sales').get();

    for (var doc in snapshot.docs) {
      // Get the list of products for this sale
      List<dynamic> products = doc['products'] ?? [];

      // Loop through the products array and sum up the prices
      double saleTotal = 0.0;
      for (var product in products) {
        double price = product['price'] ?? 0.0;
        saleTotal += price;

        // Check if this sale is from today
        if (product['date'] == today) {
          todaySales += price;
        }
      }

      // Add the total amount of this sale to the overall totalSales
      totalSales += saleTotal;
    }

    // Return the total sales and today's sales
    return {
      'totalSales': totalSales,
      'todaySales': todaySales,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Total Sales')),
      body:  FutureBuilder<Map<String, double>>(
        future: getSalesData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data == 0.0) {
            return Center(child: Text('No sales data available.'));
          }

          double totalSales = snapshot.data?['totalSales'] ?? 0.0;
          return Center(
            child: Text(
              'Total Sales: \$${totalSales.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          );
        },
      ),
    );
  }
}

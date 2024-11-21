import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class TotalSalesScreen extends StatelessWidget {
  // Method to get total sales from Firebase
  Future<double> getTotalSales() async {
    double totalSales = 0.0;
    QuerySnapshot snapshot =
        await FirebaseFirestore.instance.collection('sales').get();

    for (var doc in snapshot.docs) {
      totalSales += doc['price'] ?? 0.0;
    }

    return totalSales;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Total Sales')),
      body: FutureBuilder<double>(
        future: getTotalSales(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data == 0.0) {
            return Center(child: Text('No sales data available.'));
          }

          double totalSales = snapshot.data ?? 0.0;
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

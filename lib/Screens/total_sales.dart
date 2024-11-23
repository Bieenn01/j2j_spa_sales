import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class TotalSalesScreen extends StatelessWidget {
  // Method to get total sales for various time periods from Firebase
  Future<Map<String, double>> getSalesData() async {
    double totalSales = 0.0;
    double todaySales = 0.0;
    double last7DaysSales = 0.0;
    double last15DaysSales = 0.0;
    double last30DaysSales = 0.0;

    // Get today's date and other relevant date ranges
    String today =
        "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}";
    DateTime now = DateTime.now();
    DateTime sevenDaysAgo = now.subtract(Duration(days: 7));
    DateTime fifteenDaysAgo = now.subtract(Duration(days: 15));
    DateTime thirtyDaysAgo = now.subtract(Duration(days: 30));

    // Format the dates to match the Firestore date format
    String formattedSevenDaysAgo =
        "${sevenDaysAgo.year}-${sevenDaysAgo.month.toString().padLeft(2, '0')}-${sevenDaysAgo.day.toString().padLeft(2, '0')}";
    String formattedFifteenDaysAgo =
        "${fifteenDaysAgo.year}-${fifteenDaysAgo.month.toString().padLeft(2, '0')}-${fifteenDaysAgo.day.toString().padLeft(2, '0')}";
    String formattedThirtyDaysAgo =
        "${thirtyDaysAgo.year}-${thirtyDaysAgo.month.toString().padLeft(2, '0')}-${thirtyDaysAgo.day.toString().padLeft(2, '0')}";

    // Get all documents from the 'sales' collection
    QuerySnapshot snapshot =
        await FirebaseFirestore.instance.collection('sales').get();

    // Loop through each sale document
    for (var doc in snapshot.docs) {
      // Get the list of products for this sale
      List<dynamic> products = doc['products'] ?? [];
      double saleTotal = 0.0;

      // Loop through each product and calculate the sale total
      for (var product in products) {
        double price = product['price'] ?? 0.0;
        saleTotal += price;

        // Check if this sale is from today
        if (product['date'] == today) {
          todaySales += price;
        }

        // Check if this sale is within the last 7, 15, or 30 days
        if (product['date'] == formattedSevenDaysAgo) {
          last7DaysSales += price;
        }
        if (product['date'] == formattedFifteenDaysAgo) {
          last15DaysSales += price;
        }
        if (product['date'] == formattedThirtyDaysAgo) {
          last30DaysSales += price;
        }
      }

      // Add the total amount of this sale to the overall totalSales
      totalSales += saleTotal;
    }

    // Return the sales data for different periods
    return {
      'totalSales': totalSales,
      'todaySales': todaySales,
      'last7DaysSales': last7DaysSales,
      'last15DaysSales': last15DaysSales,
      'last30DaysSales': last30DaysSales,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Map<String, double>>(
        future: getSalesData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return Center(child: Text('No sales data available.'));
          }

          // Retrieve the sales data
          double totalSales = snapshot.data?['totalSales'] ?? 0.0;
          double todaySales = snapshot.data?['todaySales'] ?? 0.0;
          double last7DaysSales = snapshot.data?['last7DaysSales'] ?? 0.0;
          double last15DaysSales = snapshot.data?['last15DaysSales'] ?? 0.0;
          double last30DaysSales = snapshot.data?['last30DaysSales'] ?? 0.0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sales Overview',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 20),
                // Display total sales for different time periods
                _buildSalesTile('Total Sales', totalSales),
                _buildSalesTile('Today\'s Sales', todaySales),
                _buildSalesTile('Last 7 Days Sales', last7DaysSales),
                _buildSalesTile('Last 15 Days Sales', last15DaysSales),
                _buildSalesTile('Last 30 Days Sales', last30DaysSales),
              ],
            ),
          );
        },
      ),
    );
  }

  // Helper widget to display sales data for a given period
  Widget _buildSalesTile(String title, double amount) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              '\₱${amount.toStringAsFixed(2)}',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green),
            ),
          ],
        ),
      ),
    );
  }
}

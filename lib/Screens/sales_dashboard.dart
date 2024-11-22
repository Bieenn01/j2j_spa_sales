import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:j2j_spa_sales/Screens/production_selection.dart';


class DashboardScreen extends StatelessWidget {
  // Method to get sales data
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
      appBar: AppBar(
        title: Text('Dashboard'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sales Overview',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            // Dashboard Grid for metrics
            Expanded(
              child: FutureBuilder<Map<String, double>>(
                future: getSalesData(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData) {
                    return Center(child: Text('No sales data available.'));
                  }

                  var salesData = snapshot.data!;

                  return GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16.0,
                    mainAxisSpacing: 16.0,
                    children: [
                      // Sales Today Tile
                      DashboardTile(
                        title: 'Sales Today',
                        amount: Future.value(salesData['todaySales'] ?? 0.0),
                        icon: Icons.attach_money,
                        onTap: () {
                          // Navigate to TotalSalesScreen when tapped
                          Navigator.pushNamed(context, '/total_sales');
                        },
                      ),
                      // Total Sales Tile
                      DashboardTile(
                        title: 'Total Sales',
                        amount: Future.value(salesData['totalSales'] ?? 0.0),
                        icon: Icons.attach_money,
                        onTap: () {
                          // Navigate to TotalSalesScreen when tapped
                          Navigator.pushNamed(context, '/total_sales');
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class DashboardTile extends StatelessWidget {
  final String title;
  final Future<double> amount; // Accept Future<double> here
  final IconData icon;
  final VoidCallback onTap;

  const DashboardTile({
    required this.title,
    required this.amount,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 50,
                color: Colors.blue,
              ),
              SizedBox(height: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10),
              // Use FutureBuilder to handle the Future<double> data
              FutureBuilder<double>(
                future: amount, // This is where the Future<double> is passed
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  } else if (!snapshot.hasData) {
                    return Text('No data');
                  }

                  return Text(
                    '\$${snapshot.data!.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

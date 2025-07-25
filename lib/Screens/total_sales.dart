import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class TotalSalesScreen extends StatefulWidget {
  @override
  _TotalSalesScreenState createState() => _TotalSalesScreenState();
}

class _TotalSalesScreenState extends State<TotalSalesScreen> {
  DateTimeRange? selectedDateRange;

  Future<Map<String, double>> getSalesData({DateTimeRange? dateRange}) async {
    double totalSales = 0.0;
    double todaySales = 0.0;
    double rangeSales = 0.0;

    String todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

    QuerySnapshot snapshot =
        await FirebaseFirestore.instance.collection('sales').get();

    for (var doc in snapshot.docs) {
      var data = doc.data() as Map<String, dynamic>;
      var paymentDetails = data['payment_details'];
      var paymentType = paymentDetails['payment_type'];
      var totalAmount = data['total_amount'] ?? 0.0;
      var partialPaid = paymentDetails['partial_amount_paid'] ?? 0.0;
      var date = data['date'] ?? '';
      double saleTotal = 0.0;

      if (paymentType == 'Full') {
        saleTotal += totalAmount;
      } else if (paymentType == 'Partial') {
        saleTotal += partialPaid;
      }

      totalSales += saleTotal;

      // Check if the sale is for today
      if (date == todayDate) {
        todaySales += saleTotal;
      }

      // Calculate range sales if a date range is provided
      if (dateRange != null) {
        DateTime saleDate = DateTime.parse(date);
        if (saleDate.isAfter(dateRange.start.subtract(Duration(days: 1))) &&
            saleDate.isBefore(dateRange.end.add(Duration(days: 1)))) {
          rangeSales += saleTotal;
        }
      }
    }

    return {
      'totalSales': totalSales,
      'todaySales': todaySales,
      'rangeSales': rangeSales,
    };
  }

  Future<void> _pickDateRange() async {
    DateTimeRange? pickedRange = await showDateRangePicker(
      context: context,
      initialDateRange: selectedDateRange ??
          DateTimeRange(
            start: DateTime.now().subtract(Duration(days: 7)),
            end: DateTime.now(),
          ),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (pickedRange != null && pickedRange != selectedDateRange) {
      setState(() {
        selectedDateRange = pickedRange;
      });
    }
  }

Future<List<FlSpot>> _getMonthlySalesData() async {
    List<double> monthlySales =
        List.generate(12, (_) => 0.0); // Initialize with 12 months
    int currentYear = DateTime.now().year;

    QuerySnapshot snapshot =
        await FirebaseFirestore.instance.collection('sales').get();

    for (var doc in snapshot.docs) {
      var data = doc.data() as Map<String, dynamic>;
      var paymentDetails = data['payment_details'];
      var paymentType = paymentDetails['payment_type'];
      var totalAmount = data['total_amount'] ?? 0.0;
      var partialPaid = paymentDetails['partial_amount_paid'] ?? 0.0;
      var date = data['date'] ?? '';

      // Skip if the date field is invalid
      if (date.isEmpty) continue;

      DateTime saleDate = DateTime.tryParse(date) ??
          DateTime(1970); // Default to epoch on invalid parse
      if (saleDate.year != currentYear)
        continue; // Skip sales not in the current year

      double saleTotal = 0.0;
      if (paymentType == 'Full') {
        saleTotal += totalAmount;
      } else if (paymentType == 'Partial') {
        saleTotal += partialPaid;
      }

      int monthIndex =
          saleDate.month - 1; // Convert to zero-indexed for the list
      monthlySales[monthIndex] += saleTotal;
    }

    // Convert monthly sales to FlSpot for the chart
    List<FlSpot> spots = [];
    for (int i = 0; i < 12; i++) {
      spots.add(FlSpot(i.toDouble(), monthlySales[i]));
    }

    return spots;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Total Sales'),
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_today),
            onPressed: _pickDateRange,
          ),
        ],
      ),
      body: FutureBuilder<Map<String, double>>(
        future: getSalesData(dateRange: selectedDateRange),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return Center(child: Text('No sales data available.'));
          }

          double totalSales = snapshot.data?['totalSales'] ?? 0.0;
          double todaySales = snapshot.data?['todaySales'] ?? 0.0;
          double rangeSales = snapshot.data?['rangeSales'] ?? 0.0;

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
                _buildSalesTile('Total Sales', totalSales),
                _buildSalesTile('Today\'s Sales', todaySales),
                if (selectedDateRange != null)
                  Card(
                    color: Colors.yellow[100],
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.orange, width: 2),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.date_range,
                                color: Colors.orange,
                                size: 28,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Sales from ${DateFormat('MMMM d, yyyy').format(selectedDateRange!.start)} to ${DateFormat('MMMM d, yyyy').format(selectedDateRange!.end)}',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange[800],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            '₱${rangeSales.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                SizedBox(height: 30),
                FutureBuilder<List<FlSpot>>(
                  future: _getMonthlySalesData(),
                  builder: (context, chartSnapshot) {
                    if (chartSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    } else if (chartSnapshot.hasError) {
                      return Center(
                          child: Text('Error: ${chartSnapshot.error}'));
                    } else if (!chartSnapshot.hasData) {
                      return Center(child: Text('No monthly sales data.'));
                    }

                    return Card(
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Monthly Sales Analytics',
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 16),
                            AspectRatio(
                              aspectRatio: 1.7,
                              child: LineChart(
                                LineChartData(
                                  gridData: FlGridData(show: true),
                                  titlesData: FlTitlesData(show: true),
                                  borderData: FlBorderData(show: true),
                                  lineBarsData: [
                                    LineChartBarData(
                                      spots: chartSnapshot.data!,
                                      isCurved: true,
                                      gradient: LinearGradient(
                                        colors: [Colors.blue, Colors.purple],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      barWidth: 5,
                                      belowBarData: BarAreaData(
                                        show: true,
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.blue.withOpacity(0.3),
                                            Colors.purple.withOpacity(0.3)
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSalesTile(String label, double amount) {
    return Card(
      color: Colors.white,
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        title: Text(label),
        trailing: Text(
          '₱${amount.toStringAsFixed(2)}',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

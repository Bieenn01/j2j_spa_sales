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
  bool hasExpenses = false; // To determine if expenses exist

  // Function to fetch expenses data
  Future<List<Map<String, dynamic>>> getExpenseDetails() async {
    List<Map<String, dynamic>> expensesList = [];
    DateTime today = DateTime.now();
    String todayDate = DateFormat('yyyy-MM-dd').format(today);

    QuerySnapshot expenseSnapshot =
        await FirebaseFirestore.instance.collection('expenses').get();

    for (var doc in expenseSnapshot.docs) {
      var data = doc.data() as Map<String, dynamic>;
      var amount = data['amount'] ?? 0.0;
      var date = data['date'];

      // Handle Timestamp and String date fields
      DateTime? expenseDate;
      if (date is Timestamp) {
        expenseDate = date.toDate();
      } else if (date is String) {
        expenseDate = DateTime.tryParse(date);
      }

      if (expenseDate == null) continue;

      // Filter today's expenses
      if (DateFormat('yyyy-MM-dd').format(expenseDate) == todayDate) {
        expensesList.add(data);
      }
    }

    return expensesList;
  }

  Future<Map<String, double>> getSalesAndExpenseData(
      {DateTimeRange? dateRange}) async {
    double totalSales = 0.0;
    double todaySales = 0.0;
    double rangeSales = 0.0;
    double totalExpenses = 0.0;
    double todayExpenses = 0.0;
    double rangeExpenses = 0.0;

    DateTime today = DateTime.now();
    String todayDate = DateFormat('yyyy-MM-dd').format(today);

    // Fetch sales
    QuerySnapshot salesSnapshot =
        await FirebaseFirestore.instance.collection('sales').get();
    for (var doc in salesSnapshot.docs) {
      var data = doc.data() as Map<String, dynamic>;
      var paymentDetails = data['payment_details'];
      var paymentType = paymentDetails['payment_type'];
      var totalAmount = data['total_amount'] ?? 0.0;
      var partialPaid = paymentDetails['partial_amount_paid'] ?? 0.0;
      var date = data['date'];

      double saleTotal = 0.0;

      // Handle Timestamp and String date fields
      DateTime? saleDate;
      if (date is Timestamp) {
        saleDate = date.toDate();
      } else if (date is String) {
        saleDate = DateTime.tryParse(date);
      }

      if (saleDate == null) continue;

      if (paymentType == 'Full') {
        saleTotal += totalAmount;
      } else if (paymentType == 'Partial') {
        saleTotal += partialPaid;
      }

      totalSales += saleTotal;

      // Today's sales
      if (DateFormat('yyyy-MM-dd').format(saleDate) == todayDate) {
        todaySales += saleTotal;
      }

      // Range sales
      if (dateRange != null &&
          saleDate.isAfter(dateRange.start.subtract(Duration(days: 1))) &&
          saleDate.isBefore(dateRange.end.add(Duration(days: 1)))) {
        rangeSales += saleTotal;
      }
    }

    // Fetch expenses
    QuerySnapshot expenseSnapshot =
        await FirebaseFirestore.instance.collection('expenses').get();
    for (var doc in expenseSnapshot.docs) {
      var data = doc.data() as Map<String, dynamic>;
      var amount = data['amount'] ?? 0.0;
      var date = data['date'];

      // Handle Timestamp and String date fields
      DateTime? expenseDate;
      if (date is Timestamp) {
        expenseDate = date.toDate();
      } else if (date is String) {
        expenseDate = DateTime.tryParse(date);
      }

      if (expenseDate == null) continue;

      // Total expenses
      totalExpenses += amount;

      // Today's expenses
      if (DateFormat('yyyy-MM-dd').format(expenseDate) == todayDate) {
        todayExpenses += amount;
      }

      // Filter expenses for the selected range
      if (dateRange != null &&
          expenseDate.isAfter(dateRange.start.subtract(Duration(days: 1))) &&
          expenseDate.isBefore(dateRange.end.add(Duration(days: 1)))) {
        rangeExpenses += amount;
      }
    }

    // Adjust range sales to subtract range expenses
    if (dateRange != null) {
      rangeSales -= rangeExpenses;
    }

    // Determine if there are any expenses
    hasExpenses = totalExpenses > 0;

    // Return the calculated data
    return {
      'totalSales': totalSales - totalExpenses,
      'todaySales': todaySales - todayExpenses,
      'rangeSales': rangeSales,
      'totalExpenses': totalExpenses,
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

      DateTime saleDate = DateTime.tryParse(date) ?? DateTime(1970);
      if (saleDate.year != currentYear) continue;

      double saleTotal = 0.0;
      if (paymentType == 'Full') {
        saleTotal += totalAmount;
      } else if (paymentType == 'Partial') {
        saleTotal += partialPaid;
      }

      int monthIndex = saleDate.month - 1;
      monthlySales[monthIndex] += saleTotal;
    }

    List<FlSpot> spots = [];
    for (int i = 0; i < 12; i++) {
      spots.add(FlSpot(i.toDouble(), monthlySales[i]));
    }

    return spots;
  }

  // Function to display the expenses in a dialog
  Future<void> _showExpenses() async {
    List<Map<String, dynamic>> expenses = await getExpenseDetails();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Expense Details'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: expenses.map((expense) {
                return ListTile(
                  title: Text('₱${expense['amount']}'),
                  subtitle: Text(expense['name'] ?? 'No Description'),
                );
              }).toList(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(''),
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_today),
            onPressed: _pickDateRange,
          ),

        ],
      ),
      body: FutureBuilder<Map<String, double>>(
        future: getSalesAndExpenseData(dateRange: selectedDateRange),
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
          double totalExpenses = snapshot.data?['totalExpenses'] ?? 0.0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sales Overview ${hasExpenses ? "(Net)" : ""}',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 20),
                // _buildSalesTile(
                //     'Total Sales ${hasExpenses ? "(After Expenses)" : ""}',
                //     totalSales),
                _buildSalesTile(
                    'Today\'s Sales ${hasExpenses ? "(After Expenses)" : ""}',
                    todaySales),
                _buildSalesTile(
                  'Total Expenses',
                  totalExpenses,
                  trailingIcon: IconButton(
                    icon: Icon(Icons.receipt),
                    onPressed:
                        _showExpenses, // This will trigger the expense list
                  ),
                ),
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

  Widget _buildSalesTile(String label, double amount, {Widget? trailingIcon}) {
    return Card(
      color: Colors.white,
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            if (trailingIcon != null) trailingIcon,
          ],
        ),
        trailing: Text(
          '₱${amount.toStringAsFixed(2)}',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

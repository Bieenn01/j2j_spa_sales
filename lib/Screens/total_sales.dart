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
  List<String> todayExpenseNames = [];

Future<Map<String, dynamic>> getSalesAndExpensesData(
      {DateTimeRange? dateRange}) async {
    double totalSales = 0.0;
    double totalExpenses = 0.0;
    double todaySales = 0.0;
    double todayExpenses = 0.0;
    double rangeSales = 0.0;
    double rangeExpenses = 0.0;
    todayExpenseNames.clear(); // Reset the list of today's expense names
    List<double> todayExpenseAmounts =
        []; // List to store today's expense amounts

    DateTime todayDate =
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

    // Fetch sales data
    QuerySnapshot salesSnapshot =
        await FirebaseFirestore.instance.collection('sales').get();

    for (var doc in salesSnapshot.docs) {
      var data = doc.data() as Map<String, dynamic>;
      var paymentDetails = data['payment_details'];
      var paymentType = paymentDetails['payment_type'];
      var totalAmount = data['total_amount'] ?? 0.0;
      var partialPaid = paymentDetails['partial_amount_paid'] ?? 0.0;
      var timestamp = data['timestamp'] as Timestamp;
      var date = data['date'] ?? '';
      double saleTotal = 0.0;

      if (paymentType == 'Full') {
        saleTotal += totalAmount;
      } else if (paymentType == 'Partial') {
        saleTotal += partialPaid;
      }

      totalSales += saleTotal;

      DateTime saleDate = timestamp.toDate();

      if (saleDate.year == todayDate.year &&
          saleDate.month == todayDate.month &&
          saleDate.day == todayDate.day) {
        todaySales += saleTotal;
      }

      if (dateRange != null) {
        DateTime saleDate = DateTime.parse(date);
        if (saleDate.isAfter(dateRange.start.subtract(Duration(days: 1))) &&
            saleDate.isBefore(dateRange.end.add(Duration(days: 1)))) {
          rangeSales += saleTotal;
        }
      }
    }
    

    // Fetch expenses data
    QuerySnapshot expensesSnapshot =
        await FirebaseFirestore.instance.collection('expenses').get();

for (var doc in expensesSnapshot.docs) {
      var data = doc.data() as Map<String, dynamic>;
      var amount = data['amount'] ?? 0.0;
      var name = data['name'] ?? '';
      var timestamp = data['date']; // Don't cast to Timestamp immediately.

      totalExpenses += amount;

      // Initialize expenseDate with a default value
      DateTime expenseDate = DateTime.now();

      // Handle the timestamp conversion correctly
      if (timestamp is Timestamp) {
        expenseDate = timestamp.toDate(); // Convert Timestamp to DateTime
      } else if (timestamp is String) {
        try {
          expenseDate = DateTime.parse(timestamp); // Parse String to DateTime
        } catch (e) {
          print('Error parsing date string: $timestamp');
        }
      }

      // Check if the expense date matches today's date
      if (expenseDate.year == todayDate.year &&
          expenseDate.month == todayDate.month &&
          expenseDate.day == todayDate.day) {
        todayExpenses += amount;
        if (name.isNotEmpty) {
          todayExpenseNames.add(name);
          todayExpenseAmounts.add(amount); // Store the expense amount
        }
      }

      // If a date range is selected, check if the expense date is within the range
      if (dateRange != null) {
        if (expenseDate.isAfter(dateRange.start.subtract(Duration(days: 1))) &&
            expenseDate.isBefore(dateRange.end.add(Duration(days: 1)))) {
          rangeExpenses += amount;
        }
      }
    }


    todaySales -= todayExpenses;
    rangeSales -= rangeExpenses;

    return {
      'totalSales': totalSales,
      'totalExpenses': totalExpenses,
      'todaySales': todaySales,
      'rangeSales': rangeSales,
      'todayExpenseNames': todayExpenseNames,
      'todayExpenseAmounts':
          todayExpenseAmounts, // Return today's expense amounts
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(''),
        actions: [
          Text(
          'To view total sale on a specified date range',
          style: TextStyle(fontSize: 11),
          ),
          SizedBox(width: 3,),
          Icon(Icons.arrow_right_alt),
          IconButton(
            icon: Icon(Icons.calendar_today),
            onPressed: _pickDateRange,
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: getSalesAndExpensesData(dateRange: selectedDateRange),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return Center(child: Text('No sales or expenses data available.'));
          }

          double totalSales = snapshot.data?['totalSales'] ?? 0.0;
          double totalExpenses = snapshot.data?['totalExpenses'] ?? 0.0;
          double todaySales = snapshot.data?['todaySales'] ?? 0.0;
          double rangeSales = snapshot.data?['rangeSales'] ?? 0.0;
          double netSales = totalSales - totalExpenses;

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
                // _buildSalesTile('Total Sales', totalSales),
                // _buildSalesTile('Total Expenses', totalExpenses),
                _buildSalesTile('Net Sales', netSales),
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
                          SizedBox(height: 12),
                          // Row with two IconButtons for expenses and clients
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              IconButton(
                                icon:
                                    Icon(Icons.list_alt, color: Colors.orange),
                                onPressed: () async {
                                  // Fetch expenses data and filter based on the selected date range
                                  QuerySnapshot expensesSnapshot =
                                      await FirebaseFirestore.instance
                                          .collection('expenses')
                                          .get();
                                  List<Map<String, dynamic>> filteredExpenses =
                                      [];

                                  for (var doc in expensesSnapshot.docs) {
                                    var data =
                                        doc.data() as Map<String, dynamic>;
                                    var amount = data['amount'] ?? 0.0;
                                    var name = data['name'] ?? '';
                                    var timestamp = data['date'] as Timestamp;

                                    DateTime expenseDate = timestamp.toDate();

                                    // Check if the expense date falls within the selected date range
                                    if (expenseDate.isAfter(selectedDateRange!
                                            .start
                                            .subtract(Duration(days: 1))) &&
                                        expenseDate.isBefore(selectedDateRange!
                                            .end
                                            .add(Duration(days: 1)))) {
                                      filteredExpenses.add({
                                        'name': name,
                                        'amount': amount,
                                      });
                                    }
                                  }

                                  // Show the dialog with the filtered expenses
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: Text(
                                          "Expenses for Selected Date Range"),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: filteredExpenses
                                            .map<Widget>((expense) {
                                          return Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(expense['name']),
                                              Text(
                                                '₱${expense['amount'].toStringAsFixed(2)}',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                            ],
                                          );
                                        }).toList(),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                          child: Text('Close'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                              IconButton(
                                icon: Icon(Icons.person, color: Colors.orange),
                                onPressed: () async {
                                  // Fetch the sales data for clients
                                  QuerySnapshot salesSnapshot =
                                      await FirebaseFirestore.instance
                                          .collection('sales')
                                          .get();
                                  List<String> clients = [];

                                  for (var doc in salesSnapshot.docs) {
                                    var data =
                                        doc.data() as Map<String, dynamic>;
                                    var timestamp =
                                        data['timestamp'] as Timestamp;
                                    var clientName = data['client_name'] ?? '';

                                    DateTime saleDate = timestamp.toDate();

                                    if (saleDate.isAfter(selectedDateRange!
                                            .start
                                            .subtract(Duration(days: 1))) &&
                                        saleDate.isBefore(selectedDateRange!.end
                                            .add(Duration(days: 1)))) {
                                      if (clientName.isNotEmpty &&
                                          !clients.contains(clientName)) {
                                        clients.add(clientName);
                                      }
                                    }
                                  }

                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: Text(
                                          "Clients Who Availed the Product"),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: clients.map<Widget>((client) {
                                          return Text(client);
                                        }).toList(),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                          child: Text('Close'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                SizedBox(height: 30),
                Text(
                  'Sales vs Expenses Chart',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 20),
                AspectRatio(
                  aspectRatio: 1.5,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceEvenly,
                      barGroups: [
                        BarChartGroupData(
                          x: 0,
                          barRods: [
                            BarChartRodData(
                              toY: totalSales,
                              color: Colors.green,
                              width: 15,
                            ),
                          ],
                          showingTooltipIndicators: [0],
                        ),
                        BarChartGroupData(
                          x: 1,
                          barRods: [
                            BarChartRodData(
                              toY: totalExpenses,
                              color: Colors.red,
                              width: 15,
                            ),
                          ],
                          showingTooltipIndicators: [0],
                        ),
                      ],
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: true),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              switch (value.toInt()) {
                                case 0:
                                  return Text('Sales');
                                case 1:
                                  return Text('Expenses');
                                default:
                                  return Text('');
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
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
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '₱${amount.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (label == "Today's Sales") // Add IconButton for today's expenses
              // Fetch the data and show today's expense names and amounts
              IconButton(
                icon: Icon(Icons.list_alt),
                onPressed: () async {
                  // Fetch the data and show today's expense names and amounts
                  var data = await getSalesAndExpensesData(
                      dateRange: selectedDateRange);

                  // Create a list of expense names and amounts
                  List<Map<String, dynamic>> todayExpensesData = [];
                  for (int i = 0; i < data['todayExpenseNames'].length; i++) {
                    todayExpensesData.add({
                      'name': data['todayExpenseNames'][i],
                      'amount': data['todayExpenseAmounts'][i],
                    });
                  }

                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text("Today's Expenses"),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: todayExpensesData.map<Widget>((expense) {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(expense['name']),
                              Text(
                                '₱${expense['amount'].toStringAsFixed(2)}',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text('Close'),
                        ),
                      ],
                    ),
                  );
                },
              ),

          ],
        ),
      ),
    );
  }
}

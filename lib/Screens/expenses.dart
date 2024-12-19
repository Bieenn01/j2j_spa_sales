import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Import for date formatting

class ExpensesScreen extends StatefulWidget {
  @override
  _ExpensesScreenState createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  final TextEditingController _expenseNameController = TextEditingController();
  final TextEditingController _expenseAmountController =
      TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;

  Future<void> _addExpense() async {
    String name = _expenseNameController.text.trim();
    double? amount = double.tryParse(_expenseAmountController.text.trim());

    if (name.isNotEmpty && amount != null && amount > 0) {
      await FirebaseFirestore.instance.collection('expenses').add({
        'name': name,
        'amount': amount,
        'date': Timestamp.now(),
      });

      _expenseNameController.clear();
      _expenseAmountController.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid input.')),
      );
    }
  }

  Future<void> _selectDateRange(BuildContext context) async {
    DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : DateTimeRange(start: DateTime.now(), end: DateTime.now()),
    );
    if (picked != null && picked.start != null && picked.end != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Expenses')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                TextField(
                  controller: _expenseNameController,
                  decoration: InputDecoration(
                    labelText: 'Expense Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 10),
                TextField(
                  controller: _expenseAmountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Amount',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Space out the buttons evenly
                  children: [
                    IconButton(
                      icon: Row(
                        mainAxisSize: MainAxisSize.min, // Make the row just as wide as the icon and text
                        children: [
                          Icon(Icons.add), // The add icon for Add Expense
                          SizedBox(width: 8), // Spacing between icon and text
                          Text('Add Expense'), // The label
                        ],
                      ),
                      onPressed: _addExpense,
                    ),
                    IconButton(
                      icon: Row(
                        mainAxisSize: MainAxisSize.min, // Make the row just as wide as the icon and text
                        children: [
                          Icon(Icons.date_range), // The date range icon
                          SizedBox(width: 8), // Spacing between icon and text
                          Text('Select Date Range'), // The label
                        ],
                      ),
                      onPressed: () => _selectDateRange(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('expenses')
                  // Adjust the start and end dates to include the full day range
                  .where('date', isGreaterThanOrEqualTo: _startDate != null
                      ? Timestamp.fromDate(DateTime(
                          _startDate!.year, _startDate!.month, _startDate!.day, 0, 0)) // Start of day
                      : null)
                  .where('date', isLessThanOrEqualTo: _endDate != null
                      ? Timestamp.fromDate(DateTime(
                          _endDate!.year, _endDate!.month, _endDate!.day, 23, 59, 59)) // End of day
                      : null)
                  .orderBy('date', descending: true) // Order by date
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  String message = _startDate != null && _endDate != null
                      ? 'No expenses found from ${DateFormat('MMM dd, yyyy').format(_startDate!)} to ${DateFormat('MMM dd, yyyy').format(_endDate!)}'
                      : 'No expenses found.';
                  return Center(child: Text(message));
                }

                double totalExpenses = snapshot.data!.docs.fold(
                  0.0,
                  (sum, doc) =>
                      sum + (doc.data() as Map<String, dynamic>)['amount'],
                );

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'Total Expenses: ₱${totalExpenses.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        children: snapshot.data!.docs.map((doc) {
                          var data = doc.data() as Map<String, dynamic>;
                          Timestamp timestamp = data['date'] ?? Timestamp.now();
                          DateTime date = timestamp.toDate();
                          String formattedDate =
                              DateFormat('MMM dd, yyyy').format(date);

                          return ListTile(
                            title: Text(data['name']),
                            subtitle: Text(
                              '₱${data['amount'].toStringAsFixed(2)} - $formattedDate',
                            ),
                            trailing: IconButton(
                              icon: Icon(Icons.delete),
                              onPressed: () {
                                FirebaseFirestore.instance
                                    .collection('expenses')
                                    .doc(doc.id)
                                    .delete();
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

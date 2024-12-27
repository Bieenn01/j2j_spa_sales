import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // To format the selected date

class ExpensesScreen extends StatefulWidget {
  @override
  _ExpensesScreenState createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  final TextEditingController _productController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  DateTime? _selectedDate; // Variable to store the selected date

  Future<void> _addExpense() async {
    final String product = _productController.text.trim();
    final String amountText = _amountController.text.trim();

    if (product.isEmpty || amountText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter both product and amount.')),
      );
      return;
    }

    double? amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a valid amount.')),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('expenses').add({
        'name': product,
        'amount': amount,
        'date': Timestamp.now(), // Store the date as a Firestore Timestamp
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Expense added successfully!')),
      );

      // Clear input fields
      _productController.clear();
      _amountController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding expense: $e')),
      );
    }
  }

  Future<void> _deleteExpense(String docId) async {
    try {
      await FirebaseFirestore.instance
          .collection('expenses')
          .doc(docId)
          .delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Expense deleted successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting expense: $e')),
      );
    }
  }

  // Function to show the date picker and set the selected date
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  // Function to get today's start and end timestamp for default filtering
  Timestamp _getStartOfDay() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    return Timestamp.fromDate(startOfDay);
  }

  Timestamp _getEndOfDay() {
    final now = DateTime.now();
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
    return Timestamp.fromDate(endOfDay);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Expenses'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _productController,
              decoration: InputDecoration(labelText: 'Product'),
            ),
            TextField(
              controller: _amountController,
              decoration: InputDecoration(labelText: 'Amount'),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 20),

            // Row for Add Expense and Select Date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: _addExpense,
                  child: Text('Add Expense'),
                ),
                Row(
                  children: [
                    Text(
                      _selectedDate == null
                          ? 'Select Date' // When no date is selected
                          : DateFormat('MM/dd/yyyy').format(
                              _selectedDate!), // Format the selected date
                      style: TextStyle(fontSize: 16),
                    ),
                    IconButton(
                      icon: Icon(Icons.calendar_today),
                      onPressed: () => _selectDate(context),
                      tooltip: 'Select Date',
                    ),
                  ],
                ),
              ],
            ),

            SizedBox(height: 20),

            // Display the expenses based on the selected date or default to today
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('expenses')
                    .where('date',
                        isGreaterThanOrEqualTo: _selectedDate != null
                            ? Timestamp.fromDate(DateTime(
                                _selectedDate!.year,
                                _selectedDate!.month,
                                _selectedDate!.day,
                              ))
                            : _getStartOfDay()) // Filter based on selected date or today
                    .where('date',
                        isLessThanOrEqualTo: _selectedDate != null
                            ? Timestamp.fromDate(DateTime(
                                _selectedDate!.year,
                                _selectedDate!.month,
                                _selectedDate!.day,
                                23,
                                59,
                                59,
                              ))
                            : _getEndOfDay()) // Filter based on selected date or today
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(child: CircularProgressIndicator());
                  }

                  final expenses = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: expenses.length,
                    itemBuilder: (context, index) {
                      final expense = expenses[index];
                      final data = expense.data() as Map<String, dynamic>;
                      final docId = expense.id;

                      return ListTile(
                        title: Text(data['name']),
                        subtitle: Text(
                          'Date: ${DateFormat('MM/dd/yyyy hh:mm a').format(DateTime.fromMillisecondsSinceEpoch(data['date'].seconds * 1000))}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '₱${data['amount'].toStringAsFixed(2)}',
                              style: TextStyle(fontSize: 16),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                _deleteExpense(docId);
                              },
                            ),
                          ],
                        ),
                      );
                    },
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

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // For formatting the date

class PaymentDetailsScreen extends StatefulWidget {
  @override
  _PaymentDetailsScreenState createState() => _PaymentDetailsScreenState();
}

class _PaymentDetailsScreenState extends State<PaymentDetailsScreen> {
  TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<String> clientNames = []; // List to store client names for autocomplete

  Future<void> _fetchClientNames() async {
    var snapshot = await FirebaseFirestore.instance.collection('sales').get();
    setState(() {
      clientNames = snapshot.docs
          .map((doc) =>
              (doc.data() as Map<String, dynamic>)['client_name'] as String)
          .toSet()
          .toList()
        ..sort();
    });
  }

  Future<QuerySnapshot> _searchPayments() {
    if (_searchQuery.isEmpty) {
      return FirebaseFirestore.instance.collection('sales').limit(3).get();
    } else {
      return FirebaseFirestore.instance
          .collection('sales')
          .where('client_name', isEqualTo: _searchQuery)
          .get();
    }
  }

  String formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'No date';
    return DateFormat('MM/dd/yyyy').format(timestamp.toDate());
  }

  Future<void> _archivePayment(
      String docId, Map<String, dynamic> paymentData) async {
    try {
      // Move the document to the "archive" collection
      await FirebaseFirestore.instance
          .collection('archive')
          .doc(docId)
          .set(paymentData);

      // Delete the document from the "sales" collection
      await FirebaseFirestore.instance.collection('sales').doc(docId).delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment archived successfully.')),
      );

      setState(() {}); // Refresh the UI
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error archiving payment: $e')),
      );
    }
  }

  void _showArchiveConfirmation(
      BuildContext context, String docId, Map<String, dynamic> paymentData) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Archive Payment'),
          content: Text('Are you sure you want to archive this payment?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                _archivePayment(docId, paymentData);
              },
              child: Text('Archive'),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _fetchClientNames();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Payment Details'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Autocomplete<String>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text.isEmpty) {
                  return const Iterable<String>.empty();
                }
                return clientNames.where((clientName) => clientName
                    .toLowerCase()
                    .contains(textEditingValue.text.toLowerCase()));
              },
              onSelected: (String selectedClient) {
                setState(() {
                  _searchQuery = selectedClient;
                });
              },
              fieldViewBuilder:
                  (context, controller, focusNode, onFieldSubmitted) {
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    labelText: 'Search by Client Name',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: FutureBuilder<QuerySnapshot>(
              future: _searchPayments(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('No data found.'));
                }

                var paymentDetailsList = snapshot.data!.docs.map((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  return {
                    'id': doc.id,
                    'client_name': data['client_name'],
                    'payment_type': data['payment_details']['payment_type'],
                    'total_amount': data['total_amount'],
                    'partial_amount_paid': data['payment_details']
                        ['partial_amount_paid'],
                    'remaining_balance': data['payment_details']
                        ['remaining_balance'],
                    'payment_method': data['payment_details']['payment_method'],
                    'products': data['products'],
                    'date': data['date'],
                  };
                }).toList();

                return ListView.builder(
                  itemCount: paymentDetailsList.length,
                  itemBuilder: (context, index) {
                    var paymentDetails = paymentDetailsList[index];
                    var clientName = paymentDetails['client_name'];
                    var paymentType = paymentDetails['payment_type'];
                    var totalAmount = paymentDetails['total_amount'];
                    var partialAmount = paymentDetails['partial_amount_paid'];
                    var remainingBalance = paymentDetails['remaining_balance'];
                    var paymentMethod = paymentDetails['payment_method'];
                    var docId = paymentDetails['id'];
                    var products = paymentDetails['products'];
                    var paymentDate = paymentDetails['date'].toString();
                    var formattedDate =
                        paymentDate != null ? paymentDate : 'No date';

                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      child: ListTile(
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              clientName,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.blue,
                              ),
                            ),
                            SizedBox(width: 10),
                            Text(
                              formattedDate,
                              style: TextStyle(
                                fontStyle: FontStyle.italic,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Payment Type: $paymentType'),
                            if (paymentType == 'Partial') ...[
                              Text('Payment Method: $paymentMethod'),
                              Text(
                                'Partial Amount Paid: ₱${partialAmount.toStringAsFixed(2)}',
                                style: TextStyle(color: Colors.green),
                              ),
                              Text(
                                'Remaining Balance: ₱${remainingBalance.toStringAsFixed(2)}',
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                            if (paymentType == 'Full') ...[
                              Text(
                                'Total Amount Paid: ₱${totalAmount.toStringAsFixed(2)}',
                                style: TextStyle(color: Colors.green),
                              ),
                            ],
                            if (products.isNotEmpty) ...[
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  'Products Purchased:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.blue,
                                  ),
                                ),
                              ),
                              ExpansionTile(
                                title: Text('${products.length} Products'),
                                children: products.map<Widget>((product) {
                                  return ListTile(
                                    title: Text(
                                      product.toString(),
                                      style: TextStyle(
                                        fontSize: 12,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            (paymentType == 'Full' || remainingBalance == 0)
                                ? Icon(
                                    Icons.check,
                                    color: Colors.green,
                                  )
                                : IconButton(
                                    icon: Icon(Icons.payment),
                                    onPressed: () {
                                      _showPaymentDialog(
                                          context, docId, remainingBalance);
                                    },
                                  ),
                            IconButton(
                              icon: Icon(Icons.archive),
                              onPressed: (paymentType == 'Full' ||
                                      remainingBalance == 0)
                                  ? () {
                                      _showArchiveConfirmation(
                                          context, docId, paymentDetails);
                                    }
                                  : null, // Button is disabled if the remaining balance is not zero
                            ),
                          ],
                        ),

                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showPaymentDialog(
      BuildContext context, String docId, double remainingBalance) async {
    TextEditingController paymentController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Pay Remaining Balance'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: paymentController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Enter Payment Amount (₱)',
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Remaining Balance: ₱${remainingBalance.toStringAsFixed(2)}',
                style: TextStyle(color: Colors.red),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                double paymentAmount =
                    double.tryParse(paymentController.text) ?? 0.0;
                if (paymentAmount <= 0 || paymentAmount > remainingBalance) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Invalid payment amount.'),
                    ),
                  );
                  return;
                }

                await FirebaseFirestore.instance
                    .collection('sales')
                    .doc(docId)
                    .update({
                  'payment_details.partial_amount_paid':
                      FieldValue.increment(paymentAmount),
                  'payment_details.remaining_balance':
                      remainingBalance - paymentAmount,
                });

                if (remainingBalance - paymentAmount == 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Payment completed!'),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Partial payment completed!'),
                    ),
                  );
                }

                Navigator.of(context).pop();
              },
              child: Text('Pay'),
            ),
          ],
        );
      },
    );
  }
}

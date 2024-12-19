import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:j2j_spa_sales/db/products.dart';

class ProductSelectionScreen extends StatefulWidget {
  @override
  _ProductSelectionScreenState createState() => _ProductSelectionScreenState();
}

class _ProductSelectionScreenState extends State<ProductSelectionScreen> {
  List<Product> productList = [];
  List<Product> filteredProductList = [];
  Set<Product> selectedProducts = Set();
  TextEditingController searchController = TextEditingController();

  TextEditingController clientNameController = TextEditingController();
  String paymentType = 'Full';

  @override
  void initState() {
    super.initState();
    searchController.addListener(_filterProducts);
    _loadProducts();
  }

  @override
  void dispose() {
    searchController.dispose();
    clientNameController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    QuerySnapshot<Map<String, dynamic>> snapshot =
        await FirebaseFirestore.instance.collection('products').get();
    setState(() {
      productList = snapshot.docs.map((doc) {
        return Product.fromFirestore(doc);
      }).toList();
      filteredProductList = List.from(productList);
    });
  }

  void _filterProducts() {
    setState(() {
      filteredProductList = productList
          .where((product) => product.name
              .toLowerCase()
              .contains(searchController.text.toLowerCase()))
          .toList();
    });
  }



Future<void> _showPaymentDialog() async {
    String localPaymentType =
        paymentType; // Local variable to manage dialog state
    String paymentMethod =
        ""; // To track the payment method for Partial Payment
    TextEditingController partialPaymentController = TextEditingController();
    double totalAmount = selectedProducts.fold(
        0.0, (sum, product) => sum + product.price); // Calculate total amount

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Complete Sale'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: clientNameController,
                      decoration: InputDecoration(labelText: 'Client Name'),
                    ),
                    Row(
                      children: [
                        Text('Payment Type:'),
                        Radio<String>(
                          value: 'Full',
                          groupValue: localPaymentType,
                          onChanged: (String? value) {
                            setDialogState(() {
                              localPaymentType = value!;
                            });
                          },
                        ),
                        Text('Full'),
                        Radio<String>(
                          value: 'Partial',
                          groupValue: localPaymentType,
                          onChanged: (String? value) {
                            setDialogState(() {
                              localPaymentType = value!;
                            });
                          },
                        ),
                        Text('Partial'),
                      ],
                    ),
                    if (localPaymentType == 'Partial')
                      Column(
                        children: [
                          DropdownButtonFormField<String>(
                            decoration:
                                InputDecoration(labelText: 'Payment Method'),
                            value: paymentMethod.isEmpty ? null : paymentMethod,
                            items: ["Gcash", "Cash", "Check"]
                                .map((method) => DropdownMenuItem(
                                      value: method,
                                      child: Text(method),
                                    ))
                                .toList(),
                            onChanged: (String? value) {
                              setDialogState(() {
                                paymentMethod = value!;
                              });
                            },
                          ),
                          TextField(
                            controller: partialPaymentController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                                labelText: 'Partial Payment Amount'),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    String clientName = clientNameController.text.trim();

                    // Validation
                    if (clientName.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Please enter client name.')),
                      );
                      return;
                    }

                    if (selectedProducts.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('No products selected.')),
                      );
                      return;
                    }

                    double partialPayment = 0.0;
                    if (localPaymentType == 'Partial') {
                      if (paymentMethod.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('Please select a payment method.')),
                        );
                        return;
                      }

                      partialPayment = double.tryParse(
                              partialPaymentController.text.trim()) ??
                          0.0;

                      if (partialPayment <= 0 || partialPayment > totalAmount) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  'Partial payment must be greater than 0 and less than or equal to the total amount.')),
                        );
                        return;
                      }
                    }

                    // Save to Firestore
                    setState(() {
                      paymentType = localPaymentType; // Update parent state
                    });

                    await addProductsToFirebase(
                      selectedProducts,
                      clientName,
                      paymentType,
                      partialPayment: partialPayment,
                      remainingBalance: totalAmount - partialPayment,
                      paymentMethod: paymentMethod,
                    );

                    Navigator.of(context).pop();
                  },
                  child: Text('Complete Sale'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> addProductsToFirebase(
    Set<Product> selectedProducts,
    String clientName,
    String paymentType, {
    double partialPayment = 0.0,
    double remainingBalance = 0.0,
    String paymentMethod = '',
  }) async {
    DateTime now = DateTime.now();
    String today =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    DocumentReference salesRef =
        FirebaseFirestore.instance.collection('sales').doc();

    List<Map<String, dynamic>> productDetails = selectedProducts.map((product) {
      return {
        'product_name': product.name,
        'price': product.price,
        'date': today,
      };
    }).toList();

    try {
      Map<String, dynamic> paymentDetails = {
        'payment_type': paymentType,
        'payment_method': paymentMethod,
      };

      if (paymentType == 'Partial') {
        paymentDetails['partial_amount_paid'] = partialPayment;
        paymentDetails['remaining_balance'] = remainingBalance;
      }

      await salesRef.set({
        'products': productDetails,
        'total_amount':
            selectedProducts.fold(0.0, (sum, product) => sum + product.price),
        'timestamp': FieldValue.serverTimestamp(),
        'date': today,
        'client_name': clientName,
        'payment_details': paymentDetails,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sale completed with $clientName!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add products: $e')),
      );
    }

    setState(() {
      selectedProducts.clear();
    });
  }


  Future<void> _sendSelectedProductsToFirebase() async {
    _showPaymentDialog();
  }

  void _clearSelectedProducts() {
    setState(() {
      selectedProducts.clear();
    });
  }

   void _showProductDialog({Product? product}) {
    final nameController = TextEditingController(text: product?.name ?? '');
    final priceController =
        TextEditingController(text: product?.price.toString() ?? '');
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(product == null ? 'Add Product' : 'Update Product'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: 'Product Name'),
              ),
              TextField(
                controller: priceController,
                decoration: InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
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
                final name = nameController.text.trim();
                final price = double.tryParse(priceController.text.trim()) ?? 0;
                if (name.isNotEmpty && price > 0) {
                  if (product == null) {
                    await _addProduct(name, price);
                  } else {
                    product.name = name;
                    product.price = price;
                    await _updateProduct(product);
                  }
                  Navigator.of(context).pop();
                }
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addProduct(String name, double price) async {
    final newProduct = Product(name: name, price: price);
    final docRef = await FirebaseFirestore.instance
        .collection('products')
        .add(newProduct.toFirestore());
    newProduct.id = docRef.id;
    setState(() {
      productList.add(newProduct);
      filteredProductList = List.from(productList);
    });
  }

  Future<void> _updateProduct(Product product) async {
    if (product.id.isNotEmpty) {
      await FirebaseFirestore.instance
          .collection('products')
          .doc(product.id)
          .update(product.toFirestore());
      setState(() {
        final index = productList.indexWhere((p) => p.id == product.id);
        if (index != -1) {
          productList[index] = product;
          filteredProductList = List.from(productList);
        }
      });
    }
  }

  Future<void> _deleteProduct(Product product) async {
    if (product.id.isNotEmpty) {
      await FirebaseFirestore.instance
          .collection('products')
          .doc(product.id)
          .delete();
      setState(() {
        productList.remove(product);
        filteredProductList = List.from(productList);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Products'),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(kToolbarHeight),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      labelText: 'Search Products',
                      hintText: 'Enter product name...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: CircleAvatar(
                    backgroundColor:
                        Colors.green, // Set the circular background to green
                    child: Icon(
                      Icons.add,
                      color: Colors.white, // Set the icon color to white
                    ),
                  ),
                  onPressed: () => _showProductDialog(),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: filteredProductList.isEmpty
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: filteredProductList.length,
                    itemBuilder: (context, index) {
                      final product = filteredProductList[index];
                      return Card(
                        margin: EdgeInsets.all(8),
                        child: ListTile(
                          leading: Checkbox(
                            value: selectedProducts.contains(product),
                            onChanged: (bool? value) {
                              setState(() {
                                if (value == true) {
                                  selectedProducts.add(product);
                                } else {
                                  selectedProducts.remove(product);
                                }
                              });
                            },
                          ),
                          title: Text(product.name),
                          subtitle: Text('₱${product.price}'),
                          trailing: PopupMenuButton(
                            onSelected: (value) {
                              if (value == 'edit') {
                                _showProductDialog(product: product);
                              } else if (value == 'delete') {
                                _deleteProduct(product);
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'edit',
                                child: Text('Edit'),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Text('Delete'),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Divider(),
          if (selectedProducts.isNotEmpty)
            Expanded(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'Selected Products (${selectedProducts.length}):',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      children: selectedProducts.map((product) {
                        return ListTile(
                          title: Text(product.name),
                          subtitle: Text('₱${product.price}'),
                          trailing: IconButton(
                            icon: Icon(Icons.remove_circle, color: Colors.red),
                            onPressed: () {
                              setState(() {
                                selectedProducts.remove(product);
                              });
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: _clearSelectedProducts,
                          child: Text('Clear All'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: EdgeInsets.symmetric(
                                vertical: 12, horizontal: 20),
                          ),
                        ),
                        ElevatedButton.icon(
                          icon: Icon(Icons.cloud_upload),
                          label: Text('Complete'),
                          onPressed: _sendSelectedProductsToFirebase,
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                                vertical: 12, horizontal: 20),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

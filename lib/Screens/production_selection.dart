import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:j2j_spa_sales/db/products.dart';

class ProductSelectionScreen extends StatefulWidget {
  @override
  _ProductSelectionScreenState createState() => _ProductSelectionScreenState();
}

class _ProductSelectionScreenState extends State<ProductSelectionScreen> {
  // List of all products
  final List<Product> productList = [
    Product(name: "Hifu Face", price: 2500),
    Product(name: "Hifu Body", price: 3000),
    Product(name: "Basic Facial", price: 350),
    Product(name: "Facial with Dia Peel", price: 499),
    Product(name: "BB Glow Facial", price: 499),
    Product(name: "Black Doll Facial", price: 999),
    Product(name: "Pico Laser Facial", price: 1399),
    Product(name: "Vampire/PRP Facial", price: 1500),
    Product(name: "Whole Body Massage 9am-11am/hr", price: 200),
    Product(name: "Whole Body Massage 11am-2pm/hr", price: 250),
    Product(name: "Whole Body Massage 2pm-6pm/hr", price: 350),
    Product(name: "Vintosa Add-on", price: 100),
    Product(name: "Hot Stone Add-on", price: 100),
    Product(name: "Earcandle Add-on", price: 100),
    Product(name: "Foot Massage 30 min", price: 150),
    Product(name: "Foot Massage 1 hour", price: 250),
    Product(name: "Foot Spa", price: 200),
    Product(name: "RF Face", price: 200),
    Product(name: "RF Back", price: 350),
    Product(name: "RF Arms", price: 350),
    Product(name: "RF Thigh", price: 400),
    Product(name: "RF Tummy", price: 500),
    Product(name: "10+2 RF Package", price: 12000),
    Product(name: "Muscle Stimul", price: 500),
    Product(name: "Manicure Regular", price: 80),
    Product(name: "Pedicure Regular", price: 85),
    Product(name: "Manicure Gel Polish", price: 199),
    Product(name: "Pedicure Gel Polish", price: 199),
    Product(name: "Eyelash Extension", price: 350),
    Product(name: "Soft Nail Ext. w/ Gel", price: 499),
    Product(name: "Upper Lip Laser", price: 200),
    Product(name: "Lower Lip Laser", price: 200),
    Product(name: "Under Arm Laser", price: 350),
    Product(name: "Brazilian Laser", price: 850),
    Product(name: "Beard", price: 399),
    Product(name: "Wart Removal (Face & Neck)", price: 1500),
  ];

  // List of filtered products (based on search query)
  List<Product> filteredProductList = [];

  // Set of selected products
  Set<Product> selectedProducts = Set();

  // Controller for the search bar
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize filteredProductList to show all products initially
    filteredProductList = List.from(productList);

    // Listen to changes in the search text and update the filtered list
    searchController.addListener(_filterProducts);
  }

  // Method to filter products based on search query
  void _filterProducts() {
    setState(() {
      filteredProductList = productList
          .where((product) => product.name
              .toLowerCase()
              .contains(searchController.text.toLowerCase()))
          .toList();
    });
  }

Future<void> addProductsToFirebase(Set<Product> selectedProducts) async {
    // Get the current date
    DateTime now = DateTime.now();
    String today =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    // Create a unique document ID for the sale transaction
    DocumentReference salesRef =
        FirebaseFirestore.instance.collection('sales').doc();

    // Prepare the list of products with additional details
    List<Map<String, dynamic>> productDetails = selectedProducts.map((product) {
      return {
        'product_name': product.name,
        'price': product.price,
        'date': today,
      };
    }).toList();

    try {
      // Add the sale transaction with selected products to Firebase as a single document
      await salesRef.set({
        'products': productDetails,
        'total_amount':
            selectedProducts.fold(0.0, (sum, product) => sum + product.price),
        'timestamp': FieldValue.serverTimestamp(),
        'date': today, // Add date field to track sales per day
      });

      // Show confirmation message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('${selectedProducts.length} products added to sales!')),
      );
    } catch (e) {
      // Handle any errors that may occur during the write operation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add products: $e')),
      );
    }

    // Clear selected products after adding to Firebase
    setState(() {
      selectedProducts.clear();
    });
  }


  @override
  void dispose() {
    searchController.dispose(); // Dispose the search controller
    super.dispose();
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
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                labelText: 'Search Products',
                hintText: 'Enter product name...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(width: 0.5, color: Colors.grey),
                ),
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Show the selected products in a list
          if (selectedProducts.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selected Products:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: selectedProducts.length,
                    itemBuilder: (context, index) {
                      final product = selectedProducts.elementAt(index);
                      return ListTile(
                        title: Text(product.name),
                        trailing: Text('₱${product.price}'),
                      );
                    },
                  ),
                ],
              ),
            ),
          // Main list of filtered products
          filteredProductList.isEmpty
              ? Center(child: Text('No products found.'))
              : Expanded(
                  child: ListView.builder(
                    itemCount: filteredProductList.length,
                    itemBuilder: (context, index) {
                      final product = filteredProductList[index];
                      return Card(
                        margin: EdgeInsets.all(8),
                        child: ListTile(
                          title: Text(product.name),
                          trailing: Text('₱${product.price}'),
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
                          onTap: () {
                            // Toggle the product selection when tapping the item
                            setState(() {
                              if (selectedProducts.contains(product)) {
                                selectedProducts.remove(product);
                              } else {
                                selectedProducts.add(product);
                              }
                            });
                          },
                        ),
                      );
                    },
                  ),
                ),
        ],
      ),
      floatingActionButton: selectedProducts.isNotEmpty
          ? Stack(
              children: [
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: FloatingActionButton(
                    onPressed: () {
                      addProductsToFirebase(selectedProducts);
                    },
                    child: Icon(Icons.check),
                    backgroundColor: Colors.green,
                  ),
                ),
                Positioned(
                  bottom: 48,
                  right: 16,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${selectedProducts.length} Selected',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            )
          : null, // Only show the FAB and label when there are selected products
    );
  }
}

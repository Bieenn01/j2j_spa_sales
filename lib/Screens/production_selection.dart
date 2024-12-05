import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:j2j_spa_sales/db/products.dart';


class ProductSelectionScreen extends StatefulWidget {
  @override
  _ProductSelectionScreenState createState() => _ProductSelectionScreenState();
}

class _ProductSelectionScreenState extends State<ProductSelectionScreen> {
  List<Product> productList = [
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

  List<Product> filteredProductList = [];
  Set<Product> selectedProducts = Set();
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    filteredProductList = List.from(productList); // Initialize filtered list
    _fetchProducts(); // Fetch products from Firestore
    searchController.addListener(_filterProducts);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // Fetch products from Firestore
  Future<void> _fetchProducts() async {
    final querySnapshot =
        await FirebaseFirestore.instance.collection('products').get();
    setState(() {
      final firestoreProducts =
          querySnapshot.docs.map((doc) => Product.fromFirestore(doc)).toList();
      productList.addAll(firestoreProducts);
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

  // Add, update, delete, and dialog methods remain the same...

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
                ),
              ),
            ),
          ),
        ),
      ),
      body: filteredProductList.isEmpty
          ? Center(child: Text('No products found.'))
          : ListView.builder(
              itemCount: filteredProductList.length,
              itemBuilder: (context, index) {
                final product = filteredProductList[index];
                return Card(
                  margin: EdgeInsets.all(8),
                  child: ListTile(
                    title: Text(product.name),
                    subtitle: Text('₱${product.price}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _showProductDialog(product: product),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteProduct(product),
                        ),
                      ],
                    ),
                    onTap: () {
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showProductDialog(),
        child: Icon(Icons.add),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showProductDialog({Product? product}) {
    final nameController = TextEditingController(text: product?.name ?? '');
    final priceController =
        TextEditingController(text: product?.price.toString() ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(product == null ? 'Add Product' : 'Edit Product'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: 'Product Name'),
              ),
              TextField(
                controller: priceController,
                decoration: InputDecoration(labelText: 'Product Price'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text;
                final price = double.tryParse(priceController.text) ?? 0.0;

                if (name.isNotEmpty && price > 0) {
                  setState(() {
                    if (product == null) {
                      // Adding new product
                      productList.add(Product(name: name, price: price));
                    } else {
                      // Editing existing product
                      product.name = name;
                      product.price = price;
                    }
                    filteredProductList = List.from(productList);
                  });
                  Navigator.pop(context);
                }
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _deleteProduct(Product product) {
    setState(() {
      productList.remove(product);
      filteredProductList = List.from(productList);
    });
  }

  

}

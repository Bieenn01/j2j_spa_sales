import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:j2j_spa_sales/Screens/payments.dart';
import 'package:j2j_spa_sales/Screens/production_selection.dart';
import 'package:j2j_spa_sales/Screens/total_sales.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home:
          DashboardScreen(), // The home screen will have the BottomNavigationBar
    );
  }
}

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Current selected index of the bottom navigation bar
  int _selectedIndex = 0;

  // Screens to display in the bottom navigation tabs
  final List<Widget> _screens = [
    TotalSalesScreen(), // First tab: Total Sales
    ProductSelectionScreen(), // Second tab: Product Selection (Or other screen)
    PaymentDetailsScreen(), // Third tab: Payment Details Screen
  ];

  // Update selected index when a tab is tapped
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex], // Display the selected screen
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex, // Highlight the selected tab
        onTap: _onItemTapped, // Handle tab selection
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.attach_money),
            label: 'Total Sales',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_shopping_cart),
            label: 'Products',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.payment),
            label: 'Payments',
          ),
        ],
      ),
    );
  }
}

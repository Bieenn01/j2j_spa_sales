import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:j2j_spa_sales/Screens/production_selection.dart';
import 'package:j2j_spa_sales/Screens/total_sales.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sales Dashboard',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ProductSelectionScreen(),
      routes: {
        '/total_sales': (context) => TotalSalesScreen(),
      },
    );
  }
}

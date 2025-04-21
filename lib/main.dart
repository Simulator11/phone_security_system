import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(AntTheftApp());
}
//first commit

class AntTheftApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AntTheftApp',
      theme: ThemeData(primarySwatch: Colors.red),
      home: HomeScreen(),
    );
  }
}

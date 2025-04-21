import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(AntTheftApp());
}
//"Initial commit of phone_security_system project"

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

import 'package:flutter/material.dart';
import 'package:flutter_background/flutter_background.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔒 Enable background execution
  var androidConfig = FlutterBackgroundAndroidConfig(
    notificationTitle: "Phone Security System Active",
    notificationText: "The app is running in the background.",
    notificationImportance: AndroidNotificationImportance.high, // ✅ Corrected
    enableWifiLock: true,
  );

  await FlutterBackground.initialize(androidConfig: androidConfig);
  await FlutterBackground.enableBackgroundExecution();

  runApp(AntTheftApp());
}

class AntTheftApp extends StatelessWidget {
  const AntTheftApp({super.key});

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

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:smartshift_application2/screens/worker/worker_shell.dart';

import 'firebase_options.dart';
import 'routes/root_gate.dart';
import 'screens/worker/discover_page.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  ); 
  runApp(const SmartShiftApp());
}

class SmartShiftApp extends StatelessWidget {
  const SmartShiftApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Shift',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF111827),
      ),
      home: const WorkerShell(),
    );
  }
}

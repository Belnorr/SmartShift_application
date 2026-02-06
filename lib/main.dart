// ignore_for_file: unused_import
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'theme/app_theme.dart';

import 'app_router.dart';

Future<void> main() async {
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
    return AppTheme(
      data: const AppThemeData(
        primary: Color.fromARGB(255, 73, 99, 170),
        primarySoft: Color(0x1F6C5CE7),
        surface: Color(0xFFF7F7FB),
        text: Color(0xFF111111),
        muted: Color.fromARGB(255, 74, 88, 116),
      ),
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        routerConfig: appRouter,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color.fromARGB(255, 8, 45, 75),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: const Color.fromARGB(255, 64, 132, 187),
            ),
          ),
          checkboxTheme: CheckboxThemeData(
            fillColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return const Color.fromARGB(255, 42, 107, 160);
              }
              return Colors.transparent;
            }),
            checkColor: const WidgetStatePropertyAll(Colors.white),
            side: const BorderSide(
              color: Color.fromARGB(255, 42, 107, 160),
              width: 1.5,
            ),
          ),
          switchTheme: SwitchThemeData(
            trackColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return const Color.fromARGB(255, 37, 99, 150);
              }
              return null;
            }),
            thumbColor: const WidgetStatePropertyAll(Colors.white),
          ),
        ),
      ),
    );
  }
}

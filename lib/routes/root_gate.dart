import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../debug/firestore_test.dart';
import '../screens/auth/login_page.dart';
import 'role_router.dart';

class RootGate extends StatefulWidget {
  const RootGate({super.key});

  @override
  State<RootGate> createState() => _RootGateState();
}

class _RootGateState extends State<RootGate> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snap.data == null) {
          return const LoginPage();
        }

        return const RoleRouter();
      },
    );
  }
}

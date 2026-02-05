import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'auth/login_page.dart'; // adjust path if needed

class RoleGate extends StatelessWidget {
  const RoleGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnap) {
        if (authSnap.connectionState == ConnectionState.waiting) {
          return const _Loading();
        }

        final user = authSnap.data;

        // NOT LOGGED IN → LOGIN PAGE
        if (user == null) {
          return const LoginPage();
        }

        // LOGGED IN → CHECK ROLE
        return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get(),
          builder: (context, roleSnap) {
            if (roleSnap.connectionState == ConnectionState.waiting) {
              return const _Loading();
            }

            final role =
                (roleSnap.data?.data()?['role'] ?? 'worker').toString();

            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (role == 'employer') {
                context.go('/e/dashboard');
              } else {
                context.go('/w/home'); // change later if needed
              }
            });

            return const _Loading();
          },
        );
      },
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

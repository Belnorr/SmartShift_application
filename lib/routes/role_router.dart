import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

class RoleRouter extends StatelessWidget {
  const RoleRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Scaffold(
            body: Center(child: Text('Setting up your profile...')),
          );
        }

        final role = snapshot.data!.data()?['role'];

        if (role == 'worker') {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.go('/w/discover'); // adjust if needed
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (role == 'employer') {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.go('/e/dashboard');
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return const Scaffold(
          body: Center(child: Text('Invalid user role')),
        );
      },
    );
  }
}

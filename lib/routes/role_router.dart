import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../screens/worker/worker_shell.dart';
import '../screens/employer/employer_shell.dart';

class RoleRouter extends StatelessWidget {
  const RoleRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    // Safety check if user suddenly becomes null
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
      builder: (context, snapshot) {
        // Show loading while fetching the role
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

        final data = snapshot.data!.data() as Map<String, dynamic>?;
        final role = data?['role'];

        if (role == 'worker') {
          return const WorkerShell();
        } else if (role == 'employer') {
          return const EmployerShell();
        } else {
          return const Scaffold(
            body: Center(child: Text('Invalid user role')),
          );
        }
      },
    );
  }
}
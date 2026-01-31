import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'smart_router_home.dart';

class RoleRouter extends StatelessWidget {
  const RoleRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final data = snap.data!.data();

        if (data == null) {
          return const Scaffold(
            body: Center(
              child: Text(
                'User profile not found.\nPlease re-register.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final role = (data['role'] ?? 'employee').toString();

        return SmartRouterHome(role: role);
      },
    );
  }
}

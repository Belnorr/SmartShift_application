import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../widgets/reward_redeem_dialog.dart';

class RewardsPage extends StatelessWidget {
  const RewardsPage({super.key});

    static String get uid =>
        FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: const Text(
          'Rewards',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .snapshots(),
        builder: (context, userSnapshot) {
          if (!userSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final userData =
              userSnapshot.data!.data() as Map<String, dynamic>;
          final int points = userData['points'] ?? 0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TotalPointsCard(points: points),
                const SizedBox(height: 24),

                const Text(
                  'Available Rewards',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                _RewardItem(
                  title: '\$10 Grocery Voucher',
                  subtitle: 'FairPrice / Cold Storage',
                  cost: 1500,
                  userPoints: points,
                ),
                const SizedBox(height: 12),
                _RewardItem(
                  title: '\$5 Drinks Voucher',
                  subtitle: 'Starbucks / Luckin',
                  cost: 1500,
                  userPoints: points,
                ),

                const SizedBox(height: 24),

                const Text(
                  'Recent Activity',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                const _ActivityList(),
              ],
            ),
          );
        },
      ),
    );
  }
}

/* ===================== TOTAL POINTS ===================== */

class _TotalPointsCard extends StatelessWidget {
  final int points;

  const _TotalPointsCard({required this.points});

  @override
  Widget build(BuildContext context) {
    const int nextReward = 1500;
    final double progress =
        (points / nextReward).clamp(0, 1).toDouble();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2A44),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.stars, color: Colors.white),
              SizedBox(width: 8),
              Text('Total Points', style: TextStyle(color: Colors.white)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            points.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Next reward: \$10 Voucher',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white24,
            valueColor:
                const AlwaysStoppedAnimation<Color>(Colors.greenAccent),
          ),
          const SizedBox(height: 6),
          Text(
            '${(nextReward - points).clamp(0, nextReward)} pts to go',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

/* ===================== REWARD ITEM ===================== */

class _RewardItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final int cost;
  final int userPoints;

  const _RewardItem({
    required this.title,
    required this.subtitle,
    required this.cost,
    required this.userPoints,
  });

  String _generateCoupon() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    return 'SS-' +
        List.generate(
          8,
          (_) => chars[
              DateTime.now().microsecondsSinceEpoch % chars.length],
        ).join();
  }

  Future<void> _redeem(BuildContext context) async {
    if (userPoints < cost) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not enough points')),
      );
      return;
    }

    final code = _generateCoupon();

    final userRef = FirebaseFirestore.instance
        .collection('users')
        .doc(RewardsPage.uid);

    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(userRef);
      final currentPoints = snap['points'] ?? 0;

      if (currentPoints < cost) {
        throw Exception('Not enough points');
      }

      tx.update(userRef, {
        'points': currentPoints - cost,
      });
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => RewardRedeemDialog(couponCode: code),
    );
  }

  @override
  Widget build(BuildContext context) {
    final disabled = userPoints < cost;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.card_giftcard),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style:
                      const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          ),
          Text(
            '$cost pts',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: disabled ? null : () => _redeem(context),
          ),
        ],
      ),
    );
  }
}

/* ===================== ACTIVITY LIST ===================== */

class _ActivityList extends StatelessWidget {
  const _ActivityList();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(RewardsPage.uid)
          .collection('bookedShifts')
          .orderBy('bookedAt', descending: true)
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return const Text('No recent activity');

        return Column(
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final bool positive = data['status'] == 'completed';

            final Timestamp? ts = data['date'];
            final dateLabel = ts != null
                ? DateFormat('EEE, d MMM').format(ts.toDate())
                : '';

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ActivityItem(
                title:
                    positive ? 'Completed Shift' : 'Shift Cancelled',
                subtitle: data['title'] ?? '',
                date: dateLabel,
                points: positive
                    ? '+${data['rewardPoints']} pts'
                    : '-50 pts',
                positive: positive,
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

/* ===================== ACTIVITY ITEM ===================== */

class _ActivityItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final String date;
  final String points;
  final bool positive;

  const _ActivityItem({
    required this.title,
    required this.subtitle,
    required this.date,
    required this.points,
    required this.positive,
  });

  @override
  Widget build(BuildContext context) {
    final color = positive ? Colors.green : Colors.red;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            positive ? Icons.check_circle : Icons.cancel,
            color: color,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style:
                        const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(
                  '$subtitle • $date',
                  style:
                      const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          ),
          Text(
            points,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

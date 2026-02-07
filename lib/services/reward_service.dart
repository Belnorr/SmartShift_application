import 'package:cloud_firestore/cloud_firestore.dart';

class RewardService {
  static Future<void> redeemReward({
    required String userId,
    required int cost,
    required String rewardTitle,
    required String couponCode,
  }) async {
    final userRef =
        FirebaseFirestore.instance.collection('users').doc(userId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(userRef);

      if (!snapshot.exists) {
        throw Exception('User not found');
      }

      final data = snapshot.data()!;
      final int currentPoints = data['points'] ?? 0;

      if (currentPoints < cost) {
        throw Exception('Not enough points');
      }

      // Deduct points
      transaction.update(userRef, {
        'points': currentPoints - cost,
      });

      // Log reward redemption
      final rewardLogRef = userRef
          .collection('rewardHistory')
          .doc();

      transaction.set(rewardLogRef, {
        'title': rewardTitle,
        'pointsUsed': cost,
        'couponCode': couponCode,
        'redeemedAt': FieldValue.serverTimestamp(),
      });
    });
  }
}

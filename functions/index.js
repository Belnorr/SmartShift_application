/**
 * Firebase Cloud Functions
 * Region: asia-southeast1 (Singapore)
 * Purpose:
 * - Enforce shift capacity
 * - Auto close / reopen shifts
 * - Auto complete shifts
 * - Award points
 * - Handle cancellations safely
 */

const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

const db = admin.firestore();

/* ============================================================================
   1️SHIFT BOOKED
   - Increase bookedCount
   - Close shift if capacity reached
============================================================================ */

exports.onShiftBooked = functions
  .region('asia-southeast1')
  .firestore
  .document('users/{uid}/bookedShifts/{bookingId}')
  .onCreate(async (snap) => {
    const data = snap.data();
    if (!data || !data.shiftId) return null;

    const shiftRef = db.collection('shifts').doc(data.shiftId);

    await db.runTransaction(async (tx) => {
      const shiftSnap = await tx.get(shiftRef);
      if (!shiftSnap.exists) return;

      const shift = shiftSnap.data();
      const bookedCount = (shift.bookedCount || 0) + 1;
      const capacity = shift.capacity || 0;

      tx.update(shiftRef, {
        bookedCount: bookedCount,
        status: bookedCount >= capacity ? 'closed' : 'open',
      });
    });

    return null;
  });

/* ============================================================================
   2️SHIFT CANCELLED
   - Decrease bookedCount
   - Reopen shift if capacity available
============================================================================ */
exports.onLateCancellation = functions
  .region('asia-southeast1')
  .firestore
  .document('users/{uid}/bookedShifts/{bookingId}')
  .onUpdate(async (change) => {
    const before = change.before.data();
    const after = change.after.data();

    if (!before || !after) return null;

    if (before.status === 'upcoming' && after.status === 'cancelled') {
      const startTime = after.startTime;
      if (!(startTime instanceof admin.firestore.Timestamp)) return null;

      const now = admin.firestore.Timestamp.now();
      const secondsDiff = startTime.seconds - now.seconds;

      // Less than 24 hours
      if (secondsDiff < 86400) {
        const userRef = change.after.ref.parent.parent;
        if (!userRef) return null;

        await userRef.update({
          reliability: admin.firestore.FieldValue.increment(-5),
          'stats.lateCancellations':
            admin.firestore.FieldValue.increment(1),
        });
      }
    }

    return null;
  });

/* ============================================================================
   AUTO COMPLETE SHIFTS
   - Runs every 15 minutes
   - Marks shifts as completed
   - Awards points
   - Updates user stats
============================================================================ */

exports.completeShifts = functions
  .region('asia-southeast1')
  .pubsub
  .schedule('every 15 minutes')
  .timeZone('Asia/Singapore')
  .onRun(async () => {
    const now = admin.firestore.Timestamp.now();

    const bookingsSnap = await db
      .collectionGroup('bookedShifts')
      .where('status', '==', 'upcoming')
      .where('endTime', '<=', now)
      .get();

    if (bookingsSnap.empty) return null;

    const batch = db.batch();

    bookingsSnap.docs.forEach((doc) => {
      const data = doc.data();
      const userRef = doc.ref.parent.parent;

      if (!userRef) return;

      batch.update(doc.ref, {
        status: 'completed',
        completedAt: admin.firestore.Timestamp.now(),
      });

      batch.update(userRef, {
        points: admin.firestore.FieldValue.increment(
          data.rewardPoints || 0
        ),
        'stats.shiftsCompleted':
          admin.firestore.FieldValue.increment(1),
      });
    });

    await batch.commit();
    return null;
  });

/* ============================================================================
  LATE CANCELLATION PENALTY
   - If cancelled < 24h before start
   - Reduce reliability
   - Increase lateCancellation count
============================================================================ */

exports.onLateCancellation = functions
  .region('asia-southeast1')
  .firestore
  .document('users/{uid}/bookedShifts/{bookingId}')
  .onUpdate(async (change) => {
    const before = change.before.data();
    const after = change.after.data();

    if (!before || !after) return null;

    if (before.status === 'upcoming' && after.status === 'cancelled') {
      const startTime = after['date/startTime'];
      if (!startTime) return null;

      const now = admin.firestore.Timestamp.now();
      const secondsDiff =
        startTime.seconds - now.seconds;

      // Less than 24 hours
      if (secondsDiff < 86400) {
        const userRef = change.after.ref.parent.parent;

        if (!userRef) return null;

        await userRef.update({
          reliability:
            admin.firestore.FieldValue.increment(-5),
          'stats.lateCancellations':
            admin.firestore.FieldValue.increment(1),
        });
      }
    }

    return null;
  });

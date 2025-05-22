
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../database/user_db.dart';

class AlertSender {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> sendAlertToAllGuardians(BuildContext context) async {
    try {
      // Get logged-in user from local DB
      final user = await UserDB.getLoggedInUser();
      if (user == null) throw Exception('No user logged in');

      final userPhone = user.phone;
      final userName = user.name;

      // Step 1: Get guardians from Firestore
      final guardiansSnapshot = await _firestore
          .collection('users')
          .doc(userPhone)
          .collection('guardians')
          .get();

      final guardianPhones = guardiansSnapshot.docs
          .map((doc) => doc.id) // Guardian phone numbers
          .toList();

      if (guardianPhones.isEmpty) throw Exception('No guardians saved');

      // Step 2: Send alert to each guardian
      for (final phone in guardianPhones) {
        await _firestore.collection('alerts').doc(phone).set({
          'isAlert': true,
          'userName': userName ?? 'Someone',
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Alert sent to all guardians')),
      );
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Failed to send alert: $e')),
      );
      print('❌ Error sending alert: $e');
    }
  }
}

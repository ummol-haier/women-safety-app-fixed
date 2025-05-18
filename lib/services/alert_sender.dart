// ignore: depend_on_referenced_packages
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:location/location.dart';
import 'package:flutter/material.dart';

class AlertSender {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> sendAlertToAllGuardians(BuildContext context) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No user logged in');

      final userId = user.uid;

      // Step 1: Get user name from Firestore
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userName = userDoc.data()?['name'] ?? 'Someone';

      // Step 2: Get guardians from subcollection
      final guardiansSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('guardians')
          .get();

      final guardianPhones = guardiansSnapshot.docs
          .map((doc) => doc.data()['phone'] as String)
          .toList();

      if (guardianPhones.isEmpty) throw Exception('No guardians saved');

      // Step 3: Get current location
      final location = Location();
      final locData = await location.getLocation();

      final locationUrl =
          'https://www.google.com/maps?q=${locData.latitude},${locData.longitude}';

      // Step 4: Send alert to each guardian (via Firestore)
      for (final phone in guardianPhones) {
        await _firestore.collection('alerts').doc(phone).set({
          'isAlert': true,
          'userName': userName,
          'locationUrl': locationUrl,
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
      rethrow;
    }
  }
}

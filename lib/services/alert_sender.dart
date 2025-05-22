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

      // Debug prints to help diagnose the issue
      print('🔍 Debug Info:');
      print('User Phone: $userPhone');
      print('User Name: $userName');

      // Step 1: Get guardians from Firestore (corrected path)
      final docSnapshot = await _firestore
          .collection('guardian_links')
          .doc(userPhone)
          .get();

      print('Document Path: guardian_links/$userPhone');
      print('Document Exists: ${docSnapshot.exists}');
      print('Document Data: ${docSnapshot.data()}');


      if (!docSnapshot.exists) throw Exception('No guardians saved');
      
      final data = docSnapshot.data();
      if (data == null || !data.containsKey('guardians') || !(data['guardians'] is Map) || (data['guardians'] as Map).isEmpty) {
        throw Exception('No guardians saved');
      }

      final guardiansMap = data['guardians'] as Map;
      final guardianPhones = guardiansMap.keys.toList();

      // Step 2: Send alert to each guardian
      for (final phone in guardianPhones) {
        await _firestore.collection('alerts').doc(phone).set({
          'isAlert': true,
          'userName': userName,
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

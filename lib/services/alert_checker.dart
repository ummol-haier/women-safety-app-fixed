import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../screens/guardian/alert_screen.dart';

class AlertChecker {
  static StreamSubscription<DocumentSnapshot>? _subscription;

  static void startListeningForAlerts({
    required String guardianPhone,
    required BuildContext context,
  }) {
    final docRef = FirebaseFirestore.instance.collection('alerts').doc(guardianPhone);

    _subscription = docRef.snapshots().listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        final bool alert = data['isAlert'] ?? false;
        if (alert) {
          final String userName = data['userName'] ?? 'User';
          final String locationUrl = data['locationUrl'] ?? '';
          
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => AlertScreen(userName: userName, locationUrl: locationUrl),
          ));
        }
      }
    });
  }

  static void stopListening() {
    _subscription?.cancel();
  }
}

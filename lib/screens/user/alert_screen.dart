// lib/screens/user/alert_screen.dart
import 'package:flutter/material.dart';
import '../../services/alert_sender.dart';

class AlertScreen extends StatelessWidget {
  const AlertScreen({super.key});

  final AlertSender _alertSender = AlertSender();

  void _sendAlert(BuildContext context) async {
    await _alertSender.sendAlertToAllGuardians(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red.shade100,
      appBar: AppBar(
        title: const Text('Emergency Alert'),
        backgroundColor: Colors.red,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              size: 100,
              color: Colors.red.shade900,
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
              onPressed: () => _sendAlert(context),
              icon: const Icon(Icons.send),
              label: const Text(
                'Send Alert',
                style: TextStyle(fontSize: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

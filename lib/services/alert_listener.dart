import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:url_launcher/url_launcher.dart';

class AlertListener {
  static Stream<DocumentSnapshot>? _alertStream;
  static AudioPlayer? _audioPlayer;

  static void listenForGuardianAlert({
    required String guardianPhone,
    required BuildContext context,
    required String guardianSmsNumber, // guardian's own phone number for SMS
  }) {
    _alertStream = FirebaseFirestore.instance
        .collection('alerts')
        .doc(guardianPhone)
        .snapshots();

    _alertStream!.listen((snapshot) async {
      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data() as Map<String, dynamic>;
        final bool isAlert = data['isAlert'] ?? false;
        if (isAlert) {
          final String userName = data['userName'] ?? 'User';
          final String locationUrl = data['locationUrl'] ?? '';

          // 1. Siren বাজাও
          _audioPlayer = AudioPlayer();
          await _audioPlayer!.setReleaseMode(ReleaseMode.loop);
          await _audioPlayer!.play(AssetSource('sounds/siren.mp3'));

          // 2. Dialog দেখাও
          if (context.mounted) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (ctx) => AlertDialog(
                title: const Text('Emergency Alert!'),
                content: Text('$userName needs your help!'),
                actions: [
                  TextButton(
                    onPressed: () async {
                      // 3. Siren বন্ধ করো
                      await _audioPlayer?.stop();
                      Navigator.of(ctx).pop();
                      // 4. User-এর নাম ও location সহ SMS পাঠাও
                      final smsBody =
                          'Emergency! $userName needs help. Location: $locationUrl';
                      final smsUri = Uri.parse('sms:$guardianSmsNumber?body=${Uri.encodeComponent(smsBody)}');
                      if (await canLaunchUrl(smsUri)) {
                        await launchUrl(smsUri);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Could not launch SMS app.')),
                        );
                      }
                    },
                    child: const Text('Respond'),
                  ),
                ],
              ),
            );
          }
        }
      }
    });
  }

  static Future<void> stopSiren() async {
    await _audioPlayer?.stop();
  }
}

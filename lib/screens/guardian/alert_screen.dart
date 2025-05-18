import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vibration/vibration.dart';
import 'package:audioplayers/audioplayers.dart';

class AlertScreen extends StatefulWidget {
  final String userName;
  final String locationUrl;
  const AlertScreen({super.key, required this.userName, required this.locationUrl});

  @override
  State<AlertScreen> createState() => _AlertScreenState();
}

class _AlertScreenState extends State<AlertScreen> {
  late AudioPlayer _audioPlayer;
  bool _isResponded = false;

  @override
  void initState() {
    super.initState();
    _startAlert();
  }

  Future<void> _startAlert() async {
    // Vibrate in a pattern (repeat)
    if (await Vibration.hasVibrator()) {
      Vibration.vibrate(pattern: [0, 1000, 500, 1000, 500], repeat: 0);
    }
    // Play siren in loop
    _audioPlayer = AudioPlayer();
    await _audioPlayer.setReleaseMode(ReleaseMode.loop);
    await _audioPlayer.play(AssetSource('sounds/siren.mp3'));
  }

  Future<void> _stopAlert() async {
    await _audioPlayer.stop();
    Vibration.cancel();
  }

  @override
  void dispose() {
    _stopAlert();
    super.dispose();
  }

  void _respond() async {
    await _stopAlert();
    setState(() {
      _isResponded = true;
    });
    // Open map with location
    if (widget.locationUrl.isNotEmpty && widget.locationUrl.startsWith('http')) {
      // ignore: use_build_context_synchronously
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => _MapRedirectScreen(url: widget.locationUrl),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red.shade900,
      body: Center(
        child: _isResponded
            ? const Icon(Icons.check_circle, color: Colors.green, size: 80)
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.warning, color: Colors.white, size: 100),
                  const SizedBox(height: 24),
                  const Text(
                    'EMERGENCY ALERT!',
                    style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${widget.userName} needs your help!',
                    style: const TextStyle(color: Colors.white, fontSize: 20),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.red.shade900,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    icon: const Icon(Icons.check),
                    label: const Text('Respond'),
                    onPressed: _respond,
                  ),
                ],
              ),
      ),
    );
  }
}

class _MapRedirectScreen extends StatelessWidget {
  final String url;
  const _MapRedirectScreen({required this.url});

  @override
  Widget build(BuildContext context) {
    Future.delayed(Duration.zero, () async {
      // ignore: use_build_context_synchronously
      Navigator.of(context).pop();
      // ignore: deprecated_member_use
      await launchUrl(Uri.parse(url));
    });
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

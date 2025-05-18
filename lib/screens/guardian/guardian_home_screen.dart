import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../services/alert_checker.dart';
import '../../../services/alert_listener.dart';
import '../../utils/auth_helper.dart';
import '../role_selection_screen.dart';
import '../../database/guardian_db.dart';
import '../../database/user_db.dart';
import '../user/user_home_screen.dart';

class GuardianHomeScreen extends StatefulWidget {
  const GuardianHomeScreen({super.key});

  @override
  State<GuardianHomeScreen> createState() => _GuardianHomeScreenState();
}

class _GuardianHomeScreenState extends State<GuardianHomeScreen> {
  List<Map<String, dynamic>> linkedUsers = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _startAlertListener();
    _fetchLinkedUsers();
  }

  void _startAlertListener() async {
    final guardianPhone = await AuthHelper.getCurrentGuardianPhone();
    if (guardianPhone != null && guardianPhone.isNotEmpty) {
      AlertListener.listenForGuardianAlert(
        guardianPhone: guardianPhone,
        context: context,
        guardianSmsNumber: guardianPhone,
      );
    }
  }

  Future<void> _fetchLinkedUsers() async {
    setState(() {
      isLoading = true;
    });
    final guardianPhone = await AuthHelper.getCurrentGuardianPhone();
    if (guardianPhone != null && guardianPhone.isNotEmpty) {
      final doc = await FirebaseFirestore.instance
          .collection('guardian_links')
          .doc(guardianPhone)
          .get();
      if (doc.exists) {
        final guardians = doc.data()?['guardians'] as List<dynamic>?;
        linkedUsers = guardians?.map((g) => Map<String, dynamic>.from(g)).toList() ?? [];
      } else {
        linkedUsers = [];
      }
    }
    setState(() {
      isLoading = false;
    });
  }

  void _editNoteDialog(Map<String, dynamic> user) {
    final noteController = TextEditingController(text: user['note'] ?? '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Note for ${user['userName']}'),
        content: TextField(
          controller: noteController,
          decoration: const InputDecoration(labelText: 'Note'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final guardianPhone = await AuthHelper.getCurrentGuardianPhone();
              final docRef = FirebaseFirestore.instance.collection('guardian_links').doc(guardianPhone);
              final doc = await docRef.get();
              if (doc.exists) {
                List guardians = (doc.data()?['guardians'] ?? []);
                for (var g in guardians) {
                  if (g['userPhone'] == user['userPhone']) {
                    g['note'] = noteController.text.trim();
                  }
                }
                await docRef.update({'guardians': guardians});
                setState(() { user['note'] = noteController.text.trim(); });
              }
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _switchToUserMode() async {
    final guardian = await GuardianDB.getLoggedInGuardian();
    if (guardian != null && guardian.isFemale) {
      final users = await UserDB.getUsers();
      final userForGuardian = users.firstWhere(
        (u) => u.phone == guardian.userPhone,
        orElse: () => null as dynamic, // workaround for null
      );
      if (userForGuardian != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => UserHomeScreen(fromGuardianMode: true),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No user account found for this phone.')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Switch to user mode is only for female guardians.')),
      );
    }
  }

  @override
  void dispose() {
    AlertChecker.stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Guardian Home"),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            tooltip: 'Switch to User Mode',
            onPressed: _switchToUserMode,
          ),
          IconButton(
            icon: const Icon(Icons.delete_forever),
            tooltip: 'Delete Account',
            onPressed: () async {
              await GuardianDB.deleteLoggedInGuardian();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
                  (route) => false,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Account deleted successfully'),
                    backgroundColor: Colors.red,
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await GuardianDB.logoutAll();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
                  (route) => false,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Logged out successfully'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : linkedUsers.isEmpty
              ? const Center(child: Text('No users have added you as guardian.'))
              : ListView.builder(
                  itemCount: linkedUsers.length,
                  itemBuilder: (context, index) {
                    final user = linkedUsers[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: const Icon(Icons.person, color: Colors.redAccent),
                        title: Text(user['userName'] ?? ''),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user['userPhone'] ?? ''),
                            if ((user['note'] ?? '').isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text('Note: ${user['note']}', style: const TextStyle(fontSize: 12)),
                              ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          tooltip: 'Edit Note',
                          onPressed: () => _editNoteDialog(user),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

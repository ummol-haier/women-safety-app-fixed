import 'dart:async';
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

  // Fixed issues with Firestore data fetching and removed unnecessary casts.
  Stream<List<Map<String, dynamic>>> fetchGuardians(String guardianPhone) {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    return firestore.collection('guardians').doc(guardianPhone).snapshots().asyncMap((guardianSnapshot) async {
      if (guardianSnapshot.exists) {
        Map<String, dynamic> guardianData = guardianSnapshot.data()!;
        List<Map<String, dynamic>> usersList = [];

        for (var userPhone in guardianData['linkedUsers']) {
          final userDoc = await firestore.collection('users').doc(userPhone).get();
          if (userDoc.exists) {
            Map<String, dynamic> userData = userDoc.data()!;
            usersList.add({
              'userPhone': userPhone,
              'userName': userData['name'] ?? 'Unknown User',
              'note': guardianData['guardians'][userPhone]['note'] ?? '',
              'isPrimary': guardianData['guardians'][userPhone]['isPrimary'] ?? false,
            });
          }
        }
        return usersList;
      }
      return [];
    });
  }

  // Updated to use a consistent Firestore schema for guardians and linkedUsers.
  Future<void> _fetchLinkedUsers() async {
    setState(() {
      isLoading = true;
    });

    final guardianPhone = await AuthHelper.getCurrentGuardianPhone();
    linkedUsers = [];

    if (guardianPhone != null && guardianPhone.isNotEmpty) {
      final usersSnapshot = await FirebaseFirestore.instance.collection('users').get();

      for (var userDoc in usersSnapshot.docs) {
        final linkedUsersList = userDoc.data()['linkedUsers'] as List<dynamic>?;
        final guardiansMap = userDoc.data()['guardians'] as Map<String, dynamic>?;

        if (linkedUsersList != null && linkedUsersList.contains(guardianPhone) && guardiansMap != null) {
          final guardianDetails = guardiansMap[guardianPhone];
          final userData = {
            "userPhone": userDoc.id,
            "userName": userDoc.data()['name'] ?? "Unknown User",
            "note": guardianDetails['note'] ?? '',
            "isPrimary": guardianDetails['isPrimary'] ?? false,
          };
          linkedUsers.add(userData);
        }
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
              // Updated to use the `guardians` collection instead of `guardian_links`.
              final docRef = FirebaseFirestore.instance.collection('guardians').doc(guardianPhone);
              final doc = await docRef.get();
              if (doc.exists) {
                Map<String, dynamic> guardians = doc.data()?['guardians'] ?? {};
                if (guardians.containsKey(user['userPhone'])) {
                  guardians[user['userPhone']]['note'] = noteController.text.trim();
                  await docRef.update({'guardians': guardians});
                  setState(() {
                    user['note'] = noteController.text.trim();
                  });
                }
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
      // Replaced dangerous cast with a safer try-catch block.
      User? userForGuardian;
      try {
        userForGuardian = users.firstWhere((u) => u.phone == guardian.userPhone);
      } catch (e) {
        userForGuardian = null;
      }
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

  // Dynamically fetch the guardian's phone number instead of hardcoding it.
  Future<String?> _getGuardianPhone() async {
    return await AuthHelper.getCurrentGuardianPhone();
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
      body: FutureBuilder<String?>(
        future: _getGuardianPhone(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('Error fetching guardian phone number.'));
          }

          final guardianPhone = snapshot.data!;
          return StreamBuilder<List<Map<String, dynamic>>>(
            stream: fetchGuardians(guardianPhone),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('No users have added you as guardian.'));
              }

              final guardians = snapshot.data!;
              return ListView.builder(
                itemCount: guardians.length,
                itemBuilder: (context, index) {
                  final guardian = guardians[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      leading: const Icon(Icons.person, color: Colors.redAccent),
                      title: Text(guardian['userName'] ?? ''),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(guardian['userPhone'] ?? ''),
                          if ((guardian['note'] ?? '').isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text('Note: ${guardian['note']}', style: const TextStyle(fontSize: 12)),
                            ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        tooltip: 'Edit Note',
                        onPressed: () => _editNoteDialog(guardian),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../database/guardian_db.dart';
import '../../widgets/edit_guardian_dialog.dart';

class GuardianListScreen extends StatefulWidget {
  const GuardianListScreen({super.key});

  @override
  State<GuardianListScreen> createState() => _GuardianListScreenState();
}

class _GuardianListScreenState extends State<GuardianListScreen> {
  List<Guardian> guardians = [];

  @override
  void initState() {
    super.initState();
    _fetchGuardians();
  }

  Future<void> _fetchGuardians() async {
    final fetched = await GuardianDB.getGuardians();
    setState(() {
      guardians = fetched;
    });
  }

  Future<void> _deleteGuardian(Guardian guardian) async {
    await GuardianDB.deleteGuardian(guardian.id!);
    _fetchGuardians();
  }

  Future<void> _toggleBlock(Guardian guardian) async {
    final updated = Guardian(
      id: guardian.id,
      userName: guardian.userName,
      userPhone: guardian.userPhone,
      note: guardian.note,
      isPrimary: guardian.isPrimary,
      isBlocked: !guardian.isBlocked,
      email: guardian.email,
      password: guardian.password,
      isLoggedIn: guardian.isLoggedIn,
    );
    await GuardianDB.updateGuardian(updated);
    _fetchGuardians();
  }

  Future<void> _markPrimary(Guardian guardian) async {
    // Only one can be primary: set all to false, then set this one to true
    for (final g in guardians) {
      if (g.isPrimary && g.id != guardian.id) {
        final updated = Guardian(
          id: g.id,
          userName: g.userName,
          userPhone: g.userPhone,
          note: g.note,
          isPrimary: false,
          isBlocked: g.isBlocked,
          email: g.email,
          password: g.password,
          isLoggedIn: g.isLoggedIn,
        );
        await GuardianDB.updateGuardian(updated);
      }
    }
    final updated = Guardian(
      id: guardian.id,
      userName: guardian.userName,
      userPhone: guardian.userPhone,
      note: guardian.note,
      isPrimary: true,
      isBlocked: guardian.isBlocked,
      email: guardian.email,
      password: guardian.password,
      isLoggedIn: guardian.isLoggedIn,
    );
    await GuardianDB.updateGuardian(updated);
    _fetchGuardians();
  }

  void _editGuardian(Guardian? guardian) async {
    showDialog(
      context: context,
      builder: (context) => EditGuardianDialog(
        guardian: guardian,
        onSave: (updatedGuardian) async {
          if (guardian == null) {
            await GuardianDB.insertGuardian(updatedGuardian);
          } else {
            // If marking as primary, ensure only one is primary
            if (updatedGuardian.isPrimary) {
              for (final g in guardians) {
                if (g.isPrimary && g.id != updatedGuardian.id) {
                  final notPrimary = Guardian(
                    id: g.id,
                    userName: g.userName,
                    userPhone: g.userPhone,
                    note: g.note,
                    isPrimary: false,
                    isBlocked: g.isBlocked,
                    email: g.email,
                    password: g.password,
                    isLoggedIn: g.isLoggedIn,
                  );
                  await GuardianDB.updateGuardian(notPrimary);
                }
              }
            }
            await GuardianDB.updateGuardian(updatedGuardian);
          }
          _fetchGuardians();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Guardians')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _editGuardian(null),
        tooltip: 'Add Guardian',
        child: const Icon(Icons.add),
      ),
      body: guardians.isEmpty
          ? const Center(child: Text('No guardians found.'))
          : ListView.builder(
              itemCount: guardians.length,
              itemBuilder: (context, index) {
                final guardian = guardians[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: guardian.isPrimary ? Colors.orange : Colors.blueAccent,
                      child: Text(guardian.userName.isNotEmpty ? guardian.userName[0].toUpperCase() : '?'),
                    ),
                    title: Text(
                      guardian.userName,
                      style: TextStyle(
                        color: guardian.isBlocked ? Colors.grey : Colors.black,
                        fontWeight: FontWeight.bold,
                        decoration: guardian.isBlocked ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          guardian.userPhone,
                          style: TextStyle(
                            color: guardian.isBlocked ? Colors.grey : Colors.black87,
                            decoration: guardian.isBlocked ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        if (guardian.note.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text('Note: ${guardian.note}', style: const TextStyle(fontSize: 12)),
                          ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(guardian.isPrimary ? Icons.star : Icons.star_border, color: Colors.orange),
                          tooltip: guardian.isPrimary ? 'Primary Guardian' : 'Mark as Primary',
                          onPressed: guardian.isPrimary ? null : () => _markPrimary(guardian),
                        ),
                        IconButton(
                          icon: Icon(guardian.isBlocked ? Icons.block : Icons.check_circle, color: Colors.red),
                          tooltip: guardian.isBlocked ? 'Unblock' : 'Block',
                          onPressed: () => _toggleBlock(guardian),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          tooltip: 'Edit',
                          onPressed: () => _editGuardian(guardian),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          tooltip: 'Delete',
                          onPressed: () => _deleteGuardian(guardian),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

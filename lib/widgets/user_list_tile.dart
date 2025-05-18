import 'package:flutter/material.dart';
import '../models/user_model.dart';

class UserListTile extends StatelessWidget {
  final UserModel user;
  final VoidCallback onDelete;
  final VoidCallback onTogglePrimary;
  final VoidCallback onToggleBlock;
  final VoidCallback onTestAlert;
  final VoidCallback onEdit;

  const UserListTile({
    super.key,
    required this.user,
    required this.onDelete,
    required this.onTogglePrimary,
    required this.onToggleBlock,
    required this.onTestAlert,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: user.isBlocked ? Colors.grey[300] : Colors.white,
      child: ListTile(
        title: Row(
          children: [
            Text(user.name),
            if (user.isPrimary)
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Chip(
                  label: const Text('Primary'),
                  backgroundColor: Colors.orange[200],
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Phone: ${user.phone}"),
            if (user.note.isNotEmpty) Text("Note: ${user.note}"),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'Edit':
                onEdit();
                break;
              case 'Delete':
                onDelete();
                break;
              case 'Primary':
                onTogglePrimary();
                break;
              case 'Block':
                onToggleBlock();
                break;
              case 'Alert':
                onTestAlert();
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'Edit', child: Text('Edit')),
            const PopupMenuItem(value: 'Delete', child: Text('Delete')),
            PopupMenuItem(
              value: 'Primary',
              child: Text(user.isPrimary ? 'Unmark Primary' : 'Mark Primary'),
            ),
            PopupMenuItem(
              value: 'Block',
              child: Text(user.isBlocked ? 'Unblock' : 'Block'),
            ),
            const PopupMenuItem(value: 'Alert', child: Text('Test Alert')),
          ],
        ),
      ),
    );
  }
}

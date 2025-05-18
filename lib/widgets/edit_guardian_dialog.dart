//এটা হচ্ছে guardian add/edit করার জন্য ইউজার-ফ্রেন্ডলি ফর্ম ডায়ালগ।

import 'package:flutter/material.dart';
import '../../database/guardian_db.dart';

class EditGuardianDialog extends StatefulWidget {
  final Guardian? guardian;
  final void Function(Guardian) onSave;
  const EditGuardianDialog({super.key, this.guardian, required this.onSave});

  @override
  State<EditGuardianDialog> createState() => _EditGuardianDialogState();
}

class _EditGuardianDialogState extends State<EditGuardianDialog> {
  late TextEditingController nameController;
  late TextEditingController phoneController;
  late TextEditingController noteController;
  bool isPrimary = false;
  bool isBlocked = false;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.guardian?.userName ?? '');
    phoneController = TextEditingController(text: widget.guardian?.userPhone ?? '');
    noteController = TextEditingController(text: widget.guardian?.note ?? '');
    isPrimary = widget.guardian?.isPrimary ?? false;
    isBlocked = widget.guardian?.isBlocked ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.guardian == null ? 'Add Guardian' : 'Edit Guardian'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: 'Phone'),
              keyboardType: TextInputType.phone,
            ),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(labelText: 'Note'),
            ),
            Row(
              children: [
                Checkbox(
                  value: isPrimary,
                  onChanged: (val) {
                    setState(() {
                      isPrimary = val ?? false;
                    });
                  },
                ),
                const Text('Primary'),
                Checkbox(
                  value: isBlocked,
                  onChanged: (val) {
                    setState(() {
                      isBlocked = val ?? false;
                    });
                  },
                ),
                const Text('Blocked'),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final guardian = Guardian(
              id: widget.guardian?.id,
              userName: nameController.text.trim(),
              userPhone: phoneController.text.trim(),
              note: noteController.text.trim(),
              isPrimary: isPrimary,
              isBlocked: isBlocked,
              email: widget.guardian?.email ?? '',
              password: widget.guardian?.password ?? '',
            );
            widget.onSave(guardian);
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

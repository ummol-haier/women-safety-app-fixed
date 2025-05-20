import 'package:ally/widgets/custom_textfield.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../database/emergency_contact_db.dart';
import '../../database/user_db.dart';
import 'package:ally/models/contact_model.dart'; 

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController numberController = TextEditingController();
  final TextEditingController searchController = TextEditingController();

  List<EmergencyContact> contacts = [];
  String searchText = '';
  bool permissionDenied = false;

  @override
  void initState() {
    super.initState();
    _fetchContacts();
  }

  Future<void> _fetchContacts() async {
    final fetchedContacts = await EmergencyContactDB.getContacts();
    setState(() {
      contacts = fetchedContacts;
    });
  }

  String normalizePhone(String phone) {
    // Remove spaces, dashes, and leading zeros, and ensure +88 for Bangladesh
    String p = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (p.startsWith('0')) {
      p = '+88' + p.substring(1);
    } else if (!p.startsWith('+88')) {
      p = '+88' + p;
    }
    return p;
  }

  Future<void> saveContact() async {
    String name = nameController.text.trim();
    String number = normalizePhone(numberController.text.trim());
    if (name.isEmpty || number.isEmpty) return;
    final newContact = EmergencyContact(name: name, phone: number);
    await EmergencyContactDB.insertContact(newContact);
    // Firestore sync: add/update guardian link
    try {
      final user = await UserDB.getLoggedInUser();
      if (user != null) {
        print('Saving guardian link for: ' + number);
        await FirebaseFirestore.instance.collection('guardian_links').doc(number).set({
          'guardians': FieldValue.arrayUnion([
            {
              'userName': user.name,
              'userPhone': normalizePhone(user.phone),
              'note': '',
            }
          ]),
          'addedBy': FieldValue.arrayUnion([
            {
              'uid': user.uid,
              'name': user.name,
              'userPhone': normalizePhone(user.phone),
              'note': '',
            }
          ])
        }, SetOptions(merge: true));
      }
    } catch (e) {
      print('Firestore error: ' + e.toString());
    }
    nameController.clear();
    numberController.clear();
    _fetchContacts();
  }

  void deleteContact(EmergencyContact contact) async {
    await EmergencyContactDB.deleteContact(contact.id!);
    _fetchContacts();
  }

  void editContact(EmergencyContact contact) {
    nameController.text = contact.name;
    numberController.text = contact.phone;
    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController noteController = TextEditingController(text: contact.note);
        bool isPriority = contact.isPriority;
        bool isBlocked = contact.isBlocked;
        return AlertDialog(
          title: const Text('Edit Contact'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: numberController,
                decoration: const InputDecoration(labelText: 'Number'),
                keyboardType: TextInputType.phone,
              ),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(labelText: 'Note'),
              ),
              Row(
                children: [
                  Checkbox(
                    value: isPriority,
                    onChanged: (val) {
                      isPriority = val ?? false;
                      (context as Element).markNeedsBuild();
                    },
                  ),
                  const Text('Priority'),
                  Checkbox(
                    value: isBlocked,
                    onChanged: (val) {
                      isBlocked = val ?? false;
                      (context as Element).markNeedsBuild();
                    },
                  ),
                  const Text('Blocked'),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final updated = EmergencyContact(
                  id: contact.id,
                  name: nameController.text.trim(),
                  phone: normalizePhone(numberController.text.trim()),
                  note: noteController.text.trim(),
                  isPriority: isPriority,
                  isBlocked: isBlocked,
                );
                await EmergencyContactDB.updateContact(updated);
                // Firestore sync: update note for guardian link
                try {
                  final user = await UserDB.getLoggedInUser();
                  if (user != null) {
                    final docRef = FirebaseFirestore.instance.collection('guardian_links').doc(updated.phone);
                    final doc = await docRef.get();
                    if (doc.exists) {
                      List guardians = (doc.data()?['guardians'] ?? []);
                      for (var g in guardians) {
                        if (normalizePhone(g['userPhone']) == normalizePhone(user.phone)) {
                          g['note'] = updated.note;
                        }
                      }
                      await docRef.update({'guardians': guardians});
                    }
                  }
                } catch (e) { print('Firestore update error: ' + e.toString()); }
                nameController.clear();
                numberController.clear();
                Navigator.pop(context);
                _fetchContacts();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void backspace() {
    setState(() {
      final text = numberController.text;
      if (text.isNotEmpty) {
        numberController.text = text.substring(0, text.length - 1);
      }
    });
  }

  void addDigit(String digit) {
    setState(() {
      numberController.text += digit;
    });
  }

  Widget buildKeypadButton(String text, {VoidCallback? onPressed}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(6.0),
        child: ElevatedButton(
          onPressed: onPressed ?? () => addDigit(text),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.all(20),
            backgroundColor: Colors.redAccent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: Text(text, style: const TextStyle(fontSize: 24)),
        ),
      ),
    );
  }

  Widget buildKeypad() {
    return Column(
      children: [
        for (int i = 0; i < 3; i++)
          Row(
            children: List.generate(
              3,
              (j) => buildKeypadButton('${i * 3 + j + 1}'),
            ),
          ),
        Row(
          children: [
            buildKeypadButton('X', onPressed: backspace),
            buildKeypadButton('0'),
            buildKeypadButton('+'),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (permissionDenied) {
      return Scaffold(
        appBar: AppBar(title: const Text('Your Guardian Contacts')),
        body: const Center(child: Text('Permission denied. Please enable contacts permission.')),
      );
    }
    final filteredContacts = contacts.where((contact) {
      return contact.name.toLowerCase().contains(searchText.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Guardian Contacts'),
        centerTitle: true,
        backgroundColor: Colors.redAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CustomTextField(
              labelText: 'Name',
              controller: nameController,
              hintText: 'Enter name',
              keyboardType: TextInputType.name, obscureText: false,
            ),
            const SizedBox(height: 12),
            CustomTextField(
              labelText: 'Number',
              controller: numberController,
              hintText: 'Enter number',
              readOnly: true,
              keyboardType: TextInputType.none, obscureText: false,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 140,
                  child: ElevatedButton(
                    onPressed: saveContact,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('SAVE', style: TextStyle(fontSize: 18)),
                  ),
                ),
                const SizedBox(width: 20),
                if (nameController.text.isNotEmpty || numberController.text.isNotEmpty)
                  SizedBox(
                    width: 140,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          nameController.clear();
                          numberController.clear();
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('CANCEL', style: TextStyle(fontSize: 18)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            buildKeypad(),
            const SizedBox(height: 20),
            CustomTextField(
              labelText: 'Search',
              controller: searchController,
              hintText: 'Search contacts',
              keyboardType: TextInputType.text,
              onChanged: (value) {
                setState(() {
                  searchText = value;
                });
              }, obscureText: false,
            ),
            const SizedBox(height: 20),
            if (filteredContacts.isEmpty)
              const Center(child: Text('No contacts found')),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredContacts.length,
              itemBuilder: (context, index) {
                final contact = filteredContacts[index];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: contact.isPriority ? Colors.orange : Colors.redAccent,
                      child: Text(contact.name.isNotEmpty ? contact.name[0].toUpperCase() : '?'),
                    ),
                    title: Text(
                      contact.name,
                      style: TextStyle(
                        color: contact.isBlocked ? Colors.grey : Colors.black,
                        fontWeight: contact.isPriority ? FontWeight.bold : FontWeight.normal,
                        decoration: contact.isBlocked ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(contact.phone),
                        if (contact.note.isNotEmpty) Text('Note: ${contact.note}'),
                        if (contact.isPriority)
                          const Text(
                            'Primary Guardian',
                            style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                          ),
                        if (contact.isBlocked)
                          const Text(
                            'Blocked',
                            style: TextStyle(color: Colors.grey),
                          ),
                      ],
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) async {
                        if (value == 'edit') {
                          editContact(contact);
                        } else if (value == 'delete') {
                          deleteContact(contact);
                        } else if (value == 'toggle_block') {
                          final updated = EmergencyContact(
                            id: contact.id,
                            name: contact.name,
                            phone: contact.phone,
                            note: contact.note,
                            isPriority: contact.isPriority,
                            isBlocked: !contact.isBlocked,
                          );
                          await EmergencyContactDB.updateContact(updated);
                          _fetchContacts();
                        } else if (value == 'make_primary') {
                          // Only one can be primary: set all to false, then set this one to true
                          for (var c in contacts) {
                            if (c.isPriority && c.id != contact.id) {
                              final notPrimary = EmergencyContact(
                                id: c.id,
                                name: c.name,
                                phone: c.phone,
                                note: c.note,
                                isPriority: false,
                                isBlocked: c.isBlocked,
                              );
                              await EmergencyContactDB.updateContact(notPrimary);
                            }
                          }
                          final updated = EmergencyContact(
                            id: contact.id,
                            name: contact.name,
                            phone: contact.phone,
                            note: contact.note,
                            isPriority: true,
                            isBlocked: contact.isBlocked,
                          );
                          await EmergencyContactDB.updateContact(updated);
                          _fetchContacts();
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'edit', child: Text('Edit')),
                        const PopupMenuItem(value: 'delete', child: Text('Delete')),
                        PopupMenuItem(
                          value: 'toggle_block',
                          child: Text(contact.isBlocked ? 'Unblock' : 'Block'),
                        ),
                        if (!contact.isPriority)
                          const PopupMenuItem(value: 'make_primary', child: Text('Mark as Primary')),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

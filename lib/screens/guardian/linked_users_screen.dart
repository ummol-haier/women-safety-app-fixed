import 'package:flutter/material.dart';

class LinkedUsersScreen extends StatelessWidget {
  const LinkedUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Dummy data - later dynamic data fetch korbo
    final List<Map<String, String>> linkedUsers = [
      {"name": "Samira", "phone": "+880123456789"},
      {"name": "Anika", "phone": "+880987654321"},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Linked Users"),
        backgroundColor: Colors.redAccent,
      ),
      body: ListView.builder(
        itemCount: linkedUsers.length,
        itemBuilder: (context, index) {
          final user = linkedUsers[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: const Icon(Icons.person, color: Colors.redAccent),
              title: Text(user["name"]!),
              subtitle: Text(user["phone"]!),
            ),
          );
        },
      ),
    );
  }
}

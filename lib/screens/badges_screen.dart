import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../database/database_helper.dart';

class BadgesScreen extends StatelessWidget {
  const BadgesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('نشان‌ها')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: DatabaseHelper.instance.getBadges(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final badges = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: badges.length,
            itemBuilder: (context, index) {
              final badge = badges[index];
              final unlocked = badge['unlocked'] == 1;
              return Card(
                child: ListTile(
                  leading: Text(badge['icon'], style: const TextStyle(fontSize: 32)),
                  title: Text(badge['name']),
                  subtitle: Text(badge['description']),
                  trailing: unlocked
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : const Icon(Icons.lock_outline),
                  enabled: unlocked,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
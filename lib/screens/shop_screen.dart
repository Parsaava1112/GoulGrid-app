import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/gamification_service.dart';
import '../services/task_provider.dart';

class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('فروشگاه امتیاز')),
      body: Consumer<TaskProvider>(
        builder: (context, taskProvider, _) {
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: GamificationService.shopItems.length,
            itemBuilder: (context, index) {
              final item = GamificationService.shopItems[index];
              final price = item['price'] as int;
              final canAfford = taskProvider.totalPoints >= price;
              return FutureBuilder<bool>(
                future: GamificationService.isItemPurchased(item['id']),
                builder: (context, snapshot) {
                  final purchased = snapshot.data ?? false;
                  return Card(
                    child: ListTile(
                      leading: Text(item['icon'], style: const TextStyle(fontSize: 32)),
                      title: Text(item['name']),
                      subtitle: Text(item['description']),
                      trailing: purchased
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : ElevatedButton(
                              onPressed: canAfford
                                  ? () async {
                                      // کسر امتیاز و ذخیره خرید
                                      // ساده‌سازی: اینجا فقط خرید ثبت می‌شود
                                      // در نسخه کامل باید امتیاز کم شود
                                      await GamificationService.purchaseItem(item['id']);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('${item['name']} خریداری شد!')),
                                        );
                                      }
                                    }
                                  : null,
                              child: Text('$price امتیاز'),
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
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/theme_provider.dart';
import 'badges_screen.dart';
import 'shop_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('تنظیمات')),
      body: ListView(
        children: [
          const ListTile(
            title: Text('تم برنامه'),
            subtitle: Text('انتخاب حالت نمایش'),
          ),
          RadioListTile<AppTheme>(
            title: const Text('تاریک'),
            value: AppTheme.dark,
            groupValue: themeProvider.theme,
            onChanged: (value) => themeProvider.setTheme(value!),
          ),
          RadioListTile<AppTheme>(
            title: const Text('روشن'),
            value: AppTheme.light,
            groupValue: themeProvider.theme,
            onChanged: (value) => themeProvider.setTheme(value!),
          ),
          RadioListTile<AppTheme>(
            title: const Text('مشکی خالص (AMOLED)'),
            value: AppTheme.amoled,
            groupValue: themeProvider.theme,
            onChanged: (value) => themeProvider.setTheme(value!),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.emoji_events),
            title: const Text('نشان‌ها'),
            trailing: const Icon(Icons.chevron_left),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BadgesScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.store),
            title: const Text('فروشگاه امتیاز'),
            trailing: const Icon(Icons.chevron_left),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ShopScreen()),
            ),
          ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('درباره امتیازدهی'),
            subtitle: Text('هر عادت ۵۰ امتیاز، بونوس تکمیل همه ۱۰۰ امتیاز'),
          ),
        ],
      ),
    );
  }
}
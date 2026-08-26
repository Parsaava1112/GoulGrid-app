import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common/sqlite_api.dart' show databaseFactory;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'database/database_helper.dart';
import 'screens/home_screen.dart';
import 'services/notification_service.dart';
import 'services/theme_provider.dart';
import 'services/task_provider.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // تنظیم دیتابیس برای دسکتاپ
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    // تنظیم منطقه زمانی
    tz.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Tehran'));
    } catch (e) {
      debugPrint('Warning: Could not set Tehran timezone, using UTC: $e');
      tz.setLocalLocation(tz.UTC);
    }

    // دیتابیس
    try {
      await DatabaseHelper.instance.database;
    } catch (e) {
      debugPrint('Database init failed: $e');
    }

    // سرویس اعلان
    try {
      await NotificationService.instance.init();
    } catch (e) {
      debugPrint('Notification init failed: $e');
    }

    // تم
    final themeProvider = ThemeProvider();
    try {
      await themeProvider.loadTheme();
    } catch (e) {
      debugPrint('Theme loading failed: $e');
    }

    // اجرای برنامه
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => themeProvider),
          ChangeNotifierProvider(create: (_) => TaskProvider()..loadData()),
        ],
        child: const MyApp(),
      ),
    );
  } catch (e) {
    debugPrint('Fatal error during startup: $e');
    runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'خطا در راه‌اندازی برنامه:\n$e',
                textDirection: TextDirection.rtl,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    final selectedDarkTheme = themeProvider.theme == AppTheme.amoled
        ? amoledTheme
        : darkTheme;

    return MaterialApp(
      title: 'مدیریت تسک و عادت',
      debugShowCheckedModeBanner: false,
      locale: const Locale('fa'),
      supportedLocales: const [Locale('fa')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: lightTheme,
      darkTheme: selectedDarkTheme,
      themeMode: themeProvider.isDark ? ThemeMode.dark : ThemeMode.light,
      home: const HomeScreen(),
    );
  }
}

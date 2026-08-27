import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'database/database_helper.dart';
import 'screens/home_screen.dart';
import 'services/notification_service.dart';
import 'services/theme_provider.dart';
import 'services/task_provider.dart';
import 'theme/app_theme.dart';

// برای پشتیبانی از دسکتاپ، فقط در صورت نیاز
import 'dart:io' show Platform;
import 'package:sqflite_common_ffi/sqflite_ffi.dart'
    if (dart.library.io) 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // تنظیم منطقه زمانی
  tz.initializeTimeZones();
  try {
    tz.setLocalLocation(tz.getLocation('Asia/Tehran'));
  } catch (e) {
    tz.setLocalLocation(tz.UTC);
  }

  // تنظیم دیتابیس برای دسکتاپ (در اندروید اجرا نمی‌شود)
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // اجرای برنامه با مدیریت خطا
  runZonedGuarded(() async {
    try {
      await DatabaseHelper.instance.database;
    } catch (e) {
      // اگر دیتابیس خطا داد، ادامه می‌دهیم
    }

    try {
      await NotificationService.instance.init();
    } catch (e) {
      // اگر اعلان خطا داد، ادامه می‌دهیم
    }

    final themeProvider = ThemeProvider();
    await themeProvider.loadTheme();

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => themeProvider),
          ChangeNotifierProvider(create: (_) => TaskProvider()..loadData()),
        ],
        child: const MyApp(),
      ),
    );
  }, (error, stackTrace) {
    // خطای سراسری – فقط چاپ می‌کنیم
    debugPrint('Uncaught error: $error');
    debugPrint('Stack trace: $stackTrace');
  });

  // خطاهای فریم‌ورک
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details); // در debug نمایش داده شود
  };
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    ThemeData selectedTheme;
    switch (themeProvider.theme) {
      case AppTheme.light:
        selectedTheme = lightTheme;
        break;
      case AppTheme.amoled:
        selectedTheme = amoledTheme;
        break;
      case AppTheme.dark:
      default:
        selectedTheme = darkTheme;
    }

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
      themeMode: themeProvider.isDark ? ThemeMode.dark : ThemeMode.light,
      darkTheme: selectedTheme,
      theme: selectedTheme,
      home: const HomeScreen(),
    );
  }
}

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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Asia/Tehran'));

  await DatabaseHelper.instance.database;
  await NotificationService.instance.init();

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

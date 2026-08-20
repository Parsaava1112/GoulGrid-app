import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

ThemeData _baseTheme(ColorScheme colorScheme, Brightness brightness) {
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: colorScheme,
  );
}

final darkTheme = _baseTheme(
  ColorScheme.fromSeed(seedColor: Colors.teal, brightness: Brightness.dark),
  Brightness.dark,
);

final lightTheme = _baseTheme(
  ColorScheme.fromSeed(seedColor: Colors.teal, brightness: Brightness.light),
  Brightness.light,
);

final amoledTheme = _baseTheme(
  ColorScheme(
    brightness: Brightness.dark,
    primary: Colors.tealAccent,
    onPrimary: Colors.black,
    secondary: Colors.teal,
    onSecondary: Colors.black,
    error: Colors.redAccent,
    onError: Colors.black,
    surface: Colors.black,
    onSurface: Colors.white,
  ),
  Brightness.dark,
);
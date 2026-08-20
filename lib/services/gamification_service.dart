import 'package:shared_preferences/shared_preferences.dart';

class GamificationService {
  static const int pointsPerLevel = 500; // هر ۵۰۰ امتیاز یک سطح

  static int getLevel(int totalPoints) => (totalPoints / pointsPerLevel).floor() + 1;
  static int getCurrentLevelPoints(int totalPoints) => totalPoints % pointsPerLevel;
  static int getNextLevelPoints() => pointsPerLevel;

  // آیتم‌های فروشگاه
  static const List<Map<String, dynamic>> shopItems = [
    {
      'id': 'theme_ocean',
      'name': 'تم اقیانوس',
      'description': 'رنگ‌های آبی خنک',
      'price': 200,
      'icon': '🌊',
    },
    {
      'id': 'theme_sunset',
      'name': 'تم غروب',
      'description': 'رنگ‌های گرم',
      'price': 300,
      'icon': '🌅',
    },
    {
      'id': 'theme_forest',
      'name': 'تم جنگل',
      'description': 'سبز آرامش‌بخش',
      'price': 250,
      'icon': '🌲',
    },
  ];

  static String getThemeColor(String themeId) {
    switch (themeId) {
      case 'theme_ocean':
        return '0xFF0277BD';
      case 'theme_sunset':
        return '0xFFE65100';
      case 'theme_forest':
        return '0xFF2E7D32';
      default:
        return '0xFF00897B'; // teal
    }
  }

  static Future<bool> isItemPurchased(String itemId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('shop_$itemId') ?? false;
  }

  static Future<void> purchaseItem(String itemId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('shop_$itemId', true);
  }
}
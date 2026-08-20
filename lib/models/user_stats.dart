class UserStats {
  final int totalPoints;
  final int level;
  final int currentLevelPoints;
  final int nextLevelPoints;
  final int bestStreak;
  final int currentStreak;
  final int badgesCount;

  UserStats({
    required this.totalPoints,
    required this.level,
    required this.currentLevelPoints,
    required this.nextLevelPoints,
    required this.bestStreak,
    required this.currentStreak,
    required this.badgesCount,
  });
}

class Badge {
  final String id;
  final String name;
  final String description;
  final String icon;
  final bool unlocked;

  Badge({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.unlocked,
  });
}
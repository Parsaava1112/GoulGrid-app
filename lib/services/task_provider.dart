import 'package:flutter/foundation.dart';

import '../database/database_helper.dart';
import '../models/completion.dart';
import '../models/task.dart';
import 'notification_service.dart';

class TaskProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  List<Task> _tasks = [];
  Set<int> _completedToday = {};
  int _todayPoints = 0;
  int _totalPoints = 0;
  bool _bonusEarnedToday = false;
  bool _loading = false;
  int _currentStreak = 0;
  int _bestStreak = 0;
  int _unlockedBadges = 0;

  List<Task> get tasks => _tasks;
  Set<int> get completedToday => _completedToday;
  int get todayPoints => _todayPoints;
  int get totalPoints => _totalPoints;
  bool get bonusEarnedToday => _bonusEarnedToday;
  bool get loading => _loading;
  int get currentStreak => _currentStreak;
  int get bestStreak => _bestStreak;
  int get unlockedBadges => _unlockedBadges;

  String get todayDate {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> loadData() async {
    _loading = true;
    notifyListeners();

    try {
      _tasks = await _db.getTasks(activeOnly: true);
      final completions = await _db.getCompletionsForDate(todayDate);
      _completedToday = completions.map((c) => c.taskId).toSet();

      final summary = await _db.getSummary(todayDate);
      _todayPoints = summary?.totalPoints ?? 0;
      _bonusEarnedToday = summary?.bonusEarned ?? false;
      _totalPoints = await _db.getTotalPoints();

      final streakInfo = await _db.getStreakInfo();
      _currentStreak = streakInfo['current'] as int;
      _bestStreak = streakInfo['best'] as int;

      _unlockedBadges = await _db.getUnlockedBadgesCount();

      await _rescheduleAll();
      await _checkAndUnlockBadges();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> _rescheduleAll() async {
    for (final task in _tasks) {
      await NotificationService.instance.scheduleTaskNotification(task);
    }
  }

  Future<void> addTask(Task task) async {
    final id = await _db.insertTask(task);
    final newTask = task.copyWith(id: id);
    _tasks.add(newTask);
    await NotificationService.instance.scheduleTaskNotification(newTask);
    notifyListeners();
  }

  Future<void> updateTask(Task task) async {
    await _db.updateTask(task);
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) _tasks[index] = task;
    await NotificationService.instance.scheduleTaskNotification(task);
    notifyListeners();
  }

  Future<void> deleteTask(int id) async {
    await _db.deleteTask(id);
    _tasks.removeWhere((t) => t.id == id);
    _completedToday.remove(id);
    await NotificationService.instance.cancelTaskNotification(id);
    notifyListeners();
  }

  Future<bool> completeTask(int taskId, bool verified) async {
    if (!verified || _completedToday.contains(taskId)) return false;

    final date = todayDate;
    final now = DateTime.now();
    final completion = Completion(
      taskId: taskId,
      date: date,
      completedAt: now.toIso8601String(),
      pointsEarned: 50,
    );

    await _db.insertCompletion(completion);
    await _db.addPoints(date, 50);

    _completedToday.add(taskId);
    _todayPoints += 50;
    _totalPoints += 50;

    // بررسی تکمیل همه و بونوس
    final allDone = _tasks.every((task) => _completedToday.contains(task.id));
    if (allDone && !_bonusEarnedToday && _tasks.isNotEmpty) {
      await _db.addPoints(date, 100, bonus: true);
      _todayPoints += 100;
      _totalPoints += 100;
      _bonusEarnedToday = true;
    }

    // به‌روزرسانی استریک
    await _db.updateStreak(date, _completedToday.length, _tasks.length);
    final streakInfo = await _db.getStreakInfo();
    _currentStreak = streakInfo['current'] as int;
    _bestStreak = streakInfo['best'] as int;

    await _checkAndUnlockBadges();
    notifyListeners();
    return true;
  }

  Future<void> _checkAndUnlockBadges() async {
    // نشان اول
    if (_totalPoints > 0) {
      await _db.unlockBadge('first_task');
    }
    // استریک ۳
    if (_bestStreak >= 3) {
      await _db.unlockBadge('streak_3');
    }
    // استریک ۷
    if (_bestStreak >= 7) {
      await _db.unlockBadge('streak_7');
    }
    // امتیاز ۵۰۰
    if (_totalPoints >= 500) {
      await _db.unlockBadge('points_500');
    }
    // امتیاز ۱۰۰۰
    if (_totalPoints >= 1000) {
      await _db.unlockBadge('points_1000');
    }
    _unlockedBadges = await _db.getUnlockedBadgesCount();
  }
}
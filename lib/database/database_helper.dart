import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/completion.dart';
import '../models/daily_summary.dart';
import '../models/task.dart';

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();
  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'habit_manager.db');
    return openDatabase(
      path,
      version: 2,
      onConfigure: (db) async => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tasks(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT DEFAULT '',
        category TEXT DEFAULT 'عمومی',
        reminder_time TEXT NOT NULL,
        verification_question TEXT DEFAULT 'آیا این کار را واقعاً انجام دادید؟',
        is_active INTEGER DEFAULT 1,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE completions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        task_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        completed_at TEXT NOT NULL,
        points_earned INTEGER NOT NULL,
        FOREIGN KEY(task_id) REFERENCES tasks(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE daily_summary(
        date TEXT PRIMARY KEY,
        total_points INTEGER DEFAULT 0,
        bonus_earned INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE streaks(
        date TEXT PRIMARY KEY,
        all_completed INTEGER DEFAULT 0,
        completed_count INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE badges(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        icon TEXT NOT NULL,
        unlocked INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE shop_purchases(
        item_id TEXT PRIMARY KEY,
        purchased_at TEXT NOT NULL
      )
    ''');

    await _seedBadges(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE streaks(
          date TEXT PRIMARY KEY,
          all_completed INTEGER DEFAULT 0,
          completed_count INTEGER DEFAULT 0
        )
      ''');
      await db.execute('''
        CREATE TABLE badges(
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          description TEXT NOT NULL,
          icon TEXT NOT NULL,
          unlocked INTEGER DEFAULT 0
        )
      ''');
      await db.execute('''
        CREATE TABLE shop_purchases(
          item_id TEXT PRIMARY KEY,
          purchased_at TEXT NOT NULL
        )
      ''');
      await _seedBadges(db);
    }
  }

  Future<void> _seedBadges(Database db) async {
    final badges = [
      {'id': 'first_task', 'name': 'اولین قدم', 'description': 'اولین تسک را انجام دادید', 'icon': '🎯'},
      {'id': 'streak_3', 'name': 'سه روز پیاپی', 'description': '۳ روز پیاپی همه عادت‌ها را انجام دادید', 'icon': '🔥'},
      {'id': 'streak_7', 'name': 'هفته طلایی', 'description': '۷ روز پیاپی', 'icon': '🏆'},
      {'id': 'points_500', 'name': 'نیم‌هزار', 'description': 'کسب ۵۰۰ امتیاز', 'icon': '⭐'},
      {'id': 'points_1000', 'name': 'هزارتایی', 'description': 'کسب ۱۰۰۰ امتیاز', 'icon': '💎'},
    ];
    for (final badge in badges) {
      await db.insert('badges', {
        'id': badge['id'],
        'name': badge['name'],
        'description': badge['description'],
        'icon': badge['icon'],
        'unlocked': 0,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }

  // ----- Task CRUD -----
  Future<int> insertTask(Task task) async {
    final db = await database;
    return db.insert('tasks', task.toMap());
  }

  Future<int> updateTask(Task task) async {
    final db = await database;
    return db.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<int> deleteTask(int id) async {
    final db = await database;
    return db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Task>> getTasks({bool activeOnly = true}) async {
    final db = await database;
    final rows = activeOnly
        ? await db.query('tasks', where: 'is_active = ?', whereArgs: [1])
        : await db.query('tasks');
    return rows.map((row) => Task.fromMap(row)).toList();
  }

  Future<Task?> getTask(int id) async {
    final db = await database;
    final rows = await db.query('tasks', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Task.fromMap(rows.first);
  }

  // ----- Completions -----
  Future<int> insertCompletion(Completion completion) async {
    final db = await database;
    return db.insert('completions', completion.toMap());
  }

  Future<List<Completion>> getCompletionsForDate(String date) async {
    final db = await database;
    final rows = await db.query('completions', where: 'date = ?', whereArgs: [date]);
    return rows.map((row) => Completion.fromMap(row)).toList();
  }

  Future<bool> isTaskCompletedOnDate(int taskId, String date) async {
    final db = await database;
    final rows = await db.query(
      'completions',
      where: 'task_id = ? AND date = ?',
      whereArgs: [taskId, date],
    );
    return rows.isNotEmpty;
  }

  Future<int> countCompletionsForDate(String date) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM completions WHERE date = ?',
      [date],
    );
    return (result.first['count'] as int?) ?? 0;
  }

  // ----- Daily Summary -----
  Future<DailySummary?> getSummary(String date) async {
    final db = await database;
    final rows = await db.query('daily_summary', where: 'date = ?', whereArgs: [date]);
    if (rows.isEmpty) return null;
    final row = rows.first;
    return DailySummary(
      date: row['date'] as String,
      totalPoints: row['total_points'] as int? ?? 0,
      bonusEarned: (row['bonus_earned'] as int? ?? 0) == 1,
    );
  }

  Future<void> addPoints(String date, int points, {bool bonus = false}) async {
    final db = await database;
    await db.transaction((txn) async {
      final rows = await txn.query('daily_summary', where: 'date = ?', whereArgs: [date]);
      if (rows.isEmpty) {
        await txn.insert('daily_summary', {
          'date': date,
          'total_points': points,
          'bonus_earned': bonus ? 1 : 0,
        });
      } else {
        final current = rows.first['total_points'] as int? ?? 0;
        final alreadyBonus = (rows.first['bonus_earned'] as int? ?? 0) == 1;
        await txn.update(
          'daily_summary',
          {
            'total_points': current + points,
            'bonus_earned': (alreadyBonus || bonus) ? 1 : 0,
          },
          where: 'date = ?',
          whereArgs: [date],
        );
      }
    });
  }

  Future<int> getTotalPoints() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(total_points), 0) as total FROM daily_summary',
    );
    return (result.first['total'] as int?) ?? 0;
  }

  // ----- Streaks -----
  Future<void> updateStreak(String date, int completedCount, int totalTasks) async {
    final db = await database;
    final allCompleted = completedCount >= totalTasks && totalTasks > 0 ? 1 : 0;
    await db.insert('streaks', {
      'date': date,
      'all_completed': allCompleted,
      'completed_count': completedCount,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, dynamic>> getStreakInfo() async {
    final db = await database;
    final rows = await db.query('streaks', orderBy: 'date DESC');
    int currentStreak = 0;
    int bestStreak = 0;
    int tempStreak = 0;

    for (final row in rows) {
      if ((row['all_completed'] as int? ?? 0) == 1) {
        tempStreak++;
        if (tempStreak > bestStreak) bestStreak = tempStreak;
      } else {
        tempStreak = 0;
      }
    }

    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final todayRow = rows.where((r) => r['date'] == todayStr).toList();
    if (todayRow.isNotEmpty && (todayRow.first['all_completed'] as int? ?? 0) == 1) {
      currentStreak = 1;
      var checkDate = today.subtract(const Duration(days: 1));
      while (true) {
        final dateStr = '${checkDate.year}-${checkDate.month.toString().padLeft(2, '0')}-${checkDate.day.toString().padLeft(2, '0')}';
        final row = rows.where((r) => r['date'] == dateStr).toList();
        if (row.isNotEmpty && (row.first['all_completed'] as int? ?? 0) == 1) {
          currentStreak++;
          checkDate = checkDate.subtract(const Duration(days: 1));
        } else {
          break;
        }
      }
    }

    return {'current': currentStreak, 'best': bestStreak};
  }

  // ----- Badges -----
  Future<List<Map<String, dynamic>>> getBadges() async {
    final db = await database;
    return db.query('badges');
  }

  Future<void> unlockBadge(String id) async {
    final db = await database;
    await db.update('badges', {'unlocked': 1}, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> getUnlockedBadgesCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM badges WHERE unlocked = 1');
    return (result.first['count'] as int?) ?? 0;
  }

  // ----- Shop -----
  Future<bool> isItemPurchased(String itemId) async {
    final db = await database;
    final rows = await db.query('shop_purchases', where: 'item_id = ?', whereArgs: [itemId]);
    return rows.isNotEmpty;
  }

  Future<void> purchaseItem(String itemId) async {
    final db = await database;
    await db.insert('shop_purchases', {
      'item_id': itemId,
      'purchased_at': DateTime.now().toIso8601String(),
    });
  }
}

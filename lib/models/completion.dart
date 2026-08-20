class Completion {
  final int? id;
  final int taskId;
  final String date;
  final String completedAt;
  final int pointsEarned;

  Completion({
    this.id,
    required this.taskId,
    required this.date,
    required this.completedAt,
    this.pointsEarned = 50,
  });

  Map<String, dynamic> toMap() {
    return {
      'task_id': taskId,
      'date': date,
      'completed_at': completedAt,
      'points_earned': pointsEarned,
    };
  }

  factory Completion.fromMap(Map<String, dynamic> map) {
    return Completion(
      id: map['id'] as int?,
      taskId: map['task_id'] as int,
      date: map['date'] as String,
      completedAt: map['completed_at'] as String,
      pointsEarned: map['points_earned'] as int? ?? 50,
    );
  }
}
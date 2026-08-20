class Task {
  final int? id;
  final String title;
  final String description;
  final String category;
  final String reminderTime; // فرمت: HH:mm
  final String verificationQuestion;
  final bool isActive;
  final String createdAt;

  Task({
    this.id,
    required this.title,
    this.description = '',
    this.category = 'عمومی',
    required this.reminderTime,
    this.verificationQuestion = 'آیا این کار را واقعاً انجام دادید؟',
    this.isActive = true,
    required this.createdAt,
  });

  Task copyWith({
    int? id,
    String? title,
    String? description,
    String? category,
    String? reminderTime,
    String? verificationQuestion,
    bool? isActive,
    String? createdAt,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      reminderTime: reminderTime ?? this.reminderTime,
      verificationQuestion: verificationQuestion ?? this.verificationQuestion,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'reminder_time': reminderTime,
      'verification_question': verificationQuestion,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] as int?,
      title: map['title'] as String,
      description: map['description'] as String? ?? '',
      category: map['category'] as String? ?? 'عمومی',
      reminderTime: map['reminder_time'] as String,
      verificationQuestion: map['verification_question'] as String? ??
          'آیا این کار را واقعاً انجام دادید؟',
      isActive: (map['is_active'] as int? ?? 1) == 1,
      createdAt: map['created_at'] as String,
    );
  }
}
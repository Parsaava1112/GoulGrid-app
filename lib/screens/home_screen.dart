import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/task.dart';
import '../services/task_provider.dart';
import 'add_edit_task_screen.dart';
import 'settings_screen.dart';
import 'statistics_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _celebrate() {
    _confettiController.play();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مدیریت تسک و عادت'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const StatisticsScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddEditTaskScreen()),
        ),
        child: const Icon(Icons.add),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              _SummaryCard(provider: context.watch<TaskProvider>()),
              Expanded(
                child: Consumer<TaskProvider>(
                  builder: (context, provider, _) {
                    if (provider.loading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (provider.tasks.isEmpty) {
                      return const _EmptyState();
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.only(bottom: 80),
                      itemCount: provider.tasks.length,
                      itemBuilder: (context, index) {
                        final task = provider.tasks[index];
                        final done = provider.completedToday.contains(task.id);
                        return _TaskTile(
                          task: task,
                          done: done,
                          onToggle: () => _showVerificationDialog(task),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showVerificationDialog(Task task) async {
    final provider = context.read<TaskProvider>();

    if (provider.completedToday.contains(task.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('این تسک امروز انجام شده است.')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تأیید انجام'),
        content: Text(task.verificationQuestion),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('خیر'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('بله'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final earned = await provider.completeTask(task.id!, true);
      if (earned) {
        _celebrate();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تسک انجام شد +۵۰ امتیاز')),
          );
        }
      }
    }
  }
}

class _SummaryCard extends StatelessWidget {
  final TaskProvider provider;

  const _SummaryCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    final completed = provider.completedToday.length;
    final total = provider.tasks.length;
    final progress = total == 0 ? 0.0 : completed / total;
    final level = (provider.totalPoints / 500).floor() + 1;
    final levelProgress = (provider.totalPoints % 500) / 500;

    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('امتیاز امروز', style: Theme.of(context).textTheme.titleMedium),
                Text('${provider.todayPoints} امتیاز',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.star, size: 18, color: Colors.amber),
                const SizedBox(width: 4),
                Text('سطح $level'),
                const Spacer(),
                Text('استریک: ${provider.currentStreak} روز 🔥'),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: levelProgress),
            const SizedBox(height: 8),
            Text('کل امتیاز: ${provider.totalPoints}'),
            const SizedBox(height: 12),
            LinearProgressIndicator(value: progress),
            const SizedBox(height: 8),
            Text('$completed از $total انجام شده'),
            if (provider.bonusEarnedToday)
              const Chip(label: Text('بونوس ۱۰۰ امتیازی دریافت شد 🎉')),
          ],
        ),
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  final Task task;
  final bool done;
  final VoidCallback onToggle;

  const _TaskTile({
    required this.task,
    required this.done,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: Checkbox(
          value: done,
          onChanged: (_) => onToggle(),
        ),
        title: Text(
          task.title,
          style: TextStyle(
            decoration: done ? TextDecoration.lineThrough : null,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              children: [
                Chip(
                  label: Text(task.category),
                  visualDensity: VisualDensity.compact,
                ),
                Chip(
                  label: Text('⏰ ${task.reminderTime}'),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            if (task.description.isNotEmpty)
              Text(
                task.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddEditTaskScreen(task: task),
                ),
              );
            } else if (value == 'delete') {
              context.read<TaskProvider>().deleteTask(task.id!);
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'edit', child: Text('ویرایش')),
            PopupMenuItem(value: 'delete', child: Text('حذف')),
          ],
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AddEditTaskScreen(task: task)),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.checklist,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'هنوز تسکی اضافه نشده است.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}

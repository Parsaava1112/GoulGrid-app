import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/task.dart';
import '../services/task_provider.dart';

class AddEditTaskScreen extends StatefulWidget {
  final Task? task;

  const AddEditTaskScreen({super.key, this.task});

  @override
  State<AddEditTaskScreen> createState() => _AddEditTaskScreenState();
}

class _AddEditTaskScreenState extends State<AddEditTaskScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _categoryController;
  late final TextEditingController _timeController;
  late final TextEditingController _verificationController;

  bool _saving = false; // جلوگیری از کلیک دوباره

  bool get isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();
    final task = widget.task;
    _titleController = TextEditingController(text: task?.title ?? '');
    _descriptionController = TextEditingController(text: task?.description ?? '');
    _categoryController = TextEditingController(text: task?.category ?? '');
    _timeController = TextEditingController(text: task?.reminderTime ?? '');
    _verificationController = TextEditingController(
      text: task?.verificationQuestion ?? 'آیا این کار را واقعاً انجام دادید؟',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _timeController.dispose();
    _verificationController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (time != null) {
      setState(() {
        _timeController.text =
            '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _save() async {
    if (_saving) return; // جلوگیری از کلیک همزمان

    if (!_formKey.currentState!.validate()) {
      // نمایش پیام خطا
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لطفاً خطاهای فرم را برطرف کنید.')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final now = DateTime.now();
      final dateStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final task = Task(
        id: widget.task?.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _categoryController.text.trim().isEmpty
            ? 'عمومی'
            : _categoryController.text.trim(),
        reminderTime: _timeController.text.trim(),
        verificationQuestion: _verificationController.text.trim().isEmpty
            ? 'آیا این کار را واقعاً انجام دادید؟'
            : _verificationController.text.trim(),
        createdAt: widget.task?.createdAt ?? dateStr,
      );

      final provider = context.read<TaskProvider>();
      if (isEditing) {
        await provider.updateTask(task);
      } else {
        await provider.addTask(task);
      }

      if (mounted) {
        Navigator.pop(context);
        // نمایش پیام موفقیت
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isEditing ? 'تسک ویرایش شد.' : 'تسک اضافه شد.')),
        );
      }
    } catch (e) {
      debugPrint('Error saving task: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('خطا در ذخیره‌سازی. لطفاً دوباره تلاش کنید.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'ویرایش تسک' : 'افزودن تسک'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'عنوان تسک',
                hintText: 'مثلاً ورزش صبحگاهی',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'عنوان الزامی است';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'توضیحات',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _categoryController,
              decoration: const InputDecoration(
                labelText: 'دسته‌بندی',
                hintText: 'کار، سلامتی، ورزش، مطالعه، شخصی...',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _timeController,
              readOnly: true,
              onTap: _pickTime,
              decoration: const InputDecoration(
                labelText: 'زمان یادآوری',
                suffixIcon: Icon(Icons.access_time),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'زمان یادآوری را انتخاب کنید';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _verificationController,
              decoration: const InputDecoration(
                labelText: 'سوال تأیید انجام',
                hintText: 'آیا این کار را واقعاً انجام دادید؟',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _saving ? null : _save, // غیرفعال هنگام ذخیره
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: Text(isEditing ? 'ذخیره تغییرات' : 'افزودن تسک'),
            ),
          ],
        ),
      ),
    );
  }
}

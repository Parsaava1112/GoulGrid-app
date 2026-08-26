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
  final _messengerKey = GlobalKey<ScaffoldMessengerState>(); // برای پیام بعد از بستن

  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _categoryController;
  late final TextEditingController _timeController;
  late final TextEditingController _verificationController;

  bool get isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();
    final task = widget.task;
    _titleController = TextEditingController(text: task?.title ?? '');
    _descriptionController = TextEditingController(text: task?.description ?? '');
    _categoryController = TextEditingController(text: task?.category ?? '');
    _timeController = TextEditingController(text: task?.reminderTime ?? '09:00'); // پیش‌فرض
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
    // بستن کیبورد
    FocusScope.of(context).unfocus();

    // اعتبارسنجی
    if (!_formKey.currentState!.validate()) {
      _messengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('لطفاً خطاهای فرم را برطرف کنید.')),
      );
      return;
    }

    try {
      final now = DateTime.now();
      final dateStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      // اگر زمان خالی باشد، پیش‌فرض 09:00
      final reminderTime = _timeController.text.trim().isEmpty
          ? '09:00'
          : _timeController.text.trim();

      final task = Task(
        id: widget.task?.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _categoryController.text.trim().isEmpty
            ? 'عمومی'
            : _categoryController.text.trim(),
        reminderTime: reminderTime,
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

      // نمایش پیام موفقیت با استفاده از messengerKey (حتی بعد از بستن صفحه)
      _messengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(isEditing ? 'تسک ویرایش شد.' : 'تسک اضافه شد.')),
      );

      // بستن صفحه بعد از نمایش پیام
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error saving task: $e');
      _messengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('خطا در ذخیره‌سازی. لطفاً دوباره تلاش کنید.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: _messengerKey,
      child: Scaffold(
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
                  labelText: 'عنوان تسک *',
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
              // فیلد زمان: حالا اختیاری است و پیش‌فرض 09:00 دارد
              TextFormField(
                controller: _timeController,
                readOnly: true,
                onTap: _pickTime,
                decoration: const InputDecoration(
                  labelText: 'زمان یادآوری',
                  hintText: 'پیش‌فرض: 09:00',
                  suffixIcon: Icon(Icons.access_time),
                ),
                // بدون validator
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
                onPressed: _save,
                icon: const Icon(Icons.save),
                label: Text(isEditing ? 'ذخیره تغییرات' : 'افزودن تسک'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

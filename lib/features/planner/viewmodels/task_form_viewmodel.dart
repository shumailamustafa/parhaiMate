import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/utils/date_time_utils.dart';
import '../../../domain/entities/domain_entities.dart';
import '../../../domain/repositories/repositories.dart';

/// ViewModel for Add & Edit Study Task screens.
class TaskFormViewModel extends GetxController {
  TaskFormViewModel({
    required PlannerRepository plannerRepository,
    required SubjectRepository subjectRepository,
    DateTime Function()? nowProvider,
    dynamic initialArgs,
  })  : _plannerRepository = plannerRepository,
        _subjectRepository = subjectRepository,
        _nowProvider = nowProvider ?? DateTime.now,
        _initialArgs = initialArgs;

  static const int minDurationMinutes = 15;
  static const int maxDurationMinutes = 360;
  static const int durationStepMinutes = 15;
  static const List<int> durationChoices = <int>[15, 30, 45, 60, 90];

  final PlannerRepository _plannerRepository;
  final SubjectRepository _subjectRepository;
  final DateTime Function() _nowProvider;
  final dynamic _initialArgs;

  final TextEditingController titleController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  final Rxn<PlannerTaskEntity> editingTask = Rxn<PlannerTaskEntity>();
  final RxList<SubjectEntity> subjects = <SubjectEntity>[].obs;
  final RxnInt selectedSubjectId = RxnInt();
  late final Rx<DateTime> selectedDate;
  final RxString scheduledTime = '16:00'.obs;
  final RxInt targetMinutes = 30.obs;
  final RxnString titleError = RxnString();
  final RxBool isSaving = false.obs;
  final RxBool isLoading = false.obs;

  StreamSubscription<List<SubjectEntity>>? _subjectsSub;
  bool _disposed = false;

  bool get isEditing => editingTask.value != null;

  DateTime get today => DateTimeUtils.startOfDay(_nowProvider());

  @override
  void onInit() {
    super.onInit();
    selectedDate = today.obs;

    titleController.addListener(() {
      if (titleError.value != null && titleController.text.trim().isNotEmpty) {
        titleError.value = null;
      }
    });

    _subjectsSub = _subjectRepository
        .watchSubjects(archived: false)
        .listen(subjects.assignAll);

    final arg = _initialArgs ?? Get.arguments;
    if (arg is int) {
      unawaited(_loadTaskForEdit(arg));
    } else if (arg is PlannerTaskEntity) {
      _populateFromEntity(arg);
    } else if (arg is Map<String, dynamic>) {
      final dateArg = arg['date'];
      if (dateArg is DateTime) {
        selectedDate.value = DateTimeUtils.startOfDay(dateArg);
      }
      final subjectArg = arg['subjectId'];
      if (subjectArg is int) {
        selectedSubjectId.value = subjectArg;
      }
    }
  }

  Future<void> _loadTaskForEdit(int taskId) async {
    isLoading.value = true;
    try {
      final loaded = await _plannerRepository.getById(taskId);
      if (!_disposed && loaded != null) {
        _populateFromEntity(loaded);
      }
    } finally {
      if (!_disposed) {
        isLoading.value = false;
      }
    }
  }

  void _populateFromEntity(PlannerTaskEntity task) {
    editingTask.value = task;
    titleController.text = task.title;
    notesController.text = task.notes ?? '';
    selectedSubjectId.value = task.subjectId;
    selectedDate.value = DateTimeUtils.parseDateKey(task.scheduledDate);
    scheduledTime.value = (task.scheduledTime?.trim().isNotEmpty ?? false)
        ? task.scheduledTime!.trim()
        : '16:00';
    targetMinutes.value =
        task.targetMinutes.clamp(minDurationMinutes, maxDurationMinutes);
  }

  SubjectEntity? get selectedSubject {
    final id = selectedSubjectId.value;
    if (id == null) {
      return null;
    }
    for (final s in subjects) {
      if (s.id == id) {
        return s;
      }
    }
    return null;
  }

  String get formattedDateLabel => DateTimeUtils.formatFullDate(selectedDate.value);

  String get formattedTimeLabel {
    final label = DateTimeUtils.formatTaskTimeLabel(scheduledTime.value);
    return label.isEmpty ? 'No specific time' : label;
  }

  String get formattedDurationSummary => '${targetMinutes.value} minutes';

  void selectSubject(int? subjectId) {
    selectedSubjectId.value = subjectId;
  }

  void selectDate(DateTime date) {
    selectedDate.value = DateTimeUtils.startOfDay(date);
  }

  void selectTime(TimeOfDay time) {
    final hh = time.hour.toString().padLeft(2, '0');
    final mm = time.minute.toString().padLeft(2, '0');
    scheduledTime.value = '$hh:$mm';
  }

  void selectTimeKey(String key) {
    scheduledTime.value = key;
  }

  void selectDuration(int minutes) {
    targetMinutes.value =
        minutes.clamp(minDurationMinutes, maxDurationMinutes);
  }

  void adjustDuration(int delta) {
    targetMinutes.value =
        (targetMinutes.value + delta).clamp(minDurationMinutes, maxDurationMinutes);
  }

  TimeOfDay get currentTimeOfDay {
    final parts = scheduledTime.value.split(':');
    if (parts.length == 2) {
      final h = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      if (h != null && m != null && h >= 0 && h < 24 && m >= 0 && m < 60) {
        return TimeOfDay(hour: h, minute: m);
      }
    }
    return const TimeOfDay(hour: 16, minute: 0);
  }

  Future<bool> saveTask() async {
    final title = titleController.text.trim();
    if (title.isEmpty) {
      titleError.value = 'Enter a task title';
      return false;
    }
    if (isSaving.value) {
      return false;
    }

    isSaving.value = true;
    try {
      final cleanNotes = notesController.text.trim();
      final notesVal = cleanNotes.isEmpty ? null : cleanNotes;
      final dateKey = DateTimeUtils.toDateKey(selectedDate.value);
      final timeVal =
          scheduledTime.value.trim().isEmpty ? null : scheduledTime.value.trim();

      final current = editingTask.value;
      if (current == null) {
        await _plannerRepository.createTask(
          subjectId: selectedSubjectId.value,
          title: title,
          scheduledDate: dateKey,
          scheduledTime: timeVal,
          targetMinutes: targetMinutes.value,
          notes: notesVal,
        );
      } else {
        await _plannerRepository.updateTask(
          PlannerTaskEntity(
            id: current.id,
            subjectId: selectedSubjectId.value,
            title: title,
            scheduledDate: dateKey,
            scheduledTime: timeVal,
            targetMinutes: targetMinutes.value,
            notes: notesVal,
            isCompleted: current.isCompleted,
            createdAtMs: current.createdAtMs,
            updatedAtMs: DateTime.now().toUtc().millisecondsSinceEpoch,
          ),
        );
      }
      return true;
    } finally {
      if (!_disposed) {
        isSaving.value = false;
      }
    }
  }

  Future<void> toggleDoneAndExit() async {
    final current = editingTask.value;
    if (current == null) {
      return;
    }
    await _plannerRepository.toggleTaskCompletion(
      current.id,
      isCompleted: !current.isCompleted,
    );
  }

  void startStudyingNow() {
    final current = editingTask.value;
    final notesSeed =
        titleController.text.trim().isNotEmpty ? titleController.text.trim() : null;
    unawaited(
      Get.offNamed<void>(
        AppRoutes.sessionSetup,
        arguments: <String, dynamic>{
          if ((selectedSubjectId.value ?? current?.subjectId) != null)
            'subjectId': selectedSubjectId.value ?? current?.subjectId,
          'focusMinutes': targetMinutes.value,
          if (notesSeed != null) 'notes': notesSeed,
        },
      ),
    );
  }

  Future<void> deleteTask() async {
    final current = editingTask.value;
    if (current == null) {
      return;
    }
    await _plannerRepository.deleteTask(current.id);
  }

  @override
  void onClose() {
    _disposed = true;
    unawaited(_subjectsSub?.cancel());
    titleController.dispose();
    notesController.dispose();
    super.onClose();
  }
}

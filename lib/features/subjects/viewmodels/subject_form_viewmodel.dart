import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/utils/date_time_utils.dart';
import '../../../domain/entities/domain_entities.dart';
import '../../../domain/enums/domain_enums.dart';
import '../../../domain/repositories/repositories.dart';

/// ViewModel for Add Subject & Edit Subject screens.
class SubjectFormViewModel extends GetxController {
  SubjectFormViewModel({
    required SubjectRepository subjectRepository,
    required SessionRepository sessionRepository,
    required PlannerRepository plannerRepository,
    int? initialSubjectId,
  })  : _subjectRepository = subjectRepository,
        _sessionRepository = sessionRepository,
        _plannerRepository = plannerRepository,
        _initialSubjectId = initialSubjectId;

  static const int minTargetMinutes = 30;
  static const int maxTargetMinutes = 2400;
  static const int targetStepMinutes = 30;

  final SubjectRepository _subjectRepository;
  final SessionRepository _sessionRepository;
  final PlannerRepository _plannerRepository;
  final int? _initialSubjectId;

  final TextEditingController nameController = TextEditingController();

  final Rxn<SubjectEntity> editingSubject = Rxn<SubjectEntity>();
  final Rx<SubjectIconKey> selectedIcon = SubjectIconKey.sigma.obs;
  final Rx<SubjectIdentifier> selectedIdentifier = SubjectIdentifier.circle.obs;
  final RxInt targetMinutes = 300.obs;
  final RxnString nameError = RxnString();
  final RxBool isSaving = false.obs;
  final RxBool isLoading = false.obs;
  final RxInt linkedSessionsCount = 0.obs;
  final RxInt linkedTasksCount = 0.obs;

  bool _disposed = false;

  bool get isEditing => editingSubject.value != null;

  @override
  void onInit() {
    super.onInit();
    nameController.addListener(() {
      if (nameError.value != null && nameController.text.trim().isNotEmpty) {
        nameError.value = null;
      }
    });

    final arg = _initialSubjectId ?? Get.arguments;
    if (arg is int) {
      unawaited(_loadSubjectForEdit(arg));
    } else if (arg is SubjectEntity) {
      _populateFromEntity(arg);
      unawaited(_loadLinkedCounts(arg.id));
    }
  }

  Future<void> _loadSubjectForEdit(int subjectId) async {
    isLoading.value = true;
    try {
      final loaded = await _subjectRepository.getById(subjectId);
      if (!_disposed && loaded != null) {
        _populateFromEntity(loaded);
        await _loadLinkedCounts(loaded.id);
      }
    } finally {
      if (!_disposed) {
        isLoading.value = false;
      }
    }
  }

  Future<void> _loadLinkedCounts(int subjectId) async {
    final sessions = await _sessionRepository.getCompletedSessions(
      subjectId: subjectId,
    );
    final tasks = await _plannerRepository.getAllTasks();
    final subjectTasks = tasks.where((t) => t.subjectId == subjectId).length;
    if (!_disposed) {
      linkedSessionsCount.value = sessions.length;
      linkedTasksCount.value = subjectTasks;
    }
  }

  void _populateFromEntity(SubjectEntity subject) {
    editingSubject.value = subject;
    nameController.text = subject.name;
    selectedIcon.value = subject.iconKey;
    selectedIdentifier.value = subject.identifier;
    targetMinutes.value =
        subject.targetMinutes.clamp(minTargetMinutes, maxTargetMinutes);
  }

  void selectIcon(SubjectIconKey iconKey) {
    selectedIcon.value = iconKey;
  }

  void selectIdentifier(SubjectIdentifier identifier) {
    selectedIdentifier.value = identifier;
  }

  void adjustTargetMinutes(int delta) {
    targetMinutes.value =
        (targetMinutes.value + delta).clamp(minTargetMinutes, maxTargetMinutes);
  }

  String get weeklyTargetCaption =>
      '${DateTimeUtils.formatMinutes(targetMinutes.value)} per week';

  Future<bool> saveSubject() async {
    final trimmed = nameController.text.trim();
    if (trimmed.isEmpty) {
      nameError.value = 'Enter a subject name';
      return false;
    }
    if (isSaving.value) {
      return false;
    }

    isSaving.value = true;
    try {
      final current = editingSubject.value;
      if (current == null) {
        await _subjectRepository.createSubject(
          name: trimmed,
          identifier: selectedIdentifier.value,
          iconKey: selectedIcon.value,
          targetMinutes: targetMinutes.value,
        );
      } else {
        await _subjectRepository.updateSubject(
          SubjectEntity(
            id: current.id,
            name: trimmed,
            identifier: selectedIdentifier.value,
            iconKey: selectedIcon.value,
            targetMinutes: targetMinutes.value,
            createdAtMs: current.createdAtMs,
            updatedAtMs: DateTime.now().toUtc().millisecondsSinceEpoch,
            isArchived: current.isArchived,
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

  Future<void> toggleArchiveAndReturn() async {
    final current = editingSubject.value;
    if (current == null) {
      return;
    }
    await _subjectRepository.setArchived(
      current.id,
      isArchived: !current.isArchived,
    );
    if (!_disposed) {
      editingSubject.value = SubjectEntity(
        id: current.id,
        name: current.name,
        identifier: current.identifier,
        iconKey: current.iconKey,
        targetMinutes: current.targetMinutes,
        createdAtMs: current.createdAtMs,
        updatedAtMs: DateTime.now().toUtc().millisecondsSinceEpoch,
        isArchived: !current.isArchived,
      );
    }
  }

  Future<void> deleteSubjectAndExit() async {
    final current = editingSubject.value;
    if (current == null) {
      return;
    }
    await _subjectRepository.deleteSubject(current.id);
    unawaited(Get.offAllNamed<void>(AppRoutes.home));
  }

  @override
  void onClose() {
    _disposed = true;
    nameController.dispose();
    super.onClose();
  }
}

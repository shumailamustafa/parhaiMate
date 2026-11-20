import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/utils/date_time_utils.dart';
import '../../../domain/entities/domain_entities.dart';
import '../../../domain/enums/domain_enums.dart';
import '../../../domain/repositories/repositories.dart';

/// ViewModel for Timer Preset Management & Create/Edit Preset form.
class PresetsViewModel extends GetxController {
  PresetsViewModel({
    required PresetRepository presetRepository,
  }) : _presetRepo = presetRepository;

  final PresetRepository _presetRepo;

  final RxList<TimerPresetEntity> presets = <TimerPresetEntity>[].obs;
  final RxBool isLoading = true.obs;

  StreamSubscription<List<TimerPresetEntity>>? _presetsSub;

  @override
  void onInit() {
    super.onInit();
    _presetsSub = _presetRepo.watchPresets().listen((data) {
      presets.assignAll(data);
      isLoading.value = false;
    });
  }

  void usePreset(TimerPresetEntity preset) {
    unawaited(
      Get.toNamed<void>(
        AppRoutes.sessionSetup,
        arguments: <String, dynamic>{
          'mode': preset.timerMode,
          'focusMinutes': preset.focusMinutes,
          'shortBreakMinutes': preset.shortBreakMinutes,
          'longBreakMinutes': preset.longBreakMinutes,
          'totalCycles': preset.cyclesBeforeLongBreak,
        },
      ),
    );
  }

  String subtitleForPreset(TimerPresetEntity p) {
    switch (p.timerMode) {
      case TimerMode.focus:
        return 'Focus Timer · ${DateTimeUtils.formatMinutes(p.focusMinutes)}';
      case TimerMode.stopwatch:
        return 'Stopwatch · No limit';
      case TimerMode.pomodoro:
        return 'Pomodoro · ${p.focusMinutes} / ${p.shortBreakMinutes} / ${p.longBreakMinutes} min · ${p.cyclesBeforeLongBreak} cycles';
    }
  }

  @override
  void onClose() {
    unawaited(_presetsSub?.cancel());
    super.onClose();
  }
}

/// Form ViewModel for Create / Edit Timer Preset screens.
class PresetFormViewModel extends GetxController {
  PresetFormViewModel({
    required PresetRepository presetRepository,
    int? initialPresetId,
  })  : _presetRepo = presetRepository,
        _initialPresetId = initialPresetId;

  final PresetRepository _presetRepo;
  final int? _initialPresetId;

  final TextEditingController nameController = TextEditingController();

  final Rxn<TimerPresetEntity> editingPreset = Rxn<TimerPresetEntity>();
  final Rx<TimerMode> selectedMode = TimerMode.pomodoro.obs;
  final RxInt focusMinutes = 25.obs;
  final RxInt shortBreakMinutes = 5.obs;
  final RxInt longBreakMinutes = 15.obs;
  final RxInt cyclesBeforeLongBreak = 4.obs;
  final RxnString nameError = RxnString();
  final RxBool isSaving = false.obs;
  final RxBool isLoading = false.obs;

  bool _disposed = false;

  bool get isEditing => editingPreset.value != null;

  @override
  void onInit() {
    super.onInit();
    nameController.addListener(() {
      if (nameError.value != null && nameController.text.trim().isNotEmpty) {
        nameError.value = null;
      }
    });

    final arg = _initialPresetId ?? Get.arguments;
    if (arg is int) {
      unawaited(_loadPreset(arg));
    } else if (arg is TimerPresetEntity) {
      _populate(arg);
    }
  }

  Future<void> _loadPreset(int id) async {
    isLoading.value = true;
    try {
      final loaded = await _presetRepo.getById(id);
      if (!_disposed && loaded != null) {
        _populate(loaded);
      }
    } finally {
      if (!_disposed) {
        isLoading.value = false;
      }
    }
  }

  void _populate(TimerPresetEntity preset) {
    editingPreset.value = preset;
    nameController.text = preset.name;
    selectedMode.value = preset.timerMode;
    focusMinutes.value = preset.focusMinutes.clamp(5, 180);
    shortBreakMinutes.value = preset.shortBreakMinutes.clamp(1, 30);
    longBreakMinutes.value = preset.longBreakMinutes.clamp(5, 60);
    cyclesBeforeLongBreak.value = preset.cyclesBeforeLongBreak.clamp(1, 8);
  }

  void selectMode(TimerMode mode) {
    selectedMode.value = mode;
  }

  void adjustFocus(int delta) {
    focusMinutes.value = (focusMinutes.value + delta).clamp(5, 180);
  }

  void adjustShortBreak(int delta) {
    shortBreakMinutes.value = (shortBreakMinutes.value + delta).clamp(1, 30);
  }

  void adjustLongBreak(int delta) {
    longBreakMinutes.value = (longBreakMinutes.value + delta).clamp(5, 60);
  }

  void adjustCycles(int delta) {
    cyclesBeforeLongBreak.value =
        (cyclesBeforeLongBreak.value + delta).clamp(1, 8);
  }

  int get fullSessionMinutes {
    switch (selectedMode.value) {
      case TimerMode.focus:
        return focusMinutes.value;
      case TimerMode.stopwatch:
        return 0;
      case TimerMode.pomodoro:
        final breaks = cyclesBeforeLongBreak.value > 1
            ? (cyclesBeforeLongBreak.value - 1) * shortBreakMinutes.value
            : 0;
        // Same rule as the timer engine: short breaks between cycles,
        // then one long break that closes the set.
        return (cyclesBeforeLongBreak.value * focusMinutes.value) +
            breaks +
            longBreakMinutes.value;
    }
  }

  String get fullSessionSummaryLabel {
    if (selectedMode.value == TimerMode.stopwatch) {
      return 'No time limit';
    }
    return DateTimeUtils.formatMinutes(fullSessionMinutes);
  }

  Future<bool> savePreset() async {
    final trimmed = nameController.text.trim();
    if (trimmed.isEmpty) {
      nameError.value = 'Enter a preset name';
      return false;
    }
    if (isSaving.value) {
      return false;
    }
    isSaving.value = true;
    try {
      final current = editingPreset.value;
      if (current == null) {
        await _presetRepo.createPreset(
          name: trimmed,
          timerMode: selectedMode.value,
          focusMinutes: focusMinutes.value,
          shortBreakMinutes: shortBreakMinutes.value,
          longBreakMinutes: longBreakMinutes.value,
          cyclesBeforeLongBreak: cyclesBeforeLongBreak.value,
        );
      } else {
        await _presetRepo.updatePreset(
          TimerPresetEntity(
            id: current.id,
            name: trimmed,
            timerMode: selectedMode.value,
            focusMinutes: focusMinutes.value,
            shortBreakMinutes: shortBreakMinutes.value,
            longBreakMinutes: longBreakMinutes.value,
            cyclesBeforeLongBreak: cyclesBeforeLongBreak.value,
            isDefault: current.isDefault,
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

  Future<void> deletePreset() async {
    final current = editingPreset.value;
    if (current == null) {
      return;
    }
    await _presetRepo.deletePreset(current.id);
  }

  @override
  void onClose() {
    _disposed = true;
    nameController.dispose();
    super.onClose();
  }
}

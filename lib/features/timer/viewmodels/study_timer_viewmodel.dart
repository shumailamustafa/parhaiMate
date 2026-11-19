import 'dart:async';

import 'package:get/get.dart';

import '../../../domain/entities/domain_entities.dart';
import '../../../domain/enums/domain_enums.dart';
import '../../../domain/repositories/repositories.dart';

/// ViewModel for the Study Timer tab (04 Study Timer.png).
class StudyTimerViewModel extends GetxController {
  StudyTimerViewModel({
    required SubjectRepository subjectRepository,
    required SettingsRepository settingsRepository,
  })  : _subjectRepository = subjectRepository,
        _settingsRepository = settingsRepository;

  static const List<int> durationChoices = <int>[15, 25, 30, 45, 60];

  final SubjectRepository _subjectRepository;
  final SettingsRepository _settingsRepository;

  final RxList<SubjectEntity> subjects = <SubjectEntity>[].obs;
  final RxnInt selectedSubjectId = RxnInt();
  final Rx<TimerMode> selectedMode = TimerMode.pomodoro.obs;
  final RxInt focusMinutes = 25.obs;
  final RxInt shortBreakMinutes = 5.obs;
  final RxInt longBreakMinutes = 15.obs;
  final RxInt totalCycles = 4.obs;

  StreamSubscription<List<SubjectEntity>>? _subjectsSub;
  bool _disposed = false;

  @override
  void onInit() {
    super.onInit();
    _subjectsSub = _subjectRepository
        .watchSubjects(archived: false)
        .listen(subjects.assignAll);
    unawaited(_loadDefaultMode());
  }

  Future<void> _loadDefaultMode() async {
    final mode = await _settingsRepository.getDefaultTimerMode();
    if (!_disposed) {
      selectedMode.value = mode;
    }
  }

  void selectMode(TimerMode mode) {
    selectedMode.value = mode;
  }

  void selectSubject(int? subjectId) {
    selectedSubjectId.value = subjectId;
  }

  void selectDuration(int minutes) {
    focusMinutes.value = minutes.clamp(1, 180);
  }

  /// Applies preset parameters when invoked from Timer Presets management.
  void applyPreset(TimerPresetEntity preset) {
    selectedMode.value = preset.timerMode;
    focusMinutes.value = preset.focusMinutes;
    shortBreakMinutes.value = preset.shortBreakMinutes;
    longBreakMinutes.value = preset.longBreakMinutes;
    totalCycles.value = preset.cyclesBeforeLongBreak;
  }

  bool isPresetDuration(int minutes) => durationChoices.contains(minutes);

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

  Map<String, dynamic> buildSessionSetupArgs() {
    return <String, dynamic>{
      'mode': selectedMode.value,
      'subjectId': selectedSubjectId.value,
      'focusMinutes': focusMinutes.value,
      'shortBreakMinutes': shortBreakMinutes.value,
      'longBreakMinutes': longBreakMinutes.value,
      'totalCycles': totalCycles.value,
    };
  }

  @override
  void onClose() {
    _disposed = true;
    unawaited(_subjectsSub?.cancel());
    super.onClose();
  }
}

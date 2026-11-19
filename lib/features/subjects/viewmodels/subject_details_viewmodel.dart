import 'dart:async';

import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/utils/date_time_utils.dart';
import '../../../domain/entities/domain_entities.dart';
import '../../../domain/repositories/repositories.dart';

/// ViewModel for Subject Details screen (09 Subject Details.png & variants).
class SubjectDetailsViewModel extends GetxController {
  SubjectDetailsViewModel({
    required SubjectRepository subjectRepository,
    required SessionRepository sessionRepository,
    required PlannerRepository plannerRepository,
    int? initialSubjectId,
    DateTime Function()? nowProvider,
  })  : _subjectRepository = subjectRepository,
        _sessionRepository = sessionRepository,
        _plannerRepository = plannerRepository,
        _initialSubjectId = initialSubjectId,
        _nowProvider = nowProvider ?? DateTime.now;

  final SubjectRepository _subjectRepository;
  final SessionRepository _sessionRepository;
  final PlannerRepository _plannerRepository;
  final int? _initialSubjectId;
  final DateTime Function() _nowProvider;

  final Rxn<SubjectEntity> subject = Rxn<SubjectEntity>();
  final RxList<StudySessionEntity> sessions = <StudySessionEntity>[].obs;
  final RxInt linkedTasksCount = 0.obs;
  final RxBool isLoading = true.obs;

  StreamSubscription<SubjectEntity?>? _subjectSub;
  StreamSubscription<List<StudySessionEntity>>? _sessionsSub;
  StreamSubscription<List<PlannerTaskEntity>>? _tasksSub;
  int? _subjectId;

  @override
  void onInit() {
    super.onInit();
    final arg = _initialSubjectId ?? Get.arguments;
    if (arg is int) {
      _subjectId = arg;
    } else if (arg is SubjectEntity) {
      _subjectId = arg.id;
      subject.value = arg;
    }

    final id = _subjectId;
    if (id == null) {
      isLoading.value = false;
      return;
    }

    _subjectSub = _subjectRepository.watchById(id).listen((value) {
      subject.value = value;
      isLoading.value = false;
    });
    _sessionsSub = _sessionRepository
        .watchCompletedSessions(subjectId: id)
        .listen(sessions.assignAll);
    _tasksSub = _plannerRepository.watchAllTasks().listen((tasks) {
      linkedTasksCount.value = tasks.where((t) => t.subjectId == id).length;
    });
  }

  int get totalMinutes {
    final totalSec = sessions.fold<int>(0, (sum, s) => sum + s.durationSeconds);
    return totalSec ~/ 60;
  }

  int get todayMinutes {
    final now = _nowProvider();
    final todayKey = DateTimeUtils.toDateKey(now);
    var totalSec = 0;
    for (final s in sessions) {
      final key = DateTimeUtils.toDateKey(
        DateTime.fromMillisecondsSinceEpoch(s.startedAtMs, isUtc: true),
      );
      if (key == todayKey) {
        totalSec += s.durationSeconds;
      }
    }
    return totalSec ~/ 60;
  }

  int get weekMinutes {
    final now = _nowProvider();
    final startMs = DateTimeUtils.startOfWeek(now).toUtc().millisecondsSinceEpoch;
    final endMs =
        DateTimeUtils.endOfWeekExclusive(now).toUtc().millisecondsSinceEpoch;
    var totalSec = 0;
    for (final s in sessions) {
      if (s.startedAtMs >= startMs && s.startedAtMs < endMs) {
        totalSec += s.durationSeconds;
      }
    }
    return totalSec ~/ 60;
  }

  int get monthMinutes {
    final now = _nowProvider();
    var totalSec = 0;
    for (final s in sessions) {
      final local = DateTime.fromMillisecondsSinceEpoch(
        s.startedAtMs,
        isUtc: true,
      ).toLocal();
      if (local.year == now.year && local.month == now.month) {
        totalSec += s.durationSeconds;
      }
    }
    return totalSec ~/ 60;
  }

  int get averageSessionMinutes {
    if (sessions.isEmpty) {
      return 0;
    }
    final totalSec = sessions.fold<int>(0, (sum, s) => sum + s.durationSeconds);
    return (totalSec / sessions.length / 60).round();
  }

  double get weekProgress {
    final target = subject.value?.targetMinutes ?? 0;
    if (target <= 0) {
      return 0;
    }
    return (weekMinutes / target).clamp(0.0, 1.0);
  }

  int get dailyTargetMinutes {
    final weeklyTarget = subject.value?.targetMinutes ?? 0;
    if (weeklyTarget <= 0) {
      return 0;
    }
    return (weeklyTarget / 7).round();
  }

  /// Minutes studied per weekday (Mon index 0 .. Sun index 6) in current week.
  List<int> get weeklyDayMinutes {
    final weekStart = DateTimeUtils.startOfWeek(_nowProvider());
    final dayTotalsSeconds = List<int>.filled(7, 0);

    for (final s in sessions) {
      final localDate = DateTimeUtils.startOfDay(
        DateTime.fromMillisecondsSinceEpoch(s.startedAtMs, isUtc: true),
      );
      final diff = localDate.difference(weekStart).inDays;
      if (diff >= 0 && diff < 7) {
        dayTotalsSeconds[diff] += s.durationSeconds;
      }
    }

    return dayTotalsSeconds.map((sec) => sec ~/ 60).toList();
  }

  int get currentTodayWeekdayIndex => _nowProvider().weekday - 1;

  List<StudySessionEntity> get previewSessions {
    if (sessions.length <= 6) {
      return sessions.toList();
    }
    return sessions.take(6).toList();
  }

  String formatSessionDateHeading(int startedAtMs) {
    final sessionDay = DateTimeUtils.startOfDay(
      DateTime.fromMillisecondsSinceEpoch(startedAtMs, isUtc: true),
    );
    final today = DateTimeUtils.startOfDay(_nowProvider());
    final yesterday = today.subtract(const Duration(days: 1));
    if (sessionDay == today) {
      return 'Today';
    }
    if (sessionDay == yesterday) {
      return 'Yesterday';
    }
    return DateTimeUtils.formatShortDate(sessionDay);
  }

  Future<void> toggleArchive() async {
    final current = subject.value;
    if (current == null) {
      return;
    }
    await _subjectRepository.setArchived(
      current.id,
      isArchived: !current.isArchived,
    );
  }

  Future<void> deleteSubjectAndExit() async {
    final current = subject.value;
    if (current == null) {
      return;
    }
    await _subjectRepository.deleteSubject(current.id);
    unawaited(Get.offAllNamed<void>(AppRoutes.home));
  }

  @override
  void onClose() {
    unawaited(_subjectSub?.cancel());
    unawaited(_sessionsSub?.cancel());
    unawaited(_tasksSub?.cancel());
    super.onClose();
  }
}

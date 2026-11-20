import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/utils/date_time_utils.dart';
import '../../../domain/entities/domain_entities.dart';
import '../../../domain/repositories/repositories.dart';

/// ViewModel for Achievements screen (14 Achievements.png & detail sheets).
class AchievementsViewModel extends GetxController {
  AchievementsViewModel({
    required AchievementRepository achievementRepository,
  }) : _achievementRepository = achievementRepository;

  final AchievementRepository _achievementRepository;

  final RxList<AchievementEntity> achievements = <AchievementEntity>[].obs;
  final RxBool isLoading = true.obs;

  StreamSubscription<List<AchievementEntity>>? _achievementsSub;

  @override
  void onInit() {
    super.onInit();
    _achievementsSub =
        _achievementRepository.watchAchievements().listen((data) {
      achievements.assignAll(data);
      isLoading.value = false;
    });
  }

  int get unlockedCount => achievements.where((a) => a.isUnlocked).length;

  int get totalCount => achievements.length;

  int get unlockedPercent {
    if (achievements.isEmpty) {
      return 0;
    }
    return ((unlockedCount / achievements.length) * 100).round();
  }

  double get overallProgress {
    if (achievements.isEmpty) {
      return 0;
    }
    return (unlockedCount / achievements.length).clamp(0.0, 1.0);
  }

  IconData iconForAchievement(String code) {
    switch (code) {
      case 'first_session':
        return Icons.play_arrow_outlined;
      case 'focus_starter':
        return Icons.access_time_rounded;
      case 'consistent_learner':
        return Icons.local_fire_department_outlined;
      case 'study_champion':
        return Icons.emoji_events_outlined;
      case 'time_master':
        return Icons.hourglass_empty_rounded;
      case 'weekly_warrior':
        return Icons.track_changes_rounded;
      default:
        return Icons.emoji_events_outlined;
    }
  }

  String progressLabelFor(AchievementEntity a) {
    switch (a.code) {
      case 'first_session':
        return '${a.currentValue} of ${a.targetValue} session';
      case 'focus_starter':
        return '${DateTimeUtils.formatMinutes(a.currentValue)} of 1h';
      case 'consistent_learner':
        return '${a.currentValue} of ${a.targetValue} days';
      case 'study_champion':
        return '${a.currentValue} of ${a.targetValue} sessions';
      case 'time_master':
        return '${a.currentValue} of ${a.targetValue} hours';
      case 'weekly_warrior':
        return '${DateTimeUtils.formatMinutes(a.currentValue)} of ${DateTimeUtils.formatMinutes(a.targetValue)}';
      default:
        return '${a.currentValue} of ${a.targetValue} ${a.unitLabel}';
    }
  }

  String remainingLabelFor(AchievementEntity a) {
    final rem = math.max(0, a.targetValue - a.currentValue);
    switch (a.code) {
      case 'first_session':
        return '$rem more session to go';
      case 'focus_starter':
      case 'weekly_warrior':
        return '${DateTimeUtils.formatMinutes(rem)} more to go';
      case 'consistent_learner':
        return '$rem more ${rem == 1 ? 'day' : 'days'} to go';
      case 'study_champion':
        return '$rem more ${rem == 1 ? 'session' : 'sessions'} to go';
      case 'time_master':
        return '$rem more ${rem == 1 ? 'hour' : 'hours'} to go';
      default:
        return '$rem more ${a.unitLabel} to go';
    }
  }

  @override
  void onClose() {
    unawaited(_achievementsSub?.cancel());
    super.onClose();
  }
}

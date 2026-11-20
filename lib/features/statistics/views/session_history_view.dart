import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_time_utils.dart';
import '../../../core/widgets/widgets.dart';
import '../../../shared/enums/subject_visuals.dart';
import '../../../shared/widgets/widgets.dart';
import '../viewmodels/session_history_viewmodel.dart';

/// Session History screen matching Session History.png & Empty state.
class SessionHistoryView extends GetView<SessionHistoryViewModel> {
  const SessionHistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const PmAppBar(title: 'Session History'),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const PmLoadingState(message: 'Loading session history...');
        }

        final hasAnySessions = controller.allSessions.isNotEmpty;
        final selectedSubject = controller.selectedSubjectId.value;
        final groups = controller.groupedSessions;
        final subjects = controller.subjects;

        if (!hasAnySessions) {
          return Padding(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            child: Column(
              children: <Widget>[
                PmEmptyState(
                  icon: Icons.history_rounded,
                  title: 'No study sessions yet',
                  subtitle: 'Sessions you finish are saved here',
                  actionLabel: 'Start Studying',
                  onAction: () => Get.toNamed<void>(AppRoutes.sessionSetup),
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPadding,
                8,
                AppSpacing.screenPadding,
                4,
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: <Widget>[
                          PmChip(
                            label: 'All subjects',
                            selected: selectedSubject == null,
                            onTap: () => controller.selectSubjectFilter(null),
                          ),
                          ...subjects.map(
                            (s) => Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: PmChip(
                                label: s.name,
                                selected: selectedSubject == s.id,
                                onTap: () =>
                                    controller.selectSubjectFilter(s.id),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  PmIconButton(
                    icon: Icons.swap_vert_rounded,
                    tooltip: 'Toggle sort order',
                    onPressed: controller.toggleSortOrder,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding,
                vertical: 6,
              ),
              child: Text(controller.sortLabel, style: AppTypography.meta12),
            ),
            Expanded(
              child: groups.isEmpty
                  ? SingleChildScrollView(
                      padding: const EdgeInsets.all(AppSpacing.screenPadding),
                      child: PmEmptyState(
                        icon: Icons.history_rounded,
                        title: 'No sessions for this subject',
                        subtitle:
                            'Try picking All subjects or finish a session for this subject',
                        ghostActionLabel: 'Show all subjects',
                        onGhostAction: () =>
                            controller.selectSubjectFilter(null),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.screenPadding,
                        4,
                        AppSpacing.screenPadding,
                        28,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: List<Widget>.generate(groups.length, (gIndex) {
                          final group = groups[gIndex];
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: gIndex < groups.length - 1 ? 20 : 0,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: <Widget>[
                                PmSectionHeader(
                                  title: group.heading,
                                  trailingMeta: group.totalLabel,
                                ),
                                const SizedBox(height: 10),
                                PmWhiteCard(
                                  padding: EdgeInsets.zero,
                                  child: Column(
                                    children: List<Widget>.generate(
                                      group.sessions.length,
                                      (sIndex) {
                                        final session = group.sessions[sIndex];
                                        final subject = controller.subjectForId(
                                          session.subjectId,
                                        );
                                        final finishedAt =
                                            DateTime.fromMillisecondsSinceEpoch(
                                          session.endedAtMs ??
                                              session.startedAtMs,
                                          isUtc: true,
                                        );
                                        return Column(
                                          children: <Widget>[
                                            StudySessionRow(
                                              title: subject?.name ??
                                                  'General Study',
                                              subtitle:
                                                  '${session.sessionType.label} · Finished ${DateTimeUtils.formatClockTime(finishedAt)}',
                                              durationLabel: DateTimeUtils
                                                  .formatSecondsAsMinutesLabel(
                                                session.durationSeconds,
                                              ),
                                              icon: subject?.iconKey.iconData ??
                                                  session.sessionType.iconData,
                                            ),
                                            if (sIndex <
                                                group.sessions.length - 1)
                                              const Divider(
                                                height: 1,
                                                color: AppColors.divider,
                                              ),
                                          ],
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ),
                    ),
            ),
          ],
        );
      }),
    );
  }
}

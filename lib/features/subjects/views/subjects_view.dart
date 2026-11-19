import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_time_utils.dart';
import '../../../core/widgets/widgets.dart';
import '../../../shared/widgets/widgets.dart';
import '../viewmodels/subjects_viewmodel.dart';

/// My Subjects screen matching 08 My Subjects.png and empty/archived/search states.
class SubjectsView extends GetView<SubjectsViewModel> {
  const SubjectsView({super.key, this.showTitleHeader = true});

  final bool showTitleHeader;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Obx(() {
        final hasAnySubjects = controller.allSubjects.isNotEmpty;
        final activeCount = controller.activeSubjects.length;
        final archivedCount = controller.archivedSubjects.length;
        final showingArchived = controller.showArchived.value;
        final query = controller.searchQuery.value.trim();
        final visible = controller.filteredSubjects;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            16,
            AppSpacing.screenPadding,
            28,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (showTitleHeader)
                Row(
                  children: <Widget>[
                    const Expanded(
                      child: Text('My Subjects', style: AppTypography.title24),
                    ),
                    PmIconButton(
                      icon: Icons.add_rounded,
                      variant: PmIconButtonVariant.navy,
                      tooltip: 'Add Subject',
                      onPressed: () => Get.toNamed<void>(AppRoutes.addSubject),
                    ),
                  ],
                ),
              if (!hasAnySubjects && !controller.isLoading.value) ...<Widget>[
                const SizedBox(height: 24),
                PmEmptyState(
                  icon: Icons.menu_book_outlined,
                  title: 'No subjects yet',
                  subtitle:
                      "Add the subjects you're studying to track time for each one",
                  actionLabel: 'Add Subject',
                  actionIcon: Icons.add_rounded,
                  onAction: () => Get.toNamed<void>(AppRoutes.addSubject),
                ),
              ] else ...<Widget>[
                if (showTitleHeader) const SizedBox(height: 16),
                PmTextField(
                  controller: controller.searchController,
                  hintText: 'Search subjects',
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                  suffixIcon: query.isNotEmpty
                      ? IconButton(
                          tooltip: 'Clear search',
                          icon: const Icon(
                            Icons.close_rounded,
                            size: 20,
                            color: AppColors.textPrimary,
                          ),
                          onPressed: controller.clearSearch,
                        )
                      : null,
                ),
                const SizedBox(height: 14),
                PmSegmentedControl<bool>(
                  selectedValue: showingArchived,
                  onChanged: controller.setShowArchived,
                  options: <PmSegmentOption<bool>>[
                    PmSegmentOption<bool>(
                      value: false,
                      label: 'Active ($activeCount)',
                    ),
                    PmSegmentOption<bool>(
                      value: true,
                      label: 'Archived ($archivedCount)',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (visible.isEmpty && query.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 8),
                  PmEmptyState(
                    icon: Icons.search_rounded,
                    title: 'No subjects match "$query"',
                    subtitle: 'Try another name or clear the search',
                    ghostActionLabel: 'Clear search',
                    onGhostAction: controller.clearSearch,
                  ),
                ] else if (visible.isEmpty) ...<Widget>[
                  const SizedBox(height: 8),
                  PmEmptyState(
                    icon: showingArchived
                        ? Icons.archive_outlined
                        : Icons.menu_book_outlined,
                    title: showingArchived
                        ? 'No archived subjects'
                        : 'No active subjects',
                    subtitle: showingArchived
                        ? 'Subjects you archive will stay safe here until you restore them'
                        : 'Add a subject or restore one from Archived',
                    actionLabel: showingArchived ? null : 'Add Subject',
                    actionIcon: showingArchived ? null : Icons.add_rounded,
                    onAction: showingArchived
                        ? null
                        : () => Get.toNamed<void>(AppRoutes.addSubject),
                  ),
                ] else ...<Widget>[
                  Text(
                    controller.tabSummaryLabel,
                    style: AppTypography.secondary14,
                  ),
                  const SizedBox(height: 12),
                  ...List<Widget>.generate(visible.length, (index) {
                    final subject = visible[index];
                    final totalMin =
                        controller.totalMinutesForSubject(subject.id);
                    final weekMin =
                        controller.weekMinutesForSubject(subject.id);
                    final targetMin = subject.targetMinutes;
                    final progress = targetMin > 0
                        ? (weekMin / targetMin).clamp(0.0, 1.0)
                        : 0.0;

                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: index < visible.length - 1 ? 12 : 0,
                      ),
                      child: SubjectCard(
                        name: subject.name,
                        iconKey: subject.iconKey,
                        identifier: subject.identifier,
                        totalLabel:
                            '${DateTimeUtils.formatMinutes(totalMin)} total',
                        weekStudiedLabel: DateTimeUtils.formatMinutes(weekMin),
                        weekTargetLabel: DateTimeUtils.formatMinutes(targetMin),
                        weekProgress: progress,
                        onTap: () => Get.toNamed<void>(
                          AppRoutes.subjectDetails,
                          arguments: subject.id,
                        ),
                      ),
                    );
                  }),
                ],
              ],
            ],
          ),
        );
      }),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/widgets.dart';
import '../viewmodels/session_summary_viewmodel.dart';

/// Completed study session summary matching 07 Session Summary.png.
class SessionSummaryView extends GetView<SessionSummaryViewModel> {
  const SessionSummaryView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoading.value) {
            return const PmLoadingState(message: 'Preparing session summary...');
          }

          final s = controller.session.value;
          if (s == null) {
            return Padding(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              child: PmEmptyState(
                icon: Icons.check_circle_outline_rounded,
                title: 'No completed session found',
                subtitle: 'Return home to view your study dashboard.',
                actionLabel: 'Back to Home',
                onAction: controller.saveAndGoHome,
              ),
            );
          }

          final currentNotes = s.notes?.trim();
          final hasNotes = currentNotes != null && currentNotes.isNotEmpty;

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenPadding,
              24,
              AppSpacing.screenPadding,
              28,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        size: 30,
                        color: AppColors.onPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Session Completed',
                  style: AppTypography.title24,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  'Nice work on ${controller.subjectName.value}',
                  style: AppTypography.secondary14,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 22),
                PmGreyCard(
                  padding: const EdgeInsets.all(AppSpacing.cardPaddingLarge),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        'Total study time',
                        style: AppTypography.secondary14,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        controller.durationLabel,
                        style: AppTypography.display32,
                      ),
                      const SizedBox(height: 16),
                      _DetailRow(
                        label: 'Subject',
                        value: controller.subjectName.value,
                      ),
                      const Divider(height: 22, color: AppColors.track),
                      _DetailRow(
                        label: 'Session type',
                        value: s.sessionType.label,
                      ),
                      const Divider(height: 22, color: AppColors.track),
                      _DetailRow(
                        label: 'Start time',
                        value: controller.startTimeLabel,
                      ),
                      const Divider(height: 22, color: AppColors.track),
                      _DetailRow(
                        label: 'End time',
                        value: controller.endTimeLabel,
                      ),
                      const Divider(height: 22, color: AppColors.track),
                      _DetailRow(
                        label: 'Session duration',
                        value: controller.durationLabel,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                PmWhiteCard(
                  padding: const EdgeInsets.all(AppSpacing.cardPaddingLarge),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        'Session statistics',
                        style: AppTypography.body16SemiBold,
                      ),
                      const SizedBox(height: 14),
                      IntrinsicHeight(
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  const Text(
                                    'Focus duration',
                                    style: AppTypography.secondary14,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    controller.durationLabel,
                                    style: AppTypography.body16SemiBold,
                                  ),
                                ],
                              ),
                            ),
                            const VerticalDivider(
                              width: 24,
                              thickness: 1,
                              color: AppColors.divider,
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  const Text(
                                    'Goal contribution',
                                    style: AppTypography.secondary14,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '+${controller.goalContributionPercent}% of daily goal',
                                    style: AppTypography.body16SemiBold,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 24, color: AppColors.divider),
                      const Text(
                        'Daily progress',
                        style: AppTypography.secondary14,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        controller.dailyProgressLabel,
                        style: AppTypography.body16SemiBold,
                      ),
                      const SizedBox(height: 10),
                      PmProgressBar(
                        progress: controller.dailyProgressFraction,
                        height: 7,
                      ),
                    ],
                  ),
                ),
                if (hasNotes) ...<Widget>[
                  const SizedBox(height: 14),
                  PmWhiteCard(
                    padding: const EdgeInsets.all(AppSpacing.cardPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text(
                          'Session notes',
                          style: AppTypography.secondary14SemiBold,
                        ),
                        const SizedBox(height: 6),
                        Text(currentNotes, style: AppTypography.secondary14),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                PmSecondaryButton(
                  label: 'Add Notes',
                  icon: Icons.description_outlined,
                  onPressed: () => _showAddNotesSheet(context),
                ),
                const SizedBox(height: 14),
                PmPrimaryButton(
                  label: 'Save Session',
                  onPressed: controller.saveAndGoHome,
                ),
                const SizedBox(height: 10),
                PmSecondaryButton(
                  label: 'Start Another Session',
                  onPressed: controller.startAnotherSession,
                ),
                const SizedBox(height: 10),
                Center(
                  child: PmGhostButton(
                    label: 'Back to Home',
                    onPressed: controller.saveAndGoHome,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Future<void> _showAddNotesSheet(BuildContext context) async {
    await PmBottomSheet.show<void>(
      context: context,
      title: 'Session notes',
      child: _SessionNotesSheet(controller: controller),
    );
  }
}

class _SessionNotesSheet extends StatefulWidget {
  const _SessionNotesSheet({required this.controller});

  final SessionSummaryViewModel controller;

  @override
  State<_SessionNotesSheet> createState() => _SessionNotesSheetState();
}

class _SessionNotesSheetState extends State<_SessionNotesSheet> {
  late final TextEditingController _draftController;

  @override
  void initState() {
    super.initState();
    _draftController = TextEditingController(
      text: widget.controller.notesController.text,
    );
  }

  @override
  void dispose() {
    _draftController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        PmTextArea(
          label: 'Notes',
          hintText: 'Add a note for this session',
          controller: _draftController,
        ),
        const SizedBox(height: 20),
        Obx(
          () => PmPrimaryButton(
            label: 'Save notes',
            isLoading: widget.controller.isSavingNotes.value,
            onPressed: () async {
              final navigator = Navigator.of(context);
              await widget.controller.saveNotes(_draftController.text);
              if (mounted) {
                navigator.pop();
              }
            },
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(child: Text(label, style: AppTypography.secondary14)),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            style: AppTypography.secondary14SemiBold,
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

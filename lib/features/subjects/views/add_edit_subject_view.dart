import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/widgets.dart';
import '../../../shared/enums/subject_visuals.dart';
import '../../../shared/widgets/widgets.dart';
import '../viewmodels/subject_form_viewmodel.dart';

/// Add / Edit Subject screen matching Add Subject.png, Error.png & Edit Subject.png.
class AddEditSubjectView extends GetView<SubjectFormViewModel> {
  const AddEditSubjectView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isEditing = controller.isEditing;
      final current = controller.editingSubject.value;
      final selectedIcon = controller.selectedIcon.value;
      final selectedIdentifier = controller.selectedIdentifier.value;

      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: PmAppBar(
          title: isEditing ? 'Edit Subject' : 'Add Subject',
        ),
        body: controller.isLoading.value
            ? const PmLoadingState(message: 'Loading subject...')
            : Column(
                children: <Widget>[
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.screenPadding,
                        12,
                        AppSpacing.screenPadding,
                        24,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          PmTextField(
                            label: 'Subject name',
                            hintText: 'e.g. Mathematics',
                            controller: controller.nameController,
                            errorText: controller.nameError.value,
                            textInputAction: TextInputAction.done,
                          ),
                          const SizedBox(height: 22),
                          const Text(
                            'Icon',
                            style: AppTypography.secondary14SemiBold,
                          ),
                          const SizedBox(height: 10),
                          GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 4,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.05,
                            children: SubjectIconKey.values.map((iconKey) {
                              return _SubjectIconTile(
                                key: ValueKey<String>(
                                  'subject_icon_${iconKey.key}',
                                ),
                                iconKey: iconKey,
                                selected: selectedIcon == iconKey,
                                onTap: () => controller.selectIcon(iconKey),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 22),
                          const Text(
                            'Identifier',
                            style: AppTypography.secondary14SemiBold,
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: SubjectIdentifier.values.map((id) {
                              return PmChip(
                                label: id.label,
                                selected: selectedIdentifier == id,
                                selectedBorderOnly: true,
                                leading: SubjectIdentifierBadge(
                                  identifier: id,
                                  size: 8,
                                ),
                                onTap: () => controller.selectIdentifier(id),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Shown next to the subject name in lists and the planner',
                            style: AppTypography.meta12,
                          ),
                          const SizedBox(height: 22),
                          PmStepperField(
                            label: 'Weekly target',
                            valueLabel: '${controller.targetMinutes.value} min',
                            canDecrement: controller.targetMinutes.value >
                                SubjectFormViewModel.minTargetMinutes,
                            canIncrement: controller.targetMinutes.value <
                                SubjectFormViewModel.maxTargetMinutes,
                            onDecrement: () => controller.adjustTargetMinutes(
                              -SubjectFormViewModel.targetStepMinutes,
                            ),
                            onIncrement: () => controller.adjustTargetMinutes(
                              SubjectFormViewModel.targetStepMinutes,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            controller.weeklyTargetCaption,
                            style: AppTypography.secondary14,
                          ),
                          if (isEditing && current != null) ...<Widget>[
                            const SizedBox(height: 28),
                            Row(
                              children: <Widget>[
                                Expanded(
                                  child: PmSecondaryButton(
                                    label: current.isArchived
                                        ? 'Restore Subject'
                                        : 'Archive Subject',
                                    size: PmButtonSize.medium,
                                    onPressed: () async {
                                      final navigator = Navigator.of(context);
                                      await controller.toggleArchiveAndReturn();
                                      if (context.mounted) {
                                        navigator.pop();
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Center(
                                    child: PmGhostButton(
                                      label: 'Delete Subject',
                                      icon: Icons.delete_outline_rounded,
                                      onPressed: () =>
                                          _showDeleteConfirmation(context),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.screenPadding,
                        10,
                        AppSpacing.screenPadding,
                        16,
                      ),
                      child: PmPrimaryButton(
                        label: 'Save Subject',
                        isLoading: controller.isSaving.value,
                        onPressed: () async {
                          final navigator = Navigator.of(context);
                          final saved = await controller.saveSubject();
                          if (saved && context.mounted) {
                            navigator.pop(true);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
      );
    });
  }

  Future<void> _showDeleteConfirmation(BuildContext context) async {
    final subject = controller.editingSubject.value;
    if (subject == null) {
      return;
    }
    final sCount = controller.linkedSessionsCount.value;
    final tCount = controller.linkedTasksCount.value;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: AppColors.barrierScrim,
      builder: (dialogContext) => PmConfirmationDialog(
        icon: Icons.delete_outline_rounded,
        title: 'Delete ${subject.name}?',
        message:
            "Its $sCount sessions and $tCount planned tasks will be deleted too. You can't undo this.",
        confirmLabel: 'Delete Subject',
        isDestructive: true,
        onConfirm: () => Navigator.of(dialogContext).pop(true),
      ),
    );
    if (confirmed ?? false) {
      await controller.deleteSubjectAndExit();
    }
  }
}

class _SubjectIconTile extends StatelessWidget {
  const _SubjectIconTile({
    required this.iconKey,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final SubjectIconKey iconKey;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary : AppColors.surface,
      borderRadius: AppRadii.cardRadius,
      child: InkWell(
        borderRadius: AppRadii.cardRadius,
        onTap: onTap,
        child: Stack(
          children: <Widget>[
            Center(
              child: Icon(
                iconKey.iconData,
                size: 24,
                color: selected ? AppColors.onPrimary : AppColors.primary,
              ),
            ),
            if (selected)
              const Positioned(
                top: 8,
                right: 8,
                child: Icon(
                  Icons.check_rounded,
                  size: 14,
                  color: AppColors.onPrimary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

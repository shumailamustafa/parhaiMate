import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_time_utils.dart';
import '../../../core/widgets/widgets.dart';
import '../../../domain/entities/domain_entities.dart';
import '../../../domain/enums/domain_enums.dart';
import '../../../shared/widgets/widgets.dart';

/// Opens the reusable subject selection sheet allowing optional subject picking.
Future<void> showSubjectPickerSheet({
  required BuildContext context,
  required List<SubjectEntity> subjects,
  required int? selectedSubjectId,
  required ValueChanged<int?> onSelected,
}) {
  return PmBottomSheet.show<void>(
    context: context,
    title: 'Select Subject',
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _SubjectPickerOptionRow(
          title: 'General Study',
          subtitle: 'No subject assigned',
          leading: Container(
            width: AppSpacing.iconBoxSize,
            height: AppSpacing.iconBoxSize,
            decoration: BoxDecoration(
              color: selectedSubjectId == null
                  ? AppColors.primary
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.menu_book_outlined,
              size: 20,
              color: selectedSubjectId == null
                  ? AppColors.onPrimary
                  : AppColors.primary,
            ),
          ),
          selected: selectedSubjectId == null,
          onTap: () {
            onSelected(null);
            Navigator.of(context).pop();
          },
        ),
        if (subjects.isEmpty) ...<Widget>[
          const SizedBox(height: 12),
          const Text(
            'No subjects added yet. You can start studying with General Study anytime.',
            style: AppTypography.secondary14,
          ),
        ] else
          ...subjects.map((subject) {
            final isSelected = subject.id == selectedSubjectId;
            return Column(
              children: <Widget>[
                const Divider(height: 1, color: AppColors.divider),
                _SubjectPickerOptionRow(
                  title: subject.name,
                  subtitle:
                      'Weekly target: ${DateTimeUtils.formatMinutes(subject.targetMinutes)}',
                  identifier: subject.identifier,
                  leading: SubjectIconBox(
                    iconKey: subject.iconKey,
                    selected: isSelected,
                  ),
                  selected: isSelected,
                  onTap: () {
                    onSelected(subject.id);
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          }),
      ],
    ),
  );
}

class _SubjectPickerOptionRow extends StatelessWidget {
  const _SubjectPickerOptionRow({
    required this.title,
    required this.subtitle,
    required this.leading,
    required this.selected,
    required this.onTap,
    this.identifier,
  });

  final String title;
  final String subtitle;
  final Widget leading;
  final bool selected;
  final VoidCallback onTap;
  final SubjectIdentifier? identifier;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: AppRadii.controlRadius,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          children: <Widget>[
            leading,
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      if (identifier != null) ...<Widget>[
                        SubjectIdentifierBadge(identifier: identifier!),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: Text(
                          title,
                          style: AppTypography.body16SemiBold,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTypography.secondary14),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              size: 20,
              color: selected ? AppColors.primary : AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

/// Opens the reusable Custom Duration stepper sheet (5 to 180 minutes).
Future<void> showCustomDurationSheet({
  required BuildContext context,
  required int initialMinutes,
  required ValueChanged<int> onApply,
}) {
  var minutes = initialMinutes.clamp(5, 180);

  return PmBottomSheet.show<void>(
    context: context,
    title: 'Custom Duration',
    child: StatefulBuilder(
      builder: (context, setModalState) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            PmStepperField(
              label: 'Focus duration',
              valueLabel: '$minutes min',
              canDecrement: minutes > 5,
              canIncrement: minutes < 180,
              onDecrement: () {
                if (minutes > 5) {
                  setModalState(() => minutes = (minutes - 5).clamp(5, 180));
                }
              },
              onIncrement: () {
                if (minutes < 180) {
                  setModalState(() => minutes = (minutes + 5).clamp(5, 180));
                }
              },
            ),
            const SizedBox(height: 20),
            PmPrimaryButton(
              label: 'Apply',
              onPressed: () {
                onApply(minutes);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    ),
  );
}

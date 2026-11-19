import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Standard labeled input field with inline monochrome (!) validation row.
class PmTextField extends StatelessWidget {
  const PmTextField({
    super.key,
    this.label,
    this.hintText,
    this.controller,
    this.errorText,
    this.onChanged,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLines = 1,
    this.minLines,
    this.keyboardType,
    this.textInputAction,
    this.readOnly = false,
    this.onTap,
  });

  final String? label;
  final String? hintText;
  final TextEditingController? controller;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final int maxLines;
  final int? minLines;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool readOnly;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null && errorText!.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (label != null) ...<Widget>[
          Text(label!, style: AppTypography.secondary14SemiBold),
          const SizedBox(height: AppSpacing.xs),
        ],
        TextField(
          controller: controller,
          onChanged: onChanged,
          maxLines: maxLines,
          minLines: minLines,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          readOnly: readOnly,
          onTap: onTap,
          style: AppTypography.body16,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            enabledBorder: OutlineInputBorder(
              borderRadius: AppRadii.controlRadius,
              borderSide: BorderSide(
                color: hasError ? AppColors.foreground : AppColors.border,
                width: hasError ? 1.3 : 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppRadii.controlRadius,
              borderSide: BorderSide(
                color: hasError ? AppColors.foreground : AppColors.primary,
                width: 1.5,
              ),
            ),
          ),
        ),
        if (hasError) ...<Widget>[
          const SizedBox(height: 6),
          Row(
            children: <Widget>[
              const Icon(
                Icons.error_rounded,
                size: 16,
                color: AppColors.foreground,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  errorText!,
                  style: AppTypography.secondary14Medium.copyWith(
                    color: AppColors.foreground,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Multi-line notes input matching Session Setup & Study Task forms.
class PmTextArea extends StatelessWidget {
  const PmTextArea({
    super.key,
    this.label,
    this.hintText,
    this.controller,
    this.onChanged,
    this.minLines = 3,
    this.maxLines = 5,
  });

  final String? label;
  final String? hintText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final int minLines;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return PmTextField(
      label: label,
      hintText: hintText,
      controller: controller,
      onChanged: onChanged,
      minLines: minLines,
      maxLines: maxLines,
      keyboardType: TextInputType.multiline,
    );
  }
}

/// Tappable 52px dropdown/picker trigger matching Subject & Time selectors.
class PmDropdownField extends StatelessWidget {
  const PmDropdownField({
    required this.valueText,
    required this.onTap,
    super.key,
    this.label,
    this.placeholder,
    this.leading,
    this.trailingIcon = Icons.keyboard_arrow_down_rounded,
  });

  final String? label;
  final String? valueText;
  final String? placeholder;
  final Widget? leading;
  final IconData trailingIcon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasValue = valueText != null && valueText!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (label != null) ...<Widget>[
          Text(label!, style: AppTypography.secondary14SemiBold),
          const SizedBox(height: AppSpacing.xs),
        ],
        SizedBox(
          height: AppSpacing.controlHeight,
          child: Material(
            color: AppColors.card,
            shape: const RoundedRectangleBorder(
              borderRadius: AppRadii.controlRadius,
              side: BorderSide(color: AppColors.border),
            ),
            child: InkWell(
              borderRadius: AppRadii.controlRadius,
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: <Widget>[
                    if (leading != null) ...<Widget>[
                      leading!,
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: Text(
                        hasValue ? valueText! : (placeholder ?? ''),
                        style: AppTypography.body16.copyWith(
                          color: hasValue
                              ? AppColors.textPrimary
                              : AppColors.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(
                      trailingIcon,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class PmSegmentOption<T> {
  const PmSegmentOption({required this.value, required this.label});

  final T value;
  final String label;
}

/// Light-grey (#F0F0F0) segmented pill switcher with white active card.
class PmSegmentedControl<T> extends StatelessWidget {
  const PmSegmentedControl({
    required this.options,
    required this.selectedValue,
    required this.onChanged,
    super.key,
  });

  final List<PmSegmentOption<T>> options;
  final T selectedValue;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.controlRadius,
      ),
      child: Row(
        children: options.map((option) {
          final selected = option.value == selectedValue;
          return Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => onChanged(option.value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                decoration: BoxDecoration(
                  color: selected ? AppColors.card : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  option.label,
                  style: AppTypography.secondary14.copyWith(
                    color: selected
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// 52px bordered numeric stepper (- / value / +) for durations & goals.
class PmStepperField extends StatelessWidget {
  const PmStepperField({
    required this.valueLabel,
    required this.onDecrement,
    required this.onIncrement,
    super.key,
    this.label,
    this.canDecrement = true,
    this.canIncrement = true,
  });

  final String? label;
  final String valueLabel;
  final VoidCallback? onDecrement;
  final VoidCallback? onIncrement;
  final bool canDecrement;
  final bool canIncrement;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (label != null) ...<Widget>[
          Text(label!, style: AppTypography.secondary14SemiBold),
          const SizedBox(height: AppSpacing.xs),
        ],
        Container(
          height: AppSpacing.controlHeight,
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: AppRadii.controlRadius,
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: <Widget>[
              SizedBox(
                width: 48,
                height: 48,
                child: IconButton(
                  onPressed: canDecrement ? onDecrement : null,
                  icon: Icon(
                    Icons.remove_rounded,
                    size: 20,
                    color: canDecrement
                        ? AppColors.textPrimary
                        : AppColors.textMuted,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  valueLabel,
                  textAlign: TextAlign.center,
                  style: AppTypography.body16SemiBold,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(
                width: 48,
                height: 48,
                child: IconButton(
                  onPressed: canIncrement ? onIncrement : null,
                  icon: Icon(
                    Icons.add_rounded,
                    size: 20,
                    color: canIncrement
                        ? AppColors.textPrimary
                        : AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Pill choice chip with navy active state and white bordered inactive state.
class PmChip extends StatelessWidget {
  const PmChip({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
    this.leading,
    this.selectedBorderOnly = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget? leading;

  /// When true, renders a white chip with navy border (Subject Identifier style).
  final bool selectedBorderOnly;

  @override
  Widget build(BuildContext context) {
    final fillColor = selected && !selectedBorderOnly
        ? AppColors.primary
        : AppColors.card;
    final borderColor = selected ? AppColors.primary : AppColors.border;
    final textColor = selected && !selectedBorderOnly
        ? AppColors.onPrimary
        : (selected ? AppColors.primary : AppColors.textPrimary);

    return Material(
      color: fillColor,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadii.pillRadius,
        side: BorderSide(color: borderColor),
      ),
      child: InkWell(
        borderRadius: AppRadii.pillRadius,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (leading != null) ...<Widget>[
                leading!,
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: AppTypography.secondary14SemiBold.copyWith(
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Circular task completion checkbox (navy fill + white check when done).
class PmCheckCircle extends StatelessWidget {
  const PmCheckCircle({
    required this.checked,
    required this.onTap,
    super.key,
  });

  final bool checked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: SizedBox(
        width: AppSpacing.minTouchTarget,
        height: AppSpacing.minTouchTarget,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: checked ? AppColors.primary : Colors.transparent,
              border: Border.all(
                color: checked ? AppColors.primary : AppColors.textSecondary,
                width: 1.6,
              ),
            ),
            child: checked
                ? const Icon(
                    Icons.check_rounded,
                    size: 16,
                    color: AppColors.onPrimary,
                  )
                : null,
          ),
        ),
      ),
    );
  }
}

/// Navy toggle switch matching ParhaiMate Settings/Component Library.
class PmSwitch extends StatelessWidget {
  const PmSwitch({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 48,
        height: 28,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          borderRadius: AppRadii.pillRadius,
          color: value ? AppColors.primary : AppColors.track,
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 160),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.onPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class PmWeekDayItem {
  const PmWeekDayItem({
    required this.date,
    required this.dayShort,
    required this.dayNumber,
    this.hasActivity = false,
    this.isToday = false,
  });

  final DateTime date;
  final String dayShort;
  final String dayNumber;
  final bool hasActivity;
  final bool isToday;
}

/// 7-day horizontal date selector used on Home Dashboard & Study Planner.
class PmWeekDateStrip extends StatelessWidget {
  const PmWeekDateStrip({
    required this.days,
    required this.selectedDate,
    required this.onSelectDate,
    super.key,
  });

  final List<PmWeekDayItem> days;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onSelectDate;

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List<Widget>.generate(days.length, (index) {
        final item = days[index];
        final selected = _isSameDay(item.date, selectedDate);
        final borderColor = selected
            ? AppColors.primary
            : (item.isToday ? AppColors.foreground : AppColors.border);

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              left: index == 0 ? 0 : 3,
              right: index == days.length - 1 ? 0 : 3,
            ),
            child: Material(
              color: selected ? AppColors.primary : AppColors.card,
              shape: RoundedRectangleBorder(
                borderRadius: AppRadii.controlRadius,
                side: BorderSide(
                  color: borderColor,
                  width: item.isToday && !selected ? 1.4 : 1,
                ),
              ),
              child: InkWell(
                borderRadius: AppRadii.controlRadius,
                onTap: () => onSelectDate(item.date),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        item.dayShort,
                        style: AppTypography.meta12.copyWith(
                          color: selected
                              ? AppColors.onPrimary.withValues(alpha: 0.85)
                              : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.dayNumber,
                        style: AppTypography.body16SemiBold.copyWith(
                          color: selected
                              ? AppColors.onPrimary
                              : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: item.hasActivity
                              ? (selected
                                  ? AppColors.onPrimary
                                  : AppColors.primary)
                              : Colors.transparent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

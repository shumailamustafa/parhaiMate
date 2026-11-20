import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_time_utils.dart';
import '../../../core/widgets/widgets.dart';
import '../services/report_service.dart';
import '../viewmodels/export_report_viewmodel.dart';

/// Export Study Report screen matching Export Study Report.png.
class ExportReportView extends GetView<ExportReportViewModel> {
  const ExportReportView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PmAppBar(title: 'Export Study Report'),
      body: Obx(() {
        final period = controller.selectedPeriod.value;
        final format = controller.selectedFormat.value;
        final preview = controller.preview.value;
        final isLoading = controller.isLoading.value;
        final isExporting = controller.isExporting.value;

        return Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        'Report period',
                        style: AppTypography.secondary14SemiBold,
                      ),
                      const SizedBox(height: 8),
                      PmSegmentedControl<ReportPeriod>(
                        options: const <PmSegmentOption<ReportPeriod>>[
                          PmSegmentOption<ReportPeriod>(
                            value: ReportPeriod.week,
                            label: 'Week',
                          ),
                          PmSegmentOption<ReportPeriod>(
                            value: ReportPeriod.month,
                            label: 'Month',
                          ),
                          PmSegmentOption<ReportPeriod>(
                            value: ReportPeriod.allTime,
                            label: 'All time',
                          ),
                        ],
                        selectedValue: period,
                        onChanged: controller.setPeriod,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Format',
                        style: AppTypography.secondary14SemiBold,
                      ),
                      const SizedBox(height: 8),
                      _FormatOptionCard(
                        icon: Icons.picture_as_pdf_outlined,
                        title: 'PDF report',
                        subtitle:
                            'Clean monochrome printable summary of sessions and subjects.',
                        selected: format == ReportFormat.pdf,
                        onTap: () => controller.setFormat(ReportFormat.pdf),
                      ),
                      const SizedBox(height: 10),
                      _FormatOptionCard(
                        icon: Icons.table_chart_outlined,
                        title: 'CSV data',
                        subtitle:
                            'Spreadsheet-ready session log for further analysis.',
                        selected: format == ReportFormat.csv,
                        onTap: () => controller.setFormat(ReportFormat.csv),
                      ),
                      const SizedBox(height: 20),
                      PmGreyCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            const Text(
                              'Report preview',
                              style: AppTypography.section18,
                            ),
                            const SizedBox(height: 12),
                            if (isLoading || preview == null)
                              const Text(
                                'Loading study totals...',
                                style: AppTypography.secondary14,
                              )
                            else ...<Widget>[
                              _PreviewStatRow(
                                label: 'Study time',
                                value: DateTimeUtils.formatMinutes(
                                  preview.totalMinutes,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _PreviewStatRow(
                                label: 'Sessions',
                                value: '${preview.sessionsCount}',
                              ),
                              const SizedBox(height: 8),
                              _PreviewStatRow(
                                label: 'Subjects',
                                value: '${preview.subjectsCount}',
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              PmPrimaryButton(
                label: 'Export Report',
                isLoading: isExporting,
                onPressed: isLoading ? null : () => _export(context),
              ),
            ],
          ),
        );
      }),
    );
  }

  Future<void> _export(BuildContext context) async {
    final file = await controller.exportAndShare();
    if (file != null && context.mounted) {
      PmToast.show(context, 'Report ready: ${file.fileName}');
    }
  }
}

class _FormatOptionCard extends StatelessWidget {
  const _FormatOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadii.cardRadius,
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.border,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: AppRadii.cardRadius,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: <Widget>[
              Icon(icon, size: 22, color: AppColors.textPrimary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(title, style: AppTypography.body16SemiBold),
                    const SizedBox(height: 2),
                    Text(subtitle, style: AppTypography.secondary14),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 22,
                color: selected ? AppColors.primary : AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreviewStatRow extends StatelessWidget {
  const _PreviewStatRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(child: Text(label, style: AppTypography.secondary14)),
        Text(value, style: AppTypography.body16SemiBold),
      ],
    );
  }
}

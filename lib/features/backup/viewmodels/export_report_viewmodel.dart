import 'dart:async';

import 'package:get/get.dart';

import '../services/report_service.dart';

/// ViewModel backing the Export Study Report screen.
class ExportReportViewModel extends GetxController {
  ExportReportViewModel({
    required ReportService reportService,
  }) : _reportService = reportService;

  final ReportService _reportService;

  final Rx<ReportPeriod> selectedPeriod = ReportPeriod.week.obs;
  final Rx<ReportFormat> selectedFormat = ReportFormat.pdf.obs;
  final Rxn<ReportPreviewData> preview = Rxn<ReportPreviewData>();
  final RxBool isLoading = true.obs;
  final RxBool isExporting = false.obs;
  final Rxn<GeneratedReportFile> exportedReport = Rxn<GeneratedReportFile>();

  bool _disposed = false;

  @override
  void onInit() {
    super.onInit();
    unawaited(refreshPreview());
  }

  Future<void> setPeriod(ReportPeriod period) async {
    if (selectedPeriod.value == period) {
      return;
    }
    selectedPeriod.value = period;
    await refreshPreview();
  }

  void setFormat(ReportFormat format) {
    selectedFormat.value = format;
  }

  Future<void> refreshPreview() async {
    isLoading.value = true;
    final data = await _reportService.loadPreview(selectedPeriod.value);
    if (!_disposed) {
      preview.value = data;
      isLoading.value = false;
    }
  }

  Future<GeneratedReportFile?> exportAndShare() async {
    if (isExporting.value) {
      return null;
    }
    isExporting.value = true;
    try {
      final generated = await _reportService.exportReport(
        period: selectedPeriod.value,
        format: selectedFormat.value,
      );
      if (!_disposed) {
        exportedReport.value = generated;
      }
      await _reportService.shareReport(generated);
      return generated;
    } finally {
      if (!_disposed) {
        isExporting.value = false;
      }
    }
  }

  @override
  void onClose() {
    _disposed = true;
    super.onClose();
  }
}

import 'dart:io';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../../core/utils/date_time_utils.dart';
import '../../../domain/entities/domain_entities.dart';
import '../../../domain/repositories/repositories.dart';

enum ReportPeriod {
  week('This week'),
  month('This month'),
  allTime('All time');

  const ReportPeriod(this.label);

  final String label;
}

enum ReportFormat { pdf, csv }

class ReportPreviewData {
  const ReportPreviewData({
    required this.totalMinutes,
    required this.sessionsCount,
    required this.subjectsCount,
    required this.sessions,
    required this.subjectNamesById,
  });

  final int totalMinutes;
  final int sessionsCount;
  final int subjectsCount;
  final List<StudySessionEntity> sessions;
  final Map<int, String> subjectNamesById;
}

class GeneratedReportFile {
  const GeneratedReportFile({
    required this.fileName,
    required this.filePath,
    required this.format,
  });

  final String fileName;
  final String filePath;
  final ReportFormat format;
}

/// Generates CSV & PDF study reports strictly following monochrome/navy branding.
class ReportService {
  ReportService({
    required SessionRepository sessionRepository,
    required SubjectRepository subjectRepository,
    DateTime Function()? nowProvider,
    Future<Directory> Function()? exportDirectoryProvider,
    Future<void> Function(String filePath, String subject)? shareFileHandler,
  })  : _sessionRepository = sessionRepository,
        _subjectRepository = subjectRepository,
        _nowProvider = nowProvider ?? DateTime.now,
        _exportDirectoryProvider = exportDirectoryProvider,
        _shareFileHandler = shareFileHandler;

  final SessionRepository _sessionRepository;
  final SubjectRepository _subjectRepository;
  final DateTime Function() _nowProvider;
  final Future<Directory> Function()? _exportDirectoryProvider;
  final Future<void> Function(String filePath, String subject)? _shareFileHandler;

  Future<ReportPreviewData> loadPreview(ReportPeriod period) async {
    final now = _nowProvider();
    int? startMs;
    int? endMs;

    switch (period) {
      case ReportPeriod.week:
        startMs = DateTimeUtils.startOfWeek(now).toUtc().millisecondsSinceEpoch;
        endMs = DateTimeUtils.endOfWeekExclusive(now)
            .toUtc()
            .millisecondsSinceEpoch;
      case ReportPeriod.month:
        startMs = DateTime(now.year, now.month, 1).toUtc().millisecondsSinceEpoch;
        endMs =
            DateTime(now.year, now.month + 1, 1).toUtc().millisecondsSinceEpoch;
      case ReportPeriod.allTime:
        startMs = null;
        endMs = null;
    }

    final sessions = await _sessionRepository.getCompletedSessions(
      startMsInclusive: startMs,
      endMsExclusive: endMs,
    );
    final subjects = await _subjectRepository.getSubjects();
    final subjectNames = <int, String>{
      for (final s in subjects) s.id: s.name,
    };

    final totalMinutes =
        sessions.fold<int>(0, (sum, s) => sum + s.durationSeconds) ~/ 60;
    final distinctSubjects = <int?>{for (final s in sessions) s.subjectId};

    return ReportPreviewData(
      totalMinutes: totalMinutes,
      sessionsCount: sessions.length,
      subjectsCount:
          sessions.isEmpty ? subjects.length : distinctSubjects.length,
      sessions: sessions,
      subjectNamesById: subjectNames,
    );
  }

  String buildCsvContent(ReportPreviewData data) {
    final rows = <List<dynamic>>[
      <String>[
        'Date',
        'Subject',
        'Mode',
        'Duration Minutes',
        'Start Time',
        'End Time',
        'Notes',
      ],
      ...data.sessions.map((s) {
        final startDt =
            DateTime.fromMillisecondsSinceEpoch(s.startedAtMs, isUtc: true)
                .toLocal();
        final endDt = DateTime.fromMillisecondsSinceEpoch(
          s.endedAtMs ?? s.startedAtMs,
          isUtc: true,
        ).toLocal();
        final subjectName = s.subjectId == null
            ? 'General Study'
            : (data.subjectNamesById[s.subjectId!] ?? 'General Study');
        return <dynamic>[
          DateTimeUtils.toDateKey(startDt),
          subjectName,
          s.sessionType.label,
          (s.durationSeconds / 60).round(),
          DateTimeUtils.formatClockTime(startDt),
          DateTimeUtils.formatClockTime(endDt),
          s.notes ?? '',
        ];
      }),
    ];

    return const ListToCsvConverter().convert(rows);
  }

  Future<Uint8List> buildPdfBytes(
    ReportPeriod period,
    ReportPreviewData data,
  ) async {
    final doc = pw.Document();
    const navy = PdfColor.fromInt(0xFF123B52);
    const lightGrey = PdfColor.fromInt(0xFFF0F0F0);
    const darkGrey = PdfColor.fromInt(0xFF5C5C5C);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => <pw.Widget>[
          pw.Text(
            'ParhaiMate Study Report',
            style: pw.TextStyle(
              fontSize: 22,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.black,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Period: ${period.label} - Generated ${DateTimeUtils.toDateKey(_nowProvider())}',
            style: const pw.TextStyle(fontSize: 11, color: darkGrey),
          ),
          pw.SizedBox(height: 18),
          pw.Container(
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(
              color: lightGrey,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: <pw.Widget>[
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: <pw.Widget>[
                    pw.Text(
                      'Total Study Time',
                      style: const pw.TextStyle(fontSize: 10, color: darkGrey),
                    ),
                    pw.Text(
                      DateTimeUtils.formatMinutes(data.totalMinutes),
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: navy,
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: <pw.Widget>[
                    pw.Text(
                      'Sessions',
                      style: const pw.TextStyle(fontSize: 10, color: darkGrey),
                    ),
                    pw.Text(
                      '${data.sessionsCount}',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: <pw.Widget>[
                    pw.Text(
                      'Subjects',
                      style: const pw.TextStyle(fontSize: 10, color: darkGrey),
                    ),
                    pw.Text(
                      '${data.subjectsCount}',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Text(
            'Study Sessions',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          if (data.sessions.isEmpty)
            pw.Text(
              'No completed study sessions in this period.',
              style: const pw.TextStyle(fontSize: 11, color: darkGrey),
            )
          else
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              headerDecoration: const pw.BoxDecoration(color: navy),
              cellStyle: const pw.TextStyle(fontSize: 9.5),
              headers: const <String>['Date', 'Subject', 'Mode', 'Duration'],
              data: data.sessions.map((s) {
                final date = DateTime.fromMillisecondsSinceEpoch(
                  s.startedAtMs,
                  isUtc: true,
                ).toLocal();
                final subj = s.subjectId == null
                    ? 'General Study'
                    : (data.subjectNamesById[s.subjectId!] ?? 'General Study');
                return <String>[
                  DateTimeUtils.toDateKey(date),
                  subj,
                  s.sessionType.label,
                  DateTimeUtils.formatSecondsAsMinutesLabel(s.durationSeconds),
                ];
              }).toList(),
            ),
        ],
      ),
    );

    return doc.save();
  }

  Future<GeneratedReportFile> exportReport({
    required ReportPeriod period,
    required ReportFormat format,
  }) async {
    final preview = await loadPreview(period);
    final dirProvider = _exportDirectoryProvider;
    final dir = dirProvider != null
        ? await dirProvider()
        : await getApplicationDocumentsDirectory();
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    final dateKey = DateTimeUtils.toDateKey(_nowProvider());
    final ext = format == ReportFormat.pdf ? 'pdf' : 'csv';
    final fileName = 'parhaimate-report-$dateKey.$ext';
    final file = File(p.join(dir.path, fileName));

    if (format == ReportFormat.csv) {
      await file.writeAsString(buildCsvContent(preview), flush: true);
    } else {
      final bytes = await buildPdfBytes(period, preview);
      await file.writeAsBytes(bytes, flush: true);
    }

    return GeneratedReportFile(
      fileName: fileName,
      filePath: file.path,
      format: format,
    );
  }

  Future<void> shareReport(GeneratedReportFile report) async {
    final shareHandler = _shareFileHandler;
    if (shareHandler != null) {
      await shareHandler(report.filePath, 'ParhaiMate Study Report');
      return;
    }
    await SharePlus.instance.share(
      ShareParams(
        files: <XFile>[XFile(report.filePath)],
        subject: 'ParhaiMate Study Report (${report.fileName})',
      ),
    );
  }
}

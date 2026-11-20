import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' as drift;
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants/app_info.dart';
import '../../../core/utils/date_time_utils.dart';
import '../../../data/database/app_database.dart';
import '../../../domain/enums/domain_enums.dart';
import '../../../domain/repositories/repositories.dart';

class BackupPreviewSummary {
  const BackupPreviewSummary({
    required this.subjectsCount,
    required this.sessionsCount,
    required this.tasksCount,
    required this.presetsCount,
    required this.suggestedFileName,
    required this.estimatedSizeBytes,
  });

  final int subjectsCount;
  final int sessionsCount;
  final int tasksCount;
  final int presetsCount;
  final String suggestedFileName;
  final int estimatedSizeBytes;

  String get formattedSize {
    if (estimatedSizeBytes < 1024) {
      return '$estimatedSizeBytes B';
    }
    final kb = (estimatedSizeBytes / 1024).ceil();
    return 'About $kb KB';
  }
}

class ParsedBackupDocument {
  const ParsedBackupDocument({
    required this.fileName,
    required this.exportedAtIso,
    required this.schemaVersion,
    required this.dailyGoalMinutes,
    required this.weeklyGoalMinutes,
    required this.defaultTimerMode,
    required this.subjects,
    required this.sessions,
    required this.tasks,
    required this.presets,
    required this.dailyGoals,
    required this.streakRecords,
    required this.achievements,
  });

  final String fileName;
  final String exportedAtIso;
  final int schemaVersion;
  final int dailyGoalMinutes;
  final int weeklyGoalMinutes;
  final String defaultTimerMode;
  final List<Map<String, dynamic>> subjects;
  final List<Map<String, dynamic>> sessions;
  final List<Map<String, dynamic>> tasks;
  final List<Map<String, dynamic>> presets;
  final List<Map<String, dynamic>> dailyGoals;
  final List<Map<String, dynamic>> streakRecords;
  final List<Map<String, dynamic>> achievements;

  DateTime? get exportedAtDate => DateTime.tryParse(exportedAtIso);
}

class BackupParseFailure {
  const BackupParseFailure({
    required this.title,
    required this.message,
  });

  final String title;
  final String message;
}

class BackupParseResult {
  const BackupParseResult.success(this.document) : failure = null;
  const BackupParseResult.error(this.failure) : document = null;

  final ParsedBackupDocument? document;
  final BackupParseFailure? failure;

  bool get isSuccess => document != null;
}

/// Raised when the pre-restore safety copy cannot be written.
class BackupSnapshotException implements Exception {
  const BackupSnapshotException(this.details);

  final String details;

  @override
  String toString() => 'BackupSnapshotException: $details';
}

class ExportedBackupFile {
  const ExportedBackupFile({
    required this.fileName,
    required this.filePath,
    required this.locationLabel,
    required this.bytesCount,
  });

  final String fileName;
  final String filePath;
  final String locationLabel;
  final int bytesCount;
}

/// Offline JSON backup export, schema validation, and transactional restore service.
class BackupService {
  BackupService({
    required AppDatabase database,
    required GoalStreakRepository goalStreakRepository,
    required SettingsRepository settingsRepository,
    required AchievementRepository achievementRepository,
    DateTime Function()? nowProvider,
    Future<Directory> Function()? exportDirectoryProvider,
    Future<void> Function(String filePath, String subject)? shareFileHandler,
    Future<({String name, String content})?> Function()? pickBackupFileHandler,
    Future<String?> Function(String fileName, Uint8List bytes)?
        saveBackupFileHandler,
    Future<Directory> Function()? snapshotDirectoryProvider,
  })  : _snapshotDirectoryProvider = snapshotDirectoryProvider,
        _db = database,
        _goalRepo = goalStreakRepository,
        _settingsRepo = settingsRepository,
        _achievementRepo = achievementRepository,
        _nowProvider = nowProvider ?? DateTime.now,
        _exportDirectoryProvider = exportDirectoryProvider,
        _shareFileHandler = shareFileHandler,
        _pickBackupFileHandler = pickBackupFileHandler,
        _saveBackupFileHandler = saveBackupFileHandler;

  static const int currentSchemaVersion = 1;

  /// How many automatic pre-restore safety copies are kept on the device.
  static const int maxSafetySnapshots = 3;

  final Future<Directory> Function()? _snapshotDirectoryProvider;

  /// Path of the safety copy written before the most recent Replace restore.
  String? lastSafetySnapshotPath;

  final AppDatabase _db;
  final GoalStreakRepository _goalRepo;
  final SettingsRepository _settingsRepo;
  final AchievementRepository _achievementRepo;
  final DateTime Function() _nowProvider;
  final Future<Directory> Function()? _exportDirectoryProvider;
  final Future<void> Function(String filePath, String subject)? _shareFileHandler;
  final Future<({String name, String content})?> Function()?
      _pickBackupFileHandler;
  final Future<String?> Function(String fileName, Uint8List bytes)?
      _saveBackupFileHandler;

  String buildFileName() =>
      'parhaimate-backup-${DateTimeUtils.toDateKey(_nowProvider())}.json';

  Future<BackupPreviewSummary> getExportPreview() async {
    final json = await buildBackupJson();
    final subjects = await _db.subjectDao.getAllSubjects();
    final sessions = await _db.sessionDao.getCompletedSessions();
    final tasks = await _db.plannerDao.getAllTasks();
    final presets = await _db.presetDao.getAllPresets();

    return BackupPreviewSummary(
      subjectsCount: subjects.length,
      sessionsCount: sessions.length,
      tasksCount: tasks.length,
      presetsCount: presets.length,
      suggestedFileName: buildFileName(),
      estimatedSizeBytes: utf8.encode(json).length,
    );
  }

  /// Generates a complete JSON snapshot excluding transient active_timer_states.
  Future<String> buildBackupJson() async {
    final subjects = await _db.subjectDao.getAllSubjects();
    final sessions = await _db.sessionDao.getCompletedSessions();
    final tasks = await _db.plannerDao.getAllTasks();
    final presets = await _db.presetDao.getAllPresets();
    final dailyGoals = await _db.goalStreakDao.getAllDailyGoals();
    final streaks = await _db.goalStreakDao.getAllStreakRecords();
    final achievements = await _db.achievementDao.getAllAchievements();
    final dailyGoal = await _goalRepo.getDailyGoalMinutes();
    final weeklyGoal = await _goalRepo.getWeeklyGoalMinutes();
    final defaultMode = await _settingsRepo.getDefaultTimerMode();

    final payload = <String, dynamic>{
      'schemaVersion': currentSchemaVersion,
      'appName': 'ParhaiMate',
      'appVersion': AppInfo.version,
      'exportedAtUtc': _nowProvider().toUtc().toIso8601String(),
      'settings': <String, dynamic>{
        'dailyGoalMinutes': dailyGoal,
        'weeklyGoalMinutes': weeklyGoal,
        'defaultTimerMode': defaultMode.key,
      },
      'subjects': subjects
          .map(
            (s) => <String, dynamic>{
              'id': s.id,
              'name': s.name,
              'color': s.color,
              'icon': s.icon,
              'targetMinutes': s.targetMinutes,
              'createdAt': s.createdAt,
              'updatedAt': s.updatedAt,
              'isArchived': s.isArchived,
            },
          )
          .toList(),
      'studySessions': sessions
          .map(
            (s) => <String, dynamic>{
              'id': s.id,
              'subjectId': s.subjectId,
              'sessionType': s.sessionType,
              'startedAt': s.startedAt,
              'endedAt': s.endedAt,
              'durationSeconds': s.durationSeconds,
              'status': s.status,
              'notes': s.notes,
              'createdAt': s.createdAt,
            },
          )
          .toList(),
      'plannerTasks': tasks
          .map(
            (t) => <String, dynamic>{
              'id': t.id,
              'subjectId': t.subjectId,
              'title': t.title,
              'scheduledDate': t.scheduledDate,
              'scheduledTime': t.scheduledTime,
              'targetMinutes': t.targetMinutes,
              'notes': t.notes,
              'isCompleted': t.isCompleted,
              'createdAt': t.createdAt,
              'updatedAt': t.updatedAt,
            },
          )
          .toList(),
      'timerPresets': presets
          .map(
            (pr) => <String, dynamic>{
              'id': pr.id,
              'name': pr.name,
              'timerMode': pr.timerMode,
              'focusMinutes': pr.focusMinutes,
              'shortBreakMinutes': pr.shortBreakMinutes,
              'longBreakMinutes': pr.longBreakMinutes,
              'cyclesBeforeLongBreak': pr.cyclesBeforeLongBreak,
              'isDefault': pr.isDefault,
            },
          )
          .toList(),
      'dailyGoals': dailyGoals
          .map(
            (g) => <String, dynamic>{
              'dateKey': g.dateKey,
              'targetMinutes': g.targetMinutes,
              'createdAt': g.createdAt,
            },
          )
          .toList(),
      'streakRecords': streaks
          .map(
            (r) => <String, dynamic>{
              'dateKey': r.dateKey,
              'studyMinutes': r.studyMinutes,
              'streakQualified': r.streakQualified,
            },
          )
          .toList(),
      'achievements': achievements
          .map(
            (a) => <String, dynamic>{
              'achievementCode': a.achievementCode,
              'unlockedAt': a.unlockedAt,
            },
          )
          .toList(),
    };

    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  /// Exports backup JSON to user-visible storage via native Save As dialog,
  /// returning `null` if the user cancels the Save picker.
  Future<ExportedBackupFile?> exportBackupToFile() async {
    final jsonContent = await buildBackupJson();
    final bytes = Uint8List.fromList(utf8.encode(jsonContent));
    final fileName = buildFileName();

    final dirProvider = _exportDirectoryProvider;
    final saveHandler = _saveBackupFileHandler;

    if (dirProvider != null && saveHandler == null) {
      final dir = await dirProvider();
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      final file = File(p.join(dir.path, fileName));
      await file.writeAsBytes(bytes, flush: true);
      return ExportedBackupFile(
        fileName: fileName,
        filePath: file.path,
        locationLabel: 'Downloads',
        bytesCount: bytes.length,
      );
    }

    // Prepare a shareable temp file so "Share File" always has a valid local path.
    final tempDir = await _resolveShareTempDirectory();
    if (!await tempDir.exists()) {
      await tempDir.create(recursive: true);
    }
    final tempShareFile = File(p.join(tempDir.path, fileName));
    await tempShareFile.writeAsBytes(bytes, flush: true);

    String? savedPath;
    if (saveHandler != null) {
      savedPath = await saveHandler(fileName, bytes);
    } else {
      savedPath = await FilePicker.saveFile(
        dialogTitle: 'Save ParhaiMate backup',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: const <String>['json'],
        bytes: bytes,
      );
    }

    if (savedPath == null || savedPath.trim().isEmpty) {
      return null;
    }

    // On desktop platforms saveFile returns a filesystem path without writing bytes.
    if (saveHandler == null &&
        !savedPath.startsWith('content://') &&
        !savedPath.startsWith('/document/')) {
      final directFile = File(savedPath);
      if (!await directFile.exists()) {
        await directFile.writeAsBytes(bytes, flush: true);
      }
    }

    return ExportedBackupFile(
      fileName: fileName,
      filePath: tempShareFile.path,
      locationLabel: _resolveSavedLocationLabel(savedPath),
      bytesCount: bytes.length,
    );
  }

  Future<Directory> _resolveShareTempDirectory() async {
    final provider = _exportDirectoryProvider;
    if (provider != null) {
      return provider();
    }
    try {
      return await getTemporaryDirectory();
    } catch (_) {
      return Directory.systemTemp;
    }
  }

  String _resolveSavedLocationLabel(String savedPath) {
    final lower = savedPath.toLowerCase();
    if (lower.contains('download')) {
      return 'Downloads';
    }
    if (lower.contains('content://') || lower.contains('/document/')) {
      return 'Selected folder';
    }
    final dirName = p.basename(p.dirname(savedPath));
    return dirName.isEmpty || dirName == '.' ? 'Selected folder' : dirName;
  }

  Future<void> shareBackupFile(ExportedBackupFile file) async {
    final shareHandler = _shareFileHandler;
    if (shareHandler != null) {
      await shareHandler(file.filePath, 'ParhaiMate Backup');
      return;
    }
    await SharePlus.instance.share(
      ShareParams(
        files: <XFile>[XFile(file.filePath)],
        subject: 'ParhaiMate Backup (${file.fileName})',
      ),
    );
  }

  Future<({String name, String content})?> pickBackupFile() async {
    final pickHandler = _pickBackupFileHandler;
    if (pickHandler != null) {
      return pickHandler();
    }
    final result = await FilePicker.pickFiles(
      type: FileType.any,
      withData: true,
    );
    if (result == null || result.files.isEmpty) {
      return null;
    }
    final picked = result.files.first;
    final name = picked.name;
    if (picked.bytes != null) {
      return (name: name, content: utf8.decode(picked.bytes!, allowMalformed: true));
    }
    if (picked.path != null) {
      final content = await File(picked.path!).readAsString();
      return (name: name, content: content);
    }
    return null;
  }

  /// Parses & validates raw backup text cleanly matching reference error screens.
  BackupParseResult validateAndParse(
    String rawContent, {
    required String fileName,
  }) {
    if (!fileName.toLowerCase().endsWith('.json')) {
      return BackupParseResult.error(
        BackupParseFailure(
          title: "Couldn't read this file",
          message:
              "$fileName isn't a ParhaiMate backup. Choose a .json file exported from ParhaiMate.",
        ),
      );
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(rawContent);
    } on FormatException {
      return BackupParseResult.error(
        BackupParseFailure(
          title: "Couldn't read this file",
          message:
              "$fileName isn't a ParhaiMate backup. Choose a .json file exported from ParhaiMate.",
        ),
      );
    }

    if (decoded is! Map<String, dynamic>) {
      return BackupParseResult.error(
        BackupParseFailure(
          title: "Couldn't read this file",
          message:
              "$fileName isn't a ParhaiMate backup. Choose a .json file exported from ParhaiMate.",
        ),
      );
    }

    final appName = decoded['appName'];
    final schemaVersion = decoded['schemaVersion'];
    final subjectsRaw = decoded['subjects'];
    final sessionsRaw = decoded['studySessions'];
    final tasksRaw = decoded['plannerTasks'];
    final settingsRaw = decoded['settings'];

    if (appName != 'ParhaiMate' ||
        schemaVersion is! int ||
        schemaVersion < 1 ||
        schemaVersion > currentSchemaVersion ||
        subjectsRaw is! List ||
        sessionsRaw is! List ||
        tasksRaw is! List ||
        settingsRaw is! Map<String, dynamic>) {
      return BackupParseResult.error(
        BackupParseFailure(
          title: 'This backup is damaged',
          message:
              'Some data in $fileName is missing. Try a newer backup file.',
        ),
      );
    }

    try {
      final subjects = _asMapList(subjectsRaw);
      final sessions = _asMapList(sessionsRaw);
      final tasks = _asMapList(tasksRaw);
      final presets = decoded['timerPresets'] is List
          ? _asMapList(decoded['timerPresets'] as List<dynamic>)
          : <Map<String, dynamic>>[];
      final dailyGoals = decoded['dailyGoals'] is List
          ? _asMapList(decoded['dailyGoals'] as List<dynamic>)
          : <Map<String, dynamic>>[];
      final streakRecords = decoded['streakRecords'] is List
          ? _asMapList(decoded['streakRecords'] as List<dynamic>)
          : <Map<String, dynamic>>[];
      final achievements = decoded['achievements'] is List
          ? _asMapList(decoded['achievements'] as List<dynamic>)
          : <Map<String, dynamic>>[];

      final subjectIds = <int>{};
      for (final s in subjects) {
        final id = s['id'];
        final name = s['name'];
        final target = s['targetMinutes'];
        if (id is! int ||
            name is! String ||
            name.trim().isEmpty ||
            target is! int ||
            target <= 0) {
          throw const FormatException('Invalid subject record');
        }
        subjectIds.add(id);
      }

      for (final sess in sessions) {
        final subjId = sess['subjectId'];
        final dur = sess['durationSeconds'];
        final startedAt = sess['startedAt'];
        if (dur is! int ||
            dur < 0 ||
            startedAt is! int ||
            (subjId != null && (subjId is! int || !subjectIds.contains(subjId)))) {
          throw const FormatException('Invalid session record');
        }
      }

      for (final task in tasks) {
        final subjId = task['subjectId'];
        final title = task['title'];
        final date = task['scheduledDate'];
        final dur = task['targetMinutes'];
        if (title is! String ||
            title.trim().isEmpty ||
            date is! String ||
            dur is! int ||
            dur <= 0 ||
            (subjId != null && (subjId is! int || !subjectIds.contains(subjId)))) {
          throw const FormatException('Invalid task record');
        }
      }

      final dailyGoalMin = settingsRaw['dailyGoalMinutes'];
      final weeklyGoalMin = settingsRaw['weeklyGoalMinutes'];
      final defaultMode = settingsRaw['defaultTimerMode'];
      if (dailyGoalMin is! int || weeklyGoalMin is! int || defaultMode is! String) {
        throw const FormatException('Invalid settings block');
      }

      return BackupParseResult.success(
        ParsedBackupDocument(
          fileName: fileName,
          exportedAtIso: (decoded['exportedAtUtc'] as String?) ?? '',
          schemaVersion: schemaVersion,
          dailyGoalMinutes: dailyGoalMin,
          weeklyGoalMinutes: weeklyGoalMin,
          defaultTimerMode: defaultMode,
          subjects: subjects,
          sessions: sessions,
          tasks: tasks,
          presets: presets,
          dailyGoals: dailyGoals,
          streakRecords: streakRecords,
          achievements: achievements,
        ),
      );
    } on FormatException {
      return BackupParseResult.error(
        BackupParseFailure(
          title: 'This backup is damaged',
          message:
              'Some data in $fileName is missing. Try a newer backup file.',
        ),
      );
    }
  }

  List<Map<String, dynamic>> _asMapList(List<dynamic> list) {
    final result = <Map<String, dynamic>>[];
    for (final item in list) {
      if (item is! Map<String, dynamic>) {
        throw const FormatException('Invalid entry');
      }
      result.add(item);
    }
    return result;
  }

  /// Writes the current data to a private safety copy before it is replaced.
  ///
  /// Throws [BackupSnapshotException] if the copy cannot be written, so a
  /// Replace restore never runs without a way back.
  Future<String> createSafetySnapshot() async {
    try {
      final Directory dir;
      final custom = _snapshotDirectoryProvider;
      final exportDir = _exportDirectoryProvider;
      if (custom != null) {
        dir = await custom();
      } else if (exportDir != null) {
        dir = Directory(p.join((await exportDir()).path, 'safety_snapshots'));
      } else {
        final docs = await getApplicationDocumentsDirectory();
        dir = Directory(p.join(docs.path, 'safety_snapshots'));
      }
      final json = await buildBackupJson();
      // Small file: synchronous I/O keeps this step atomic with the restore
      // flow (and deterministic under widget-test fake async).
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }

      final stamp = _nowProvider().toUtc().millisecondsSinceEpoch;
      final file = File(p.join(dir.path, 'pre-restore-$stamp.json'))
        ..writeAsStringSync(json, flush: true);

      // Keep only the newest few snapshots.
      final existing = dir
          .listSync()
          .whereType<File>()
          .where((f) => p.basename(f.path).startsWith('pre-restore-'))
          .toList()
        ..sort((a, b) => b.path.compareTo(a.path));
      for (final old in existing.skip(maxSafetySnapshots)) {
        old.deleteSync();
      }

      lastSafetySnapshotPath = file.path;
      return file.path;
    } catch (error) {
      throw BackupSnapshotException('$error');
    }
  }

  Future<void> restoreBackup(
    ParsedBackupDocument doc,
    BackupRestoreMode mode,
  ) async {
    if (mode == BackupRestoreMode.replace) {
      await createSafetySnapshot();
    }
    await _db.transaction(() async {
      if (mode == BackupRestoreMode.replace) {
        await _db.delete(_db.activeTimerStates).go();
        await _db.delete(_db.sessionEvents).go();
        await _db.delete(_db.studySessions).go();
        await _db.delete(_db.plannerTasks).go();
        await _db.delete(_db.subjects).go();
        await _db.delete(_db.dailyGoals).go();
        await _db.delete(_db.streakRecords).go();
        if (doc.presets.isNotEmpty) {
          await _db.delete(_db.timerPresets).go();
        }
        await _db.settingsDao.setValue(
          AppDatabase.keyDailyGoalMinutes,
          '${doc.dailyGoalMinutes}',
        );
        await _db.settingsDao.setValue(
          AppDatabase.keyWeeklyGoalMinutes,
          '${doc.weeklyGoalMinutes}',
        );
        await _db.settingsDao.setValue(
          AppDatabase.keyDefaultTimerMode,
          doc.defaultTimerMode,
        );
      }

      final existingSubjects = await _db.subjectDao.getAllSubjects();
      final existingByName = <String, int>{
        for (final s in existingSubjects) s.name.trim().toLowerCase(): s.id,
      };
      final subjectIdMap = <int, int>{};

      for (final raw in doc.subjects) {
        final oldId = raw['id'] as int;
        final name = (raw['name'] as String).trim();
        final normalized = name.toLowerCase();

        if (mode == BackupRestoreMode.merge && existingByName.containsKey(normalized)) {
          subjectIdMap[oldId] = existingByName[normalized]!;
          continue;
        }

        final nowMs = _nowProvider().toUtc().millisecondsSinceEpoch;
        final newId = await _db.subjectDao.insertSubject(
          SubjectsCompanion.insert(
            name: name,
            color: drift.Value<String>((raw['color'] as String?) ?? 'circle'),
            icon: drift.Value<String>((raw['icon'] as String?) ?? 'book'),
            targetMinutes: drift.Value<int>(
              (raw['targetMinutes'] as int?) ?? 300,
            ),
            createdAt: (raw['createdAt'] as int?) ?? nowMs,
            updatedAt: (raw['updatedAt'] as int?) ?? nowMs,
            isArchived: drift.Value<bool>((raw['isArchived'] as bool?) ?? false),
          ),
        );
        subjectIdMap[oldId] = newId;
        existingByName[normalized] = newId;
      }

      final existingSessions = await _db.sessionDao.getCompletedSessions();
      final existingSessionSignatures = <String>{
        for (final s in existingSessions)
          '${s.startedAt}_${s.durationSeconds}_${s.sessionType}',
      };

      for (final raw in doc.sessions) {
        final startedAt = raw['startedAt'] as int;
        final durationSec = raw['durationSeconds'] as int;
        final sessionType = (raw['sessionType'] as String?) ?? 'focus';
        final sig = '${startedAt}_${durationSec}_$sessionType';
        if (mode == BackupRestoreMode.merge &&
            existingSessionSignatures.contains(sig)) {
          continue;
        }
        final oldSubjId = raw['subjectId'] as int?;
        final newSubjId = oldSubjId == null ? null : subjectIdMap[oldSubjId];
        final createdAt = (raw['createdAt'] as int?) ?? startedAt;
        await _db.sessionDao.insertSession(
          StudySessionsCompanion.insert(
            subjectId: drift.Value<int?>(newSubjId),
            sessionType: sessionType,
            startedAt: startedAt,
            endedAt: drift.Value<int?>(raw['endedAt'] as int?),
            durationSeconds: drift.Value<int>(durationSec),
            status: 'completed',
            notes: drift.Value<String?>(raw['notes'] as String?),
            createdAt: createdAt,
          ),
        );
        existingSessionSignatures.add(sig);
      }

      final existingTasks = await _db.plannerDao.getAllTasks();
      final existingTaskSignatures = <String>{
        for (final t in existingTasks)
          '${t.title.trim().toLowerCase()}_${t.scheduledDate}_${t.scheduledTime ?? ''}',
      };

      for (final raw in doc.tasks) {
        final title = (raw['title'] as String).trim();
        final date = raw['scheduledDate'] as String;
        final time = raw['scheduledTime'] as String?;
        final sig = '${title.toLowerCase()}_${date}_${time ?? ''}';
        if (mode == BackupRestoreMode.merge &&
            existingTaskSignatures.contains(sig)) {
          continue;
        }
        final oldSubjId = raw['subjectId'] as int?;
        final newSubjId = oldSubjId == null ? null : subjectIdMap[oldSubjId];
        final nowMs = _nowProvider().toUtc().millisecondsSinceEpoch;
        await _db.plannerDao.insertTask(
          PlannerTasksCompanion.insert(
            subjectId: drift.Value<int?>(newSubjId),
            title: title,
            scheduledDate: date,
            scheduledTime: drift.Value<String?>(time),
            targetMinutes: drift.Value<int>(
              (raw['targetMinutes'] as int?) ?? 30,
            ),
            notes: drift.Value<String?>(raw['notes'] as String?),
            isCompleted: drift.Value<bool>((raw['isCompleted'] as bool?) ?? false),
            createdAt: (raw['createdAt'] as int?) ?? nowMs,
            updatedAt: (raw['updatedAt'] as int?) ?? nowMs,
          ),
        );
        existingTaskSignatures.add(sig);
      }

      final existingPresets = await _db.presetDao.getAllPresets();
      final existingPresetNames = <String>{
        for (final pr in existingPresets) pr.name.trim().toLowerCase(),
      };
      for (final raw in doc.presets) {
        final name = (raw['name'] as String?)?.trim();
        if (name == null || name.isEmpty) {
          continue;
        }
        if (mode == BackupRestoreMode.merge &&
            existingPresetNames.contains(name.toLowerCase())) {
          continue;
        }
        await _db.presetDao.insertPreset(
          TimerPresetsCompanion.insert(
            name: name,
            timerMode: drift.Value<String>((raw['timerMode'] as String?) ?? 'focus'),
            focusMinutes: (raw['focusMinutes'] as int?) ?? 25,
            shortBreakMinutes: (raw['shortBreakMinutes'] as int?) ?? 5,
            longBreakMinutes: (raw['longBreakMinutes'] as int?) ?? 15,
            cyclesBeforeLongBreak: (raw['cyclesBeforeLongBreak'] as int?) ?? 4,
            isDefault: drift.Value<bool>((raw['isDefault'] as bool?) ?? false),
          ),
        );
        existingPresetNames.add(name.toLowerCase());
      }

      for (final raw in doc.dailyGoals) {
        final dateKey = raw['dateKey'] as String?;
        final target = raw['targetMinutes'] as int?;
        if (dateKey != null && target != null && target > 0) {
          final existingGoal = await _db.goalStreakDao.getGoalForDate(dateKey);
          if (existingGoal == null) {
            await _db.goalStreakDao.upsertDailyGoal(
              dateKey: dateKey,
              targetMinutes: target,
              nowMs: (raw['createdAt'] as int?) ??
                  _nowProvider().toUtc().millisecondsSinceEpoch,
            );
          } else if (mode == BackupRestoreMode.replace) {
            await (_db.update(_db.dailyGoals)
                  ..where((t) => t.id.equals(existingGoal.id)))
                .write(
              DailyGoalsCompanion(
                targetMinutes: drift.Value<int>(target),
              ),
            );
          }
        }
      }

      // Rebuild accurate streak records from restored study sessions
      final restoredSessions = await _db.sessionDao.getCompletedSessions();
      final secByDate = <String, int>{};
      for (final s in restoredSessions) {
        final dateKey = DateTimeUtils.toDateKey(
          DateTime.fromMillisecondsSinceEpoch(s.startedAt, isUtc: true),
        );
        secByDate[dateKey] = (secByDate[dateKey] ?? 0) + s.durationSeconds;
      }
      for (final entry in secByDate.entries) {
        final existingRecord =
            await _db.goalStreakDao.getStreakRecordForDate(entry.key);
        final minutes = entry.value ~/ 60;
        final qualified = entry.value > 0;
        if (existingRecord == null) {
          await _db.goalStreakDao.upsertStreakRecord(
            StreakRecordsCompanion.insert(
              dateKey: entry.key,
              studyMinutes: drift.Value<int>(minutes),
              streakQualified: drift.Value<bool>(qualified),
            ),
          );
        } else {
          await (_db.update(_db.streakRecords)
                ..where((t) => t.id.equals(existingRecord.id)))
              .write(
            StreakRecordsCompanion(
              studyMinutes: drift.Value<int>(minutes),
              streakQualified: drift.Value<bool>(qualified),
            ),
          );
        }
      }
    });

    await _achievementRepo.evaluateAndUnlock(
      nowMs: _nowProvider().toUtc().millisecondsSinceEpoch,
    );
  }
}

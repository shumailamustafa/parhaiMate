import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:parhaimate/app/app.dart';
import 'package:parhaimate/app/bindings/initial_binding.dart';
import 'package:parhaimate/app/lifecycle/app_lifecycle_handler.dart';
import 'package:parhaimate/app/routes/app_routes.dart';
import 'package:parhaimate/core/services/timer_engine_service.dart';
import 'package:parhaimate/data/database/app_database.dart';

void main() {
  group('Stage 1 Foundation Verification', () {
    test('pubspec.yaml contains required dependencies and excludes notifications', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      for (final pkg in <String>[
        'get:',
        'drift:',
        'sqlite3_flutter_libs:',
        'sqlite3:',
        'path_provider:',
        'shared_preferences:',
        'fl_chart:',
        'intl:',
        'pdf:',
        'csv:',
        'file_picker:',
        'share_plus:',
        'drift_dev:',
        'build_runner:',
      ]) {
        expect(pubspec, contains(pkg));
      }

      expect(pubspec, isNot(contains('flutter_local_notifications')));
      expect(pubspec, isNot(contains('timezone')));
      expect(pubspec, isNot(contains('google_fonts')));
    });

    test('AndroidManifest and backup rules enforce minimal permissions', () {
      final manifest =
          File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
      expect(manifest, contains('android:label="ParhaiMate"'));
      expect(manifest, contains('android:allowBackup="true"'));
      expect(manifest, contains('@xml/backup_rules'));
      expect(manifest, contains('@xml/data_extraction_rules'));
      expect(manifest, isNot(contains('POST_NOTIFICATIONS')));
      expect(manifest, isNot(contains('ACCESS_FINE_LOCATION')));
      expect(manifest, isNot(contains('READ_CONTACTS')));
      expect(manifest, isNot(contains('CAMERA')));

      expect(
        File('android/app/src/main/res/xml/backup_rules.xml').existsSync(),
        isTrue,
      );
      expect(
        File('android/app/src/main/res/xml/data_extraction_rules.xml')
            .existsSync(),
        isTrue,
      );
    });

    test('MVVM feature-first directory structure exists', () {
      for (final dir in <String>[
        'lib/app/routes',
        'lib/app/bindings',
        'lib/app/lifecycle',
        'lib/core/theme',
        'lib/core/widgets',
        'lib/core/services',
        'lib/data/database/tables',
        'lib/data/database/daos',
        'lib/data/repositories',
        'lib/domain/entities',
        'lib/domain/enums',
        'lib/domain/repositories',
        'lib/features/onboarding/views',
        'lib/features/home/views',
        'lib/features/timer/views',
        'lib/features/subjects/views',
        'lib/features/planner/views',
        'lib/features/calendar/views',
        'lib/features/statistics/views',
        'lib/features/goals/views',
        'lib/features/achievements/views',
        'lib/features/backup/views',
        'lib/features/settings/views',
        'lib/shared/widgets',
      ]) {
        expect(Directory(dir).existsSync(), isTrue, reason: '$dir missing');
      }
    });

    testWidgets('ParhaiMateRootApp renders pure white scaffold', (tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      await tester.pumpWidget(
        ParhaiMateRootApp(
          initialRoute: AppRoutes.components,
          initialBinding: InitialBinding(database: db),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Component Library'), findsOneWidget);
      final scaffoldContext = tester.element(find.byType(Scaffold));
      expect(
        Theme.of(scaffoldContext).scaffoldBackgroundColor,
        const Color(0xFFFFFFFF),
      );

      if (Get.isRegistered<AppLifecycleHandler>()) {
        Get.find<AppLifecycleHandler>().detach();
      }
      if (Get.isRegistered<TimerEngineService>()) {
        Get.find<TimerEngineService>().onClose();
      }
      Get.reset();
      await db.close();
    });
  });
}

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parhaimate/main.dart';

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

    testWidgets('ParhaiMateApp renders pure white scaffold', (tester) async {
      await tester.pumpWidget(const ParhaiMateApp());
      expect(find.text('ParhaiMate'), findsOneWidget);
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, const Color(0xFFFFFFFF));
    });
  });
}

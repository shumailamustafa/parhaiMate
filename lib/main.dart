import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/bindings/initial_binding.dart';
import 'core/constants/app_info.dart';
import 'core/services/local_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppInfo.load();

  // Real alerts are only wired up in the shipped app; tests use a no-op.
  // The saved on/off preference is applied by the splash screen.
  final notifications = LocalNotificationService();
  await notifications.initialize(enabled: true);

  runApp(
    ParhaiMateRootApp(
      initialBinding: InitialBinding(notificationService: notifications),
    ),
  );
}

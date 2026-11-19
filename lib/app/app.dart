import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/theme/app_theme.dart';
import 'bindings/initial_binding.dart';
import 'routes/app_pages.dart';
import 'routes/app_routes.dart';

class ParhaiMateRootApp extends StatelessWidget {
  const ParhaiMateRootApp({
    super.key,
    this.initialRoute = AppRoutes.splash,
    this.initialBinding,
  });

  final String initialRoute;
  final Bindings? initialBinding;

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ParhaiMate',
      theme: AppTheme.light,
      themeMode: ThemeMode.light,
      initialRoute: initialRoute,
      initialBinding: initialBinding ?? InitialBinding(),
      getPages: AppPages.pages,
    );
  }
}

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/widgets.dart';

/// Privacy Policy screen matching Privacy Policy.png and disclosing local + Auto Backup storage.
class PrivacyPolicyView extends StatelessWidget {
  const PrivacyPolicyView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      appBar: PmAppBar(title: 'Privacy Policy'),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.screenPadding,
          16,
          AppSpacing.screenPadding,
          32,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Your study data', style: AppTypography.body16SemiBold),
            SizedBox(height: 8),
            Text(
              'ParhaiMate stores your subjects, study sessions, planned tasks, goals, streaks, and presets locally on your device in an offline SQLite database. If Android Auto Backup is enabled in your Android device settings, your local app database may be backed up by Android OS; temporary export cache files are excluded.',
              style: AppTypography.secondary14,
            ),
            SizedBox(height: 24),
            Text('No account required', style: AppTypography.body16SemiBold),
            SizedBox(height: 8),
            Text(
              'You can use ParhaiMate completely offline without creating an account. It contains no analytics trackers, no advertisements, and does not send your study data to any server.',
              style: AppTypography.secondary14,
            ),
            SizedBox(height: 24),
            Text('Backups you control', style: AppTypography.body16SemiBold),
            SizedBox(height: 8),
            Text(
              'JSON backups and CSV/PDF study reports are generated locally on your device and shared or stored strictly where you choose. Anyone with a backup file can read its contents.',
              style: AppTypography.secondary14,
            ),
          ],
        ),
      ),
    );
  }
}

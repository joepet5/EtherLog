import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/backup_service.dart';
import '../services/auth_service.dart';
import '../services/case_storage.dart';
import '../utils/app_haptics.dart';
import '../l10n/app_localizations.dart';
import '../widgets/animated_gradient_background.dart';

class DataBackupScreen extends StatefulWidget {
  const DataBackupScreen({super.key});

  @override
  State<DataBackupScreen> createState() => _DataBackupScreenState();
}

class _DataBackupScreenState extends State<DataBackupScreen> {
  AppLocalizations get l10n => AppLocalizations.of(context);
  bool _busy = false;
  int _caseCount = 0;

  @override
  void initState() {
    super.initState();
    _loadCount();
  }

  Future<void> _loadCount() async {
    final cases = await CaseStorage.getAllCases();
    if (!mounted) return;
    setState(() => _caseCount = cases.length);
  }

  Future<void> _export() async {
    if (_busy) return;
    await AppHaptics.light();
    if (_caseCount == 0) {
      await AppHaptics.heavy();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.noCasesToBackup)),
      );
      return;
    }

    final authOk = await AuthService.verifyBiometrics('Authenticate to export JSON backup');
    if (!authOk) return;
    setState(() => _busy = true);
    try {
      final fileName = await BackupService.exportToJson();
      if (!mounted) return;
      if (fileName != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.backupSaved(fileName)),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.error}: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _import() async {
    if (_busy) return;
    await AppHaptics.light();
    setState(() => _busy = true);
    try {
      final count = await BackupService.importFromJson();
      if (!mounted) return;
      if (count > 0) {
        await _loadCount();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.restoredNCases(count)),
            backgroundColor: AppTheme.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.noCasesImported)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.error}: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: Text(l10n.backupRestore)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.surfaceLight),
            ),
            child: Text(
              '$_caseCount ${l10n.cases.toLowerCase()}',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 20),
          _actionCard(
            icon: Icons.cloud_upload_outlined,
            title: l10n.backup,
            subtitle: l10n.backupDescription,
            buttonLabel: l10n.exportBackupFile,
            onTap: _busy ? null : _export,
          ),
          const SizedBox(height: 12),
          _actionCard(
            icon: Icons.cloud_download_outlined,
            title: l10n.restore,
            subtitle: l10n.restoreDescription,
            buttonLabel: l10n.restoreFromBackup,
            onTap: _busy ? null : _import,
          ),
          if (_busy) ...[
            const SizedBox(height: 24),
            const Center(child: CircularProgressIndicator()),
          ],
        ],
      ),
    );
  }

  Widget _actionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String buttonLabel,
    required VoidCallback? onTap,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.surfaceLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onTap,
              child: Text(buttonLabel),
            ),
          ),
        ],
      ),
    );
  }
}

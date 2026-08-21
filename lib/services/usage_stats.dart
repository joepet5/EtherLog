import 'package:shared_preferences/shared_preferences.dart';

/// App usage counters for achievements (PDF exports, etc.).
class UsageStats {
  static const _pdfExportKey = 'pdf_export_count';

  static Future<int> pdfExportCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_pdfExportKey) ?? 0;
  }

  static Future<void> incrementPdfExport() async {
    final prefs = await SharedPreferences.getInstance();
    final n = prefs.getInt(_pdfExportKey) ?? 0;
    await prefs.setInt(_pdfExportKey, n + 1);
  }
}
import 'dart:convert';
import 'package:file_selector/file_selector.dart';
import 'package:intl/intl.dart';
import 'case_record.dart';
import 'pdf_preferences.dart';

class CsvService {
  static Future<String?> exportToCsv(List<CaseRecord> cases, {required PdfPreferences prefs}) async {
    if (cases.isEmpty) return null;

    final filtered = cases.where((c) {
      if (!prefs.useDateRange) return true;
      if (prefs.fromDate != null && c.date.isBefore(prefs.fromDate!)) return false;
      if (prefs.toDate != null && c.date.isAfter(prefs.toDate!.add(const Duration(days: 1)))) return false;
      return true;
    }).toList();
    
    if (filtered.isEmpty) return null;

    final StringBuffer sb = StringBuffer();
    // Header
    sb.writeln('Date,Hospital,Hospital Number,Age,Sex,Weight,ASA,Priority,Surgery Type,Procedure,Anaesthetist,Supervisor,Anaesthesia 1,Anaesthesia 2,Anaesthesia 3,Airway,Regional,Monitoring,Complications');

    final df = DateFormat('yyyy-MM-dd HH:mm');

    String _esc(String? val) {
      if (val == null) return '';
      String clean = val.replaceAll('"', '""');
      if (clean.contains(',') || clean.contains('
') || clean.contains('"')) {
        return '""';
      }
      return clean;
    }

    for (final c in filtered) {
      final date = _esc(df.format(c.date));
      final hosp = _esc(c.hospital);
      final hn = prefs.includeHospitalNumbers ? _esc(c.hospitalNumber) : '';
      final age = _esc(c.age.toString());
      final sex = _esc(c.sex);
      final weight = _esc(c.weight.toString());
      final asa = _esc(c.asaGrade);
      final prio = _esc(c.priority);
      final surg = _esc(c.surgeryType);
      final proc = _esc(c.procedure);
      final ana = _esc(c.primaryAnaesthetist);
      final sup = _esc(c.supervisor);
      final type1 = c.anaesthesiaTypes.isNotEmpty ? _esc(c.anaesthesiaTypes[0]) : '';
      final type2 = c.anaesthesiaTypes.length > 1 ? _esc(c.anaesthesiaTypes[1]) : '';
      final type3 = c.anaesthesiaTypes.length > 2 ? _esc(c.anaesthesiaTypes[2]) : '';
      
      final airway = _esc(c.airwayManagement.map((e) => e['name']).join('; '));
      final reg = _esc(c.regionalBlocks.map((e) => e['name']).join('; '));
      final mon = _esc(c.monitoring.join('; '));
      final comp = _esc(c.complications.map((e) => e['title']).join('; '));

      sb.writeln(',,,,,,,,,,,,,,,,,,');
    }

    try {
      final now = DateTime.now();
      final dateString = DateFormat('yyyyMMdd').format(now);
      final fileName = 'etherlog_cases_.csv';

      final location = await getSaveLocation(
        suggestedName: fileName,
        acceptedTypeGroups: [
          const XTypeGroup(label: 'CSV', extensions: ['csv'], uniformTypeIdentifiers: ['public.comma-separated-values-text'])
        ],
      );

      if (location == null) return null; // Cancelled
      
      final bytes = utf8.encode(sb.toString());
      final xFile = XFile.fromData(bytes, mimeType: 'text/csv');
      await xFile.saveTo(location.path);
      return location.path;
    } catch (e) {
      throw Exception('Failed to export CSV: ');
    }
  }
}

import 'dart:convert';
import 'dart:io';
import 'package:file_selector/file_selector.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../models/case_record.dart';
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
    sb.writeln('Date,Hospital,Case Number,Age,Gender,Weight,ASA,Priority,Specialty,Procedure,Role,Supervisor,Technique,Airway,Regional,Invasive Monitoring,Complications,Notes');

    final df = DateFormat('yyyy-MM-dd HH:mm');

    String esc(String? val) {
      if (val == null) return '';
      String clean = val.replaceAll('"', '""');
      if (clean.contains(',') || clean.contains('\n') || clean.contains('"')) {
        return '"$clean"';
      }
      return clean;
    }

    for (final c in filtered) {
      final date = esc(df.format(c.date));
      final hosp = esc(c.hospital);
      final hn = prefs.includeHospitalNumbers ? esc(c.caseNumber) : '';
      final age = esc(c.patientAge?.toString());
      final sex = esc(c.patientGender);
      final weight = esc(c.patientWeight?.toString());
      final asa = esc(c.asaGrade);
      final prio = esc(c.priority);
      final surg = esc(c.specialty);
      final proc = esc(c.procedure);
      final role = esc(c.role);
      final sup = esc(c.supervisor);
      final tech = esc(c.technique);
      
      final airway = esc(c.airwayManagement);
      
      final regList = <String>[];
      for (var map in c.regionalBlocks) {
        if (map.containsKey('name') && map['name'] != null) {
          regList.add(map['name'].toString());
        }
      }
      final reg = esc(regList.join('; '));

      final invList = <String>[];
      for (var map in c.invasiveMonitoring) {
        if (map.containsKey('name') && map['name'] != null) {
          invList.add(map['name'].toString());
        }
      }
      final inv = esc(invList.join('; '));
      
      final comp = esc(c.complications.join('; '));
      final notes = esc(c.notes);

      sb.writeln('$date,$hosp,$hn,$age,$sex,$weight,$asa,$prio,$surg,$proc,$role,$sup,$tech,$airway,$reg,$inv,$comp,$notes');
    }

    try {
      final now = DateTime.now();
      final dateString = DateFormat('yyyyMMdd').format(now);
      final fileName = 'etherlog_cases_$dateString.csv';

      if (Platform.isAndroid || Platform.isIOS) {
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/$fileName');
        await file.writeAsString(sb.toString());
        await Share.shareXFiles([XFile(file.path)], subject: 'EtherLog CSV Export');
        return file.path;
      } else {
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
      }
    } catch (e) {
      throw Exception('Failed to export CSV: $e');
    }
  }
}

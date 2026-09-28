import 'dart:convert';
import 'dart:io';
import 'package:file_selector/file_selector.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../models/case_record.dart';
import 'pdf_preferences.dart';

class CsvService {
  static String generateCsvString(List<CaseRecord> cases,
      {required PdfPreferences prefs}) {
    final filtered = cases.where((c) {
      if (!prefs.useDateRange) return true;
      if (prefs.fromDate != null && c.date.isBefore(prefs.fromDate!)) {
        return false;
      }
      if (prefs.toDate != null &&
          c.date.isAfter(prefs.toDate!.add(const Duration(days: 1)))) {
        return false;
      }
      return true;
    }).toList();

    if (filtered.isEmpty) return '';

    final StringBuffer sb = StringBuffer();
    final includeFu = prefs.includeFollowUp;
    final headerExtra = includeFu
        ? ',Follow-Up Status,Rest Pain,Movement Pain,PONV,Block Assessment,Follow-Up Notes'
        : '';
    sb.writeln(
        'Date,Hospital,Case Number,Age,Gender,Weight,ASA,Priority,Specialty,Procedure,Role,Supervisor,Technique,Airway,Regional,Catheter Placed,PCA,Invasive Monitoring,Complications,Occupation,Detailed Airway Plan,FOB / C-MAC,Monitors,Temp Probe Location,Fluid Warmer / Blanket,IV Plan,Estimated Blood Loss (mL),Estimated Duration,Baseline Hb,Target Hb,Blood Ordered,NPO Hours,Third Space Rate,Analgesia Plan,Intraop Notes,Disposition,Detailed Assessment Attached,Notes$headerExtra');

    final df = DateFormat('yyyy-MM-dd HH:mm');

    String esc(String? val) {
      if (val == null) return '';
      String clean = val.replaceAll('"', '""');
      if (clean.contains(',') || clean.contains('\n') || clean.contains('\r') || clean.contains('"')) {
        return '"$clean"';
      }
      return clean;
    }

    for (final c in filtered) {
      final date = esc(df.format(c.date));
      final hosp = esc(c.hospital);
      final hn = prefs.includeHospitalNumbers ? esc(c.caseNumber) : '';
      final age = esc(c.formattedAge);
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
      final catheter = c.catheterPlaced ? 'Yes' : 'No';
      final pca = c.pca ? 'Yes' : 'No';

      final invList = <String>[];
      for (var map in c.invasiveMonitoring) {
        if (map.containsKey('name') && map['name'] != null) {
          invList.add(map['name'].toString());
        }
      }
      final inv = esc(invList.join('; '));

      final comp = esc(c.complications.join('; '));

      final det = c.detailedAssessment;
      final occVal = det != null
          ? (det['occupation']?.toString() ?? '')
          : (c.patientAge != null && c.patientAge! < 17 && c.ageUnit.toLowerCase() == 'years'
              ? 'Child'
              : '');
      final occupation = esc(occVal);
      final airwayPlan = esc(det?['ettPlan']?.toString());
      final fobCmac = esc(det?['fobCmac']?.toString());
      final monitors = esc(det?['monitors']?.toString());
      final tempProbe = esc((det?['tempProbe'] ?? det?['temperatureProbeLocation'])?.toString());
      final bgWarmer = esc(det?['bgWarmer']?.toString());
      final ivPlan = esc(det?['ivPlan']?.toString());
      final ebl = esc(det?['ebl']?.toString());
      final estDuration = esc(det?['estTime']?.toString() ?? c.surgeryDuration);
      final baselineHb = esc(det?['baselineHb']?.toString());
      final targetHb = esc(det?['targetHb']?.toString());
      final bloodOrdered = esc(det?['bloodOrdered']?.toString());
      final npoHours = esc(det?['npoHours']?.toString());
      final thirdSpaceRate = esc(det?['thirdSpaceRate']?.toString());
      final analgesiaPlan = esc(det?['analgesiaPlan']?.toString());
      final intraopNotes = esc(det?['intraopNotes']?.toString());
      final disposition = esc(det?['disposition']?.toString());
      final hasDetailed = det != null ? 'Yes' : 'No';

      final notes = esc(c.notes);

      String fuRow = '';
      if (includeFu) {
        final fuStatus = esc(c.followUpStatus);
        final restP = esc(c.restPainScore?.toString());
        final moveP = esc(c.movementPainScore?.toString());
        final ponv = esc(c.ponv);
        final blocks = esc(c.blockAssessmentTags.join('; '));
        final fuNotes = esc(c.followUpNotes);
        fuRow = ',$fuStatus,$restP,$moveP,$ponv,$blocks,$fuNotes';
      }

      sb.writeln(
          '$date,$hosp,$hn,$age,$sex,$weight,$asa,$prio,$surg,$proc,$role,$sup,$tech,$airway,$reg,$catheter,$pca,$inv,$comp,$occupation,$airwayPlan,$fobCmac,$monitors,$tempProbe,$bgWarmer,$ivPlan,$ebl,$estDuration,$baselineHb,$targetHb,$bloodOrdered,$npoHours,$thirdSpaceRate,$analgesiaPlan,$intraopNotes,$disposition,$hasDetailed,$notes$fuRow');
    }

    return sb.toString();
  }

  static Future<String?> exportToCsv(List<CaseRecord> cases,
      {required PdfPreferences prefs}) async {
    final csvContent = generateCsvString(cases, prefs: prefs);
    if (csvContent.isEmpty) return null;

    try {
      final now = DateTime.now();
      final dateString = DateFormat('yyyyMMdd').format(now);
      final fileName = 'etherlog_cases_$dateString.csv';

      if (Platform.isAndroid || Platform.isIOS) {
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/$fileName');
        await file.writeAsString(csvContent);
        await Share.shareXFiles([XFile(file.path)],
            subject: 'EtherLog CSV Export');
        return file.path;
      } else {
        final location = await getSaveLocation(
          suggestedName: fileName,
          acceptedTypeGroups: [
            const XTypeGroup(
                label: 'CSV',
                extensions: ['csv'],
                uniformTypeIdentifiers: ['public.comma-separated-values-text'])
          ],
        );

        if (location == null) return null; // Cancelled

        final bytes = utf8.encode(csvContent);
        final xFile = XFile.fromData(bytes, mimeType: 'text/csv');
        await xFile.saveTo(location.path);
        return location.path;
      }
    } catch (e) {
      throw Exception('Failed to export CSV: $e');
    }
  }
}

import 'dart:convert';
import 'dart:io';
import 'package:file_selector/file_selector.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/case_record.dart';
import '../models/doctor_profile.dart';
import '../services/case_storage.dart';
import '../services/profile_storage.dart';
import '../services/alias_storage.dart';
import '../services/firebase_leaderboard_service.dart';
import '../services/group_service.dart';
import '../models/pac_record.dart';
import '../services/pac_storage.dart';

class BackupService {
  static const _lastAutoBackupKey = 'last_auto_backup_date';

  /// Assembles a complete backup payload including cases, leaderboard profile,
  /// doctor profile, and joined private group IDs.
  static Future<Map<String, dynamic>> _buildBackupPayload(
      List<CaseRecord> cases) async {
    final jsonCases = cases.map((c) => c.toJson()).toList();

    // 1. Leaderboard Profile
    final alias = await AliasStorage.getAlias();
    final icon = await AliasStorage.getIcon();
    final optedIn = await AliasStorage.hasOptedIn();
    final userId = await FirebaseLeaderboardService.getUserId();

    // 2. Doctor Profile
    final doctorProfile = await ProfileStorage.getProfile();

    // 3. Joined Groups
    final joinedGroupIds = await GroupService.getJoinedGroupIds();

    // 4. PAC Records
    final pacRecords = await PacStorage.getAllPacRecords();

    return {
      'version': 2,
      'exportedAt': DateTime.now().toIso8601String(),
      'leaderboardProfile': {
        'userId': userId,
        if (alias != null) 'alias': alias,
        if (icon != null) 'icon': icon,
        'optIn': optedIn,
      },
      'doctorProfile': doctorProfile.toJson(),
      if (joinedGroupIds.isNotEmpty) 'joinedGroupIds': joinedGroupIds,
      if (pacRecords.isNotEmpty)
        'pacRecords': pacRecords.map((r) => r.toJson()).toList(),
      'cases': jsonCases,
    };
  }

  static Future<void> performAutoBackupIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final lastDateStr = prefs.getString(_lastAutoBackupKey);

    if (lastDateStr != null) {
      final lastDate = DateTime.tryParse(lastDateStr);
      if (lastDate != null && DateTime.now().difference(lastDate).inDays < 7) {
        return;
      }
    }

    final cases = await CaseStorage.getAllCases();
    if (cases.isEmpty) return;

    final backupPayload = await _buildBackupPayload(cases);
    final jsonString =
        const JsonEncoder.withIndent('  ').convert(backupPayload);

    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .split('.')
        .first;
    final fileName = 'etherlog_auto_backup_$timestamp.json';
    final filePath = '${directory.path}/$fileName';

    final file = File(filePath);
    await file.writeAsString(jsonString);

    await prefs.setString(_lastAutoBackupKey, DateTime.now().toIso8601String());
  }

  static Future<String?> exportToJson() async {
    final cases = await CaseStorage.getAllCases();
    if (cases.isEmpty) return null;

    final backupPayload = await _buildBackupPayload(cases);
    final jsonString =
        const JsonEncoder.withIndent('  ').convert(backupPayload);

    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .split('.')
        .first;
    final fileName = 'etherlog_backup_$timestamp.json';
    final filePath = '${directory.path}/$fileName';

    final file = File(filePath);
    await file.writeAsString(jsonString);

    await Share.shareXFiles(
      [XFile(filePath)],
      text: 'ETHERLOG Backup – $fileName',
    );

    // Track achievement stats
    final prefs = await SharedPreferences.getInstance();
    final currentCount = prefs.getInt('json_backup_count') ?? 0;
    await prefs.setInt('json_backup_count', currentCount + 1);

    return fileName;
  }

  static Future<int> importFromJson() async {
    const typeGroup = XTypeGroup(
      label: 'JSON',
      extensions: ['json'],
      uniformTypeIdentifiers: ['public.json', 'public.text'],
      mimeTypes: ['application/json'],
    );

    final XFile? picked = await openFile(
      acceptedTypeGroups: [typeGroup],
    );

    if (picked == null) return 0;

    final content = await picked.readAsString();
    final decoded = jsonDecode(content);

    // Accept modern enveloped Map or legacy List of cases
    List<dynamic> list;
    if (decoded is List) {
      // Legacy format (v1): raw list of cases
      list = decoded;
    } else if (decoded is Map<String, dynamic>) {
      if (decoded.containsKey('cases') && decoded['cases'] is List) {
        // Modern format (v2+): enveloped object with metadata & profiles
        list = decoded['cases'] as List;

        // 1. Restore Leaderboard Profile if present
        if (decoded['leaderboardProfile'] is Map) {
          final lbProfile =
              Map<String, dynamic>.from(decoded['leaderboardProfile'] as Map);
          final restoredUid = lbProfile['userId']?.toString();
          final restoredAlias = lbProfile['alias']?.toString();
          final restoredIcon = lbProfile['icon']?.toString();
          final restoredOptIn = lbProfile['optIn'] == true;

          if (restoredUid != null && restoredUid.isNotEmpty) {
            await FirebaseLeaderboardService.setUserId(restoredUid);
          }
          if (restoredAlias != null && restoredAlias.isNotEmpty) {
            await AliasStorage.setAlias(
              restoredAlias,
              icon: restoredIcon,
              optIn: restoredOptIn,
            );
          }
        }

        // 2. Restore Doctor Profile if present
        if (decoded['doctorProfile'] is Map) {
          try {
            final docProfile = DoctorProfile.fromJson(
              Map<String, dynamic>.from(decoded['doctorProfile'] as Map),
            );
            await ProfileStorage.saveProfile(docProfile);
          } catch (_) {}
        }

        // 3. Restore Joined Groups if present
        if (decoded['joinedGroupIds'] is List) {
          try {
            final groupIds = (decoded['joinedGroupIds'] as List)
                .map((e) => e.toString())
                .toList();
            final prefs = await SharedPreferences.getInstance();
            await prefs.setStringList('joined_group_ids', groupIds);
          } catch (_) {}
        }

        // 4. Restore PAC Records if present
        if (decoded['pacRecords'] is List) {
          try {
            for (final item in decoded['pacRecords'] as List) {
              if (item is Map) {
                final pac =
                    PacRecord.fromJson(Map<String, dynamic>.from(item));
                await PacStorage.savePacRecord(pac);
              }
            }
          } catch (_) {}
        }
      } else {
        // Single case record
        list = [decoded];
      }
    } else {
      return 0;
    }

    int imported = 0;
    for (final item in list) {
      try {
        if (item is Map<String, dynamic> || item is Map) {
          final mapItem = Map<String, dynamic>.from(item as Map);
          if (mapItem['complications'] is String) {
            final old = mapItem['complications'] as String;
            mapItem['complications'] = old.trim().isEmpty ? [] : [old];
          }
          if (mapItem['invasiveMonitoring'] == null) {
            mapItem['invasiveMonitoring'] = [];
          }
          if (mapItem['complications'] is! List) mapItem['complications'] = [];
          if (mapItem['invasiveMonitoring'] is! List) {
            mapItem['invasiveMonitoring'] = [];
          }

          final record = CaseRecord.fromJson(mapItem);
          await CaseStorage.saveCase(record);
          imported++;
        }
      } catch (_) {
        // Skip bad records
      }
    }

    // Automatically sync leaderboard if user has cases & opted in
    if (imported > 0) {
      try {
        await FirebaseLeaderboardService.syncAllLeagues();
      } catch (_) {}
    }

    return imported;
  }
}
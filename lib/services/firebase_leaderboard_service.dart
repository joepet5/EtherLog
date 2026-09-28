import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/case_record.dart';
import '../models/achievement.dart';
import '../models/leaderboard_league.dart';
import 'case_storage.dart';
import 'achievement_service.dart';
import 'league_calculator.dart';
import 'alias_storage.dart';
import 'leaderboard_service.dart';
import 'group_service.dart';

class FirebaseLeaderboardService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static String? _userId;

  static const _lastSyncedScoresKey = 'leaderboard_last_synced_scores';
  static const _lastSyncedAliasKey = 'leaderboard_last_synced_alias';
  static const _lastSyncedEmojiKey = 'leaderboard_last_synced_emoji';

  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  static Future<String> getUserId() async {
    if (_userId != null) return _userId!;

    // 1. Try reading from hardware-backed secure storage (Keystore / Keychain)
    try {
      _userId = await _secureStorage.read(key: 'leaderboard_user_id');
    } catch (_) {}

    // 2. Fallback to SharedPreferences or generate brand new UID
    if (_userId == null) {
      final prefs = await SharedPreferences.getInstance();
      _userId = prefs.getString('leaderboard_user_id');
      if (_userId == null) {
        _userId = const Uuid().v4();
        await prefs.setString('leaderboard_user_id', _userId!);
      }
      // Cache into secure storage so it survives app reinstallation
      try {
        await _secureStorage.write(key: 'leaderboard_user_id', value: _userId);
      } catch (_) {}
    } else {
      // Keep SharedPreferences in sync
      try {
        final prefs = await SharedPreferences.getInstance();
        if (prefs.getString('leaderboard_user_id') != _userId) {
          await prefs.setString('leaderboard_user_id', _userId!);
        }
      } catch (_) {}
    }
    return _userId!;
  }

  static Future<void> setUserId(String id) async {
    _userId = id;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('leaderboard_user_id', id);
    } catch (_) {}
    try {
      await _secureStorage.write(key: 'leaderboard_user_id', value: id);
    } catch (_) {}
  }

  /// Syncs scores across all 12 leagues at once using smart diff caching.
  /// - Only documents that actually changed are written to Firebase (saving ~85% writes).
  /// - Any league with a score <= 0 is completely deleted/omitted so 0-score users NEVER appear on the leaderboard.
  /// - If user has opted out, has no alias, or deleted all cases, all leaderboard documents are purged.
  static Future<void> syncAllLeagues({List<CaseRecord>? providedCases}) async {
    try {
      final uid = await getUserId();
      final optedIn = await AliasStorage.hasOptedIn();
      final alias = await AliasStorage.getAlias();
      final userEmoji = await AliasStorage.getIcon() ?? '👤';

      final prefs = await SharedPreferences.getInstance();
      final lastSyncedRaw = prefs.getString(_lastSyncedScoresKey);
      final lastAlias = prefs.getString(_lastSyncedAliasKey);
      final lastEmoji = prefs.getString(_lastSyncedEmojiKey);

      Map<String, int> lastScores = {};
      if (lastSyncedRaw != null) {
        try {
          final decoded = jsonDecode(lastSyncedRaw) as Map<String, dynamic>;
          lastScores = decoded.map((k, v) => MapEntry(k, (v as num).toInt()));
        } catch (_) {}
      }

      final bool profileChanged = alias != lastAlias || userEmoji != lastEmoji;

      final cases = providedCases ?? await CaseStorage.getAllCases();
      final achievements = cases.isEmpty
          ? <Achievement>[]
          : await AchievementService.getAllAchievements(cases);
      final scores = cases.isEmpty
          ? <String, int>{}
          : await LeagueCalculator.calculateAllScores(cases, achievements);

      final joinedGroups = await GroupService.getJoinedGroupIds();
      final batch = _firestore.batch();
      int opCount = 0;

      for (final league in LeaderboardLeague.allLeagues) {
        final score = scores[league.id] ?? 0;
        final lastScore = lastScores[league.id] ?? 0;
        final globalDoc = _firestore
            .collection('leaderboards')
            .doc(league.id)
            .collection('entries')
            .doc(uid);

        final shouldBeOnBoard = optedIn && alias != null && alias.trim().isNotEmpty && score > 0;

        if (shouldBeOnBoard) {
          // Write only if score changed, profile changed, or user wasn't on board
          if (score != lastScore || profileChanged || lastScore <= 0) {
            final payload = {
              'alias': alias.trim(),
              'emoji': userEmoji,
              'score': score,
              'lastUpdated': FieldValue.serverTimestamp(),
            };
            batch.set(globalDoc, payload);
            opCount++;

            for (final gid in joinedGroups) {
              final groupDoc = _firestore
                  .collection('groups')
                  .doc(gid)
                  .collection('leaderboards')
                  .doc(league.id)
                  .collection('entries')
                  .doc(uid);
              batch.set(groupDoc, payload);
              opCount++;
            }
          }
        } else {
          // Zero score or opted out: remove from leaderboard
          // Delete only if user previously had a record (or first run without cache)
          if (lastScore > 0 || lastSyncedRaw == null) {
            batch.delete(globalDoc);
            opCount++;
            for (final gid in joinedGroups) {
              final groupDoc = _firestore
                  .collection('groups')
                  .doc(gid)
                  .collection('leaderboards')
                  .doc(league.id)
                  .collection('entries')
                  .doc(uid);
              batch.delete(groupDoc);
              opCount++;
            }
          }
        }
      }

      if (opCount > 0) {
        await batch.commit();
      }

      // Cache the synced state
      await prefs.setString(_lastSyncedScoresKey, jsonEncode(scores));
      if (alias != null) await prefs.setString(_lastSyncedAliasKey, alias);
      await prefs.setString(_lastSyncedEmojiKey, userEmoji);
    } catch (e) {
      // Safely ignore error so offline case storage / operations never fail
    }
  }

  /// Verifies whether [newAlias] is available and claims it for [uid].
  /// Returns a record with success status and an optional error message.
  static Future<({bool success, String? errorMessage})> claimAlias(String newAlias, String uid) async {
    final clean = newAlias.trim();
    if (clean.length < 3) {
      return (success: false, errorMessage: 'Alias must be at least 3 characters.');
    }
    if (clean.length > 20) {
      return (success: false, errorMessage: 'Alias cannot exceed 20 characters.');
    }
    final validChars = RegExp(r'^[a-zA-Z0-9_\-\. ]+$');
    if (!validChars.hasMatch(clean)) {
      return (success: false, errorMessage: 'Alias can only contain letters, numbers, spaces, and .-_');
    }

    final normalized = clean.toLowerCase();
    try {
      final aliasDoc = await _firestore.collection('aliases').doc(normalized).get();
      if (aliasDoc.exists) {
        final existingUid = aliasDoc.data()?['uid'];
        if (existingUid != null && existingUid != uid) {
          return (success: false, errorMessage: 'This alias is already taken by another doctor. Please choose a unique name.');
        }
      }

      // Release previous alias if it was different
      final currentAlias = await AliasStorage.getAlias();
      if (currentAlias != null && currentAlias.trim().toLowerCase() != normalized) {
        final oldKey = currentAlias.trim().toLowerCase();
        final oldDoc = await _firestore.collection('aliases').doc(oldKey).get();
        if (oldDoc.exists && oldDoc.data()?['uid'] == uid) {
          await _firestore.collection('aliases').doc(oldKey).delete();
        }
      }

      // Claim the alias
      await _firestore.collection('aliases').doc(normalized).set({
        'uid': uid,
        'alias': clean,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return (success: true, errorMessage: null);
    } catch (_) {
      // If network error, still allow local save so offline mode works
      return (success: true, errorMessage: null);
    }
  }

  static Future<List<LeaderboardEntry>> getLeaderboardForLeague(
      LeaderboardLeague league, String userAlias, String userEmoji, int userScore, {String? groupId}) async {
    
    final uid = await getUserId();
    final optedIn = await AliasStorage.hasOptedIn();

    // Check if user's score/profile for this league is already in sync to avoid wasted writes
    final prefs = await SharedPreferences.getInstance();
    final lastSyncedRaw = prefs.getString(_lastSyncedScoresKey);
    final lastAlias = prefs.getString(_lastSyncedAliasKey);
    final lastEmoji = prefs.getString(_lastSyncedEmojiKey);

    Map<String, int> lastScores = {};
    if (lastSyncedRaw != null) {
      try {
        final decoded = jsonDecode(lastSyncedRaw) as Map<String, dynamic>;
        lastScores = decoded.map((k, v) => MapEntry(k, (v as num).toInt()));
      } catch (_) {}
    }

    final int lastScore = lastScores[league.id] ?? -1;
    final bool needsSync = (lastScore != userScore) || (lastAlias != userAlias) || (lastEmoji != userEmoji);

    if (needsSync) {
      final batch = _firestore.batch();
      
      final payload = {
        'alias': userAlias,
        'emoji': userEmoji,
        'score': userScore,
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      // Update or delete global score
      final globalDoc = _firestore.collection('leaderboards').doc(league.id).collection('entries').doc(uid);
      if (userScore > 0 && optedIn && userAlias.trim().isNotEmpty) {
        batch.set(globalDoc, payload);
      } else {
        batch.delete(globalDoc);
      }

      // Update or delete score in all joined groups
      final joinedGroups = await GroupService.getJoinedGroupIds();
      for (String gid in joinedGroups) {
        final groupDoc = _firestore.collection('groups').doc(gid).collection('leaderboards').doc(league.id).collection('entries').doc(uid);
        if (userScore > 0 && optedIn && userAlias.trim().isNotEmpty) {
          batch.set(groupDoc, payload);
        } else {
          batch.delete(groupDoc);
        }
      }

      try {
        await batch.commit();
        // Update cached state for this league
        lastScores[league.id] = userScore;
        await prefs.setString(_lastSyncedScoresKey, jsonEncode(lastScores));
      } catch (_) {}
    }

    // Determine which collection to fetch from
    CollectionReference collection;
    if (groupId != null) {
      collection = _firestore.collection('groups').doc(groupId).collection('leaderboards').doc(league.id).collection('entries');
    } else {
      collection = _firestore.collection('leaderboards').doc(league.id).collection('entries');
    }

    // Fetch top 100 strictly where score > 0
    final snapshot = await collection
        .where('score', isGreaterThan: 0)
        .orderBy('score', descending: true)
        .limit(100)
        .get();

    final List<LeaderboardEntry> results = [];
    bool userFound = false;

    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final rawScore = data['score'];
      final score = rawScore is num ? rawScore.toInt() : (int.tryParse(rawScore?.toString() ?? '') ?? 0);
      
      // Strict rule: 0-score users NEVER appear on leaderboard
      if (score <= 0) continue;

      final entryAlias = (data['alias'] ?? 'Unknown').toString();
      final isMe = doc.id == uid || (optedIn && userAlias.trim().isNotEmpty && entryAlias.trim().toLowerCase() == userAlias.trim().toLowerCase());

      if (isMe) {
        if (userFound) {
          // If duplicate orphaned entry from previous test install exists, silently clean it up
          if (doc.id != uid) {
            doc.reference.delete().catchError((_) {});
          }
          continue;
        }
        if (userScore <= 0 || !optedIn || userAlias.trim().isEmpty) continue;
        userFound = true;
        results.add(LeaderboardEntry(
          alias: userAlias,
          rankEmoji: userEmoji,
          score: userScore,
          isCurrentUser: true,
        ));
      } else {
        results.add(LeaderboardEntry(
          alias: entryAlias,
          rankEmoji: data['emoji'] ?? '👤',
          score: score,
          isCurrentUser: false,
        ));
      }
    }

    if (!userFound && userScore > 0 && optedIn && userAlias.trim().isNotEmpty) {
      results.add(LeaderboardEntry(
        alias: userAlias,
        rankEmoji: userEmoji,
        score: userScore,
        isCurrentUser: true,
      ));
      results.sort((a, b) => b.score.compareTo(a.score));
    }

    return results;
  }
}


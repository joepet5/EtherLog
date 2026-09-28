import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_leaderboard_service.dart';
import '../models/leaderboard_league.dart';

class Group {
  final String id;
  final String name;

  Group({required this.id, required this.name});

  factory Group.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Group(
      id: doc.id,
      name: data['name'] ?? 'Unknown Group',
    );
  }
}

class GroupService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _prefsKey = 'joined_group_ids';

  // Get locally saved group IDs
  static Future<List<String>> getJoinedGroupIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_prefsKey) ?? [];
  }

  // Save group IDs locally
  static Future<void> _saveJoinedGroupIds(List<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, ids);
  }

  // Fetch full group details for the joined IDs
  static Future<List<Group>> getJoinedGroups() async {
    final ids = await getJoinedGroupIds();
    if (ids.isEmpty) return [];

    final List<Group> groups = [];
    // Firestore whereIn has a limit of 10, so we'll fetch individually if they have a few
    for (String id in ids) {
      try {
        final doc = await _firestore.collection('groups').doc(id).get();
        if (doc.exists) {
          groups.add(Group.fromFirestore(doc));
        } else {
          // Clean up local list if group was deleted
          await leaveGroup(id);
        }
      } catch (_) {}
    }
    return groups;
  }

  // Create a new group
  static Future<Group> createGroup(String name) async {
    String code = _generateRandomCode(6);
    
    // Ensure code is unique
    bool isUnique = false;
    while (!isUnique) {
      final doc = await _firestore.collection('groups').doc(code).get();
      if (!doc.exists) {
        isUnique = true;
      } else {
        code = _generateRandomCode(6);
      }
    }

    final uid = await FirebaseLeaderboardService.getUserId();
    // Save to Firestore
    await _firestore.collection('groups').doc(code).set({
      'name': name.trim(),
      'creatorUid': uid,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Join it automatically
    await _joinLocally(code);
    unawaited(FirebaseLeaderboardService.syncAllLeagues());

    return Group(id: code, name: name);
  }

  // Join an existing group by code
  static Future<Group> joinGroup(String code) async {
    final normalizedCode = code.trim().toUpperCase();
    final doc = await _firestore.collection('groups').doc(normalizedCode).get();
    
    if (!doc.exists) {
      throw Exception('Group not found. Please check the code.');
    }

    final group = Group.fromFirestore(doc);
    await _joinLocally(normalizedCode);
    unawaited(FirebaseLeaderboardService.syncAllLeagues());
    return group;
  }

  // Leave a group
  static Future<void> leaveGroup(String code) async {
    final ids = await getJoinedGroupIds();
    ids.remove(code);
    await _saveJoinedGroupIds(ids);

    // Clean up user's documents from this group's leaderboards across all 12 leagues
    try {
      final uid = await FirebaseLeaderboardService.getUserId();
      final batch = _firestore.batch();
      for (final league in LeaderboardLeague.allLeagues) {
        final doc = _firestore
            .collection('groups')
            .doc(code)
            .collection('leaderboards')
            .doc(league.id)
            .collection('entries')
            .doc(uid);
        batch.delete(doc);
      }
      await batch.commit();
    } catch (_) {}
  }

  static Future<void> _joinLocally(String code) async {
    final ids = await getJoinedGroupIds();
    if (!ids.contains(code)) {
      ids.add(code);
      await _saveJoinedGroupIds(ids);
    }
  }

  static String _generateRandomCode(int length) {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // No I, O, 0, 1
    Random rnd = Random();
    return String.fromCharCodes(Iterable.generate(
      length,
      (_) => chars.codeUnitAt(rnd.nextInt(chars.length)),
    ));
  }
}

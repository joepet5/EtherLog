import 'package:flutter/material.dart';
import '../models/case_record.dart';
import '../theme/app_theme.dart';

class FatigueStats {
  final int activeMinutes24h;
  final bool showNudge;
  final double progress;
  final Color statusColor;

  FatigueStats({
    required this.activeMinutes24h,
    required this.showNudge,
    required this.progress,
    required this.statusColor,
  });
}

class FatigueService {
  static const int fatigueThresholdMinutes = 10 * 60; // 10 hours
  static const int maxExpectedMinutes = 14 * 60; // 14 hours max

  static DateTime _getCaseTime(CaseRecord c, bool isStart) {
    final timeStr = isStart ? c.anaesthesiaStartTime : c.anaesthesiaEndTime;
    if (timeStr == null || timeStr.isEmpty) return c.date;
    final parts = timeStr.split(':');
    if (parts.length != 2) return c.date;
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    var dt = DateTime(c.date.year, c.date.month, c.date.day, h, m);
    
    // If getting end time and it crossed midnight
    if (!isStart && c.anaesthesiaStartTime != null && c.anaesthesiaStartTime!.isNotEmpty) {
      final sParts = c.anaesthesiaStartTime!.split(':');
      if (sParts.length == 2) {
        final sH = int.tryParse(sParts[0]) ?? 0;
        final sM = int.tryParse(sParts[1]) ?? 0;
        var startDt = DateTime(c.date.year, c.date.month, c.date.day, sH, sM);
        if (dt.isBefore(startDt)) {
          dt = dt.add(const Duration(days: 1));
        }
      }
    }
    return dt;
  }

  static FatigueStats getFatigueStats(List<CaseRecord> cases) {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(hours: 24));

    // Only look at cases in the last 24 hours
    final recentCases = cases.where((c) => c.date.isAfter(yesterday) || c.date.isAtSameMomentAs(yesterday)).toList();
    
    // Sort chronologically by start time
    recentCases.sort((a, b) => _getCaseTime(a, true).compareTo(_getCaseTime(b, true)));

    int activeMinutes = 0;
    DateTime? lastEndTime;

    for (final c in recentCases) {
      final startTime = _getCaseTime(c, true);
      final endTime = _getCaseTime(c, false);
      
      if (lastEndTime != null) {
        final gapHours = startTime.difference(lastEndTime).inHours;
        if (gapHours >= 12) {
          activeMinutes = 0; // User rested for 12+ hours! Reset before adding this case.
        }
      }
      
      activeMinutes += parseDurationMinutes(c.anaesthesiaDuration);
      lastEndTime = endTime;
    }

    // Check if there's a 12+ hour gap between the last case and NOW
    if (lastEndTime != null) {
      final gapHoursNow = now.difference(lastEndTime).inHours;
      if (gapHoursNow >= 12) {
         activeMinutes = 0; // User has rested 12+ hours since their last case
      }
    }

    bool showNudge = activeMinutes >= fatigueThresholdMinutes;
    double progress = (activeMinutes / maxExpectedMinutes).clamp(0.0, 1.0);

    Color statusColor;
    if (activeMinutes < (fatigueThresholdMinutes * 0.75)) {
      statusColor = AppTheme.success; // Greenish
    } else if (activeMinutes < fatigueThresholdMinutes) {
      statusColor = AppTheme.warning; // Yellowish
    } else {
      statusColor = AppTheme.danger; // Redish
    }

    return FatigueStats(
      activeMinutes24h: activeMinutes,
      showNudge: showNudge,
      progress: progress,
      statusColor: statusColor,
    );
  }

  static int parseDurationMinutes(String? duration) {
    if (duration == null || duration.isEmpty) return 0;
    int h = 0;
    int m = 0;
    final hMatch = RegExp(r'(\d+)h').firstMatch(duration);
    final mMatch = RegExp(r'(\d+)m').firstMatch(duration);
    if (hMatch != null) h = int.tryParse(hMatch.group(1) ?? '0') ?? 0;
    if (mMatch != null) m = int.tryParse(mMatch.group(1) ?? '0') ?? 0;
    return (h * 60) + m;
  }

  static String formatDuration(int totalMinutes) {
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;
    if (h > 0 && m > 0) return '${h}h ${m}m';
    if (h > 0) return '${h}h';
    return '${m}m';
  }
}

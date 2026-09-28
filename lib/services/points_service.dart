import '../models/case_record.dart';
import 'profile_storage.dart';

class PointsService {
  static int? _parseMinutes(String? s) {
    if (s == null || s.trim().isEmpty) return null;
    final text = s.toLowerCase().trim();
    final hourMatch = RegExp(r'(\d+)\s*h').firstMatch(text);
    final minMatch = RegExp(r'(\d+)\s*m').firstMatch(text);
    final h = hourMatch != null ? int.tryParse(hourMatch.group(1)!) ?? 0 : 0;
    final m = minMatch != null ? int.tryParse(minMatch.group(1)!) ?? 0 : 0;
    if (h == 0 && m == 0) return null;
    return h * 60 + m;
  }

  static double? _ageInYears(CaseRecord c) {
    if (c.patientAge == null) return null;
    final a = c.patientAge!;
    switch (c.ageUnit) {
      case 'months':
        return a / 12.0;
      case 'days':
        return a / 365.25;
      default:
        return a;
    }
  }

  static int forCase(CaseRecord c) {
    int pts = 10;

    switch (c.asaGrade) {
      case 'ASA II':
        pts += 2;
        break;
      case 'ASA III':
        pts += 3;
        break;
      case 'ASA IV':
        pts += 5;
        break;
      case 'ASA V':
        pts += 10;
        break;
    }

    if (c.priority == 'Emergency') pts += 2;
    if (c.difficultAirway) pts += 2;

    for (final e in c.regionalBlocks) {
      final name = e['name']?.toString() ?? '';
      if (name.isEmpty || name == 'None / Not performed') continue;
      final role = e['role']?.toString() ?? '';
      if (role == 'Performed' || role == 'Supervised') {
        pts += 5;
      } else if (role == 'Assisted') {
        pts += 2;
      }
    }

    if (c.catheterPlaced) pts += 5;

    for (final e in c.invasiveMonitoring) {
      final role = e['role']?.toString() ?? '';
      if (role == 'Performed' ||
          role == 'Used independently' ||
          role == 'Supervised') {
        pts += 2;
      } else if (role == 'Assisted' || role == 'Used with assistance') {
        pts += 1;
      }
    }

    final method = c.methodOfIntubation ?? '';
    final methodRole = c.methodOfIntubationRole ?? '';
    final bool isAirwayInSitu = methodRole.toLowerCase().contains('situ') ||
        method.toLowerCase().contains('situ');

    if (c.typeOfIntubation == 'Nasal intubation' && !isAirwayInSitu) pts += 2;

    if (method == 'Awake fiberoptic intubation') {
      if (methodRole == 'Performed' || methodRole == 'Supervised') {
        pts += 10;
      } else if (methodRole == 'Assisted') {
        pts += 3;
      }
    } else if (method == 'Asleep fiberoptic intubation') {
      if (methodRole == 'Performed' || methodRole == 'Supervised') {
        pts += 7;
      } else if (methodRole == 'Assisted') {
        pts += 2;
      }
    }

    if (c.airwayManagement == 'Laryngeal Mask Airway (LMA)') {
      final lr = c.lmaRole ?? '';
      if (lr == 'Performed' || lr == 'Supervised') {
        pts += 2;
      } else if (lr == 'Assisted') {
        pts += 1;
      }
    }

    final cl = c.cormackLehane ?? '';
    if ((cl == 'Grade 3' || cl == 'Grade 4') && !isAirwayInSitu) pts += 1;

    if (c.complications.contains('None/uneventful')) {
      pts += 2;
    } else {
      for (final comp in c.complications) {
        if (comp == 'Death on table') {
          pts -= 5;
        } else if (comp == 'Cardiac arrest') {
          pts -= 3;
        } else {
          pts -= 1;
        }
      }
    }

    final surgeryMins = _parseMinutes(c.surgeryDuration);
    if (surgeryMins != null && surgeryMins > 60) {
      pts += ((surgeryMins - 60) ~/ 60) * 2;
    }

    final anaesthesiaMins = _parseMinutes(c.anaesthesiaDuration);
    if (anaesthesiaMins != null && surgeryMins != null) {
      final excess = anaesthesiaMins - surgeryMins;
      if (excess > 30) {
        pts -= (excess ~/ 30) * 1;
      }
    }

    final y = _ageInYears(c);
    if (y != null) {
      final neonateMax = 28 / 365.25;
      if (y < neonateMax) {
        pts += 5;
      } else if (y < 1.0) {
        pts += 3;
      } else if (y < 3.0) {
        pts += 2;
      } else if (y < 12.0) {
        pts += 1;
      } else if (y >= 65.0) {
        pts += 1 + ((y - 65).floor() ~/ 10);
      }
    }

    final bmi = c.bmi;
    if (bmi != null) {
      if (bmi >= 30 && bmi < 35) {
        pts += 1;
      } else if (bmi >= 35 && bmi < 40) {
        pts += 3;
      } else if (bmi >= 40) {
        pts += 5;
      }
    }

    return pts;
  }

  static int totalFor(List<CaseRecord> cases) {
    var sum = 0;
    for (final c in cases) {
      sum += forCase(c);
    }
    return sum;
  }

  static Future<int> totalWithProfileBonus(List<CaseRecord> cases) async {
    final bonus = await ProfileStorage.getProfileBonusPoints();
    return totalFor(cases) + bonus;
  }

  /// Category totals for the breakdown screen.
  static Map<String, int> categoryBreakdown(List<CaseRecord> cases) {
    final map = <String, int>{
      'Base (per case)': 0,
      'ASA grade': 0,
      'Emergency': 0,
      'Difficult airway': 0,
      'Regional blocks': 0,
      'Catheter placed': 0,
      'Invasive lines / monitoring': 0,
      'Nasal intubation': 0,
      'Fiberoptic intubation': 0,
      'LMA role': 0,
      'Cormack-Lehane 3/4': 0,
      'Complications': 0,
      'Surgery duration bonus': 0,
      'Turnover/Prolonged wakeup penalty': 0,
      'Age band': 0,
      'BMI class': 0,
    };

    for (final c in cases) {
      map['Base (per case)'] = map['Base (per case)']! + 10;

      switch (c.asaGrade) {
        case 'ASA II':
          map['ASA grade'] = map['ASA grade']! + 2;
          break;
        case 'ASA III':
          map['ASA grade'] = map['ASA grade']! + 3;
          break;
        case 'ASA IV':
          map['ASA grade'] = map['ASA grade']! + 5;
          break;
        case 'ASA V':
          map['ASA grade'] = map['ASA grade']! + 10;
          break;
      }

      if (c.priority == 'Emergency') {
        map['Emergency'] = map['Emergency']! + 2;
      }
      if (c.difficultAirway) {
        map['Difficult airway'] = map['Difficult airway']! + 2;
      }

      for (final e in c.regionalBlocks) {
        final name = e['name']?.toString() ?? '';
        if (name.isEmpty || name == 'None / Not performed') continue;
        final role = e['role']?.toString() ?? '';
        if (role == 'Performed' || role == 'Supervised') {
          map['Regional blocks'] = map['Regional blocks']! + 5;
        } else if (role == 'Assisted') {
          map['Regional blocks'] = map['Regional blocks']! + 2;
        }
      }

      if (c.catheterPlaced) {
        map['Catheter placed'] = map['Catheter placed']! + 5;
      }

      for (final e in c.invasiveMonitoring) {
        final role = e['role']?.toString() ?? '';
        if (role == 'Performed' ||
            role == 'Used independently' ||
            role == 'Supervised') {
          map['Invasive lines / monitoring'] =
              map['Invasive lines / monitoring']! + 2;
        } else if (role == 'Assisted' || role == 'Used with assistance') {
          map['Invasive lines / monitoring'] =
              map['Invasive lines / monitoring']! + 1;
        }
      }

      final method = c.methodOfIntubation ?? '';
      final methodRole = c.methodOfIntubationRole ?? '';
      final bool isAirwayInSitu = methodRole.toLowerCase().contains('situ') ||
          method.toLowerCase().contains('situ');

      if (c.typeOfIntubation == 'Nasal intubation' && !isAirwayInSitu) {
        map['Nasal intubation'] = map['Nasal intubation']! + 2;
      }

      if (method == 'Awake fiberoptic intubation') {
        if (methodRole == 'Performed' || methodRole == 'Supervised') {
          map['Fiberoptic intubation'] = map['Fiberoptic intubation']! + 10;
        } else if (methodRole == 'Assisted') {
          map['Fiberoptic intubation'] = map['Fiberoptic intubation']! + 3;
        }
      } else if (method == 'Asleep fiberoptic intubation') {
        if (methodRole == 'Performed' || methodRole == 'Supervised') {
          map['Fiberoptic intubation'] = map['Fiberoptic intubation']! + 7;
        } else if (methodRole == 'Assisted') {
          map['Fiberoptic intubation'] = map['Fiberoptic intubation']! + 2;
        }
      }

      if (c.airwayManagement == 'Laryngeal Mask Airway (LMA)') {
        final lr = c.lmaRole ?? '';
        if (lr == 'Performed' || lr == 'Supervised') {
          map['LMA role'] = map['LMA role']! + 2;
        } else if (lr == 'Assisted') {
          map['LMA role'] = map['LMA role']! + 1;
        }
      }

      final cl = c.cormackLehane ?? '';
      if ((cl == 'Grade 3' || cl == 'Grade 4') && !isAirwayInSitu) {
        map['Cormack-Lehane 3/4'] = map['Cormack-Lehane 3/4']! + 1;
      }

      if (c.complications.contains('None/uneventful')) {
        map['Complications'] = map['Complications']! + 2;
      } else {
        for (final comp in c.complications) {
          if (comp == 'Death on table') {
            map['Complications'] = map['Complications']! - 5;
          } else if (comp == 'Cardiac arrest') {
            map['Complications'] = map['Complications']! - 3;
          } else {
            map['Complications'] = map['Complications']! - 1;
          }
        }
      }

      final surgeryMins = _parseMinutes(c.surgeryDuration);
      if (surgeryMins != null && surgeryMins > 60) {
        map['Surgery duration bonus'] =
            map['Surgery duration bonus']! + ((surgeryMins - 60) ~/ 60) * 2;
      }

      final anaesthesiaMins = _parseMinutes(c.anaesthesiaDuration);
      if (anaesthesiaMins != null && surgeryMins != null) {
        final excess = anaesthesiaMins - surgeryMins;
        if (excess > 30) {
          map['Turnover/Prolonged wakeup penalty'] =
              map['Turnover/Prolonged wakeup penalty']! - (excess ~/ 30) * 1;
        }
      }

      final y = _ageInYears(c);
      if (y != null) {
        final neonateMax = 28 / 365.25;
        if (y < neonateMax) {
          map['Age band'] = map['Age band']! + 5;
        } else if (y < 1.0) {
          map['Age band'] = map['Age band']! + 3;
        } else if (y < 3.0) {
          map['Age band'] = map['Age band']! + 2;
        } else if (y < 12.0) {
          map['Age band'] = map['Age band']! + 1;
        } else if (y >= 65.0) {
          map['Age band'] = map['Age band']! + 1 + ((y - 65).floor() ~/ 10);
        }
      }

      final bmi = c.bmi;
      if (bmi != null) {
        if (bmi >= 30 && bmi < 35) {
          map['BMI class'] = map['BMI class']! + 1;
        } else if (bmi >= 35 && bmi < 40) {
          map['BMI class'] = map['BMI class']! + 3;
        } else if (bmi >= 40) {
          map['BMI class'] = map['BMI class']! + 5;
        }
      }
    }

    return map;
  }

  static List<CasePointEntry> caseBreakdown(CaseRecord c) {
    final list = <CasePointEntry>[];

    // Base
    list.add(const CasePointEntry(
      title: 'Base Case Points',
      subtitle: 'Standard case entry',
      points: 10,
    ));

    // ASA
    switch (c.asaGrade) {
      case 'ASA II':
        list.add(const CasePointEntry(title: 'ASA Grade (ASA II)', points: 2));
        break;
      case 'ASA III':
        list.add(const CasePointEntry(title: 'ASA Grade (ASA III)', points: 3));
        break;
      case 'ASA IV':
        list.add(const CasePointEntry(title: 'ASA Grade (ASA IV)', points: 5));
        break;
      case 'ASA V':
        list.add(const CasePointEntry(title: 'ASA Grade (ASA V)', points: 10));
        break;
    }

    // Emergency
    if (c.priority == 'Emergency') {
      list.add(const CasePointEntry(title: 'Emergency Priority', points: 2));
    }

    // Difficult airway
    if (c.difficultAirway) {
      list.add(
          const CasePointEntry(title: 'Difficult Airway Managed', points: 2));
    }

    // Regional
    for (final e in c.regionalBlocks) {
      final name = e['name']?.toString() ?? '';
      if (name.isEmpty || name == 'None / Not performed') continue;
      final role = e['role']?.toString() ?? '';
      if (role == 'Performed' || role == 'Supervised') {
        list.add(CasePointEntry(
            title: 'Regional Block ($role)', subtitle: name, points: 5));
      } else if (role == 'Assisted') {
        list.add(CasePointEntry(
            title: 'Regional Block (Assisted)', subtitle: name, points: 2));
      }
    }

    // Catheter
    if (c.catheterPlaced) {
      list.add(const CasePointEntry(
          title: 'Catheter Placed',
          subtitle: 'Continuous infusion / post-op boluses',
          points: 5));
    }

    // Invasive
    for (final e in c.invasiveMonitoring) {
      final name = e['name']?.toString() ?? '';
      final role = e['role']?.toString() ?? '';
      if (role == 'Performed' ||
          role == 'Used independently' ||
          role == 'Supervised') {
        list.add(CasePointEntry(
            title: 'Invasive Line / Monitor',
            subtitle: '$name ($role)',
            points: 2));
      } else if (role == 'Assisted' || role == 'Used with assistance') {
        list.add(CasePointEntry(
            title: 'Invasive Line / Monitor',
            subtitle: '$name ($role)',
            points: 1));
      }
    }

    // Intubation
    if (c.typeOfIntubation == 'Nasal intubation') {
      list.add(const CasePointEntry(title: 'Nasal Intubation', points: 2));
    }

    final method = c.methodOfIntubation ?? '';
    final methodRole = c.methodOfIntubationRole ?? '';
    if (method == 'Awake fiberoptic intubation') {
      if (methodRole == 'Performed' || methodRole == 'Supervised') {
        list.add(CasePointEntry(
            title: 'Awake Fiberoptic Intubation ($methodRole)', points: 10));
      } else if (methodRole == 'Assisted') {
        list.add(const CasePointEntry(
            title: 'Awake Fiberoptic Intubation (Assisted)', points: 3));
      }
    } else if (method == 'Asleep fiberoptic intubation') {
      if (methodRole == 'Performed' || methodRole == 'Supervised') {
        list.add(CasePointEntry(
            title: 'Asleep Fiberoptic Intubation ($methodRole)', points: 7));
      } else if (methodRole == 'Assisted') {
        list.add(const CasePointEntry(
            title: 'Asleep Fiberoptic Intubation (Assisted)', points: 2));
      }
    }

    // LMA
    if (c.airwayManagement == 'Laryngeal Mask Airway (LMA)') {
      final lr = c.lmaRole ?? '';
      if (lr == 'Performed' || lr == 'Supervised') {
        list.add(CasePointEntry(title: 'LMA Insertion ($lr)', points: 2));
      } else if (lr == 'Assisted') {
        list.add(
            const CasePointEntry(title: 'LMA Insertion (Assisted)', points: 1));
      }
    }

    // Cormack
    final cl = c.cormackLehane ?? '';
    if (cl == 'Grade 3' || cl == 'Grade 4') {
      list.add(
          CasePointEntry(title: 'High Cormack-Lehane Grade ($cl)', points: 1));
    }

    // Complications
    if (c.complications.contains('None/uneventful')) {
      list.add(const CasePointEntry(
          title: 'Uneventful Case Bonus',
          subtitle: 'No complications reported',
          points: 2));
    } else {
      for (final comp in c.complications) {
        if (comp == 'Death on table') {
          list.add(const CasePointEntry(
              title: 'On-table Mortality',
              subtitle: 'Complication penalty',
              points: -5,
              isPenalty: true));
        } else if (comp == 'Cardiac arrest') {
          list.add(const CasePointEntry(
              title: 'Cardiac Arrest',
              subtitle: 'Critical complication penalty',
              points: -3,
              isPenalty: true));
        } else {
          list.add(CasePointEntry(
              title: comp,
              subtitle: 'Complication penalty',
              points: -1,
              isPenalty: true));
        }
      }
    }

    // Duration
    final surgeryMins = _parseMinutes(c.surgeryDuration);
    if (surgeryMins != null && surgeryMins > 60) {
      final bonus = ((surgeryMins - 60) ~/ 60) * 2;
      if (bonus > 0) {
        list.add(CasePointEntry(
            title: 'Prolonged Surgery Bonus',
            subtitle: '${c.surgeryDuration}',
            points: bonus));
      }
    }

    final anaesthesiaMins = _parseMinutes(c.anaesthesiaDuration);
    if (anaesthesiaMins != null && surgeryMins != null) {
      final excess = anaesthesiaMins - surgeryMins;
      if (excess > 30) {
        final penalty = (excess ~/ 30) * 1;
        list.add(CasePointEntry(
            title: 'Turnover/Prolonged Wakeup Penalty',
            subtitle: 'Excessive duration vs surgery',
            points: -penalty,
            isPenalty: true));
      }
    }

    // Age
    final y = _ageInYears(c);
    if (y != null) {
      final neonateMax = 28 / 365.25;
      if (y < neonateMax) {
        list.add(const CasePointEntry(
            title: 'Neonatal Care Bonus', subtitle: '< 28 days', points: 5));
      } else if (y < 1.0) {
        list.add(const CasePointEntry(
            title: 'Infant Care Bonus', subtitle: '< 1 year', points: 3));
      } else if (y < 3.0) {
        list.add(const CasePointEntry(
            title: 'Toddler Care Bonus', subtitle: '< 3 years', points: 2));
      } else if (y < 12.0) {
        list.add(const CasePointEntry(
            title: 'Paediatric Care Bonus', subtitle: '< 12 years', points: 1));
      } else if (y >= 65.0) {
        final pts = 1 + ((y - 65).floor() ~/ 10);
        list.add(CasePointEntry(
            title: 'Geriatric Care Bonus',
            subtitle: 'Age ${y.toStringAsFixed(0)}',
            points: pts));
      }
    }

    // BMI
    final bmi = c.bmi;
    if (bmi != null) {
      if (bmi >= 30 && bmi < 35) {
        list.add(CasePointEntry(
            title: 'Obesity Class I Bonus',
            subtitle: 'BMI ${bmi.toStringAsFixed(1)}',
            points: 1));
      } else if (bmi >= 35 && bmi < 40) {
        list.add(CasePointEntry(
            title: 'Obesity Class II Bonus',
            subtitle: 'BMI ${bmi.toStringAsFixed(1)}',
            points: 3));
      } else if (bmi >= 40) {
        list.add(CasePointEntry(
            title: 'Morbid Obesity Bonus',
            subtitle: 'BMI ${bmi.toStringAsFixed(1)}',
            points: 5));
      }
    }

    return list;
  }

  /// Calculates the itemized breakdown, trigger counts, and contributing cases
  /// for a specific category.
  static CategoryDetailResult getCategoryDetail(
    String categoryKey,
    List<CaseRecord> cases, {
    int profileBonus = 0,
  }) {
    final items = <CategoryTriggerItem>[];
    final contributingCases = <CategoryCaseContribution>[];

    switch (categoryKey) {
      case 'Base (per case)':
        final totalPts = cases.length * 10;
        if (cases.isNotEmpty) {
          items.add(CategoryTriggerItem(
            title: 'Standard Case Entry',
            subtitle: 'Base points awarded for logging a clinical case',
            count: cases.length,
            pointsPerTrigger: 10,
            totalPoints: totalPts,
          ));
        }
        for (final c in cases) {
          contributingCases.add(CategoryCaseContribution(
            caseRecord: c,
            points: 10,
            detail: 'Base points',
          ));
        }
        break;

      case 'ASA grade':
        int c2 = 0, c3 = 0, c4 = 0, c5 = 0;
        for (final c in cases) {
          int pts = 0;
          switch (c.asaGrade) {
            case 'ASA II':
              c2++;
              pts = 2;
              break;
            case 'ASA III':
              c3++;
              pts = 3;
              break;
            case 'ASA IV':
              c4++;
              pts = 5;
              break;
            case 'ASA V':
              c5++;
              pts = 10;
              break;
          }
          if (pts > 0) {
            contributingCases.add(CategoryCaseContribution(
              caseRecord: c,
              points: pts,
              detail: c.asaGrade,
            ));
          }
        }
        if (c2 > 0) items.add(CategoryTriggerItem(title: 'ASA Grade II', count: c2, pointsPerTrigger: 2, totalPoints: c2 * 2));
        if (c3 > 0) items.add(CategoryTriggerItem(title: 'ASA Grade III', count: c3, pointsPerTrigger: 3, totalPoints: c3 * 3));
        if (c4 > 0) items.add(CategoryTriggerItem(title: 'ASA Grade IV', count: c4, pointsPerTrigger: 5, totalPoints: c4 * 5));
        if (c5 > 0) items.add(CategoryTriggerItem(title: 'ASA Grade V', count: c5, pointsPerTrigger: 10, totalPoints: c5 * 10));
        break;

      case 'Emergency':
        for (final c in cases) {
          if (c.priority == 'Emergency') {
            contributingCases.add(CategoryCaseContribution(
              caseRecord: c,
              points: 2,
              detail: 'Emergency surgery',
            ));
          }
        }
        if (contributingCases.isNotEmpty) {
          items.add(CategoryTriggerItem(
            title: 'Emergency Priority',
            subtitle: 'Urgent or emergent intervention',
            count: contributingCases.length,
            pointsPerTrigger: 2,
            totalPoints: contributingCases.length * 2,
          ));
        }
        break;

      case 'Difficult airway':
        for (final c in cases) {
          if (c.difficultAirway) {
            contributingCases.add(CategoryCaseContribution(
              caseRecord: c,
              points: 2,
              detail: 'Difficult airway managed',
            ));
          }
        }
        if (contributingCases.isNotEmpty) {
          items.add(CategoryTriggerItem(
            title: 'Difficult Airway',
            subtitle: 'Anticipated or unanticipated difficult airway',
            count: contributingCases.length,
            pointsPerTrigger: 2,
            totalPoints: contributingCases.length * 2,
          ));
        }
        break;

      case 'Regional blocks':
        final blockCounts = <String, int>{};
        final blockPoints = <String, int>{};
        final blockRoles = <String, Set<String>>{};

        for (final c in cases) {
          int casePts = 0;
          final blockNames = <String>[];
          for (final e in c.regionalBlocks) {
            final name = e['name']?.toString() ?? '';
            if (name.isEmpty || name == 'None / Not performed') continue;
            final role = e['role']?.toString() ?? '';
            int pts = 0;
            if (role == 'Performed' || role == 'Supervised') {
              pts = 5;
            } else if (role == 'Assisted') {
              pts = 2;
            }
            if (pts > 0) {
              casePts += pts;
              blockNames.add(name);
              blockCounts[name] = (blockCounts[name] ?? 0) + 1;
              blockPoints[name] = (blockPoints[name] ?? 0) + pts;
              blockRoles.putIfAbsent(name, () => <String>{}).add(role);
            }
          }
          if (casePts > 0) {
            contributingCases.add(CategoryCaseContribution(
              caseRecord: c,
              points: casePts,
              detail: blockNames.join(', '),
            ));
          }
        }

        final sortedNames = blockCounts.keys.toList()
          ..sort((a, b) => (blockPoints[b] ?? 0).compareTo(blockPoints[a] ?? 0));
        for (final name in sortedNames) {
          final count = blockCounts[name]!;
          final pts = blockPoints[name]!;
          final roles = blockRoles[name]?.join(', ') ?? '';
          final avgPerTrigger = count > 0 ? (pts / count).round() : 0;
          items.add(CategoryTriggerItem(
            title: name,
            subtitle: roles.isNotEmpty ? 'Role: $roles' : null,
            count: count,
            pointsPerTrigger: avgPerTrigger,
            totalPoints: pts,
          ));
        }
        break;

      case 'Catheter placed':
        for (final c in cases) {
          if (c.catheterPlaced) {
            contributingCases.add(CategoryCaseContribution(
              caseRecord: c,
              points: 5,
              detail: 'Continuous catheter placed',
            ));
          }
        }
        if (contributingCases.isNotEmpty) {
          items.add(CategoryTriggerItem(
            title: 'Catheter Placed',
            subtitle: 'Continuous epidural or peripheral nerve catheter',
            count: contributingCases.length,
            pointsPerTrigger: 5,
            totalPoints: contributingCases.length * 5,
          ));
        }
        break;

      case 'Invasive lines / monitoring':
        final lineCounts = <String, int>{};
        final linePoints = <String, int>{};
        final lineRoles = <String, Set<String>>{};

        for (final c in cases) {
          int casePts = 0;
          final lineNames = <String>[];
          for (final e in c.invasiveMonitoring) {
            final name = e['name']?.toString() ?? '';
            if (name.isEmpty) continue;
            final role = e['role']?.toString() ?? '';
            int pts = 0;
            if (role == 'Performed' || role == 'Used independently' || role == 'Supervised') {
              pts = 2;
            } else if (role == 'Assisted' || role == 'Used with assistance') {
              pts = 1;
            }
            if (pts > 0) {
              casePts += pts;
              lineNames.add(name);
              lineCounts[name] = (lineCounts[name] ?? 0) + 1;
              linePoints[name] = (linePoints[name] ?? 0) + pts;
              lineRoles.putIfAbsent(name, () => <String>{}).add(role);
            }
          }
          if (casePts > 0) {
            contributingCases.add(CategoryCaseContribution(
              caseRecord: c,
              points: casePts,
              detail: lineNames.join(', '),
            ));
          }
        }

        final sortedLines = lineCounts.keys.toList()
          ..sort((a, b) => (linePoints[b] ?? 0).compareTo(linePoints[a] ?? 0));
        for (final name in sortedLines) {
          final count = lineCounts[name]!;
          final pts = linePoints[name]!;
          final roles = lineRoles[name]?.join(', ') ?? '';
          final avgPerTrigger = count > 0 ? (pts / count).round() : 0;
          items.add(CategoryTriggerItem(
            title: name,
            subtitle: roles.isNotEmpty ? 'Role: $roles' : null,
            count: count,
            pointsPerTrigger: avgPerTrigger,
            totalPoints: pts,
          ));
        }
        break;

      case 'Nasal intubation':
        for (final c in cases) {
          final method = c.methodOfIntubation ?? '';
          final methodRole = c.methodOfIntubationRole ?? '';
          final bool isAirwayInSitu = methodRole.toLowerCase().contains('situ') ||
              method.toLowerCase().contains('situ');
          if (c.typeOfIntubation == 'Nasal intubation' && !isAirwayInSitu) {
            contributingCases.add(CategoryCaseContribution(
              caseRecord: c,
              points: 2,
              detail: 'Nasal endotracheal intubation',
            ));
          }
        }
        if (contributingCases.isNotEmpty) {
          items.add(CategoryTriggerItem(
            title: 'Nasal Intubation',
            subtitle: 'Nasal tube placement',
            count: contributingCases.length,
            pointsPerTrigger: 2,
            totalPoints: contributingCases.length * 2,
          ));
        }
        break;

      case 'Fiberoptic intubation':
        int awakePerf = 0, awakeAssist = 0, asleepPerf = 0, asleepAssist = 0;
        for (final c in cases) {
          final method = c.methodOfIntubation ?? '';
          final methodRole = c.methodOfIntubationRole ?? '';
          int pts = 0;
          String detail = '';
          if (method == 'Awake fiberoptic intubation') {
            if (methodRole == 'Performed' || methodRole == 'Supervised') {
              pts = 10;
              awakePerf++;
              detail = 'Awake fiberoptic (Performed)';
            } else if (methodRole == 'Assisted') {
              pts = 3;
              awakeAssist++;
              detail = 'Awake fiberoptic (Assisted)';
            }
          } else if (method == 'Asleep fiberoptic intubation') {
            if (methodRole == 'Performed' || methodRole == 'Supervised') {
              pts = 7;
              asleepPerf++;
              detail = 'Asleep fiberoptic (Performed)';
            } else if (methodRole == 'Assisted') {
              pts = 2;
              asleepAssist++;
              detail = 'Asleep fiberoptic (Assisted)';
            }
          }
          if (pts > 0) {
            contributingCases.add(CategoryCaseContribution(
              caseRecord: c,
              points: pts,
              detail: detail,
            ));
          }
        }
        if (awakePerf > 0) items.add(CategoryTriggerItem(title: 'Awake Fiberoptic (Performed/Supervised)', count: awakePerf, pointsPerTrigger: 10, totalPoints: awakePerf * 10));
        if (awakeAssist > 0) items.add(CategoryTriggerItem(title: 'Awake Fiberoptic (Assisted)', count: awakeAssist, pointsPerTrigger: 3, totalPoints: awakeAssist * 3));
        if (asleepPerf > 0) items.add(CategoryTriggerItem(title: 'Asleep Fiberoptic (Performed/Supervised)', count: asleepPerf, pointsPerTrigger: 7, totalPoints: asleepPerf * 7));
        if (asleepAssist > 0) items.add(CategoryTriggerItem(title: 'Asleep Fiberoptic (Assisted)', count: asleepAssist, pointsPerTrigger: 2, totalPoints: asleepAssist * 2));
        break;

      case 'LMA role':
        int lmaPerf = 0, lmaAssist = 0;
        for (final c in cases) {
          if (c.airwayManagement == 'Laryngeal Mask Airway (LMA)') {
            final lr = c.lmaRole ?? '';
            int pts = 0;
            String detail = '';
            if (lr == 'Performed' || lr == 'Supervised') {
              pts = 2;
              lmaPerf++;
              detail = 'LMA (Performed/Supervised)';
            } else if (lr == 'Assisted') {
              pts = 1;
              lmaAssist++;
              detail = 'LMA (Assisted)';
            }
            if (pts > 0) {
              contributingCases.add(CategoryCaseContribution(
                caseRecord: c,
                points: pts,
                detail: detail,
              ));
            }
          }
        }
        if (lmaPerf > 0) items.add(CategoryTriggerItem(title: 'LMA (Performed / Supervised)', count: lmaPerf, pointsPerTrigger: 2, totalPoints: lmaPerf * 2));
        if (lmaAssist > 0) items.add(CategoryTriggerItem(title: 'LMA (Assisted)', count: lmaAssist, pointsPerTrigger: 1, totalPoints: lmaAssist * 1));
        break;

      case 'Cormack-Lehane 3/4':
        int gr3 = 0, gr4 = 0;
        for (final c in cases) {
          final method = c.methodOfIntubation ?? '';
          final methodRole = c.methodOfIntubationRole ?? '';
          final bool isAirwayInSitu = methodRole.toLowerCase().contains('situ') ||
              method.toLowerCase().contains('situ');
          final cl = c.cormackLehane ?? '';
          if (!isAirwayInSitu) {
            if (cl == 'Grade 3') {
              gr3++;
              contributingCases.add(CategoryCaseContribution(caseRecord: c, points: 1, detail: 'Grade 3'));
            } else if (cl == 'Grade 4') {
              gr4++;
              contributingCases.add(CategoryCaseContribution(caseRecord: c, points: 1, detail: 'Grade 4'));
            }
          }
        }
        if (gr3 > 0) items.add(CategoryTriggerItem(title: 'Cormack-Lehane Grade 3', count: gr3, pointsPerTrigger: 1, totalPoints: gr3));
        if (gr4 > 0) items.add(CategoryTriggerItem(title: 'Cormack-Lehane Grade 4', count: gr4, pointsPerTrigger: 1, totalPoints: gr4));
        break;

      case 'Complications':
        int safeCount = 0;
        final compCounts = <String, int>{};
        final compPenalties = <String, int>{};

        for (final c in cases) {
          if (c.complications.contains('None/uneventful')) {
            safeCount++;
            contributingCases.add(CategoryCaseContribution(
              caseRecord: c,
              points: 2,
              detail: 'None/uneventful',
            ));
          } else {
            int casePts = 0;
            final names = <String>[];
            for (final comp in c.complications) {
              int penalty = 0;
              if (comp == 'Death on table') {
                penalty = -5;
              } else if (comp == 'Cardiac arrest') {
                penalty = -3;
              } else {
                penalty = -1;
              }
              casePts += penalty;
              names.add(comp);
              compCounts[comp] = (compCounts[comp] ?? 0) + 1;
              compPenalties[comp] = (compPenalties[comp] ?? 0) + penalty;
            }
            if (casePts != 0) {
              contributingCases.add(CategoryCaseContribution(
                caseRecord: c,
                points: casePts,
                detail: names.join(', '),
              ));
            }
          }
        }

        if (safeCount > 0) {
          items.add(CategoryTriggerItem(
            title: 'Uneventful / Safe Conduct',
            subtitle: 'No complications occurred',
            count: safeCount,
            pointsPerTrigger: 2,
            totalPoints: safeCount * 2,
          ));
        }

        for (final comp in compCounts.keys) {
          final count = compCounts[comp]!;
          final pts = compPenalties[comp]!;
          final perTrigger = count > 0 ? (pts / count).round() : 0;
          items.add(CategoryTriggerItem(
            title: comp,
            count: count,
            pointsPerTrigger: perTrigger,
            totalPoints: pts,
          ));
        }
        break;

      case 'Surgery duration bonus':
        for (final c in cases) {
          final surgeryMins = _parseMinutes(c.surgeryDuration);
          if (surgeryMins != null && surgeryMins > 60) {
            final excessHours = (surgeryMins - 60) ~/ 60;
            final pts = excessHours * 2;
            if (pts > 0) {
              contributingCases.add(CategoryCaseContribution(
                caseRecord: c,
                points: pts,
                detail: 'Duration: ${c.surgeryDuration} (+$pts pts)',
              ));
            }
          }
        }
        if (contributingCases.isNotEmpty) {
          final totalPts = contributingCases.fold<int>(0, (sum, e) => sum + e.points);
          items.add(CategoryTriggerItem(
            title: 'Long Surgeries (> 1 Hour)',
            subtitle: '+2 points for each hour beyond the first',
            count: contributingCases.length,
            pointsPerTrigger: 2,
            totalPoints: totalPts,
          ));
        }
        break;

      case 'Turnover/Prolonged wakeup penalty':
        for (final c in cases) {
          final surgeryMins = _parseMinutes(c.surgeryDuration);
          final anaesthesiaMins = _parseMinutes(c.anaesthesiaDuration);
          if (anaesthesiaMins != null && surgeryMins != null) {
            final excess = anaesthesiaMins - surgeryMins;
            if (excess > 30) {
              final penalty = (excess ~/ 30) * 1;
              contributingCases.add(CategoryCaseContribution(
                caseRecord: c,
                points: -penalty,
                detail: 'Excess: ${excess}m (-$penalty pts)',
              ));
            }
          }
        }
        if (contributingCases.isNotEmpty) {
          final totalPts = contributingCases.fold<int>(0, (sum, e) => sum + e.points);
          items.add(CategoryTriggerItem(
            title: 'Prolonged Wakeup (> 30 min excess)',
            subtitle: '-1 point for each 30-minute block exceeding surgical finish',
            count: contributingCases.length,
            pointsPerTrigger: -1,
            totalPoints: totalPts,
          ));
        }
        break;

      case 'Age band':
        int neo = 0, inf = 0, tod = 0, chd = 0, ger = 0;
        int neoPts = 0, infPts = 0, todPts = 0, chdPts = 0, gerPts = 0;

        for (final c in cases) {
          final y = _ageInYears(c);
          if (y != null) {
            const neonateMax = 28 / 365.25;
            int pts = 0;
            String detail = '';
            if (y < neonateMax) {
              pts = 5;
              neo++;
              neoPts += 5;
              detail = 'Neonate (< 28d)';
            } else if (y < 1.0) {
              pts = 3;
              inf++;
              infPts += 3;
              detail = 'Infant (< 1y)';
            } else if (y < 3.0) {
              pts = 2;
              tod++;
              todPts += 2;
              detail = 'Toddler (< 3y)';
            } else if (y < 12.0) {
              pts = 1;
              chd++;
              chdPts += 1;
              detail = 'Child (< 12y)';
            } else if (y >= 65.0) {
              pts = 1 + ((y - 65).floor() ~/ 10);
              ger++;
              gerPts += pts;
              detail = 'Geriatric (${y.toStringAsFixed(0)}y)';
            }
            if (pts > 0) {
              contributingCases.add(CategoryCaseContribution(
                caseRecord: c,
                points: pts,
                detail: detail,
              ));
            }
          }
        }
        if (neo > 0) items.add(CategoryTriggerItem(title: 'Neonate (< 28 days)', count: neo, pointsPerTrigger: 5, totalPoints: neoPts));
        if (inf > 0) items.add(CategoryTriggerItem(title: 'Infant (< 1 year)', count: inf, pointsPerTrigger: 3, totalPoints: infPts));
        if (tod > 0) items.add(CategoryTriggerItem(title: 'Toddler (< 3 years)', count: tod, pointsPerTrigger: 2, totalPoints: todPts));
        if (chd > 0) items.add(CategoryTriggerItem(title: 'Child (< 12 years)', count: chd, pointsPerTrigger: 1, totalPoints: chdPts));
        if (ger > 0) items.add(CategoryTriggerItem(title: 'Geriatric (65+ years)', count: ger, pointsPerTrigger: 0, totalPoints: gerPts));
        break;

      case 'BMI class':
        int cl1 = 0, cl2 = 0, cl3 = 0;
        for (final c in cases) {
          final bmi = c.bmi;
          if (bmi != null) {
            int pts = 0;
            String detail = '';
            if (bmi >= 30 && bmi < 35) {
              pts = 1;
              cl1++;
              detail = 'Class I Obesity (${bmi.toStringAsFixed(1)})';
            } else if (bmi >= 35 && bmi < 40) {
              pts = 3;
              cl2++;
              detail = 'Class II Obesity (${bmi.toStringAsFixed(1)})';
            } else if (bmi >= 40) {
              pts = 5;
              cl3++;
              detail = 'Morbid Obesity (${bmi.toStringAsFixed(1)})';
            }
            if (pts > 0) {
              contributingCases.add(CategoryCaseContribution(
                caseRecord: c,
                points: pts,
                detail: detail,
              ));
            }
          }
        }
        if (cl1 > 0) items.add(CategoryTriggerItem(title: 'Class I Obesity (BMI 30–34.9)', count: cl1, pointsPerTrigger: 1, totalPoints: cl1 * 1));
        if (cl2 > 0) items.add(CategoryTriggerItem(title: 'Class II Obesity (BMI 35–39.9)', count: cl2, pointsPerTrigger: 3, totalPoints: cl2 * 3));
        if (cl3 > 0) items.add(CategoryTriggerItem(title: 'Class III Morbid Obesity (BMI 40+)', count: cl3, pointsPerTrigger: 5, totalPoints: cl3 * 5));
        break;

      case 'Profile completion bonus':
        if (profileBonus > 0) {
          items.add(CategoryTriggerItem(
            title: 'Profile Setup Completed',
            subtitle: 'Awarded for filling consultant and registration details',
            count: 1,
            pointsPerTrigger: profileBonus,
            totalPoints: profileBonus,
          ));
        }
        break;

      default:
        break;
    }

    final totalPoints = items.fold<int>(0, (sum, i) => sum + i.totalPoints);
    final totalTriggers = items.fold<int>(0, (sum, i) => sum + i.count);

    // Sort contributing cases by descending date
    contributingCases.sort((a, b) => b.caseRecord.date.compareTo(a.caseRecord.date));

    return CategoryDetailResult(
      categoryKey: categoryKey,
      totalPoints: totalPoints,
      totalTriggers: totalTriggers,
      items: items,
      contributingCases: contributingCases,
    );
  }
}

class CasePointEntry {
  final String title;
  final String? subtitle;
  final int points;
  final bool isPenalty;

  const CasePointEntry({
    required this.title,
    this.subtitle,
    required this.points,
    this.isPenalty = false,
  });
}

class CategoryTriggerItem {
  final String title;
  final String? subtitle;
  final int count;
  final int pointsPerTrigger;
  final int totalPoints;

  const CategoryTriggerItem({
    required this.title,
    this.subtitle,
    required this.count,
    required this.pointsPerTrigger,
    required this.totalPoints,
  });
}

class CategoryCaseContribution {
  final CaseRecord caseRecord;
  final int points;
  final String? detail;

  const CategoryCaseContribution({
    required this.caseRecord,
    required this.points,
    this.detail,
  });
}

class CategoryDetailResult {
  final String categoryKey;
  final int totalPoints;
  final int totalTriggers;
  final List<CategoryTriggerItem> items;
  final List<CategoryCaseContribution> contributingCases;

  const CategoryDetailResult({
    required this.categoryKey,
    required this.totalPoints,
    required this.totalTriggers,
    required this.items,
    required this.contributingCases,
  });
}


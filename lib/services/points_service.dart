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
      if (role == 'Performed') {
        pts += 5;
      } else if (role == 'Assisted') {
        pts += 2;
      }
    }

    if (c.catheterPlaced) pts += 5;

    for (final e in c.invasiveMonitoring) {
      final role = e['role']?.toString() ?? '';
      if (role == 'Performed' || role == 'Used independently') {
        pts += 2;
      } else if (role == 'Assisted' || role == 'Used with assistance') {
        pts += 1;
      }
    }

    if (c.typeOfIntubation == 'Nasal intubation') pts += 2;

    final method = c.methodOfIntubation ?? '';
    final methodRole = c.methodOfIntubationRole ?? '';
    if (method == 'Awake fiberoptic intubation') {
      if (methodRole == 'Performed') {
        pts += 10;
      } else if (methodRole == 'Assisted') {
        pts += 3;
      }
    } else if (method == 'Asleep fiberoptic intubation') {
      if (methodRole == 'Performed') {
        pts += 7;
      } else if (methodRole == 'Assisted') {
        pts += 2;
      }
    }

    if (c.airwayManagement == 'Laryngeal Mask Airway (LMA)') {
      final lr = c.lmaRole ?? '';
      if (lr == 'Performed') {
        pts += 2;
      } else if (lr == 'Assisted') {
        pts += 1;
      }
    }

    final cl = c.cormackLehane ?? '';
    if (cl == 'Grade 3' || cl == 'Grade 4') pts += 1;

    if (c.complications.contains('None/uneventful')) {
      pts += 2;
    } else {
      for (final comp in c.complications) {
        if (comp == 'Death on table') {
          pts -= 5;
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
        pts -= (excess ~/ 30) * 2;
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
      'Anaesthesia vs surgery penalty': 0,
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
        if (role == 'Performed') {
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
        if (role == 'Performed' || role == 'Used independently') {
          map['Invasive lines / monitoring'] =
              map['Invasive lines / monitoring']! + 2;
        } else if (role == 'Assisted' || role == 'Used with assistance') {
          map['Invasive lines / monitoring'] =
              map['Invasive lines / monitoring']! + 1;
        }
      }

      if (c.typeOfIntubation == 'Nasal intubation') {
        map['Nasal intubation'] = map['Nasal intubation']! + 2;
      }

      final method = c.methodOfIntubation ?? '';
      final methodRole = c.methodOfIntubationRole ?? '';
      if (method == 'Awake fiberoptic intubation') {
        if (methodRole == 'Performed') {
          map['Fiberoptic intubation'] = map['Fiberoptic intubation']! + 10;
        } else if (methodRole == 'Assisted') {
          map['Fiberoptic intubation'] = map['Fiberoptic intubation']! + 3;
        }
      } else if (method == 'Asleep fiberoptic intubation') {
        if (methodRole == 'Performed') {
          map['Fiberoptic intubation'] = map['Fiberoptic intubation']! + 7;
        } else if (methodRole == 'Assisted') {
          map['Fiberoptic intubation'] = map['Fiberoptic intubation']! + 2;
        }
      }

      if (c.airwayManagement == 'Laryngeal Mask Airway (LMA)') {
        final lr = c.lmaRole ?? '';
        if (lr == 'Performed') {
          map['LMA role'] = map['LMA role']! + 2;
        } else if (lr == 'Assisted') {
          map['LMA role'] = map['LMA role']! + 1;
        }
      }

      final cl = c.cormackLehane ?? '';
      if (cl == 'Grade 3' || cl == 'Grade 4') {
        map['Cormack-Lehane 3/4'] = map['Cormack-Lehane 3/4']! + 1;
      }

      if (c.complications.contains('None/uneventful')) {
        map['Complications'] = map['Complications']! + 2;
      } else {
        for (final comp in c.complications) {
          if (comp == 'Death on table') {
            map['Complications'] = map['Complications']! - 5;
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
          map['Anaesthesia vs surgery penalty'] =
              map['Anaesthesia vs surgery penalty']! - (excess ~/ 30) * 2;
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
      list.add(const CasePointEntry(title: 'Difficult Airway Managed', points: 2));
    }

    // Regional
    for (final e in c.regionalBlocks) {
      final name = e['name']?.toString() ?? '';
      if (name.isEmpty || name == 'None / Not performed') continue;
      final role = e['role']?.toString() ?? '';
      if (role == 'Performed') {
        list.add(CasePointEntry(title: 'Regional Block (Performed)', subtitle: name, points: 5));
      } else if (role == 'Assisted') {
        list.add(CasePointEntry(title: 'Regional Block (Assisted)', subtitle: name, points: 2));
      }
    }

    // Catheter
    if (c.catheterPlaced) {
      list.add(const CasePointEntry(title: 'Catheter Placed', subtitle: 'Continuous infusion / post-op boluses', points: 5));
    }

    // Invasive
    for (final e in c.invasiveMonitoring) {
      final name = e['name']?.toString() ?? '';
      final role = e['role']?.toString() ?? '';
      if (role == 'Performed' || role == 'Used independently') {
        list.add(CasePointEntry(title: 'Invasive Line / Monitor', subtitle: '$name ($role)', points: 2));
      } else if (role == 'Assisted' || role == 'Used with assistance') {
        list.add(CasePointEntry(title: 'Invasive Line / Monitor', subtitle: '$name ($role)', points: 1));
      }
    }

    // Intubation
    if (c.typeOfIntubation == 'Nasal intubation') {
      list.add(const CasePointEntry(title: 'Nasal Intubation', points: 2));
    }

    final method = c.methodOfIntubation ?? '';
    final methodRole = c.methodOfIntubationRole ?? '';
    if (method == 'Awake fiberoptic intubation') {
      if (methodRole == 'Performed') {
        list.add(const CasePointEntry(title: 'Awake Fiberoptic Intubation (Performed)', points: 10));
      } else if (methodRole == 'Assisted') {
        list.add(const CasePointEntry(title: 'Awake Fiberoptic Intubation (Assisted)', points: 3));
      }
    } else if (method == 'Asleep fiberoptic intubation') {
      if (methodRole == 'Performed') {
        list.add(const CasePointEntry(title: 'Asleep Fiberoptic Intubation (Performed)', points: 7));
      } else if (methodRole == 'Assisted') {
        list.add(const CasePointEntry(title: 'Asleep Fiberoptic Intubation (Assisted)', points: 2));
      }
    }

    // LMA
    if (c.airwayManagement == 'Laryngeal Mask Airway (LMA)') {
      final lr = c.lmaRole ?? '';
      if (lr == 'Performed') {
        list.add(const CasePointEntry(title: 'LMA Insertion (Performed)', points: 2));
      } else if (lr == 'Assisted') {
        list.add(const CasePointEntry(title: 'LMA Insertion (Assisted)', points: 1));
      }
    }

    // Cormack
    final cl = c.cormackLehane ?? '';
    if (cl == 'Grade 3' || cl == 'Grade 4') {
      list.add(CasePointEntry(title: 'High Cormack-Lehane Grade ($cl)', points: 1));
    }

    // Complications
    if (c.complications.contains('None/uneventful')) {
      list.add(const CasePointEntry(title: 'Uneventful Case Bonus', subtitle: 'No complications reported', points: 2));
    } else {
      for (final comp in c.complications) {
        if (comp == 'Death on table') {
          list.add(const CasePointEntry(title: 'On-table Mortality', subtitle: 'Complication penalty', points: -5, isPenalty: true));
        } else {
          list.add(CasePointEntry(title: comp, subtitle: 'Complication penalty', points: -1, isPenalty: true));
        }
      }
    }

    // Duration
    final surgeryMins = _parseMinutes(c.surgeryDuration);
    if (surgeryMins != null && surgeryMins > 60) {
      final bonus = ((surgeryMins - 60) ~/ 60) * 2;
      if (bonus > 0) {
        list.add(CasePointEntry(title: 'Prolonged Surgery Bonus', subtitle: '${c.surgeryDuration}', points: bonus));
      }
    }

    final anaesthesiaMins = _parseMinutes(c.anaesthesiaDuration);
    if (anaesthesiaMins != null && surgeryMins != null) {
      final excess = anaesthesiaMins - surgeryMins;
      if (excess > 30) {
        final penalty = (excess ~/ 30) * 2;
        list.add(CasePointEntry(title: 'Anaesthesia Turnaround Penalty', subtitle: 'Excessive duration vs surgery', points: -penalty, isPenalty: true));
      }
    }

    // Age
    final y = _ageInYears(c);
    if (y != null) {
      final neonateMax = 28 / 365.25;
      if (y < neonateMax) {
        list.add(const CasePointEntry(title: 'Neonatal Care Bonus', subtitle: '< 28 days', points: 5));
      } else if (y < 1.0) {
        list.add(const CasePointEntry(title: 'Infant Care Bonus', subtitle: '< 1 year', points: 3));
      } else if (y < 3.0) {
        list.add(const CasePointEntry(title: 'Toddler Care Bonus', subtitle: '< 3 years', points: 2));
      } else if (y < 12.0) {
        list.add(const CasePointEntry(title: 'Paediatric Care Bonus', subtitle: '< 12 years', points: 1));
      } else if (y >= 65.0) {
        final pts = 1 + ((y - 65).floor() ~/ 10);
        list.add(CasePointEntry(title: 'Geriatric Care Bonus', subtitle: 'Age ${y.toStringAsFixed(0)}', points: pts));
      }
    }

    // BMI
    final bmi = c.bmi;
    if (bmi != null) {
      if (bmi >= 30 && bmi < 35) {
        list.add(CasePointEntry(title: 'Obesity Class I Bonus', subtitle: 'BMI ${bmi.toStringAsFixed(1)}', points: 1));
      } else if (bmi >= 35 && bmi < 40) {
        list.add(CasePointEntry(title: 'Obesity Class II Bonus', subtitle: 'BMI ${bmi.toStringAsFixed(1)}', points: 3));
      } else if (bmi >= 40) {
        list.add(CasePointEntry(title: 'Morbid Obesity Bonus', subtitle: 'BMI ${bmi.toStringAsFixed(1)}', points: 5));
      }
    }

    return list;
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

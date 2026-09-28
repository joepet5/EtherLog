// ignore_for_file: avoid_print
import 'package:flutter_test/flutter_test.dart';
import 'package:etherlog/models/achievement.dart';
import 'package:etherlog/models/case_record.dart';
import 'package:etherlog/services/achievement_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  test('Audit all categories and targets across all achievements', () async {
    final achievements = await AchievementService.getAllAchievements([]);
    print('Total achievements loaded: ${achievements.length}');

    final tierPoints = {
      AchievementTier.copper: 10,
      AchievementTier.bronze: 25,
      AchievementTier.ruby: 50,
      AchievementTier.silver: 100,
      AchievementTier.gold: 250,
      AchievementTier.platinum: 500,
      AchievementTier.obsidian: 1000,
      AchievementTier.diamond: 2500,
    };

    final Map<String, int> catCounts = {};
    final Map<String, int> catXp = {};
    final Map<String, Map<AchievementTier, int>> catTierCounts = {};
    final Map<AchievementTier, int> totalTierCounts = {};
    int grandTotalXp = 0;

    for (final ach in achievements) {
      final cat = ach.category;
      final tier = ach.tier;
      final pts = tierPoints[tier]!;

      catCounts[cat] = (catCounts[cat] ?? 0) + 1;
      catXp[cat] = (catXp[cat] ?? 0) + pts;

      catTierCounts.putIfAbsent(cat, () => {})[tier] = (catTierCounts[cat]![tier] ?? 0) + 1;
      totalTierCounts[tier] = (totalTierCounts[tier] ?? 0) + 1;
      grandTotalXp += pts;
    }

    print('\n======================================================');
    print('          ACHIEVEMENT XP BREAKDOWN BY SECTION');
    print('======================================================');
    final sortedCats = catXp.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    for (final entry in sortedCats) {
      final cat = entry.key;
      final xp = entry.value;
      final count = catCounts[cat]!;
      print('${cat.padRight(22)} | Count: ${count.toString().padLeft(3)} | Total XP: ${xp.toString().padLeft(6)} XP');
    }
    print('------------------------------------------------------');
    print('TOTAL: ${achievements.length} achievements | $grandTotalXp XP\n');

    print('======================================================');
    print('             ACHIEVEMENT XP BY TIER');
    print('======================================================');
    for (final tier in AchievementTier.values) {
      final count = totalTierCounts[tier] ?? 0;
      final pts = tierPoints[tier]!;
      final subtotal = count * pts;
      print('${tier.label.toUpperCase().padRight(10)} (${pts.toString().padLeft(4)} XP): ${count.toString().padLeft(3)} badges = ${subtotal.toString().padLeft(6)} XP');
    }
    print('======================================================\n');
    print('\n=== CATEGORY BREAKDOWN (${catCounts.length} categories) ===');
    for (final entry in catCounts.entries) {
      print('  ${entry.key}: ${entry.value}');
    }

    // Check targets for anomalies
    final List<String> suspiciousTargets = [];
    for (final ach in achievements) {
      if (ach.maxProgress <= 0) {
        suspiciousTargets.add('[ZERO/NEG] "${ach.title}" (${ach.category}) target=${ach.maxProgress}');
      } else if (ach.maxProgress > 1000 &&
          !['the singularity', 'logbook ascendant', 'mythical practitioner', 'etherlog legend', 'prestige', 'the high scorer', 'leveling up'].contains(ach.title.toLowerCase())) {
        suspiciousTargets.add('[VERY LARGE] "${ach.title}" (${ach.category}) target=${ach.maxProgress}');
      }
    }

    print('\n=== TARGET CONSISTENCY AUDIT ===');
    final List<String> targetMismatches = [];
    for (final ach in achievements) {
      final d = ach.description.toLowerCase();
      final t = ach.title.toLowerCase();

      // Check specific common phrases
      if ((d.startsWith('first ') || d.contains('first case') || d.contains('first ')) &&
          !d.contains('first pass') &&
          !t.contains('century') &&
          !d.contains('twenty') &&
          !d.contains('thirty') &&
          !d.contains('fifty') &&
          !d.contains('ten') &&
          !d.contains('five') &&
          ach.maxProgress != 1 &&
          ach.category != 'Power User') {
        targetMismatches.add('Desc says first/one but target is ${ach.maxProgress}: "${ach.title}" (${ach.category}) -> "${ach.description}"');
      }
    }

    print('\n=== NON-STANDARD TARGETS AUDIT ===');
    const standardTargets = {
      1, 2, 3, 4, 5, 6, 7, 8, 10, 12, 14, 15, 20, 24, 25, 30, 35, 40, 45, 48, 50, 70, 72, 75,
      100, 125, 150, 175, 200, 225, 250, 300, 350, 400, 500, 750,
      1000, 1250, 1500, 1750, 2000, 2500, 3000, 4000, 5000, 10000, 25000, 50000, 100000,
    };

    for (final ach in achievements) {
      if (!standardTargets.contains(ach.maxProgress)) {
        print('  NON-STANDARD: "${ach.title}" (${ach.category}) target=${ach.maxProgress} | desc: "${ach.description}"');
      }
    }
    final riskTitlesKnown = {
      'healthy start', 'prime health', 'fit as a fiddle', 'pure wellness', 'asa 1 master',
      'mild systemic', 'minor issues', 'bread and butter', 'common ground', 'asa 2 regular', 'asa 2 veteran',
      'severe systemic', 'complex care', 'heavy medical history', 'asa 3 specialist', 'asa 3 expert',
      'constant threat', 'high stakes', 'danger zone', 'asa 4 guardian', 'adrenaline cocktail', 'asa 4 master',
      'the last hope', 'edge of life', 'high risk survivor', 'asa 5 hero', 'ultimate risk', 'master of the brink',
      'risk manager', 'defying the odds', 'critical transfer',
      'routine check', 'unbroken streak',
      'high acuity day', 'heavy duty day', 'balanced portfolio',
      'safe hand on high risk', 'fearless', 'resilient system',
    };
    for (final ach in achievements.where((a) => a.category == 'Risk')) {
      final t = ach.title.toLowerCase().trim();
      if (!riskTitlesKnown.contains(t)) {
        print('  Risk UNMATCHED: "${ach.title}" -> target: ${ach.maxProgress} | desc: "${ach.description}"');
      }
    }

    print('\n=== EMERGENCY ACHIEVEMENTS AUDIT ===');
    final emergencyTitlesKnown = {
      'drop everything', 'adrenaline rush', 'adrenaline junkie', 'fast response',
      'olympic decathlon (trauma edition)', 'sprint to theatre', 'crisis manager',
      'emergency expert', 'unfazed', 'trauma veteran', 'emergency master',
      'trauma bay regular', 'double trouble', 'nightmare scenario', 'calm under pressure',
      'emergency regional', 'emergency block master', 'the bronchoscopy ballet',
      'fast and furious', 'emergency awake', 'emergency spine', 'carpentry and ketamine',
      'emergency heart', 'stork in a hurricane', 'emergency baby', 'zero drama delivery',
      'emergency brain', 'brain landlord', 'the fixer', 'pager slayer',
      'midnight emergency', 'holiday emergency', 'weekend trauma', 'firefighter in scrubs',
      'airway rescue', 'stable in chaos', 'emergency pediatric', 'emergency geriatric',
      'saved by the bell', 'full moon madness', 'dawn relief', 'non-stop crisis',
      'iron constitution', 'trauma team leader', 'century of carnage',
      'acute abdomen', 'bone fracture rush', 'cesarean rush', 'brain bleed rush', 'vascular clamp',
      'unstoppable force', 'master of chaos', 'automatic pilot', 'universal defender', 'the ultimate iron man',
    };
    for (final ach in achievements.where((a) => a.category == 'Emergency')) {
      final t = ach.title.toLowerCase().trim();
      if (!emergencyTitlesKnown.contains(t)) {
        print('  Emergency UNMATCHED: "${ach.title}" -> target: ${ach.maxProgress} | desc: "${ach.description}"');
      }
    }

    print('\n=== TECHNIQUES ACHIEVEMENTS AUDIT ===');
    final techTitlesKnown = {
      'gas man/woman', 'volatile regular', 'inhalational expert', 'volatile master',
      'white milk', 'white magic', 'propofol pro', 'tiva specialist', 'total intravenous master', 'tiva innovator',
      'the overachiever', 'overachiever', 'half and half', 'cse regular', 'cse expert',
      'spinal pioneer', 'sab regular', 'spinal master', 'spinal king',
      'epidural explorer', 'epidural regular', 'epidural expert', 'epidural queen',
      'mac daddy', 'smooth sedation', 'sedation master', 'mac specialist',
      'local hero', 'standby mode', 'peripheral primary', 'nerve block specialist',
      'tci tech', 'target controlled', 'tci master',
      'versatile anaesthetist', 'awake regional',
      'deep sleep 100', 'deep sleep 250', 'deep sleep 500',
      'regional purist',
    };
    for (final ach in achievements.where((a) => a.category == 'Techniques')) {
      final t = ach.title.toLowerCase().trim();
      if (!techTitlesKnown.contains(t)) {
        print('  Techniques UNMATCHED: "${ach.title}" -> target: ${ach.maxProgress} | desc: "${ach.description}"');
      }
    }

    print('\n=== AIRWAY ACHIEVEMENTS AUDIT ===');
    final airwayTitlesKnown = {
      'tube is in', 'tube beginner', 'tube regular', 'master of the tube', 'ett veteran', 'ett grandmaster',
      'mask on', 'lma beginner', 'lma regular', 'lma enthusiast', 'lma veteran',
      'bare minimum', 'just bagging', 'surgical airway', 'trach team',
      'high pressure', 'lung isolation', 'thoracic airway', 'dlt expert',
      'bronchial blocker', 'blocker pro', 'classic touch', 'proseal pro',
      'gel fit', 'supreme leader', 'ambu airway', 'fast and flexible',
      'nose knows best', 'nasal navigator', 'nasal expert', 'below the chin',
      'screen time', 'video beginner', 'video star', 'video master',
      'awake and aware', 'awake fos pro', 'awake master',
      'asleep fiberoptic', 'asleep fos pro', 'fiberoptic master',
      'micro manager', 'bending the rules', 'blind spot', 'grade 3 collector',
      'in the dark', 'grade 4 survivor', 'the sweat gland', 'sweat gland',
      'airway apprentice', 'airway journeyman', 'airway expert', 'the lord of the cords', 'lord of the cords',
      'airway ninja', 'first pass success', 'clean pass', "third time's a charm", "third times a charm",
      'multi-attempt warrior', 'lma performed', 'intubation performed', 'assisted airway', 'observed airway',
      'paediatric tube', 'giant tube', 'uncuffed care', 'cuffed standard',
      'cormack grade 1', 'cormack grade 2', 'awake fiberoptic performer', 'the sneaky scope', 'sneaky scope',
      'asleep fiberoptic performer', 'emergency airway ace', 'airway scholar', 'airway legend',
    };
    for (final ach in achievements.where((a) => a.category == 'Airway')) {
      final t = ach.title.toLowerCase().trim();
      if (!airwayTitlesKnown.contains(t)) {
        print('  Airway UNMATCHED: "${ach.title}" -> target: ${ach.maxProgress} | desc: "${ach.description}"');
      }
    }

    print('\n=== REGIONAL ACHIEVEMENTS AUDIT ===');
    final regTitlesKnown = {
      'liquid gold', 'spinal beginner', 'spinal regular', 'subarachnoid specialist', 'spinal elite',
      'nerve block novice', 'block beginner', 'block regular', 'block boss', 'block expert', 'block master',
      'sound waves', 'usg beginner', 'echogenic needle', 'ultrasonic pro', 'ultrasound master',
      'twitcher', 'stimulator pro', 'continuous relief', 'catheter champion', 'continuous infusion pro',
      'brachial plexus pro', 'upper limb legend', 'lower limb legend', 'leg day',
      'core control', 'trunk tracker', 'chest wall relief', 'paravertebral pro',
      'neck and head', 'paediatric block', 'ankle biter', 'old school',
      'plexus master', 'block collector', 'block connoisseur',
      'interscalene specialist', 'supraclavicular specialist', 'infraclavicular specialist', 'axillary specialist',
      'femoral specialist', 'adductor canal', 'sciatic specialist', 'popliteal specialist',
      'tap block master', 'rectus sheath master', 'ql block master', 'esp block master',
      'pecs master', 'serratus master', 'cervical plexus', 'scalp blockade',
      'caudal epidural', 'bier block pro', 'multi-block artist', 'the regional god',
      'fascia first', 'fascia iliaca beginner', 'fascia regular', 'fascia specialist', 'fascia master',
      'fascia usg', 'fascia catheter', 'fascia performed', 'fascia performed fifty',
      'psoas first', 'psoas beginner', 'psoas regular', 'psoas specialist', 'psoas master',
      'psoas usg', 'psoas catheter', 'psoas performed', 'psoas performed fifty',
      'plane pair', 'lower limb plane day', 'nof blocker', 'deep plane duo', 'block for nof',
      'plane explorer', 'plane legend', 'plane day list', 'block diversifier', 'trauma plane pack',
      'emergency plane pack', 'regional maximalist',
    };
    for (final ach in achievements.where((a) => a.category == 'Regional')) {
      final t = ach.title.toLowerCase().trim();
      if (!regTitlesKnown.contains(t)) {
        print('  Regional UNMATCHED: "${ach.title}" -> target: ${ach.maxProgress} | desc: "${ach.description}"');
      }
    }

    print('\n=== MONITORING ACHIEVEMENTS AUDIT ===');
    final monTitlesKnown = {
      'seeing red', 'art line beginner', 'art line regular', 'art line ace', '100 beats per minute',
      'central access', 'dilator discipline', 'cvc regular', 'the lumen lord', "seldinger's true heir",
      'x-ray vision', 'ultrasound aficionado', 'sonographic virtuoso',
      'brain waves', 'target 40 to 60', 'numbers over vibes', 'the cortical bouncer',
      'infrared vision', 'advanced brain', 'heart watcher', 'go with the flow', 'this is spinal tap!',
      'the cockpit crew', 'nasa mission control', 'line collector', 'master of the mediastinum',
      'arterial line assist', 'guidewire guardian', 'master of the frontal lobe',
      'tci pump independent', 'nirs independent', 'picco independent',
      'tee observer', 'pa catheter observer', 'subarachnoid drain pro', 'the omniscient anaesthetist',
    };
    for (final ach in achievements.where((a) => a.category == 'Monitoring')) {
      final t = ach.title.toLowerCase().trim();
      if (!monTitlesKnown.contains(t)) {
        print('  Monitoring UNMATCHED: "${ach.title}" -> target: ${ach.maxProgress} | desc: "${ach.description}"');
      }
    }

    print('\n=== DEMOGRAPHICS ACHIEVEMENTS AUDIT ===');
    final demoTitlesKnown = {
      'the micro-manager', 'the micromanager', 'micro-manager', 'micromanager',
      'tiny patient', 'nicu regular', 'neonatal guardian', 'the pediatrician', 'pediatrician',
      'infant care', 'infant specialist', 'the negotiator', 'negotiator', 'toddler time',
      'child care', 'adolescent care', 'golden years', 'the fragile cargo',
      'geriatric guardian', 'elderly protector', 'senior specialist',
      'octogenarian care', 'octogenarian club', 'centenarian',
      'bariatric basics', 'bariatric regular', 'bariatric specialist',
      'extreme bmi', 'super bariatric', 'the featherweight', 'lightweight',
      'featherweight', 'heavyweight', 'super heavyweight',
      'spectrum of age', 'spectrum of size', 'tiny tot surgeon',
      'elderly care leader', 'bariatric champion', 'underweight expert',
      'extreme age range', 'extremes of weight',
      'paediatric airway ace', 'geriatric airway ace',
      'paediatric pro',
    };
    for (final ach in achievements.where((a) => a.category == 'Demographics')) {
      final t = ach.title.toLowerCase().trim();
      if (!demoTitlesKnown.contains(t)) {
        print('  Demographics UNMATCHED: "${ach.title}" -> target: ${ach.maxProgress} | desc: "${ach.description}"');
      }
    }

    print('\n=== SAFETY & COMPLICATIONS ACHIEVEMENTS AUDIT ===');
    final safeCompKnown = {
      'the clean exit', 'recovery room favorite', 'pacu perfection', 'untouchable record',
      'the zone', 'untouchable streak', 'flawless month', 'defying gravity', 'brink walker',
      'miracle worker', 'the impossible standard', 'calm in the storm', 'storm rider',
      'eye of the hurricane', 'flawless airway', 'airway artisan', 'airway virtuoso',
      'prudent pause', 'vigilant observer', 'watchful protector', 'smooth handover',
      'intensive care liaison', 'critical care anchor', 'the stabilizer', 'silver lining', 'smooth sailing',
      'the good luck charm', 'safe hands', "the 'q' word", 'the q word', 'flawless week',
      'century of safety', 'bulletproof streak', 'quick wakeup', 'efficiency expert',
      'the bucket list', 'the exorcist protocol', 'how low can you go?', 'the iron lungs',
      "darth vader's chokehold", 'the deep breath', 'blue moon rising', 'safe recovery',
      'shiver starter', 'shiver handler', 'thermal debt collector', 'thermodynamic sorcerer', 'shiver legend track',
      'blow off some steam, bennett!', 'hypertension tamer', 'hypertension regular', 'the high-pressure architect', 'hypertension legend',
      "we're gonna need a bigger boat", 'blood bank vip', 'bleeding regular', "dracula's accountant", 'bleeding legend',
      'passing the baton', 'the cold never bothered me anyway', 'warm bodies', 'hypothermia regular', 'hypothermia specialist', 'hypothermia legend',
      'rhythm check', 'arrhythmia handler', 'arrhythmia regular', 'mozart of the monitor', 'arrhythmia legend',
      't', 'flat tire mechanic', 'the lung whisperer', 'lord of the pleura', 'pop goes the pleura',
      'red alert in theatre', 'transfusion connoisseur', "the blood bank's best customer", 'total body replacement',
      "bad blood (taylor's version)", 'not on my watch', 'cross-match critic', 'hemovigilance officer', 'trust the checklist',
      'air embolus alert', 'air bender', 'the entrapment officer', 'sub-atmospheric ace', 'bubble trouble',
      'the gastric redemption', 'the bronchial lifeguard', 'acid reflux avenger', 'the alveolar shield', 'aspiration avoider energy',
      'failed tube', 'failed intubation handler', 'failed intubation regular', 'failed intubation specialist',
      'mask trouble', 'not that dmv!', 'seal of approval', 'the grip of steel',
      'complication collector', 'complication connoisseur', 'complication scholar', 'crisis catalogue', 'crisis catalogue 50',
      'boring is beautiful', 'fire & ice', 'lethal triad disruptor', 'wrong hole, wrong place!',
      'complication night', 'complication in asa4', "all's well that ends well", 'multi complication case',
      'morbidity & mastery', 'safety net expanded', 'the transparent intubator', 'the honest scalpel',
      'no skeletons in the closet', 'safety expansion 10', 'safety expansion 25', 'safety expansion 75', 'safety expansion 100',
      'post event uneventful', 'emergency complication', 'paeds complication', 'elderly complication',
      'bariatric complication', 'maxillo complication', 'ir complication', 'paeds cardiac complication',
      'boss fight: phase two', 'cirque du soleil',
      'complication teacher', 'safety day', 'complication zero week energy',
      'safety explorer', 'safety legend', 'safety maximalist',
      'protect the plexus', 'too high, too slow',
    };
    for (final ach in achievements.where((a) => a.category == 'Safety' || a.category == 'Complications')) {
      final t = ach.title.toLowerCase().trim();
      if (!safeCompKnown.contains(t)) {
        print('  Safety/Complications UNMATCHED: "${ach.title}" (${ach.category}) -> target: ${ach.maxProgress} | desc: "${ach.description}"');
      }
    }

    print('\n=== POST-OP & ERAS ACHIEVEMENTS AUDIT ===');
    final postOpKnown = {
      'the morning rounder', 'ward patrol', 'the rounding regular', 'the bedside philosopher', 'recovery room royalty',
      'cast iron stomach', 'the motion sickness shield', 'emesis basin extinction', 'the ironclad gut',
      'whisper of pain', 'comfort zone', 'the analgesic architect', 'pain? what pain?',
      'catheter navigator', 'the infusion conductor', 'continuous flow master',
      'the sensory scout', 'dermatome detective', 'dense & direct',
      'motor recovery marshal', 'block resolution specialist', 'zero deficit guarantee',
      'the regional audit master', 'eras trailblazer',
    };
    for (final ach in achievements.where((a) => a.category == 'Post-Op & ERAS')) {
      final t = ach.title.toLowerCase().trim();
      if (!postOpKnown.contains(t)) {
        print('  Post-Op UNMATCHED: "${ach.title}" -> target: ${ach.maxProgress} | desc: "${ach.description}"');
      }
    }

    print('\n=== MENTORSHIP ACHIEVEMENTS AUDIT ===');
    final mentorKnown = {
      'passing the torch', 'the guiding light', 'patience of a saint', 'the professor of gas', 'the master mentor',
      'hands in pockets', 'the college tutor', 'training programme director', 'yoda of the airway',
      'the grand chancellor of gas', 'the dean of narcosis',
      'baptism of fire', 'nightshift guardian', 'code red wingman',
      'fragile ground', 'high-stakes shepherd', 'the hemodynamic zen master',
      'the calm in the cords', 'difficult airway wingman', 'the fiberoptic sherpa',
      'micro-dose mentor', 'paediatric co-pilot', 'the neonatal whisperer guide',
      'flashback sherpa', 'vascular navigator',
      'probe & needle sensei', 'the fascial plane coach',
      'rare bird hunter', 'curator of oddities', 'cabinet of curiosities', 'living medical journal',
    };
    for (final ach in achievements.where((a) => a.category == 'Mentorship')) {
      final t = ach.title.toLowerCase().trim();
      if (!mentorKnown.contains(t)) {
        print('  Mentorship UNMATCHED: "${ach.title}" -> target: ${ach.maxProgress} | desc: "${ach.description}"');
      }
    }

    print('\n=== PORTFOLIO ACHIEVEMENTS AUDIT ===');
    final portfolioKnown = {
      'signed, sealed, delivered', 'the photographic ledger', 'paperless perfectionist', 'the forensic archivist',
      'grade a glottis', 'vocal cord cartographer', 'the laryngeal scholar',
      'the anatomical scribe', 'hardware cataloguer',
      'the meticulous scribe', 'the clinical essayist',
    };
    for (final ach in achievements.where((a) => a.category == 'Portfolio')) {
      final t = ach.title.toLowerCase().trim();
      if (!portfolioKnown.contains(t)) {
        print('  Portfolio UNMATCHED: "${ach.title}" -> target: ${ach.maxProgress} | desc: "${ach.description}"');
      }
    }
  });

  test('Functional verification of key achievement triggers', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('doctor_dob', '1990-05-15');

    CaseRecord createSampleCase({
      required String id,
      required DateTime date,
      String specialty = 'General Surgery',
      String priority = 'Elective',
      String? anaesthesiaEndTime,
      String? surgeryEndTime,
      List<String> complications = const [],
    }) {
      return CaseRecord(
        id: id,
        caseNumber: 'CASE-$id',
        date: date,
        specialty: specialty,
        diagnosis: 'Test Diagnosis',
        procedure: 'Test Procedure',
        priority: priority,
        asaGrade: 'I',
        technique: 'General Anaesthesia',
        role: 'Primary Anaesthetist',
        anaesthesiaDuration: '60',
        surgeryDuration: '50',
        anaesthesiaEndTime: anaesthesiaEndTime ?? '10:05',
        surgeryEndTime: surgeryEndTime ?? '10:00',
        complications: complications,
      );
    }

    // 1. Quick Recovery series test: anaesthesiaEndTime < 10 mins after surgeryEndTime
    final caseQuick = createSampleCase(
      id: 'qr1',
      date: DateTime(2025, 6, 1),
      anaesthesiaEndTime: '10:08',
      surgeryEndTime: '10:00',
    );
    final achsQuick = await AchievementService.getAllAchievements([caseQuick]);
    final achQR = achsQuick.firstWhere((a) => a.title.toLowerCase() == 'quick recovery');
    expect(achQR.isUnlocked, true, reason: 'Quick Recovery should unlock when diff < 10m');

    final caseSlow = createSampleCase(
      id: 'qr2',
      date: DateTime(2025, 6, 1),
      anaesthesiaEndTime: '10:15',
      surgeryEndTime: '10:00',
    );
    final achsSlow = await AchievementService.getAllAchievements([caseSlow]);
    final achQRSlow = achsSlow.firstWhere((a) => a.title.toLowerCase() == 'quick recovery');
    expect(achQRSlow.isUnlocked, false, reason: 'Quick Recovery should not unlock when diff >= 10m');

    // 2. Dawn Relief: Emergency ending between 08:00 and 08:30
    final caseDawn = createSampleCase(
      id: 'dawn1',
      date: DateTime(2025, 6, 1),
      priority: 'Emergency',
      surgeryEndTime: '08:15',
    );
    final achsDawn = await AchievementService.getAllAchievements([caseDawn]);
    final achDawn = achsDawn.firstWhere((a) => a.title.toLowerCase() == 'dawn relief');
    expect(achDawn.isUnlocked, true, reason: 'Dawn Relief should unlock on emergency ending 08:15');

    // 3. Universal Defender: 10 emergencies across unique specialties
    final specs = [
      'General Surgery', 'Orthopedics', 'Obstetrics', 'ENT', 'Urology',
      'Spine', 'HPB', 'Radiotherapy', 'Dental/Oral Maxillofacial', 'Interventional Radiology'
    ];
    final emergencyCases = List.generate(10, (i) => createSampleCase(
      id: 'em_$i',
      date: DateTime(2025, 6, 1 + i),
      priority: 'Emergency',
      specialty: specs[i],
    ));
    final achsUniversal = await AchievementService.getAllAchievements(emergencyCases);
    final achUniv = achsUniversal.firstWhere((a) => a.title.toLowerCase() == 'universal defender');
    expect(achUniv.currentProgress, 10);
    expect(achUniv.isUnlocked, true, reason: 'Universal Defender should unlock with 10 unique emergency specialties');

    // 4. Complications: Protect the Plexus & Too High, Too Slow
    final casePlexus = createSampleCase(
      id: 'plexus1',
      date: DateTime(2025, 6, 1),
      complications: ['Position-related nerve injury'],
    );
    final achsPlexus = await AchievementService.getAllAchievements([casePlexus]);
    final achPlexus = achsPlexus.firstWhere((a) => a.title.toLowerCase() == 'protect the plexus');
    expect(achPlexus.isUnlocked, true, reason: 'Protect the Plexus should unlock for position complication');

    final caseSpinal = createSampleCase(
      id: 'spinal1',
      date: DateTime(2025, 6, 1),
      complications: ['High spinal block'],
    );
    final achsSpinal = await AchievementService.getAllAchievements([caseSpinal]);
    final achSpinal = achsSpinal.firstWhere((a) => a.title.toLowerCase() == 'too high, too slow');
    expect(achSpinal.isUnlocked, true, reason: 'Too High, Too Slow should unlock for high spinal complication');

    // 5. Holiday Shift & Birthday Shift & Auld Lang Syne
    final caseNewYear = createSampleCase(
      id: 'ny1',
      date: DateTime(2025, 12, 31, 23, 0),
    );
    final achsNY = await AchievementService.getAllAchievements([caseNewYear]);
    final achAuld = achsNY.firstWhere((a) => a.title.toLowerCase() == 'auld lang syne');
    expect(achAuld.isUnlocked, true);
    expect(achAuld.tier.name, 'bronze');

    final caseHoliday = createSampleCase(
      id: 'hol1',
      date: DateTime(2025, 12, 25, 10, 0),
    );
    final achsHol = await AchievementService.getAllAchievements([caseHoliday]);
    final achHol = achsHol.firstWhere((a) => a.title.toLowerCase() == 'holiday shift');
    expect(achHol.isUnlocked, true);
    expect(achHol.tier.name, 'ruby');

    final caseBday = createSampleCase(
      id: 'bday1',
      date: DateTime(2025, 5, 15, 10, 0),
    );
    final achsBday = await AchievementService.getAllAchievements([caseBday]);
    final achBday = achsBday.firstWhere((a) => a.title.toLowerCase() == 'birthday shift');
    expect(achBday.isUnlocked, true);
    expect(achBday.tier.name, 'ruby');

    // 6. Specialty triggers
    final caseCardio = createSampleCase(
      id: 'ct1',
      date: DateTime(2025, 6, 1),
      specialty: 'Cardiothoracic',
    );
    final achsCT = await AchievementService.getAllAchievements([caseCardio]);
    final achPump = achsCT.firstWhere((a) => a.title.toLowerCase() == 'welcome to the pump');
    expect(achPump.isUnlocked, true, reason: 'Welcome to the Pump should unlock on 1 CT case');

    final caseSpine = createSampleCase(
      id: 'sp1',
      date: DateTime(2025, 6, 1),
      specialty: 'Spine',
    );
    final achsSpine = await AchievementService.getAllAchievements([caseSpine]);
    final achProne = achsSpine.firstWhere((a) => a.title.toLowerCase() == 'the prone position');
    expect(achProne.isUnlocked, true, reason: 'The Prone Position should unlock on 1 spine case');

    // 7. Green Zone Cruiser test: 5 hours of logged time
    final caseUnder5h = createSampleCase(
      id: 'gz_under',
      date: DateTime(2025, 7, 1, 8, 0),
    ); // duration 60 mins (1h)
    final achsUnder5h = await AchievementService.getAllAchievements([caseUnder5h]);
    final achGZUnder = achsUnder5h.firstWhere((a) => a.title.toLowerCase() == 'green zone cruiser');
    expect(achGZUnder.maxProgress, 1);
    expect(achGZUnder.isUnlocked, false, reason: 'Green Zone Cruiser should not unlock under 5 hours');

    final case5h = CaseRecord(
      id: 'gz_5h',
      caseNumber: 'CASE-gz_5h',
      date: DateTime(2025, 7, 1, 8, 0),
      specialty: 'General Surgery',
      diagnosis: 'Test',
      procedure: 'Test',
      priority: 'Elective',
      asaGrade: 'I',
      technique: 'General Anaesthesia',
      role: 'Primary Anaesthetist',
      anaesthesiaDuration: '5h 0m',
      surgeryDuration: '4h 50m',
    );
    final achs5h = await AchievementService.getAllAchievements([case5h]);
    final achGZ5h = achs5h.firstWhere((a) => a.title.toLowerCase() == 'green zone cruiser');
    expect(achGZ5h.maxProgress, 1);
    expect(achGZ5h.isUnlocked, true, reason: 'Green Zone Cruiser should unlock when logged time reaches at least 5 hours');

    // 8. Dental/Maxillofacial Surgery achievements tests:
    final caseDentalRoutine = CaseRecord(
      id: 'dent_1',
      caseNumber: 'CASE-dent_1',
      date: DateTime(2025, 8, 1, 9, 0),
      specialty: 'Dental/Maxillofacial surgery',
      diagnosis: 'Impacted Wisdom Tooth',
      procedure: 'Extraction',
      priority: 'Elective',
      asaGrade: 'I',
      technique: 'General Anaesthesia (VA)',
      role: 'Primary Anaesthetist',
      anaesthesiaDuration: '1h 0m',
      surgeryDuration: '45m',
      difficultAirway: false,
      regionalBlocks: [],
      complications: ['None / Uneventful'],
    );
    final achsDentalRoutine = await AchievementService.getAllAchievements([caseDentalRoutine]);
    final achOpenWide = achsDentalRoutine.firstWhere((a) => a.title.toLowerCase() == 'open wide');
    final achDentalBlock = achsDentalRoutine.firstWhere((a) => a.title.toLowerCase() == 'dental block combo');
    final achDentalEmerg = achsDentalRoutine.firstWhere((a) => a.title.toLowerCase() == 'dental emergency');
    final achMaxilloDA = achsDentalRoutine.firstWhere((a) => a.title.toLowerCase() == 'maxillo difficult airway');

    expect(achOpenWide.isUnlocked, true, reason: 'Open Wide unlocks on first dental/maxillofacial case');
    expect(achDentalBlock.isUnlocked, false, reason: 'Dental Block Combo must NOT unlock without a regional block');
    expect(achDentalEmerg.isUnlocked, false, reason: 'Dental Emergency must NOT unlock for an elective case');
    expect(achMaxilloDA.isUnlocked, false, reason: 'Maxillo Difficult Airway must NOT unlock when difficultAirway is false');

    // With regional block
    final caseDentalBlock = caseDentalRoutine.copyWith(
      id: 'dent_block',
      regionalBlocks: [{'name': 'Mental nerve block', 'role': 'Performed'}],
    );
    final achsBlock = await AchievementService.getAllAchievements([caseDentalBlock]);
    expect(achsBlock.firstWhere((a) => a.title.toLowerCase() == 'dental block combo').isUnlocked, true,
        reason: 'Dental Block Combo should unlock when a regional block is performed');

    // With emergency
    final caseDentalEmerg = caseDentalRoutine.copyWith(
      id: 'dent_emerg',
      priority: 'Emergency',
    );
    final achsEmerg = await AchievementService.getAllAchievements([caseDentalEmerg]);
    expect(achsEmerg.firstWhere((a) => a.title.toLowerCase() == 'dental emergency').isUnlocked, true,
        reason: 'Dental Emergency should unlock when priority is Emergency');

    // With difficult airway
    final caseDentalDA = caseDentalRoutine.copyWith(
      id: 'dent_da',
      difficultAirway: true,
    );
    final achsDA = await AchievementService.getAllAchievements([caseDentalDA]);
    expect(achsDA.firstWhere((a) => a.title.toLowerCase() == 'maxillo difficult airway').isUnlocked, true,
        reason: 'Maxillo Difficult Airway should unlock when difficultAirway is true');

    // 9. The 24-Hour War Horse test: 16 hours active time (not 14 hours)
    final case14h = createSampleCase(
      id: 'shift_14h',
      date: DateTime(2025, 9, 1, 6, 0),
    ).copyWith(
      anaesthesiaDuration: '14h 0m',
      surgeryDuration: '13h 30m',
    );
    final achs14h = await AchievementService.getAllAchievements([case14h]);
    final warHorse14h = achs14h.firstWhere((a) => a.title.toLowerCase() == 'the 24-hour war horse');
    final redRing14h = achs14h.firstWhere((a) => a.title.toLowerCase() == 'red ring awakening');
    expect(redRing14h.isUnlocked, true, reason: 'Red Ring Awakening unlocks at 14 hours');
    expect(warHorse14h.isUnlocked, false, reason: 'The 24-Hour War Horse should NOT unlock at 14 hours');

    final case16h = createSampleCase(
      id: 'shift_16h',
      date: DateTime(2025, 9, 2, 6, 0),
    ).copyWith(
      anaesthesiaDuration: '16h 0m',
      surgeryDuration: '15h 30m',
    );
    final achs16h = await AchievementService.getAllAchievements([case16h]);
    final warHorse16h = achs16h.firstWhere((a) => a.title.toLowerCase() == 'the 24-hour war horse');
    expect(warHorse16h.isUnlocked, true, reason: 'The 24-Hour War Horse should unlock at 16 hours');

    // 17. Cumulative Time achievements expansion (2500h, 5000h, 10000h, 25000h, 50000h)
    final emptyAchs = await AchievementService.getAllAchievements([]);
    final ach2500 = emptyAchs.firstWhere((a) => a.title == '2,500 Hour Milestone');
    final ach5000 = emptyAchs.firstWhere((a) => a.title == 'The Half-Myriad Master');
    final ach10000 = emptyAchs.firstWhere((a) => a.title == '10,000 Hour Virtuoso');
    final ach25000 = emptyAchs.firstWhere((a) => a.title == 'Quarter-Century Veteran');
    final ach50000 = emptyAchs.firstWhere((a) => a.title == 'The Eternal Gas Titan');

    expect(ach2500.maxProgress, 2500);
    expect(ach2500.tier, AchievementTier.platinum);
    expect(ach5000.maxProgress, 5000);
    expect(ach5000.tier, AchievementTier.obsidian);
    expect(ach10000.maxProgress, 10000);
    expect(ach10000.tier, AchievementTier.obsidian);
    expect(ach25000.maxProgress, 25000);
    expect(ach25000.tier, AchievementTier.diamond);
    expect(ach50000.maxProgress, 50000);
    expect(ach50000.tier, AchievementTier.diamond);

    // Test unlock progression
    final case2500h = createSampleCase(
      id: 'case_2500h',
      date: DateTime(2025, 9, 3, 8, 0),
    ).copyWith(
      anaesthesiaDuration: '2500h 0m',
      surgeryDuration: '2400h 0m',
    );
    final achs2500 = await AchievementService.getAllAchievements([case2500h]);
    expect(achs2500.firstWhere((a) => a.title == '2,500 Hour Milestone').isUnlocked, true);
    expect(achs2500.firstWhere((a) => a.title == 'The Half-Myriad Master').isUnlocked, false);

    final case5000h = createSampleCase(
      id: 'case_5000h',
      date: DateTime(2025, 9, 4, 8, 0),
    ).copyWith(
      anaesthesiaDuration: '5000h 0m',
      surgeryDuration: '4900h 0m',
    );
    final achs5000 = await AchievementService.getAllAchievements([case5000h]);
    expect(achs5000.firstWhere((a) => a.title == 'The Half-Myriad Master').isUnlocked, true);
    expect(achs5000.firstWhere((a) => a.title == '10,000 Hour Virtuoso').isUnlocked, false);

    // 18. Triple Red Streak verification
    final caseRed1 = createSampleCase(
      id: 'red_shift_1',
      date: DateTime(2026, 9, 1, 8, 0),
    ).copyWith(anaesthesiaDuration: '10h 0m');
    final caseRed2 = createSampleCase(
      id: 'red_shift_2',
      date: DateTime(2026, 9, 3, 8, 0),
    ).copyWith(anaesthesiaDuration: '10h 30m');
    final achs2Red = await AchievementService.getAllAchievements([caseRed1, caseRed2]);
    final achTripleRed2 = achs2Red.firstWhere((a) => a.title == 'Triple Red Streak');
    expect(achTripleRed2.maxProgress, 3);
    expect(achTripleRed2.currentProgress, 2);
    expect(achTripleRed2.isUnlocked, false, reason: '2 shifts should be progress 2/3');

    final caseRed3 = createSampleCase(
      id: 'red_shift_3',
      date: DateTime(2026, 9, 5, 8, 0),
    ).copyWith(anaesthesiaDuration: '11h 0m');
    final achs3Red = await AchievementService.getAllAchievements([caseRed1, caseRed2, caseRed3]);
    final achTripleRed3 = achs3Red.firstWhere((a) => a.title == 'Triple Red Streak');
    expect(achTripleRed3.currentProgress, 3);
    expect(achTripleRed3.tier, AchievementTier.gold, reason: 'Triple Red Streak must be gold tier');
    expect(achTripleRed3.isUnlocked, true, reason: '3 red shifts in 1 week should unlock Triple Red Streak');

    // 19. Oral ETT and Nasal ETT intubation verification
    final caseOralEtt = createSampleCase(
      id: 'ett_oral',
      date: DateTime(2026, 9, 1, 9, 0),
    ).copyWith(
      airwayManagement: 'Other',
      typeOfIntubation: 'Oral intubation',
    );
    final achsOral = await AchievementService.getAllAchievements([caseOralEtt]);
    expect(achsOral.firstWhere((a) => a.title == 'Tube is In').isUnlocked, true,
        reason: 'Oral intubation must unlock Tube is In');

    final caseNasalEtt = createSampleCase(
      id: 'ett_nasal',
      date: DateTime(2026, 9, 1, 9, 0),
    ).copyWith(
      airwayManagement: 'Other',
      typeOfIntubation: 'Nasal intubation',
      ettType: 'Nasal ETT',
    );
    final achsNasal = await AchievementService.getAllAchievements([caseNasalEtt]);
    expect(achsNasal.firstWhere((a) => a.title == 'Tube is In').isUnlocked, true,
        reason: 'Nasal intubation must unlock Tube is In');

    final tenEttCases = [
      ...List.generate(5, (i) => createSampleCase(
        id: 'ett_o_$i',
        date: DateTime(2026, 9, 2, 8, 0),
      ).copyWith(typeOfIntubation: 'Oral intubation')),
      ...List.generate(5, (i) => createSampleCase(
        id: 'ett_n_$i',
        date: DateTime(2026, 9, 3, 8, 0),
      ).copyWith(typeOfIntubation: 'Nasal intubation')),
    ];
    final achs10Ett = await AchievementService.getAllAchievements(tenEttCases);
    expect(achs10Ett.firstWhere((a) => a.title == 'Tube Beginner').isUnlocked, true,
        reason: '10 mixed oral and nasal intubations must unlock Tube Beginner');
  });
}

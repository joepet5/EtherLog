import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import '../models/case_record.dart';
import '../models/achievement.dart';
import '../models/achievement_registry.dart';
import 'profile_storage.dart';
import 'points_service.dart';
import 'fatigue_service.dart';
import 'pac_storage.dart';
import '../models/pac_record.dart';

class AchievementService {
  static final Map<String, String> _categoryMap = {
    for (final item in AchievementRegistry.data)
      item['title']!.toLowerCase().trim(): item['category'] ?? 'Volume',
  };

  static String getCategory(String title) {
    final lower = title.toLowerCase().trim();
    if (_categoryMap.containsKey(lower)) return _categoryMap[lower]!;
    if (lower.startsWith('the ') &&
        _categoryMap.containsKey(lower.substring(4))) {
      return _categoryMap[lower.substring(4)]!;
    }
    return 'Volume';
  }

  static final _hourRegex = RegExp(r'(\d+)\s*h');
  static final _minRegex = RegExp(r'(\d+)\s*m');
  static final _digitRegex = RegExp(r'\d+');

  static bool hasValue(String? s) => s != null && s.trim().isNotEmpty;

  static int _parseMinutes(String? s) {
    if (s == null || s.trim().isEmpty) return 0;
    final text = s.toLowerCase().trim();

    // Check "X:YY" format (e.g. "06:30" or "10:00")
    if (text.contains(':')) {
      final parts = text.split(':');
      final h = int.tryParse(parts[0].trim()) ?? 0;
      final m = parts.length > 1 ? (int.tryParse(parts[1].trim()) ?? 0) : 0;
      return h * 60 + m;
    }

    final hourMatch = RegExp(r'(\d+)\s*(?:h|hr|hour)').firstMatch(text);
    final minMatch = RegExp(r'(\d+)\s*(?:m|min)').firstMatch(text);
    final h = hourMatch != null ? int.tryParse(hourMatch.group(1)!) ?? 0 : 0;
    final m = minMatch != null ? int.tryParse(minMatch.group(1)!) ?? 0 : 0;

    if (hourMatch == null && minMatch == null) {
      return int.tryParse(text) ?? 0;
    }

    return h * 60 + m;
  }

  static int _getCaseAnaesthesiaMinutes(CaseRecord c) {
    int m = _parseMinutes(c.anaesthesiaDuration);
    if (m > 0) return m;
    final s = _parseTimeToMinutes(c.anaesthesiaStartTime);
    final e = _parseTimeToMinutes(c.anaesthesiaEndTime);
    if (s != null && e != null) {
      int diff = e - s;
      if (diff < 0) diff += 1440;
      return diff;
    }
    return 0;
  }

  static int _extractNumberFromText(String text) {
    String t = text.toLowerCase().replaceAll(',', '');

    t = t.replaceAll(
        RegExp(r'\b\d{1,2}(?::\d{2})?\s*(?:am|pm)\b', caseSensitive: false),
        '');
    t = t.replaceAll(RegExp(r'\b\d{1,2}:\d{2}\b'), '');
    t = t.replaceAll(
        RegExp(
            r'\b\d+\s*(?:mins?|minutes?|seconds?|secs?|hours?|hrs?|h|m|days?|weeks?|months?|years?|yrs?|kg|cm|%)\b',
            caseSensitive: false),
        '');
    t = t.replaceAll(
        RegExp(
            r'\b(?:asa|grade|cormack|mallampati|stage|level|type|tier)\s*\d+(\s*[/,-]\s*\d+)*\b',
            caseSensitive: false),
        '');
    t = t.replaceAll(RegExp(r'[><=]\s*\d+'), '');

    final allNums = RegExp(r'\d+')
        .allMatches(t)
        .map((m) => int.tryParse(m.group(0)!) ?? 0)
        .where((n) => n > 0)
        .toList();
    if (allNums.isNotEmpty) {
      return allNums.reduce((a, b) => a > b ? a : b);
    }

    if (t.contains('five thousand') || t.contains('5000')) return 5000;
    if (t.contains('four thousand') || t.contains('4000')) return 4000;
    if (t.contains('three thousand') || t.contains('3000')) return 3000;
    if (t.contains('two thousand') || t.contains('2000')) return 2000;
    if (t.contains('one thousand') || t.contains('thousand')) return 1000;
    if (t.contains('seven hundred fifty') ||
        t.contains('seven hundred and fifty')) return 750;
    if (t.contains('five hundred')) return 500;
    if (t.contains('three hundred')) return 300;
    if (t.contains('two hundred fifty') || t.contains('two hundred and fifty'))
      return 250;
    if (t.contains('two hundred')) return 200;
    if (t.contains('one hundred seventy') || t.contains('hundred seventy'))
      return 175;
    if (t.contains('one hundred fifty') || t.contains('hundred fifty'))
      return 150;
    if (t.contains('one hundred twenty') || t.contains('hundred twenty'))
      return 125;
    if (t.contains('one hundred') ||
        t.contains('a hundred') ||
        t.contains('century')) return 100;
    if (t.contains('ninety')) return 90;
    if (t.contains('eighty')) return 80;
    if (t.contains('seventy')) return 70;
    if (t.contains('sixty')) return 60;
    if (t.contains('fifty')) return 50;
    if (t.contains('forty')) return 40;
    if (t.contains('thirty')) return 30;
    if (t.contains('twenty-five') || t.contains('twenty five')) return 25;
    if (t.contains('twenty')) return 20;
    if (t.contains('sixteen')) return 16;
    if (t.contains('fifteen')) return 15;
    if (t.contains('thirteen')) return 13;
    if (t.contains('twelve') || t.contains('dozen')) return 12;
    if (t.contains('ten')) return 10;
    if (t.contains('nine')) return 9;
    if (t.contains('eight')) return 8;
    if (t.contains('seven')) return 7;
    if (t.contains('six')) return 6;
    if (t.contains('five')) return 5;
    if (t.contains('four')) return 4;
    if (t.contains('three')) return 3;
    if (RegExp(r'\btwo\b').hasMatch(t)) return 2;
    if (RegExp(r'\bone\b').hasMatch(t) || RegExp(r'\bfirst\b').hasMatch(t))
      return 1;

    return 1;
  }

  static const Map<String, int> _volumeTargets = {
    // Volume additions
    'the veteran': 2000,
    'veteran': 2000,

    // Time additions
    'the blink': 1,
    'blink': 1,
    'the weekender': 48,
    'weekender': 48,

    // Emergency additions
    'the fire extinguisher': 50,
    'fire extinguisher': 50,

    // Specialties additions
    'the bat on the ceiling': 25,
    'bat on the ceiling': 25,
    'the brain trust': 25,
    'brain trust': 25,
    'the water works': 25,
    'water works': 25,
    'the dungeon master': 10,
    'dungeon master': 10,
    'the drifter': 25,
    'drifter': 25,
    'the chiropractor': 100,
    'chiropractor': 100,
    'the glow worm': 4,
    'glow worm': 4,
    'paediatric ir': 1,
    'paediatric beam': 1,
    'rt early start': 1,

    // Techniques additions
    'the vaporizer': 1,
    'vaporizer': 1,
    'the greenhouse gas contributor': 500,
    'greenhouse gas contributor': 500,
    'the whisperer': 50,
    'whisperer': 50,

    // Airway additions
    'the jaw thruster': 50,
    'jaw thruster': 50,
    'the movie critic': 100,
    'movie critic': 100,
    'the blindfolded archer': 5,
    'blindfolded archer': 5,
    'the sweat gland': 1,
    'sweat gland': 1,
    'swear gland': 1,
    'the swear gland': 1,
    'the lord of the cords': 50,
    'lord of the cords': 50,
    'uncuffed care': 1,
    'cuffed standard': 100,
    'the sneaky scope': 20,
    'sneaky scope': 20,
    'assisted airway': 50,
    'observed airway': 50,
    'airway scholar': 500,
    'airway legend': 1,

    // Regional additions
    'loss of resistance': 1,
    'the spine whisperer': 100,
    'spine whisperer': 100,
    'the electrician': 10,
    'electrician': 10,
    'the sonographer': 50,
    'sonographer': 50,
    'the gel monster': 250,
    'gel monster': 250,
    'the drip': 1,
    'drip': 1,
    'never skip leg day': 20,
    'the tap dancer': 30,
    'tap dancer': 30,
    'spinal regular': 50,

    // Monitoring additions
    'the wire whisperer': 5,
    'wire whisperer': 5,
    'neck real estate agent': 50,
    'the cheater': 1,
    'cheater': 1,
    'the plumber': 5,
    'plumber': 5,
    'the leak fixer': 10,
    'leak fixer': 10,

    // Demographics additions
    'the negotiator': 20,
    'negotiator': 20,
    'child care': 25,
    'adolescent care': 20,
    'the fragile cargo': 25,
    'fragile cargo': 25,
    'bariatric basics': 1,
    'bariatric specialist': 20,
    'tiny tot surgeon': 50,
    'featherweight': 1,
    'heavyweight': 1,
    'super heavyweight': 1,
    'extremes of weight': 1,
    'paediatric airway ace': 1,
    'geriatric airway ace': 1,

    // Safety additions
    'the good luck charm': 10,
    'good luck charm': 10,
    'safe recovery': 100,

    // Power User additions
    'the paranoid': 5,
    'paranoid': 5,
    'the high scorer': 1000,
    'high scorer': 1000,
    'etherlog legend': 10000,
    'mythical practitioner': 25000,
    'protect the plexus': 1,
    'too high, too slow': 1,
    'logbook ascendant': 50000,
    'the singularity': 100000,

    // Complications additions
    'the volcano': 1,
    'volcano': 1,
    'the dj': 1,
    'dj': 1,
    'paeds complication': 1,

    'first induction': 1,
    'two cases': 2,
    "third time's a charm": 3,
    'quarter dozen': 4,
    'high five': 5,
    'half dozen': 6,
    'lucky seven': 7,
    'octet': 8,
    'almost ten': 9,
    'getting the hang of it': 10,
    "baker's dozen": 13,
    'sweet sixteen': 16,
    'two decades': 20,
    'quarter century': 25,
    'thirty and thriving': 30,
    'forty winks': 40,
    'steady hands': 50,
    'sixty-second': 60,
    'seventy-fifth': 75,
    'eighty-eighter': 88,
    'almost 100': 90,
    'vitals under control': 100,
    '125 milestone': 125,
    '150 logged': 150,
    '175 strong': 175,
    'junior resident': 200,
    '225 cases': 225,
    'quarter master': 250,
    '300 club': 300,
    'the airway whisperer': 350,
    '400 logged': 400,
    'seasoned resident': 500,
    '550 milestone': 550,
    '600 cases': 600,
    '650 strong': 650,
    '700 logged': 700,
    '750 three-quarters': 750,
    '800 cases': 800,
    '850 milestone': 850,
    '900 cases': 900,
    'almost elite': 950,
    'consultant material': 1000,
    '1,250 cases': 1250,
    '1,500 cases': 1500,
    '1,750 cases': 1750,
    'veteran anaesthetist': 2000,
    '2,500 cases': 2500,
    '3,000 cases': 3000,
    '4,000 cases': 4000,
    'master of the logbook': 5000,
    'first blood': 1,
    'repeat offender': 2,
    'four-play': 4,
    'six pack': 6,
    'slot machine': 7,
    'crazy eights': 8,
    'superstitious': 13,
    'dirty thirty': 30,
    'the hex': 60,
    'three quarters': 75,
    'the infinity loop': 88,
    'quarter past': 125,
    'the final quarter': 175,
    'spartan': 300,
    'the oracle': 900,
    'the two-thousand yard stare': 2000,
    'living monument': 2500,
    'vaporizer king': 3000,
    'ether god': 5000,

    // PAC Clinic additions
    // Cumulative Volume
    'the gatekeeper': 1,
    'gatekeeper': 1,
    'fasting enforcer': 10,
    'mallampati scout': 25,
    'the optimiser': 50,
    'optimiser': 50,
    'century of clearances': 100,
    'clinic workhorse': 250,
    'pre-op veteran': 500,
    'risk stratifier': 750,
    'chief of pre-assessment': 1000,
    'the iron stamp': 2500,
    'iron stamp': 2500,
    'oracle of the clinic': 5000,

    // Single-Day Sprints
    'warm-up lap': 5,
    'double digits': 10,
    'morning surge': 15,
    'conveyor belt': 20,
    'quarter-century sprint': 25,
    'clinic marathon': 30,
    'pre-op engine': 35,
    'clinical centrifuge': 40,
    'industrial throughput': 45,
    'the village cleared': 50,
    'village cleared': 50,

    // Clinic Consistency
    'first clinic call': 1,
    'clinic regular': 5,
    'outpatient rhythm': 10,
    'clinic resident': 25,
    'pre-op anchor': 50,
    'seasoned assessor': 75,
    'century of clinics': 100,
    'master of the waiting room': 150,
    'the permanent fixture': 200,
    'permanent fixture': 200,
    'a year in pre-op': 365,
    'year in pre-op': 365,
  };

  static int _determineTarget(String title, String desc) {
    final t =
        title.toLowerCase().trim().replaceAll('’', "'").replaceAll('‘', "'");
    final d = desc.toLowerCase().trim();

    final volumeTarget = _volumeTargets[t];
    if (volumeTarget != null) return volumeTarget;

    if (t == 'paediatric pro') {
      if (d.contains('fifty') || d.contains('50')) return 50;
      return 25;
    }

    const explicit = <String, int>{
      'welcome to the pump': 1,
      'the prone position': 1,
      'prone position': 1,
      'heavyweight crisis': 1,
      'ear to sternal notch': 1,
      'ramp master general': 75,
      'coiling the catastrophe': 1,
      'lead apron workout': 1,
      'angio suite hostage': 1,
      'bunker tv': 1,
      'the congenital awakening': 3,
      'congenital awakening': 3,
      'sweating in pediatrics': 1,
      'honey i shrunk the patient': 1,
      'spaghetti junction': 1,
      'the gentle beam': 1,
      'gentle beam': 1,
      'beam me up, scotty': 1,
      'creature of the dark room': 1,
      'open wide': 1,
      'ultrasound deep dive': 1,
      'the morning rounder': 1,
      'ward patrol': 10,
      'the rounding regular': 25,
      'the bedside philosopher': 50,
      'recovery room royalty': 100,
      'cast iron stomach': 1,
      'the motion sickness shield': 15,
      'emesis basin extinction': 35,
      'the ironclad gut': 75,
      'whisper of pain': 1,
      'comfort zone': 15,
      'the analgesic architect': 35,
      'pain? what pain?': 75,
      'catheter navigator': 1,
      'the infusion conductor': 10,
      'continuous flow master': 25,
      'the sensory scout': 1,
      'dermatome detective': 5,
      'dense & direct': 10,
      'motor recovery marshal': 15,
      'block resolution specialist': 25,
      'zero deficit guarantee': 35,
      'the regional audit master': 50,
      'eras trailblazer': 50,
      'passing the torch': 1,
      'the guiding light': 10,
      'patience of a saint': 25,
      'the professor of gas': 50,
      'the master mentor': 100,
      'hands in pockets': 150,
      'the college tutor': 200,
      'training programme director': 300,
      'yoda of the airway': 500,
      'the grand chancellor of gas': 750,
      'the dean of narcosis': 1000,
      'baptism of fire': 5,
      'nightshift guardian': 25,
      'code red wingman': 50,
      'fragile ground': 5,
      'high-stakes shepherd': 25,
      'the hemodynamic zen master': 50,
      'the calm in the cords': 5,
      'difficult airway wingman': 15,
      'the fiberoptic sherpa': 10,
      'micro-dose mentor': 5,
      'paediatric co-pilot': 25,
      'the neonatal whisperer guide': 10,
      'flashback sherpa': 15,
      'vascular navigator': 50,
      'probe & needle sensei': 15,
      'the fascial plane coach': 50,
      'rare bird hunter': 1,
      'curator of oddities': 5,
      'cabinet of curiosities': 15,
      'living medical journal': 30,
      'signed, sealed, delivered': 1,
      'the photographic ledger': 15,
      'paperless perfectionist': 50,
      'the forensic archivist': 100,
      'grade a glottis': 1,
      'vocal cord cartographer': 25,
      'the laryngeal scholar': 75,
      'the anatomical scribe': 1,
      'hardware cataloguer': 25,
      'the meticulous scribe': 50,
      'the clinical essayist': 100,

      'night owl': 1,
      'early bird': 1,
      'weekend warrior': 1,
      'the drive-thru': 1,
      'the drive thru': 1,
      'drive-thru': 1,
      'drive thru': 1,
      'in and out': 1,
      'long haul': 1,
      'ceiling tile inspector': 1,
      'ultra marathon': 1,
      'endless case': 1,
      'quick recovery': 1,
      'waking on cue': 5,
      'gas off, eyes open': 10,
      'holiday shift': 1,
      'auld lang syne': 1,
      "new year's eve": 1,
      'birthday shift': 1,
      'shift survivor': 1,
      'the red ring veteran': 5,
      'red ring veteran': 5,
      'the 24-hour war horse': 1,
      'the 24 hour war horse': 1,
      '24-hour war horse': 1,
      'pharmacological survival': 25,
      'the post-call sanctuary': 1,
      'post-call sanctuary': 1,
      'flawless under pressure': 1,
      'sunrise extubation': 1,
      'flawless fatigue': 1,
      'the weekend gauntlet': 1,
      'weekend gauntlet': 1,
      'the green zone cruiser': 1,
      'green zone cruiser': 1,
      'the green zone guardian': 1,
      'green zone guardian': 1,
      'entering the amber alert': 1,
      'amber alert': 1,
      'red ring awakening': 1,
      'triple red streak': 3,
      'the red ring centurion': 100,
      'red ring centurion': 100,
      'heavyweight fatigue': 1,
      'midnight oil': 5,
      'graveyard shift': 10,
      'vampire shift': 20,
      'dawn patrol': 10,
      'saturday night live': 10,
      'no days off': 50,
      'speed runner': 10,
      'in sync': 25,
      'perfect alignment': 50,
      'synchronized sleep': 100,
      'swiss chronometer': 100,
      'the atomic clock': 200,
      'the maestro of emergence': 350,
      'the quantum chronometer': 500,
      'quick nap': 1,
      'deep sleep': 5,
      'time keeps ticking': 10,
      'shift work': 15,
      'full day': 24,
      'two days asleep': 48,
      'weekly grind': 50,
      'three days asleep': 72,
      'the sandman': 100,
      'sandman': 100,
      'century of sleep': 100,
      '150 hours': 150,
      '200 hours': 200,
      '300 hours': 300,
      '400 hours': 400,
      'the or inhabitant': 400,
      'or inhabitant': 400,
      'the half-thousand club': 500,
      '500 hours halfway': 500,
      '750 hours': 750,
      '1,000 hour club': 1000,
      '2,500 hour milestone': 2500,
      'the half-myriad master': 5000,
      '10,000 hour virtuoso': 10000,
      'quarter-century veteran': 25000,
      'the eternal gas titan': 50000,
      'healthy start': 1,
      'prime health': 10,
      'fit as a fiddle': 25,
      'pure wellness': 50,
      'asa 1 master': 100,
      'mild systemic': 1,
      'minor issues': 10,
      'common ground': 25,
      'asa 2 regular': 50,
      'asa 2 veteran': 100,
      'severe systemic': 1,
      'complex care': 10,
      'heavy medical history': 25,
      'asa 3 specialist': 50,
      'asa 3 expert': 100,
      'constant threat': 1,
      'high stakes': 5,
      'danger zone': 15,
      'asa 4 guardian': 25,
      'asa 4 master': 50,
      'the last hope': 1,
      'edge of life': 3,
      'high risk survivor': 5,
      'asa 5 hero': 10,
      'ultimate risk': 20,
      'risk manager': 100,
      'defying the odds': 1,
      'critical transfer': 1,
      'routine check': 10,
      'unbroken streak': 25,
      'high acuity day': 3,
      'heavy duty day': 5,
      'balanced portfolio': 1,
      'safe hand on high risk': 50,
      'fearless': 10,
      'resilient system': 100,
      'bread and butter': 10,
      'adrenaline cocktail': 5,
      'master of the brink': 50,
      'drop everything': 1,
      'adrenaline rush': 5,
      'adrenaline junkie': 10,
      'fast response': 20,
      'olympic decathlon (trauma edition)': 20,
      'sprint to theatre': 20,
      'crisis manager': 50,
      'firefighter in scrubs': 50,
      'emergency expert': 75,
      'unfazed': 100,
      'century of carnage': 100,
      'trauma veteran': 150,
      'automatic pilot': 150,
      'emergency master': 200,
      'pager slayer': 200,
      'trauma bay regular': 5,
      'full moon madness': 5,
      'double trouble': 1,
      'nightmare scenario': 1,
      'calm under pressure': 20,
      'emergency regional': 1,
      'emergency block master': 10,
      'the bronchoscopy ballet': 1,
      'fast and furious': 1,
      'emergency awake': 1,
      'emergency spine': 1,
      'emergency heart': 1,
      'emergency baby': 1,
      'emergency brain': 1,
      'brain landlord': 1,
      'the fixer': 50,
      'midnight emergency': 1,
      'holiday emergency': 1,
      'weekend trauma': 10,
      'airway rescue': 1,
      'stable in chaos': 1,
      'emergency pediatric': 1,
      'emergency geriatric': 1,
      'saved by the bell': 1,
      'dawn relief': 1,
      'non-stop crisis': 1,
      'zero drama delivery': 10,
      'iron constitution': 10,
      'trauma team leader': 25,
      'acute abdomen': 20,
      'bone fracture rush': 20,
      'carpentry and ketamine': 20,
      'cesarean rush': 20,
      'stork in a hurricane': 20,
      'brain bleed rush': 10,
      'vascular clamp': 10,
      'unstoppable force': 300,
      'master of chaos': 10,
      'universal defender': 10,
      'the ultimate iron man': 1,
      'social life extinction': 50,
      'blink and you missed it': 1,
      'generalist': 1,
      'general surgeon\'s shadow': 25,
      'appendix collector': 25,
      'general mastery': 100,
      'bone mechanic': 1,
      'orthopedic regular': 25,
      'bone master': 100,
      'baby deliverer': 1,
      'the stork\'s assistant': 5,
      'stork\'s assistant': 5,
      'obstetrician\'s ally': 25,
      'labour ward legend': 100,
      'women\'s health': 25,
      'brain trust': 1,
      'neuro anesthetist': 25,
      'skull base expert': 50,
      'heart of the matter': 1,
      'cardio regular': 25,
      'open heart': 50,
      'breathe easy': 25,
      'shared airway guru': 100,
      'shared airway gladiator': 1,
      'the tonsil trap': 10,
      'airway real estate': 25,
      'bleeding tonsil survivor': 1,
      'dry field diplomat': 50,
      'the throat pack paranoia': 75,
      'ent heavyweight': 100,
      'the graft protector': 150,
      'master plumber': 25,
      'plumbing check': 25,
      'plastic fantastic': 25,
      'teddy bear induction': 1,
      'tiny patients, big surgeries': 1,
      'paediatric pro': 25,
      'trauma specialist': 25,
      'eye see you': 25,
      'eye whisperer': 100,
      'the pancake flip': 25,
      'pancake flip': 25,
      'spine aligner': 1,
      'spine specialist': 25,
      'maxillofacial maestro': 25,
      'the whipple endurance': 25,
      'whipple endurance': 25,
      'liver whisperer': 50,
      'liver and pancreas': 25,
      'gut feeling': 25,
      'rearguard action': 50,
      'gland master': 10,
      'dark room duty': 10,
      'pain relief': 10,
      'fertility helper': 5,
      'oncology support': 25,
      'delicate touch': 25,
      'paediatric bone': 10,
      'jack of all trades': 5,
      'polymath': 10,
      'universal specialist': 15,
      'renaissance doctor': 25,
      'niche operator': 10,
      'ortho heavyweight': 250,
      'obgyn heavyweight': 250,
      'neuro heavyweight': 100,
      'cardio heavyweight': 100,
      'spine heavyweight': 100,
      'uro heavyweight': 100,
      'plastics heavyweight': 100,
      'paeds heavyweight': 100,
      'ophthal heavyweight': 100,
      'colorectal pro': 50,
      'upper gi pro': 50,
      'hpb specialist': 50,
      'gas man/woman': 1,
      'volatile regular': 50,
      'inhalational expert': 200,
      'volatile master': 500,
      'white magic': 10,
      'white milk': 1,
      'propofol pro': 25,
      'tiva specialist': 50,
      'total intravenous master': 100,
      'the overachiever': 1,
      'overachiever': 1,
      'half and half': 1,
      'cse regular': 10,
      'cse expert': 25,
      'spinal pioneer': 1,
      'sab regular': 50,
      'spinal master': 150,
      'epidural explorer': 1,
      'epidural regular': 25,
      'epidural expert': 50,
      'epidural master': 100,
      'mac daddy': 1,
      'smooth sedation': 25,
      'sedation master': 50,
      'local hero': 1,
      'standby mode': 20,
      'peripheral primary': 1,
      'nerve block specialist': 25,
      'tci tech': 1,
      'target controlled': 25,
      'tci master': 50,
      'versatile anaesthetist': 7,
      'awake regional': 1,
      'deep sleep 100': 100,
      'deep sleep 250': 250,
      'deep sleep 500': 500,
      'regional purist': 100,
      'tiva innovator': 100,
      'spinal king': 300,
      'epidural queen': 100,
      'mac specialist': 100,
      'tube is in': 1,
      'tube beginner': 10,
      'tube regular': 50,
      'master of the tube': 100,
      'ett veteran': 250,
      'ett grandmaster': 500,
      'mask on': 1,
      'lma beginner': 10,
      'lma regular': 50,
      'lma enthusiast': 100,
      'lma veteran': 250,
      'bare minimum': 1,
      'just bagging': 20,
      'surgical airway': 1,
      'trach team': 5,
      'high pressure': 1,
      'lung isolation': 1,
      'thoracic airway': 20,
      'dlt expert': 50,
      'bronchial blocker': 1,
      'blocker pro': 10,
      'classic touch': 20,
      'proseal pro': 20,
      'gel fit': 20,
      'supreme leader': 20,
      'ambu airway': 10,
      'fast and flexible': 10,
      'nose knows best': 1,
      'nasal navigator': 20,
      'nasal expert': 50,
      'below the chin': 1,
      'screen time': 1,
      'video beginner': 10,
      'video star': 50,
      'video master': 100,
      'awake and aware': 1,
      'awake fos pro': 5,
      'awake master': 15,
      'asleep fiberoptic': 1,
      'asleep fos pro': 10,
      'fiberoptic master': 25,
      'micro manager': 10,
      'bending the rules': 20,
      'blind spot': 1,
      'grade 3 collector': 10,
      'in the dark': 1,
      'grade 4 survivor': 5,
      'the sweat gland': 1,
      'sweat gland': 1,
      'airway apprentice': 5,
      'airway journeyman': 10,
      'airway expert': 25,
      'the lord of the cords': 50,
      'lord of the cords': 50,
      'airway ninja': 50,
      'first pass success': 1,
      'clean pass': 10,
      'third time\'s a charm': 1,
      'third times a charm': 1,
      'multi-attempt warrior': 1,
      'lma performed': 50,
      'intubation performed': 200,
      'assisted airway': 50,
      'observed airway': 50,
      'paediatric tube': 1,
      'giant tube': 1,
      'uncuffed care': 1,
      'cuffed standard': 100,
      'cormack grade 1': 200,
      'cormack grade 2': 50,
      'awake fiberoptic performer': 10,
      'the sneaky scope': 20,
      'sneaky scope': 20,
      'asleep fiberoptic performer': 20,
      'emergency airway ace': 1,
      'airway scholar': 500,
      'airway legend': 1,
      'liquid gold': 1,
      'spinal beginner': 10,
      'spinal regular': 50,
      'subarachnoid specialist': 100,
      'spinal elite': 250,
      'nerve block novice': 1,
      'block beginner': 10,
      'block regular': 25,
      'block boss': 50,
      'block expert': 100,
      'block master': 200,
      'sound waves': 1,
      'usg beginner': 25,
      'echogenic needle': 50,
      'ultrasonic pro': 100,
      'ultrasound master': 250,
      'twitcher': 1,
      'stimulator pro': 25,
      'continuous relief': 1,
      'catheter champion': 10,
      'continuous infusion pro': 25,
      'brachial plexus pro': 1,
      'upper limb legend': 20,
      'lower limb legend': 1,
      'leg day': 20,
      'core control': 1,
      'trunk tracker': 20,
      'chest wall relief': 1,
      'paravertebral pro': 10,
      'neck and head': 1,
      'paediatric block': 10,
      'ankle biter': 10,
      'old school': 1,
      'plexus master': 5,
      'block collector': 10,
      'block connoisseur': 20,
      'interscalene specialist': 15,
      'supraclavicular specialist': 25,
      'infraclavicular specialist': 15,
      'axillary specialist': 15,
      'femoral specialist': 20,
      'adductor canal': 20,
      'sciatic specialist': 20,
      'popliteal specialist': 15,
      'tap block master': 30,
      'rectus sheath master': 15,
      'ql block master': 15,
      'esp block master': 15,
      'pecs master': 15,
      'serratus master': 10,
      'cervical plexus': 10,
      'scalp blockade': 10,
      'caudal epidural': 25,
      'bier block pro': 5,
      'multi-block artist': 1,
      'the regional god': 500,
      'seeing red': 1,
      'art line beginner': 10,
      'art line regular': 25,
      'art line ace': 50,
      '100 beats per minute': 100,
      'central access': 1,
      'dilator discipline': 5,
      'cvc regular': 15,
      'the lumen lord': 25,
      "seldinger's true heir": 50,
      'x-ray vision': 1,
      'ultrasound aficionado': 25,
      'sonographic virtuoso': 75,
      'brain waves': 1,
      'target 40 to 60': 25,
      'numbers over vibes': 50,
      'the cortical bouncer': 100,
      'infrared vision': 10,
      'advanced brain': 10,
      'heart watcher': 5,
      'go with the flow': 5,
      'this is spinal tap!': 5,
      'the cockpit crew': 1,
      'nasa mission control': 1,
      'line collector': 5,
      'master of the mediastinum': 30,
      'arterial line assist': 20,
      'guidewire guardian': 20,
      'master of the frontal lobe': 20,
      'tci pump independent': 50,
      'nirs independent': 20,
      'picco independent': 10,
      'tee observer': 10,
      'pa catheter observer': 10,
      'subarachnoid drain pro': 10,
      'the omniscient anaesthetist': 10,
      'the micro-manager': 1,
      'the micromanager': 1,
      'micro-manager': 1,
      'micromanager': 1,
      'tiny patient': 1,
      'nicu regular': 5,
      'neonatal guardian': 15,
      'the pediatrician': 1,
      'pediatrician': 1,
      'infant care': 1,
      'infant specialist': 20,
      'the negotiator': 20,
      'negotiator': 20,
      'toddler time': 20,
      'child care': 25,
      'adolescent care': 20,
      'golden years': 1,
      'the fragile cargo': 25,
      'geriatric guardian': 25,
      'elderly protector': 50,
      'senior specialist': 100,
      'octogenarian care': 1,
      'octogenarian club': 10,
      'centenarian': 1,
      'bariatric basics': 1,
      'bariatric regular': 10,
      'bariatric specialist': 20,
      'extreme bmi': 1,
      'super bariatric': 10,
      'the featherweight': 1,
      'lightweight': 1,
      'featherweight': 1,
      'heavyweight': 1,
      'super heavyweight': 1,
      'spectrum of age': 7,
      'spectrum of size': 6,
      'tiny tot surgeon': 50,
      'elderly care leader': 250,
      'bariatric champion': 50,
      'underweight expert': 15,
      'extreme age range': 1,
      'extremes of weight': 1,
      'paediatric airway ace': 1,
      'geriatric airway ace': 1,
              'the clean exit': 1,
        'recovery room favorite': 25,
        'pacu perfection': 100,
        'untouchable record': 250,
        'the zone': 5,
        'untouchable streak': 15,
        'flawless month': 40,
        'defying gravity': 1,
        'brink walker': 10,
        'miracle worker': 1,
        'the impossible standard': 5,
        'calm in the storm': 1,
        'storm rider': 10,
        'eye of the hurricane': 25,
        'flawless airway': 1,
        'airway artisan': 10,
        'airway virtuoso': 25,
        'prudent pause': 1,
        'vigilant observer': 5,
        'watchful protector': 15,
        'smooth handover': 1,
        'intensive care liaison': 10,
        'critical care anchor': 1,
        'the stabilizer': 10,
        'silver lining': 1,
        'smooth sailing': 1,

      'the good luck charm': 10,
      'safe hands': 10,
      "the 'q' word": 25,
      'the q word': 25,
      'flawless week': 25,
      'century of safety': 100,
      'bulletproof streak': 250,
      'quick wakeup': 1,
      'efficiency expert': 50,
      'the bucket list': 1,
      'the exorcist protocol': 1,
      'how low can you go?': 1,
      'the iron lungs': 1,
      "darth vader's chokehold": 1,
      'the deep breath': 1,
      'blue moon rising': 1,
      'safe recovery': 100,
      'the bureaucrat': 1,
      'identity verified': 1,
      'data scientist': 1,
      'the hoarder': 1,
      'paper trail': 1,
      'logbook archivist': 10,
      'safety first': 1,
      'the paranoid': 5,
      'backup fanatic': 5,
      'points on the board': 100,
      'the high scorer': 1000,
      'leveling up': 1000,
      'prestige': 5000,
      'etherlog legend': 10000,
      'mythical practitioner': 25000,
      'logbook ascendant': 50000,
      'the singularity': 100000,
      'shiver starter': 1,
      'shiver handler': 5,
      'thermal debt collector': 15,
      'thermodynamic sorcerer': 30,
      'shiver legend track': 50,
      'blow off some steam, bennett!': 1,
      'hypertension tamer': 5,
      'hypertension regular': 15,
      'the high-pressure architect': 30,
      'hypertension legend': 50,
      "we're gonna need a bigger boat": 1,
      'blood bank vip': 5,
      'bleeding regular': 15,
      "dracula's accountant": 30,
      'bleeding legend': 50,
      'passing the baton': 1,
      'the cold never bothered me anyway': 1,
      'warm bodies': 5,
      'hypothermia regular': 15,
      'hypothermia specialist': 30,
      'hypothermia legend': 50,
      'rhythm check': 1,
      'arrhythmia handler': 5,
      'arrhythmia regular': 15,
      'mozart of the monitor': 30,
      'arrhythmia legend': 50,
      't': 1,
      'flat tire mechanic': 3,
      'the lung whisperer': 5,
      'lord of the pleura': 10,
      'pop goes the pleura': 1,
      'red alert in theatre': 1,
      'transfusion connoisseur': 3,
      "the blood bank's best customer": 5,
      'total body replacement': 10,
      "bad blood (taylor's version)": 1,
      'not on my watch': 3,
      'cross-match critic': 5,
      'hemovigilance officer': 10,
      'trust the checklist': 2,
      'air embolus alert': 1,
      'air bender': 3,
      'the entrapment officer': 5,
      'sub-atmospheric ace': 10,
      'bubble trouble': 1,
      'the gastric redemption': 1,
      'the bronchial lifeguard': 3,
      'acid reflux avenger': 5,
      'the alveolar shield': 10,
      'aspiration avoider energy': 10,
      'failed tube': 1,
      'failed intubation handler': 3,
      'failed intubation regular': 5,
      'failed intubation specialist': 10,
      'mask trouble': 1,
      'not that dmv!': 5,
      'seal of approval': 15,
      'the grip of steel': 30,
      'complication collector': 5,
      'complication connoisseur': 8,
      'complication scholar': 12,
      'crisis catalogue': 20,
      'crisis catalogue 50': 50,
      'boring is beautiful': 1,
      'fire & ice': 2,
      'lethal triad disruptor': 2,
      'wrong hole, wrong place!': 3,
      'complication night': 1,
      'complication in asa4': 1,
      "all's well that ends well": 1,
      'multi complication case': 1,
      'morbidity & mastery': 10,
      'safety net expanded': 30,
      'the transparent intubator': 2,
      'the honest scalpel': 20,
      'no skeletons in the closet': 50,
      'safety expansion 10': 10,
      'safety expansion 25': 25,
      'safety expansion 75': 75,
      'safety expansion 100': 100,
      'post event uneventful': 25,
      'emergency complication': 1,
      'paeds complication': 1,
      'elderly complication': 1,
      'bariatric complication': 1,
      'maxillo complication': 1,
      'ir complication': 1,
      'paeds cardiac complication': 1,
      'boss fight: phase two': 1,
      'cirque du soleil': 1,
      'jaw breaker': 1,
      'dental debut': 5,
      'oral airway ally': 10,
      'maxillo regular': 25,
      'maxillo specialist': 50,
      'face and airway': 100,
      'nasal preferrer': 10,
      'wired quiet': 5,
      'imf night': 1,
      'imf veteran': 30,
      'shared airway ace': 20,
      'ramp ready': 1,
      'bariatric beginner': 5,
      'bariatric list regular': 15,
      'bariatric list specialist': 30,
      'metabolic theatre': 50,
      'bariatric heavyweight': 100,
      'difficult bariatric airway': 1,
      'bariatric uneventful': 20,
      'dark room debut': 1,
      'ir apprentice': 5,
      'fluoro friend': 15,
      'ir regular': 25,
      'ir specialist': 50,
      'cath lab calm': 10,
      'long wire day': 1,
      'emergency ir': 1,
      'paediatric ir': 1,
      'ir night shift': 1,
      'beam me up': 1,
      'radio regular': 5,
      'mask fit mindset': 10,
      'rt specialist': 25,
      'paediatric beam': 1,
      'rt uneventful': 15,
      'repeat sitter': 10,
      'remote monitor': 1,
      'tiny heart': 1,
      'paeds cardiac debut': 3,
      'little circuit': 10,
      'paeds cardiac regular': 20,
      'paeds cardiac specialist': 40,
      'congenital calm': 15,
      'neonatal heart': 1,
      'single ventricle support': 5,
      'paeds cardiac night': 1,
      'bypass buddy jr': 10,
      'dental emergency': 1,
      'bariatric emergency': 1,
      'ir trauma assist': 1,
      'maxillo spine crossover': 1,
      'bariatric and regional': 1,
      'paeds cardiac and nicu': 1,
      'specialty starter pack': 5,
      'new frontier five': 5,
      'dark room and beam': 2,
      'airway adjacent specialist': 50,
      'jaw wire veteran': 30,
      'bariatric airway plan': 20,
      'ir lead fashion': 30,
      'rt stillness master': 40,
      'paeds cardiac mentor energy': 50,
      'maxillo nasal century path': 20,
      'bariatric vl preferrer': 15,
      'ir contrast caution': 20,
      'rt paeds series': 10,
      'congenital series': 25,
      'dental block combo': 1,
      'bariatric art line': 1,
      'ir arterial access': 1,
      'rt mac mindset': 1,
      'paeds cardiac lines': 1,
      'maxillo difficult airway': 1,
      'bariatric desat rescue': 1,
      'ir long case': 1,
      'rt early start': 1,
      'paeds cardiac emergency': 1,
      'specialty polyglot': 8,
      'new specialty regular': 50,
      'maxillo century track': 75,
      'bariatric century track': 75,
      'ir century track': 75,
      'paeds cardiac heavy': 75,
      'rt heavy': 50,
      'mixed frontier 25': 25,
      'mixed frontier 100': 100,
      'oral surgery ally': 40,
      'fascia first': 1,
      'fascia iliaca beginner': 5,
      'fascia regular': 15,
      'fascia specialist': 30,
      'fascia master': 50,
      'fascia usg': 10,
      'fascia catheter': 1,
      'fascia performed': 20,
      'psoas first': 1,
      'psoas beginner': 5,
      'psoas regular': 15,
      'psoas specialist': 30,
      'psoas master': 50,
      'psoas usg': 10,
      'psoas catheter': 1,
      'psoas performed': 20,
      'plane pair': 2,
      'lower limb plane day': 1,
      'nof blocker': 10,
      'deep plane duo': 5,
      'frontier anaesthetist': 50,
      'plane and specialty': 1,
      'ir with art line': 1,
      'bariatric with art line': 1,
      'maxillo with difficult airway flag': 1,
      'rt with uneventful': 10,
      'paeds cardiac uneventful pack': 10,
      'new specialty emergency': 1,
      'block for nof': 1,
      'complication teacher': 10,
      'multi frontier day': 2,
      'plane day list': 3,
      'safety day': 2,
      'bariatric regional hero': 1,
      'dental nasal ace': 5,
      'ir long uneventful': 1,
      'congenital lines ace': 1,
      'fascia performed fifty': 50,
      'psoas performed fifty': 50,
      'all new specialties x5': 5,
      'complication zero week energy': 25,
      'registry explorer': 10,
      'plane explorer': 10,
      'safety explorer': 10,
      'triple explorer': 3,
      'modern logbook': 2,
      'trauma plane pack': 20,
      'night frontier': 1,
      'weekend frontier': 1,
      'paeds frontier': 1,
      'elderly frontier': 1,
      'asa3 frontier': 1,
      'asa4 frontier': 1,
      'emergency plane pack': 10,
      'documentation maximalist': 100,
      'regional maximalist': 100,
      'safety maximalist': 100,
      'etherlog expansionist': 200,
      'complete new set': 3,
      'frontier legend': 200,
      'plane legend': 200,
      'safety legend': 200,
      'balanced expansion': 25,
      'cross pollinator': 3,
      'list diversifier': 15,
      'block diversifier': 15,
      'outcome first': 50,
      'quiet excellence': 100,
      'expansion complete badge': 3,
      'next chapter': 500,
    };

    final ex = explicit[t];
    if (ex != null) return ex;

    int numFromTitle = _extractNumberFromText(t);
    if (numFromTitle > 1) return numFromTitle;
    int numFromDesc = _extractNumberFromText(d);
    if (numFromDesc > 1) return numFromDesc;

    return 1;
  }

  static int _parseAsa(String grade) {
    final g = grade.toUpperCase().trim();
    if (g.contains('V') && !g.contains('IV') && !g.contains('VI')) return 5;
    if (g.contains('IV')) return 4;
    if (g.contains('III')) return 3;
    if (g.contains('II') && !g.contains('III')) return 2;
    if (g.contains('I') &&
        !g.contains('II') &&
        !g.contains('IV') &&
        !g.contains('VI')) return 1;
    if (g.contains('1')) return 1;
    if (g.contains('2')) return 2;
    if (g.contains('3')) return 3;
    if (g.contains('4')) return 4;
    if (g.contains('5')) return 5;
    return 0;
  }

  static int _getStartHour(CaseRecord c) {
    try {
      if (hasValue(c.anaesthesiaStartTime)) {
        final timeStr = c.anaesthesiaStartTime!.toLowerCase();
        final match = RegExp(r'(\d{1,2})').firstMatch(timeStr);
        if (match != null) {
          int hour = int.parse(match.group(1)!);
          if (timeStr.contains('pm') && hour < 12) hour += 12;
          if (timeStr.contains('am') && hour == 12) hour = 0;
          return hour;
        }
      }
    } catch (_) {}
    return c.date.hour;
  }

  static int _getEndHour(CaseRecord c) {
    try {
      if (hasValue(c.anaesthesiaEndTime)) {
        final timeStr = c.anaesthesiaEndTime!.toLowerCase();
        final match = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(timeStr);
        if (match != null) {
          int hour = int.parse(match.group(1)!);
          int min = int.parse(match.group(2)!);
          if (timeStr.contains('pm') && hour < 12) hour += 12;
          if (timeStr.contains('am') && hour == 12) hour = 0;
          return hour * 60 + min;
        }
      }
    } catch (_) {}
    return -1;
  }

  static int? _parseTimeToMinutes(String? timeStr) {
    if (timeStr == null || timeStr.trim().isEmpty) return null;
    try {
      final s = timeStr.trim().toLowerCase();
      final match = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(s);
      if (match != null) {
        int hour = int.parse(match.group(1)!);
        int min = int.parse(match.group(2)!);
        if (s.contains('pm') && hour < 12) hour += 12;
        if (s.contains('am') && hour == 12) hour = 0;
        return hour * 60 + min;
      }
    } catch (_) {}
    return null;
  }

  static bool _isCaseFullySupervised(CaseRecord c) {
    int optionsCount = 0;

    bool isSupervised(String? r) =>
        r != null && r.trim().toLowerCase() == 'supervised';

    // 1. Airway options
    final bool isTubeInSitu =
        (c.methodOfIntubationRole?.toLowerCase().contains('situ') ?? false) ||
        (c.methodOfIntubation?.toLowerCase().contains('situ') ?? false);
    final hasTube = (c.airwayManagement == 'Endotracheal Tube (ETT)' ||
            c.airwayManagement == 'Double lumen tube (DLT)' ||
            c.airwayManagement == 'Bronchial blocker' ||
            (c.methodOfIntubation != null &&
                c.methodOfIntubation!.trim().isNotEmpty) ||
            (c.methodOfIntubationRole != null &&
                c.methodOfIntubationRole!.trim().isNotEmpty)) &&
        !isTubeInSitu;

    if (hasTube) {
      optionsCount++;
      if (!isSupervised(c.methodOfIntubationRole)) {
        return false;
      }
    }

    final bool isLmaInSitu =
        c.lmaRole?.toLowerCase().contains('situ') ?? false;
    final hasLma = (c.airwayManagement == 'Laryngeal Mask Airway (LMA)' ||
            (c.lmaType != null && c.lmaType!.trim().isNotEmpty) ||
            (c.lmaRole != null && c.lmaRole!.trim().isNotEmpty)) &&
        !isLmaInSitu;

    if (hasLma) {
      optionsCount++;
      if (!isSupervised(c.lmaRole)) {
        return false;
      }
    }

    // 2. Regional Anaesthesia options
    for (final b in c.regionalBlocks) {
      final name = b['name']?.toString().trim() ?? '';
      final role = b['role']?.toString().trim().toLowerCase() ?? '';
      if (name.isEmpty ||
          name == 'None / Not performed' ||
          name == 'None' ||
          role.contains('situ')) {
        continue;
      }
      optionsCount++;
      final bRole = b['role']?.toString();
      if (!isSupervised(bRole)) {
        return false;
      }
    }

    // 3. Invasive Lines & Monitoring options
    for (final m in c.invasiveMonitoring) {
      final name = m['name']?.toString().trim() ?? '';
      final role = m['role']?.toString().trim().toLowerCase() ?? '';
      if (name.isEmpty || name == 'None' || role.contains('situ')) continue;
      optionsCount++;
      final mRole = m['role']?.toString();
      if (!isSupervised(mRole)) {
        return false;
      }
    }

    return optionsCount > 0;
  }

  static IconData _getIconForCategory(String cat) {
    switch (cat) {
      case 'Volume':
        return Icons.military_tech;
      case 'Time':
        return Icons.timer;
      case 'Risk':
        return Icons.shield;
      case 'Emergency':
        return Icons.flash_on;
      case 'Specialties':
        return Icons.local_hospital;
      case 'Subspecialties':
        return Icons.local_hospital; // legacy
      case 'Techniques':
        return Icons.science;
      case 'Airway':
        return Icons.air;
      case 'Regional':
        return Icons.colorize;
      case 'Monitoring':
        return Icons.monitor_heart;
      case 'Demographics':
        return Icons.child_care;
      case 'Safety':
        return Icons.verified_user;
      case 'Complications':
        return Icons.warning_amber;
      case 'Power User':
        return Icons.bolt;
      case 'Post-Op & ERAS':
        return Icons.hotel;
      case 'Mentorship':
        return Icons.supervised_user_circle;
      case 'Portfolio':
        return Icons.auto_stories;
      case 'PAC Clinic':
        return Icons.fact_check_outlined;
      default:
        return Icons.star;
    }
  }

  static Color _getTierColor(int target, String title) {
    final t = title.toLowerCase();

    if (target >= 500 ||
        t.contains('grandmaster') ||
        t.contains('ultimate') ||
        t.contains('king') ||
        t.contains('queen')) {
      return const Color(0xFFFFD700);
    }
    if (target >= 250 || t.contains('veteran')) {
      return const Color(0xFFEC407A);
    }
    if (target >= 100 || t.contains('master') || t.contains('heavyweight')) {
      return const Color(0xFFAB47BC);
    }
    if (target == 50 || t.contains('regular') || t.contains('expert')) {
      return const Color(0xFF42A5F5);
    }
    if (target == 25 || t.contains('champion')) {
      return const Color(0xFF26A69A);
    }
    if (target == 20 || target == 15) {
      return const Color(0xFF9CCC65);
    }
    if (target == 10 || t.contains('beginner') || t.contains('apprentice')) {
      return const Color(0xFFFFCA28);
    }
    if (target == 7 || target == 6) {
      return const Color(0xFFFF7043);
    }
    if (target == 5) {
      return const Color(0xFF8D6E63);
    }
    return const Color(0xFF90A4AE);
  }

  static int getAirwayMatchingCasesCount(
      List<CaseRecord> cases, List<String> keywords) {
    int count = 0;
    for (var c in cases) {
      final intubRole = c.methodOfIntubationRole?.toLowerCase() ?? '';
      final method = c.methodOfIntubation?.toLowerCase() ?? '';
      final lmaRole = c.lmaRole?.toLowerCase() ?? '';
      if (intubRole.contains('situ') ||
          method.contains('situ') ||
          lmaRole.contains('situ')) {
        continue;
      }
      String airway = c.airwayManagement?.toLowerCase() ?? '';
      String type = c.typeOfIntubation?.toLowerCase() ?? '';
      String cormack = c.cormackLehane?.toLowerCase() ?? '';
      String ett = c.ettType?.toLowerCase() ?? '';
      String lma = c.lmaType?.toLowerCase() ?? '';
      String notes = c.notes?.toLowerCase() ?? '';
      String proc = c.procedure.toLowerCase();
      String tech = c.technique.toLowerCase();
      String spec = c.specialty.toLowerCase();
      String specOther = c.specialtyOther?.toLowerCase() ?? '';
      String comps = c.complications.map((e) => e.toLowerCase()).join(' ');

      String combined =
          '$airway $method $type $cormack $ett $lma $notes $proc $tech $spec $specOther $comps';

      bool matched = false;
      for (var kw in keywords) {
        if (combined.contains(kw.toLowerCase())) {
          matched = true;
          break;
        }
      }
      if (matched) count++;
    }
    return count;
  }

  static int _getLmaBrandMatchCount(
      List<CaseRecord> cases, List<String> keywords) {
    int count = 0;
    for (var c in cases) {
      final lmaRole = c.lmaRole?.toLowerCase() ?? '';
      if (lmaRole.contains('situ')) continue;
      String airway = c.airwayManagement?.toLowerCase() ?? '';
      String lma = c.lmaType?.toLowerCase() ?? '';
      String notes = c.notes?.toLowerCase() ?? '';

      bool isLmaCase = airway.contains('lma') ||
          airway.contains('laryngeal') ||
          airway.contains('mask') ||
          airway.contains('supraglottic') ||
          lma.isNotEmpty ||
          notes.contains('lma') ||
          notes.contains('i-gel') ||
          notes.contains('igel');

      if (!isLmaCase) continue;

      String combined = '$lma $airway $notes'
          .replaceAll('-', '')
          .replaceAll('_', '')
          .replaceAll(' ', '');

      bool matched = false;
      for (var kw in keywords) {
        String cleanKw = kw
            .toLowerCase()
            .replaceAll('-', '')
            .replaceAll('_', '')
            .replaceAll(' ', '');
        if (combined.contains(cleanKw)) {
          matched = true;
          break;
        }
      }
      if (matched) count++;
    }
    return count;
  }

  static int _getIntubationOptionCount(
      List<CaseRecord> cases, String targetOption) {
    int count = 0;
    final target = targetOption.toLowerCase();
    for (var c in cases) {
      final intubRole = c.methodOfIntubationRole?.toLowerCase() ?? '';
      final method = c.methodOfIntubation?.toLowerCase() ?? '';
      if (intubRole.contains('situ') || method.contains('situ')) continue;
      bool matched = false;
      final airway = c.airwayManagement?.toLowerCase() ?? '';
      final type = c.typeOfIntubation?.toLowerCase() ?? '';
      final notes = c.notes?.toLowerCase() ?? '';

      if (airway.contains(target) ||
          method.contains(target) ||
          type.contains(target) ||
          notes.contains(target)) {
        matched = true;
      }
      if (matched) count++;
    }
    return count;
  }

  static AchievementTier _resolveTier({
    required String title,
    required String desc,
    required int target,
    String? explicit,
  }) {
    if (explicit != null && explicit.trim().isNotEmpty) {
      return AchievementTierX.fromName(explicit);
    }
    var tier = AchievementTierX.fromTarget(target);
    final blob = ('$title $desc').toLowerCase();
    int bump = 0;
    if (blob.contains('emergency') ||
        blob.contains('trauma') ||
        blob.contains('crash')) {
      bump++;
    }
    if (blob.contains('asa 4') ||
        blob.contains('asa 5') ||
        blob.contains('asa iv') ||
        blob.contains('asa v') ||
        blob.contains('asa4') ||
        blob.contains('asa5')) {
      bump++;
    }
    if (blob.contains('difficult airway') ||
        blob.contains('awake fiberoptic') ||
        blob.contains('awake fos') ||
        blob.contains('fiberoptic')) {
      bump++;
    }
    if (blob.contains('neonate') ||
        blob.contains('cardiac arrest') ||
        blob.contains('code blue')) {
      bump++;
    }
    final tLower = title.toLowerCase();
    final cumulativeTimeTitles = [
      'quick nap',
      'deep sleep',
      'time keeps ticking',
      'shift work',
      'full day',
      'two days asleep',
      'weekly grind',
      'three days asleep',
      'century of sleep',
      '150 hours',
      '200 hours',
      '300 hours',
      'the or inhabitant',
      'the half-thousand club',
      '750 hours',
      '1,000 hour club',
      '2,500 hour milestone',
      'the half-myriad master',
      '10,000 hour virtuoso',
      'quarter-century veteran',
      'the eternal gas titan',
    ];
    if (cumulativeTimeTitles.contains(tLower)) {
      bump -= 2;
    }
    final pointsTitles = [
      'points on the board',
      'the high scorer',
      'leveling up',
      'prestige',
      'etherlog legend',
      'mythical practitioner',
      'logbook ascendant',
      'the singularity'
    ];
    if (pointsTitles.contains(tLower)) {
      bump -= 1;
    }
    if (bump != 0) {
      tier = tier.bump(bump);
    }

    return tier;
  }

  static Future<List<Achievement>> getAllAchievements(
      List<CaseRecord> cases) async {
    int pdfExportCount = 0;
    int jsonBackupCount = 0;
    try {
      final prefs = await SharedPreferences.getInstance();
      pdfExportCount = prefs.getInt('pdf_export_count') ?? 0;
      jsonBackupCount = prefs.getInt('json_backup_count') ?? 0;
    } catch (_) {}

    List<PacRecord> pacRecords = [];
    try {
      pacRecords = await PacStorage.getAllPacRecords();
    } catch (_) {}
    int totalPacPatients =
        pacRecords.fold<int>(0, (sum, r) => sum + r.patientCount);
    int maxPacSingleDay = pacRecords.isEmpty
        ? 0
        : pacRecords.map((r) => r.patientCount).reduce((a, b) => a > b ? a : b);
    int totalPacDays = pacRecords.length;

    List<Achievement> achievements = [];

    int totalCases = cases.length;
    int totalMins = 0;

    int nightOwlCount = 0;
    int earlyBirdCount = 0;
    int weekendCount = 0;
    int inAndOutCount = 0;
    int longHaul = 0, marathon = 0, ultra = 0, endless = 0;
    int quickRecoveryCount = 0;
    int holidayCount = 0, newYearsCount = 0, birthdayShiftCount = 0;
    int sunriseExtubationCount = 0;
    int amberAlertCount = 0;
    int greenZoneCruiserCount = 0;
    int redRingAwakeningCount = 0;
    Map<DateTime, int> weekendMinsMap = {};
    Map<DateTime, int> dailyMinsMap = {};
    int irWithArtLineCount = 0,
        bariatricWithArtLineCount = 0,
        maxilloDifficultAirwayCount = 0;
    int uneventfulCount = 0;

    int maxConsecutiveASA12 = 0;
    int consecutiveASA12 = 0;
    Map<int, int> asaCounts = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    Map<DateTime, int> acuityDayMap = {};
    int riskManagerCount = 0,
        fearlessCount = 0,
        resilientSystemCount = 0,
        safeHandsHighRisk = 0,
        criticalTransferCount = 0,
        defyingOddsCount = 0;

    int emergencyCount = 0;
    int doubleTroubleCount = 0,
        consecutiveEmergency = 0,
        traumaBayRegularMax = 0,
        nightmareScenarioCount = 0,
        calmUnderPressureCount = 0;
    int emergencyRegionalCount = 0,
        emergencyBlockMasterCount = 0,
        fastAndFuriousCount = 0,
        emergencyAwakeCount = 0,
        midnightEmergencyCount = 0;
    int holidayEmergencyCount = 0,
        weekendTraumaCount = 0,
        airwayRescueCount = 0,
        stableInChaosCount = 0,
        emergencyPediatricCount = 0,
        emergencyGeriatricCount = 0,
        savedByTheBellCount = 0,
        ironConstitutionCount = 0;
    int emergencySpineCount = 0,
        emergencyHeartCount = 0,
        emergencyBabyCount = 0,
        emergencyBrainCount = 0,
        traumaTeamLeaderCount = 0,
        acuteAbdomenCount = 0,
        boneFractureRushCount = 0,
        cesareanRushCount = 0,
        brainBleedRushCount = 0,
        vascularClampCount = 0,
        zeroDramaCount = 0;
    Map<DateTime, int> emergencyDayMap = {};
    List<DateTime> emergencyTimestamps = [];
    Set<String> emergencySpecialties = {};

    Map<String, int> specialtyCounts = {};
    Set<String> allUsedSpecialties = {};
    int otherSpecialtyCount = 0;
    int painInterventionSpecialtyCount = 0;

    int gaCount = 0,
        tivaCount = 0,
        cseCount = 0,
        spinalCount = 0,
        epiduralCount = 0,
        macCount = 0,
        localOnlyCount = 0,
        pnbCount = 0,
        tciCount = 0;
    int awakeRegionalCount = 0, regionalPuristCount = 0, gaOrTivaCount = 0;
    Set<String> uniqueTechniques = {};

    int difficultAirwayCount = 0, emergencyAirwayCount = 0;
    int ettCount = 0,
        lmaCount = 0,
        facemaskOnlyCount = 0,
        tracheostomyCount = 0,
        jetVentilationCount = 0,
        dltCount = 0,
        bronchialBlockerCount = 0;
    int awakeFosCount = 0, asleepFosCount = 0;
    int cormack1Count = 0,
        cormack2Count = 0,
        cormack3Count = 0,
        cormack4Count = 0;
    int firstPassSuccessCount = 0;
    int multiAttemptWarriorCount = 0;
    int pediatricDifficultAirwayCount = 0;
    int geriatricDifficultAirwayCount = 0;
    int paediatricTubeCount = 0;
    int giantTubeCount = 0;
    int nasalIntubationCount = 0;
    int uncuffedEttCount = 0;
    int cuffedStandardCount = 0;
    int assistedAirwayCount = 0;
    int observedAirwayCount = 0;
    int airwayScholarCount = 0;

    int usgRegionalCount = 0,
        nerveStimulatorCount = 0,
        catheterCount = 0,
        multiBlockCaseCount = 0;
    int spinalBlockCount = 0, epiduralBlockCount = 0, peripheralBlockCount = 0;
    int interscaleneCount = 0,
        supraclavicularCount = 0,
        infraclavicularCount = 0,
        axillaryCount = 0;
    int femoralCount = 0,
        adductorCanalCount = 0,
        sciaticCount = 0,
        poplitealCount = 0;
    int tapCount = 0,
        rectusSheathCount = 0,
        qlCount = 0,
        espCount = 0,
        pecsCount = 0,
        serratusCount = 0,
        paravertebralCount = 0;
    int cervicalPlexusCount = 0,
        scalpBlockCount = 0,
        caudalCount = 0,
        ankleBlockCount = 0,
        bierBlockCount = 0,
        plexusMasterCount = 0;
    Set<String> uniqueRegionalTypes = {};
    int epiduralQueenCount = 0;

    int artLineCount = 0,
        cvcCount = 0,
        usgVascularCount = 0,
        bisEntropyCount = 0,
        nirsCount = 0,
        sedLineCount = 0;
    int teeCount = 0,
        paCatheterCount = 0,
        teePaCatheterCount = 0,
        piccoCount = 0,
        cardiacOutputCount = 0,
        lumbarDrainCount = 0;
    int multiMonitor3Count = 0,
        multiMonitor4Count = 0,
        tciPumpMonitoringCount = 0;
    int artLineAssistCount = 0, cvcAssistCount = 0;
    int teeObserverCount = 0, paCatheterObserverCount = 0;
    Set<String> uniqueMonitors = {};

    int neonateCount = 0,
        infantCount = 0,
        toddlerCount = 0,
        childCount = 0,
        adolescentCount = 0,
        pediatricTotalCount = 0;
    int elderlyCount = 0, octogenarianCount = 0, centenarianCount = 0;
    int bariatric1Count = 0,
        bariatric2Count = 0,
        bariatric3Count = 0,
        underweightCount = 0;
    int underweightAdultCount = 0,
        heavyweightCount = 0,
        superHeavyweightCount = 0;
    Set<String> ageBandsUsed = {};
    Set<String> bmiBandsUsed = {};
    List<DateTime> underweightDates = [];
    List<DateTime> superObeseDates = [];

    int consecutiveUneventful = 0, maxConsecutiveUneventful = 0;
    int quickWakeupCount = 0,
        ponvCount = 0,
        hypotensionCount = 0,
        bronchospasmCount = 0;
    int desaturationCount = 0, pacuDischargeCount = 0, perfectOutcomeCount = 0;
    int consecutivePerfectOutcomeCount = 0,
        maxConsecutivePerfectOutcomeCount = 0;
    int asa4PerfectCount = 0, asa5PerfectCount = 0, emergencyPerfectCount = 0;
    int difficultAirwayPerfectCount = 0, extendedMonitoringCount = 0;
    int hduCleanCount = 0, icuCleanCount = 0, geriatricPerfectCount = 0;

    int shiveringCount = 0, hypertensionCompCount = 0, bleedingCompCount = 0;
    int hypothermiaCompCount = 0,
        arrhythmiaCompCount = 0,
        pneumothoraxCount = 0;
    int massiveBloodLossCount = 0, transfusionReactionCount = 0, vaeCount = 0;
    int aspirationCount = 0, failedIntubationCompCount = 0, dmvCount = 0;
    int positionCompCount = 0, highSpinalCompCount = 0;
    int newComplicationEventTotal = 0;
    Set<String> newCompTypesSeen = {};
    int multiCompCaseCount = 0;
    int compoundAirwayEventCount = 0;
    int multiComp3CaseCount = 0;
    int newCompNightCount = 0, newCompAsa4Count = 0, newCompUneventfulExit = 0;
    int newCompEmergencyCount = 0,
        newCompPaedsCount = 0,
        newCompElderlyCount = 0;
    int newCompBariatricCount = 0,
        newCompMaxilloCount = 0,
        newCompIrCount = 0,
        newCompPaedsCardiacCount = 0;

    int fasciaIliacaCount = 0, psoasPlaneCount = 0;
    int fasciaUsgCount = 0, psoasUsgCount = 0;
    int fasciaCatheterCount = 0, psoasCatheterCount = 0;
    int fasciaPerformedCount = 0, psoasPerformedCount = 0;
    int fasciaAssistedCount = 0, psoasAssistedCount = 0;
    int planeEmergencyCount = 0, planeElderlyCount = 0, planeTraumaCount = 0;
    int planeWithSpinalCount = 0, multiPlaneDayMax = 0;

    int dentalMaxilloCount = 0,
        bariatricSurgCount = 0,
        irCount = 0,
        radiotherapyCount = 0,
        paedsCardiacCount = 0;
    int newSpecialtyCombined = 0;
    int dentalNasalCount = 0,
        dentalBlockComboCount = 0,
        dentalEmergencyCount = 0,
        dentalEmergencyNightCount = 0,
        maxilloUneventfulCount = 0,
        bariatricDifficultAirway = 0,
        bariatricUneventful = 0,
        bariatricEmergencyCount = 0,
        bariatricRegionalCount = 0,
        bariatricVlCount = 0,
        bariatricDesatCount = 0;
    int irUneventful = 0,
        irLongCase = 0,
        ir4hCase = 0,
        irTraumaCount = 0,
        rtUneventful = 0,
        rtEarlyStartCount = 0,
        rtMacCount = 0,
        paediatricRtCount = 0,
        paedsCardiacUneventful = 0,
        paedsCardiacEmergencyCount = 0,
        paedsCardiacNightCount = 0,
        paedsCardiacLinesCount = 0,
        paedsCardiacNeonateCount = 0;
    int newSpecialtyEmergencyCount = 0;

    int completedFollowUps = 0;
    int zeroPonvCount = 0;
    int lowRestPainCount = 0;
    int catheterPlacedCount = 0;
    int blockAssessmentCount = 0;
    int sensoryBlockDenseCount = 0;
    int motorBlockResolvedCount = 0;
    int zeroNerveDeficitCount = 0;
    int erasTrailblazerCount = 0;

    int supervisedTraineeCount = 0;
    int supervisedEmergencyCount = 0;
    int supervisedAsa4Count = 0;
    int supervisedDifficultAirwayCount = 0;
    int supervisedFiberopticCount = 0;
    int supervisedPaedsCount = 0;
    int supervisedNeonateCount = 0;
    int supervisedInvasiveLinesCount = 0;
    int supervisedRegionalBlocksCount = 0;
    int starredCount = 0;

    int caseSheetPhotoCount = 0;
    int cormackLehaneDocumentedCount = 0;
    int hardwareScribeCount = 0;
    int detailedNotesCount = 0;
    Set<String> newSpecialtySet = {};

    int darkRoomDutyCount = 0;
    int emergencyIrCount = 0;
    int paediatricIrCount = 0;
    int irNightShiftCount = 0;

    final doctorProfile = await ProfileStorage.getProfile();
    final DateTime? doctorDob = doctorProfile.dateOfBirth;

    var sortedCases = List<CaseRecord>.from(cases)
      ..sort((a, b) => a.date.compareTo(b.date));

    for (var c in sortedCases) {
      int anaesM = _getCaseAnaesthesiaMinutes(c);
      int surgM = _parseMinutes(c.surgeryDuration);
      totalMins += anaesM;
      int asaVal = _parseAsa(c.asaGrade);

      // Section A: Post-Op & ERAS
      if (c.followUpStatus == 'completed') {
        completedFollowUps++;
      }
      if (c.ponv == 'None') {
        zeroPonvCount++;
      }
      if (c.restPainScore != null && c.restPainScore! <= 2) {
        lowRestPainCount++;
      }
      if (c.catheterPlaced) {
        catheterPlacedCount++;
      }
      if (c.blockAssessmentTags.isNotEmpty) {
        blockAssessmentCount++;
      }
      if (c.blockAssessmentTags.contains('Sensory block dense')) {
        sensoryBlockDenseCount++;
      }
      if (c.blockAssessmentTags.contains('Motor block resolved')) {
        motorBlockResolvedCount++;
      }
      bool hasActiveRegional = c.regionalBlocks.any((r) {
        final role = r['role']?.toString().toLowerCase() ?? '';
        final name = r['name']?.toString() ?? '';
        return name.isNotEmpty &&
            name != 'None' &&
            name != 'None / Not performed' &&
            !role.contains('situ');
      });
      if (hasActiveRegional && !c.followUpComplications.contains('Nerve injury suspected')) {
        zeroNerveDeficitCount++;
      }
      if (c.restPainScore != null && c.restPainScore! <= 2 && c.ponv == 'None') {
        erasTrailblazerCount++;
      }

      // Section B: Mentorship
      if (_isCaseFullySupervised(c)) {
        supervisedTraineeCount++;

        if (c.priority == 'Emergency') {
          supervisedEmergencyCount++;
        }
        if (c.asaGrade == 'ASA IV' || c.asaGrade == 'ASA V') {
          supervisedAsa4Count++;
        }
        if (c.difficultAirway) {
          supervisedDifficultAirwayCount++;
        }
        if ((c.methodOfIntubation == 'Awake fiberoptic intubation' ||
                c.methodOfIntubation == 'Asleep fiberoptic intubation') &&
            !(c.methodOfIntubationRole?.toLowerCase().contains('situ') ?? false)) {
          supervisedFiberopticCount++;
        }
        if (c.specialty == 'Paediatric Surgery' ||
            (c.patientAge != null &&
                (c.ageUnit == 'days' ||
                    c.ageUnit == 'months' ||
                    (c.ageUnit == 'years' && c.patientAge! < 16)))) {
          supervisedPaedsCount++;
        }
        if (c.patientAge != null &&
            (c.ageUnit == 'days' ||
                (c.ageUnit == 'months' && c.patientAge! <= 12) ||
                (c.ageUnit == 'years' && c.patientAge! <= 1))) {
          supervisedNeonateCount++;
        }
        for (final m in c.invasiveMonitoring) {
          final name = m['name']?.toString().trim() ?? '';
          final r = m['role']?.toString().trim().toLowerCase() ?? '';
          if (name.isNotEmpty && name != 'None' && !r.contains('situ')) {
            supervisedInvasiveLinesCount++;
          }
        }
        for (final b in c.regionalBlocks) {
          final name = b['name']?.toString().trim() ?? '';
          final r = b['role']?.toString().trim().toLowerCase() ?? '';
          if (name.isNotEmpty &&
              name != 'None / Not performed' &&
              name != 'None' &&
              !r.contains('situ')) {
            supervisedRegionalBlocksCount++;
          }
        }
      }
      if (c.starred) {
        starredCount++;
      }

      // Section C: Portfolio
      if (c.caseSheetImagePath != null && c.caseSheetImagePath!.trim().isNotEmpty) {
        caseSheetPhotoCount++;
      }
      if (c.cormackLehane != null && c.cormackLehane!.trim().isNotEmpty && c.cormackLehane != 'None') {
        cormackLehaneDocumentedCount++;
      }
      if ((c.ettSize != null && c.ettSize! > 0) || (c.lmaSize != null && c.lmaSize! > 0)) {
        hardwareScribeCount++;
      }
      if (c.notes != null && c.notes!.trim().length >= 30) {
        detailedNotesCount++;
      }

      if (asaVal >= 1 && asaVal <= 5) {
        asaCounts[asaVal] = asaCounts[asaVal]! + 1;
      }

      bool hasCompEarly(String keyword) {
        return c.complications
            .any((comp) => comp.toLowerCase().contains(keyword.toLowerCase()));
      }

      final isUneventfulEarly =
          hasCompEarly('none') || hasCompEarly('uneventful');
      if ((asaVal == 1 || asaVal == 2) && isUneventfulEarly) {
        consecutiveASA12++;
        if (consecutiveASA12 > maxConsecutiveASA12)
          maxConsecutiveASA12 = consecutiveASA12;
      } else {
        consecutiveASA12 = 0;
      }

      bool hasComp(String keyword) {
        return c.complications
            .any((comp) => comp.toLowerCase().contains(keyword.toLowerCase()));
      }

      bool isNoneUneventful = hasComp('none') || hasComp('uneventful');
      if (isNoneUneventful) {
        uneventfulCount++;
        consecutiveUneventful++;
        if (consecutiveUneventful > maxConsecutiveUneventful)
          maxConsecutiveUneventful = consecutiveUneventful;
      } else {
        consecutiveUneventful = 0;
      }

      if (c.outcome == 'Uneventful PACU discharge') {
        pacuDischargeCount++;
        if (isNoneUneventful) {
          perfectOutcomeCount++;
          consecutivePerfectOutcomeCount++;
          if (consecutivePerfectOutcomeCount >
              maxConsecutivePerfectOutcomeCount) {
            maxConsecutivePerfectOutcomeCount = consecutivePerfectOutcomeCount;
          }
          if (asaVal == 4) asa4PerfectCount++;
          if (asaVal == 5) asa5PerfectCount++;
          if (hasValue(c.priority) && c.priority == 'Emergency')
            emergencyPerfectCount++;
          if (c.difficultAirway) difficultAirwayPerfectCount++;
                      bool localHasAge = c.patientAge != null;
            double localAgeY = -1;
            if (localHasAge) {
              final u = c.ageUnit.toLowerCase() ?? 'years';
              if (u.contains('month')) localAgeY = c.patientAge! / 12;
              else if (u.contains('week')) localAgeY = c.patientAge! / 52;
              else if (u.contains('day')) localAgeY = c.patientAge! / 365;
              else localAgeY = c.patientAge!;
            }
            if (localHasAge && localAgeY >= 80) geriatricPerfectCount++;
    
        }
      } else {
        consecutivePerfectOutcomeCount = 0;
      }

      if (c.outcome == 'PACU extended monitoring') extendedMonitoringCount++;
      if (c.outcome == 'HDU transfer' && isNoneUneventful) hduCleanCount++;
      if (c.outcome == 'ICU transfer intubated' && isNoneUneventful)
        icuCleanCount++;

      if (surgM > 0 && (anaesM - surgM).abs() <= 10) quickWakeupCount++;
      if (hasComp('ponv') || hasComp('nausea') || hasComp('vomiting'))
        ponvCount++;
      if (hasComp('hypotension') || hasComp('blood pressure'))
        hypotensionCount++;
      if (hasComp('bronchospasm') || hasComp('laryngospasm'))
        bronchospasmCount++;
      if (hasComp('desaturation') || hasComp('hypoxia')) desaturationCount++;

      bool compShiver = hasComp('shivering') || hasComp('shiver');
      bool compHTN = c.complications.any((comp) {
        final x = comp.toLowerCase();
        return x.contains('hypertension') && !x.contains('hypotension');
      });
      bool compBleed = hasComp('bleeding') ||
          hasComp('haemorrhage') ||
          hasComp('hemorrhage');
      bool compHypotherm = hasComp('hypothermia') || hasComp('hypothermic');
      bool compArrhythmia = hasComp('arrhythmia') ||
          hasComp('dysrhythmia') ||
          hasComp('afib') ||
          hasComp('a-fib') ||
          hasComp('vtach') ||
          hasComp('v tach') ||
          (hasComp('bradycardia') &&
              !hasComp('high spinal') &&
              !hasComp('highspinal'));
      bool compPneumo = hasComp('pneumothorax') || hasComp('pneumo');
      bool compMassive = hasComp('massive blood loss') ||
          hasComp('massive haemorrhage') ||
          hasComp('massive hemorrhage') ||
          hasComp('mtp');
      bool compTxRxn =
          hasComp('transfusion reaction') || hasComp('transfusion rxn');
      bool compVae = hasComp('venous air embolism') ||
          hasComp('air embolism') ||
          hasComp('vae');
      bool compAsp = hasComp('aspiration');
      bool compFailedTube =
          hasComp('failed intubation') || hasComp('failed tube');
      bool compDmv = hasComp('difficult mask') ||
          hasComp('difficult mask ventilation') ||
          hasComp('dmv');
      bool compPosition = hasComp('position') ||
          hasComp('positioning') ||
          hasComp('nerve injury');
      bool compHighSpinal = hasComp('high spinal') ||
          hasComp('highspinal');

      int newCompsThisCase = 0;
      if (compShiver) {
        shiveringCount++;
        newCompTypesSeen.add('shivering');
        newCompsThisCase++;
      }
      if (compHTN) {
        hypertensionCompCount++;
        newCompTypesSeen.add('hypertension');
        newCompsThisCase++;
      }
      if (compBleed) {
        bleedingCompCount++;
        newCompTypesSeen.add('bleeding');
        newCompsThisCase++;
      }
      if (compHypotherm) {
        hypothermiaCompCount++;
        newCompTypesSeen.add('hypothermia');
        newCompsThisCase++;
      }
      if (compArrhythmia) {
        arrhythmiaCompCount++;
        newCompTypesSeen.add('arrhythmia');
        newCompsThisCase++;
      }
      if (compPneumo) {
        pneumothoraxCount++;
        newCompTypesSeen.add('pneumothorax');
        newCompsThisCase++;
      }
      if (compMassive) {
        massiveBloodLossCount++;
        newCompTypesSeen.add('massive');
        newCompsThisCase++;
      }
      if (compTxRxn) {
        transfusionReactionCount++;
        newCompTypesSeen.add('txrxn');
        newCompsThisCase++;
      }
      if (compVae) {
        vaeCount++;
        newCompTypesSeen.add('vae');
        newCompsThisCase++;
      }
      if (compAsp) {
        aspirationCount++;
        newCompTypesSeen.add('aspiration');
        newCompsThisCase++;
      }
      if (compFailedTube) {
        failedIntubationCompCount++;
        newCompTypesSeen.add('failed_tube');
        newCompsThisCase++;
      }
      if (compDmv) {
        dmvCount++;
        newCompTypesSeen.add('dmv');
        newCompsThisCase++;
      }
      if (compPosition) {
        positionCompCount++;
        newCompTypesSeen.add('position');
        newCompsThisCase++;
      }
      if (compHighSpinal) {
        highSpinalCompCount++;
        newCompTypesSeen.add('high_spinal');
        newCompsThisCase++;
      }
      if (newCompsThisCase > 0) {
        newComplicationEventTotal += newCompsThisCase;
        if (newCompsThisCase >= 2) multiCompCaseCount++;
        if (newCompsThisCase >= 3) multiComp3CaseCount++;
        final startH = _getStartHour(c);
        if (startH >= 0 && startH < 5) newCompNightCount++;
        if (isNoneUneventful == false &&
            c.outcome == 'Uneventful PACU discharge') newCompUneventfulExit++;
        if (c.priority == 'Emergency') newCompEmergencyCount++;
        double ageY = -1;
        if (c.patientAge != null) {
          final unit = c.ageUnit.toLowerCase() ?? 'years';
          if (unit.contains('month'))
            ageY = c.patientAge! / 12;
          else if (unit.contains('week'))
            ageY = c.patientAge! / 52;
          else if (unit.contains('day'))
            ageY = c.patientAge! / 365;
          else
            ageY = c.patientAge!;
        }
        if (ageY >= 0 && ageY < 18) newCompPaedsCount++;
        if (ageY >= 65) newCompElderlyCount++;
        final sp = c.specialty.toLowerCase();
        if (sp.contains('bariatric')) newCompBariatricCount++;
        if (sp.contains('dental') ||
            sp.contains('maxillo') ||
            sp.contains('maxillofacial')) newCompMaxilloCount++;
        if (sp.contains('interventional radiology') ||
            sp == 'ir' ||
            sp.contains('interventional radio')) newCompIrCount++;
        if (sp.contains('paediatric cardiac') ||
            sp.contains('pediatric cardiac')) newCompPaedsCardiacCount++;
        if (asaVal >= 4) newCompAsa4Count++;
      }

      bool isDifficult = c.difficultAirway;
      if (isDifficult) difficultAirwayCount++;

      String airwayStr = c.airwayManagement?.toLowerCase() ?? '';
      String methodStr = c.methodOfIntubation?.toLowerCase() ?? '';
      String typeStr = c.typeOfIntubation?.toLowerCase() ?? '';
      String cormackStr = c.cormackLehane?.toLowerCase() ?? '';
      String ettTypeStr = c.ettType?.toLowerCase() ?? '';
      String lmaTypeStr = c.lmaType?.toLowerCase() ?? '';
      String notesStr = c.notes?.toLowerCase() ?? '';
      String procStr = c.procedure.toLowerCase();
      String compsStr = c.complications.map((e) => e.toLowerCase()).join(' ');
      String specialtyStr = c.specialty.toLowerCase();

      bool isDentalMax = specialtyStr.contains('dental') ||
          specialtyStr.contains('maxillo') ||
          specialtyStr.contains('maxillofacial');
      bool isBariatricSurg = specialtyStr.contains('bariatric');
      bool isIR = hasValue(c.specialty) &&
          (specialtyStr.contains('interventional radiology') ||
              specialtyStr == 'ir' ||
              specialtyStr.contains('interventional radio'));
      bool isRT = specialtyStr.contains('radiotherapy') ||
          specialtyStr.contains('radiation therapy');
      bool isPaedsCardiac = specialtyStr.contains('paediatric cardiac') ||
          specialtyStr.contains('pediatric cardiac');

      if (hasValue(c.specialty) &&
          (specialtyStr.contains('mri') ||
              specialtyStr.contains('dsa') ||
              specialtyStr.contains('nora') ||
              specialtyStr.contains('radiology'))) {
        darkRoomDutyCount++;
      }

      double ageYears = -1;
      bool hasAge = c.patientAge != null;
      if (hasAge) {
        final unit = c.ageUnit.toLowerCase() ?? 'years';
        if (unit.contains('month'))
          ageYears = c.patientAge! / 12;
        else if (unit.contains('week'))
          ageYears = c.patientAge! / 52;
        else if (unit.contains('day'))
          ageYears = c.patientAge! / 365;
        else
          ageYears = c.patientAge!;
      }

      int startHour = _getStartHour(c);
      if (isIR) {
        if (hasValue(c.priority) && c.priority == 'Emergency') {
          emergencyIrCount++;
        }
        if (hasAge && ageYears < 18) {
          paediatricIrCount++;
        }
        if (startHour >= 0 && startHour < 5) {
          irNightShiftCount++;
        }
      }

      if (isDentalMax) {
        dentalMaxilloCount++;
        newSpecialtySet.add('dental_maxillo');
        newSpecialtyCombined++;
      }
      if (isBariatricSurg) {
        bariatricSurgCount++;
        newSpecialtySet.add('bariatric');
        newSpecialtyCombined++;
      }
      if (isIR) {
        irCount++;
        newSpecialtySet.add('ir');
        newSpecialtyCombined++;
      }
      if (isRT) {
        radiotherapyCount++;
        newSpecialtySet.add('radiotherapy');
        newSpecialtyCombined++;
      }
      if (isPaedsCardiac) {
        paedsCardiacCount++;
        newSpecialtySet.add('paeds_cardiac');
        newSpecialtyCombined++;
      }
      if ((isDentalMax || isBariatricSurg || isIR || isRT || isPaedsCardiac) &&
          c.priority == 'Emergency') {
        newSpecialtyEmergencyCount++;
      }

      final intubRole = c.methodOfIntubationRole?.toLowerCase() ?? '';
      final lmaRole = c.lmaRole?.toLowerCase() ?? '';
      final bool isIntubInSitu =
          intubRole.contains('situ') || methodStr.contains('situ');
      final bool isLmaInSitu = lmaRole.contains('situ');

      bool isNasalCase = (typeStr.contains('nasal') ||
              airwayStr.contains('nasal') ||
              notesStr.contains('nasal') ||
              methodStr.contains('nasal')) &&
          !isIntubInSitu;
      if (isNasalCase) {
        nasalIntubationCount++;
      }
      if (isDentalMax && isNasalCase) {
        dentalNasalCount++;
      }
      if (isBariatricSurg && c.difficultAirway) bariatricDifficultAirway++;
      if (isBariatricSurg && isNoneUneventful) bariatricUneventful++;
      if (isIR && isNoneUneventful) irUneventful++;
      if (isRT && isNoneUneventful) rtUneventful++;
      if (isPaedsCardiac && isNoneUneventful) paedsCardiacUneventful++;
      if (isIR) {
        final am = _parseMinutes(c.anaesthesiaDuration);
        if (am >= 180) irLongCase++;
      }

      bool caseHasArtLine = false;
      for (var m in c.invasiveMonitoring) {
        String mName = '';
        String mRole = 'performed';
        mName = m['name']?.toString().toLowerCase() ?? '';
        mRole = m['role']?.toString().toLowerCase() ?? 'performed';
        if (mRole.contains('situ')) continue;
        if (mName.contains('arterial') ||
            mName.contains('art line') ||
            mName == 'a-line' ||
            mName.contains('radial art')) {
          caseHasArtLine = true;
          break;
        }
      }
      if (isIR && caseHasArtLine) irWithArtLineCount++;
      if (isBariatricSurg && caseHasArtLine) bariatricWithArtLineCount++;
      if (isDentalMax && c.difficultAirway) maxilloDifficultAirwayCount++;

      String techniqueStr = c.technique.toLowerCase();
      bool caseHasBlock = c.regionalBlocks.any((r) {
        String rName = '';
        String rRole = 'performed';
        rName = r['name']?.toString().toLowerCase().trim() ?? '';
        rRole = r['role']?.toString().toLowerCase().trim() ?? 'performed';
        return rName.isNotEmpty &&
            !rName.contains('none') &&
            rRole != 'assisted' &&
            rRole != 'observed' &&
            !rRole.contains('situ');
      }) ||
      techniqueStr.contains('block') ||
      techniqueStr.contains('pnb') ||
      techniqueStr.contains('regional') ||
      techniqueStr.contains('spinal') ||
      techniqueStr.contains('epidural');

      if (isDentalMax) {
        if (caseHasBlock) dentalBlockComboCount++;
        if (c.priority == 'Emergency') {
          dentalEmergencyCount++;
          if (startHour >= 18 || startHour < 8) {
            dentalEmergencyNightCount++;
          }
        }
        if (isNoneUneventful) maxilloUneventfulCount++;
      }
      if (isBariatricSurg) {
        if (caseHasBlock) bariatricRegionalCount++;
        if (c.priority == 'Emergency') bariatricEmergencyCount++;
        if (methodStr.contains('video') ||
            airwayStr.contains('video') ||
            notesStr.contains('video') ||
            procStr.contains('video')) {
          bariatricVlCount++;
        }
        if (hasComp('desat') || hasComp('hypoxia')) {
          bariatricDesatCount++;
        }
      }
      if (isIR) {
        if (c.priority == 'Emergency' || specialtyStr.contains('trauma') || procStr.contains('trauma') || procStr.contains('embol')) {
          irTraumaCount++;
        }
        final am = _parseMinutes(c.anaesthesiaDuration);
        if (am >= 240) ir4hCase++;
      }
      if (isRT) {
        if (hasAge && ageYears < 18) paediatricRtCount++;
        if (startHour < 7) rtEarlyStartCount++;
        if (techniqueStr.contains('sedation') || techniqueStr.contains('mac')) {
          rtMacCount++;
        }
      }
      if (isPaedsCardiac) {
        if (c.priority == 'Emergency') paedsCardiacEmergencyCount++;
        if (startHour >= 18 || startHour < 8) paedsCardiacNightCount++;
        if (caseHasArtLine) paedsCardiacLinesCount++;
        if (hasAge && (ageYears <= (28.0 / 365.25) || (c.ageUnit.toLowerCase().contains('day') ?? false) || (c.patientAge != null && c.patientAge! <= 28 && (c.ageUnit.toLowerCase().contains('day') ?? false)))) {
          paedsCardiacNeonateCount++;
        }
      }
      String combinedText =
          '$airwayStr $methodStr $typeStr $cormackStr $ettTypeStr $lmaTypeStr $notesStr $procStr $compsStr $specialtyStr $techniqueStr';
      if (compDmv &&
          (c.difficultAirway || combinedText.contains('difficult airway'))) {
        compoundAirwayEventCount++;
      }

      final isOralOrNasalEtt = (airwayStr == 'endotracheal tube (ett)' ||
          airwayStr.contains('ett') ||
          airwayStr.contains('endotracheal') ||
          typeStr.contains('oral') ||
          typeStr.contains('nasal') ||
          ettTypeStr.contains('ett') ||
          ettTypeStr.contains('tube') ||
          ettTypeStr.contains('oral') ||
          ettTypeStr.contains('nasal') ||
          (c.ettSize != null && c.ettSize! > 0)) &&
          !isIntubInSitu;
      if (isOralOrNasalEtt) ettCount++;
      if (airwayStr.contains('tracheostomy') ||
          procStr.contains('tracheostomy')) tracheostomyCount++;
      if (airwayStr.contains('jet')) jetVentilationCount++;
      if ((airwayStr.contains('double lumen') || airwayStr.contains('dlt')) &&
          !isIntubInSitu) {
        dltCount++;
      }
      if (airwayStr.contains('bronchial blocker') && !isIntubInSitu) {
        bronchialBlockerCount++;
      }

      if (airwayStr.contains('lma') && !isLmaInSitu) lmaCount++;
      if (airwayStr.contains('facemask')) facemaskOnlyCount++;

      if (!isIntubInSitu &&
          (methodStr.contains('awake fiberoptic') ||
              combinedText.contains('awake fiberoptic'))) awakeFosCount++;
      if (!isIntubInSitu &&
          (methodStr.contains('asleep fiberoptic') ||
              combinedText.contains('asleep fiberoptic'))) asleepFosCount++;

      // ETT Size Checks for Paediatric and Giant tubes (1 case requirement)
      double? ettSz = c.ettSize;
      bool matchedPaedsSize = false;
      bool matchedGiantSize = false;
      if (!isIntubInSitu) {
        if (ettSz != null) {
          if (ettSz <= 4.0) matchedPaedsSize = true;
          if (ettSz >= 8.5) matchedGiantSize = true;
        } else {
          if (ettTypeStr.contains('3.0') ||
              ettTypeStr.contains('3.5') ||
              ettTypeStr.contains('4.0') ||
              ettTypeStr.contains('2.5') ||
              notesStr.contains('3.0') ||
              notesStr.contains('3.5') ||
              notesStr.contains('4.0') ||
              notesStr.contains('size 3') ||
              notesStr.contains('size 4')) {
            matchedPaedsSize = true;
          }
          if (ettTypeStr.contains('8.5') ||
              ettTypeStr.contains('9.0') ||
              ettTypeStr.contains('9.5') ||
              notesStr.contains('8.5') ||
              notesStr.contains('9.0') ||
              notesStr.contains('size 8.5')) {
            matchedGiantSize = true;
          }
        }
        if (matchedPaedsSize) paediatricTubeCount++;
        if (matchedGiantSize) giantTubeCount++;

        if (ettTypeStr.contains('uncuffed') ||
            airwayStr.contains('uncuffed') ||
            notesStr.contains('uncuffed')) {
          uncuffedEttCount++;
        }
        if (ettTypeStr.contains('cuffed') && !ettTypeStr.contains('uncuffed')) {
          cuffedStandardCount++;
        }
      }

      final genRole = c.role.toLowerCase();
      if ((intubRole.contains('assist') && !isIntubInSitu) ||
          (lmaRole.contains('assist') && !isLmaInSitu) ||
          genRole.contains('assist')) {
        assistedAirwayCount++;
      }
      if ((intubRole.contains('observ') && !isIntubInSitu) ||
          (lmaRole.contains('observ') && !isLmaInSitu) ||
          genRole.contains('observ')) {
        observedAirwayCount++;
      }
      if (c.airwayManagement != null &&
          c.airwayManagement!.isNotEmpty &&
          !isIntubInSitu &&
          !isLmaInSitu) {
        airwayScholarCount++;
      }

      bool isCl1 = cormackStr == '1' ||
          cormackStr.contains('grade 1') ||
          cormackStr.contains('grade i ') ||
          cormackStr.contains('cormack 1') ||
          cormackStr.contains('cl 1') ||
          combinedText.contains('grade 1') ||
          combinedText.contains('cormack 1') ||
          combinedText.contains('grade i ') ||
          combinedText.contains('cl 1');
      bool isCl2 = cormackStr == '2' ||
          cormackStr.contains('grade 2') ||
          cormackStr.contains('grade ii') ||
          cormackStr.contains('cormack 2') ||
          cormackStr.contains('cl 2') ||
          combinedText.contains('grade 2') ||
          combinedText.contains('cormack 2') ||
          combinedText.contains('grade ii') ||
          combinedText.contains('cl 2');
      bool isCl3 = cormackStr == '3' ||
          cormackStr.contains('grade 3') ||
          cormackStr.contains('grade iii') ||
          cormackStr.contains('cormack 3') ||
          cormackStr.contains('cormack-3') ||
          cormackStr.contains('cl 3') ||
          combinedText.contains('grade 3') ||
          combinedText.contains('cormack 3') ||
          combinedText.contains('grade iii') ||
          combinedText.contains('cormack iii') ||
          combinedText.contains('cl 3');
      bool isCl4 = cormackStr == '4' ||
          cormackStr.contains('grade 4') ||
          cormackStr.contains('grade iv') ||
          cormackStr.contains('cormack 4') ||
          cormackStr.contains('cormack-4') ||
          cormackStr.contains('cl 4') ||
          combinedText.contains('grade 4') ||
          combinedText.contains('cormack 4') ||
          combinedText.contains('grade iv') ||
          combinedText.contains('cormack iv') ||
          combinedText.contains('cl 4');

      if (!isIntubInSitu) {
        if (isCl1) cormack1Count++;
        if (isCl2) cormack2Count++;
        if (isCl3) cormack3Count++;
        if (isCl4) cormack4Count++;
      }

      bool isDifficultAirwayOverride =
          c.difficultAirway || combinedText.contains('difficult airway');
      bool isOneAttempt = combinedText.contains('1 attempt') ||
          combinedText.contains('first attempt') ||
          combinedText.contains('1st attempt') ||
          combinedText.contains('attempt 1') ||
          combinedText.contains('single attempt') ||
          (!combinedText.contains('2 attempt') &&
              !combinedText.contains('3 attempt') &&
              !combinedText.contains('multiple attempts') &&
              !combinedText.contains('2nd attempt') &&
              !combinedText.contains('3rd attempt'));
      if (!isIntubInSitu && isDifficultAirwayOverride && isOneAttempt) {
        firstPassSuccessCount++;
      }

      // Multi-attempt warrior: difficult airway flagged AND attempts >= 3 (one case)
      int attemptsCount = c.difficultAirwayAttempts ?? 0;
      if (attemptsCount <= 0) {
        final attMatch = RegExp(r'(\d+)\s*attempts?').firstMatch(combinedText);
        if (attMatch != null) {
          attemptsCount = int.tryParse(attMatch.group(1)!) ?? 0;
        }
      }
      if (!isIntubInSitu && c.difficultAirway && attemptsCount >= 3) {
        multiAttemptWarriorCount++;
      }

      int validRegionalCountForCase = 0;
      bool caseHasCatheterPlaced = c.catheterPlaced;

      for (var r in c.regionalBlocks) {
        String rName = r['name']?.toString().trim() ?? '';
        String rRole = r['role']?.toString().toLowerCase() ?? 'performed';

        if (rName.isNotEmpty && rName != 'None / Not performed') {
          if (rRole == 'assisted' ||
              rRole == 'observed' ||
              rRole.contains('situ')) continue;

          validRegionalCountForCase++;
          uniqueRegionalTypes.add(rName.toLowerCase());
          String lowerR = rName.toLowerCase();

          if (lowerR.contains('spinal') || lowerR.contains('sab'))
            spinalBlockCount++;
          if (lowerR.contains('epidural') && !lowerR.contains('combined'))
            epiduralBlockCount++;
          // Peripheral/nerve block count: any block that is not neuraxial
          // (spinal, epidural, CSE). Covers interscalene, supraclavicular,
          // femoral, sciatic, fascia iliaca, TAP, etc. and 'Other peripheral'.
          final bool isNeuraxial = lowerR.contains('spinal') ||
              lowerR.contains('sab') ||
              lowerR.contains('epidural') ||
              lowerR.contains('combined spinal') ||
              lowerR.contains('cse');
          if (!isNeuraxial) peripheralBlockCount++;
          if (lowerR.contains('interscalene')) interscaleneCount++;
          if (lowerR.contains('supraclavicular')) supraclavicularCount++;
          if (lowerR.contains('infraclavicular')) infraclavicularCount++;
          if (lowerR.contains('axillary')) axillaryCount++;
          if (lowerR.contains('femoral')) femoralCount++;
          if (lowerR.contains('adductor canal')) adductorCanalCount++;
          if (lowerR.contains('sciatic') && !lowerR.contains('popliteal'))
            sciaticCount++;
          if (lowerR.contains('popliteal')) poplitealCount++;
          if (lowerR.contains('tap')) tapCount++;
          if (lowerR.contains('rectus sheath')) rectusSheathCount++;
          if (lowerR.contains('quadratus lumborum') || lowerR.contains('ql'))
            qlCount++;
          if (lowerR.contains('erector spinae') || lowerR.contains('esp'))
            espCount++;
          if (lowerR.contains('pecs')) pecsCount++;
          if (lowerR.contains('serratus')) serratusCount++;
          if (lowerR.contains('paravertebral')) paravertebralCount++;
          if (lowerR.contains('cervical plexus')) cervicalPlexusCount++;
          if (lowerR.contains('scalp')) scalpBlockCount++;
          if (lowerR.contains('caudal')) caudalCount++;
          if (lowerR.contains('ankle')) ankleBlockCount++;
          if (lowerR.contains('bier') || lowerR.contains('ivra'))
            bierBlockCount++;
          if (lowerR.contains('lumbar plexus') ||
              lowerR.contains('sacral plexus')) plexusMasterCount++;
          if (lowerR.contains('fascia iliaca') ||
              lowerR.contains('fascia iliaca plane') ||
              lowerR.contains('ficb') ||
              lowerR.contains('fi block')) {
            fasciaIliacaCount++;
            if (rRole == 'performed' || rRole == 'supervised' || rRole.isEmpty)
              fasciaPerformedCount++;
          }
          if (lowerR.contains('psoas') ||
              lowerR.contains('psoas compartment') ||
              lowerR.contains('psoas subfascial')) {
            psoasPlaneCount++;
            if (rRole == 'performed' || rRole == 'supervised' || rRole.isEmpty)
              psoasPerformedCount++;
          }

          if (r['usgGuided'] == true ||
              r['ultrasound'] == true ||
              r['usg'] == true ||
              (r['guidance']?.toString().toLowerCase().contains('ultrasound') ??
                  false)) {
            usgRegionalCount++;
            if (lowerR.contains('fascia iliaca') || lowerR.contains('ficb'))
              fasciaUsgCount++;
            if (lowerR.contains('psoas')) psoasUsgCount++;
          }
          if (r['nerveStimulator'] == true ||
              (r['guidance']?.toString().toLowerCase().contains('stimulator') ??
                  false)) {
            nerveStimulatorCount++;
          }

          r.forEach((key, val) {
            final sVal = val?.toString().toLowerCase() ?? '';
            final sKey = key.toLowerCase();
            if (sVal.contains('catheter placed') ||
                sVal.contains('continuous infusion') ||
                sVal == 'true' && sKey.contains('catheter') ||
                val == true && sKey.contains('catheter')) {
              caseHasCatheterPlaced = true;
            }
          });
        }
      }
      if (validRegionalCountForCase >= 2) multiBlockCaseCount++;
      if (caseHasCatheterPlaced) {
        catheterCount++;
      }

      bool caseFascia = false, casePsoas = false;
      for (var r in c.regionalBlocks) {
        final rName = (r['name']?.toString() ?? '').toLowerCase();
        final rRole = (r['role']?.toString() ?? 'performed').toLowerCase();
        if (rRole.contains('situ')) continue;
        final isFascia = rName.contains('fascia iliaca') ||
            rName.contains('ficb') ||
            rName.contains('fi block');
        final isPsoas = rName.contains('psoas');
        if (!isFascia && !isPsoas) continue;
        if (isFascia) caseFascia = true;
        if (isPsoas) casePsoas = true;
        if (rRole == 'assisted') {
          if (isFascia) fasciaAssistedCount++;
          if (isPsoas) psoasAssistedCount++;
        }
        final cath = r['catheter'] == true ||
            r['catheterPlaced'] == true ||
            (r['catheter']?.toString().toLowerCase() == 'true') ||
            (r.values.any((v) =>
                v?.toString().toLowerCase().contains('catheter') == true));
        if (cath) {
          if (isFascia) fasciaCatheterCount++;
          if (isPsoas) psoasCatheterCount++;
        }
      }
      if (caseFascia || casePsoas) {
        if (hasValue(c.priority) && c.priority == 'Emergency')
          planeEmergencyCount++;
        if (hasValue(c.specialty) &&
            c.specialty.toLowerCase().contains('trauma')) planeTraumaCount++;
        double ageY2 = -1;
        if (c.patientAge != null) {
          final unit = c.ageUnit.toLowerCase() ?? 'years';
          if (unit.contains('month'))
            ageY2 = c.patientAge! / 12;
          else if (unit.contains('week'))
            ageY2 = c.patientAge! / 52;
          else if (unit.contains('day'))
            ageY2 = c.patientAge! / 365;
          else
            ageY2 = c.patientAge!;
        }
        if (ageY2 >= 65) planeElderlyCount++;
        final hasSpinalTech = c.technique.toLowerCase().contains('spinal') ||
            c.regionalBlocks.any((r) =>
                (r['name']?.toString() ?? '').toLowerCase().contains('spinal') &&
                !(r['role']?.toString().toLowerCase().contains('situ') ?? false));
        if (hasSpinalTech) planeWithSpinalCount++;
      }

      Set<String> caseUniqueMonitors = {};
      bool caseHasTciPump = false;

      for (var m in c.invasiveMonitoring) {
        String mName = '';
        String mRole = 'performed';
        bool mUsg = false;
        mName = m['name']?.toString().toLowerCase() ?? '';
        mRole = m['role']?.toString().toLowerCase() ?? 'performed';
        mUsg = m['usgGuided'] == true ||
            m['ultrasound'] == true ||
            m['usg'] == true ||
            (m['guidance']?.toString().toLowerCase().contains('ultrasound') ??
                false);

        if (mName.isNotEmpty && mName != 'none') {
          if (mRole.contains('situ')) continue;
          caseUniqueMonitors.add(mName);
          uniqueMonitors.add(mName);

          bool isArt = mName.contains('arterial') ||
              mName.contains('art line') ||
              mName.contains('radial') ||
              mName.contains('femoral line');
          bool isCvc = mName.contains('cvc') ||
              mName.contains('central line') ||
              mName.contains('central') ||
              mName.contains('jugular') ||
              mName.contains('subclavian');
          bool isBis = mName.contains('bis') ||
              mName.contains('entropy') ||
              mName.contains('depth');
          bool isNirs = mName.contains('nirs') ||
              mName.contains('oximetry') ||
              mName.contains('cerebral oxygen') ||
              mName.contains('invos');
          bool isSedline = mName.contains('sedline') ||
              mName.contains('sed line') ||
              mName.contains('masimo');
          bool isTee =
              mName.contains('tee') || mName.contains('transesophageal');
          bool isPaCatheter = mName.contains('pa catheter') ||
              mName.contains('pulmonary artery') ||
              mName.contains('swan');
          bool isPicco =
              mName.contains('picco') || mName.contains('pulse contour');
          bool isCardiacOutputDevice = mName.contains('cardiac output') ||
              mName.contains('flotrac') ||
              mName.contains('lidco') ||
              mName.contains('ev1000') ||
              isPicco ||
              isPaCatheter;
          bool isLumbar = mName.contains('lumbar') ||
              mName.contains('drain') ||
              mName.contains('subarachnoid drain');
          bool isTci = mName.contains('tci') ||
              mName.contains('target controlled') ||
              mName.contains('target-controlled') ||
              mName.contains('tci pump');

          if (mUsg && (isArt || isCvc)) {
            usgVascularCount++;
          }

          if (mRole == 'assisted') {
            if (isArt) artLineAssistCount++;
            if (isCvc) cvcAssistCount++;
          } else if (mRole == 'observed') {
            if (isArt) artLineAssistCount++;
            if (isCvc) cvcAssistCount++;
            if (isTee) teeObserverCount++;
            if (isPaCatheter) paCatheterObserverCount++;
          } else {
            if (isArt) artLineCount++;
            if (isCvc) cvcCount++;
            if (isBis) bisEntropyCount++;
            if (isNirs) nirsCount++;
            if (isSedline) sedLineCount++;
            if (isTee) {
              teeCount++;
              teePaCatheterCount++;
            }
            if (isPaCatheter) {
              paCatheterCount++;
              teePaCatheterCount++;
            }
            if (isPicco) piccoCount++;
            if (isCardiacOutputDevice) cardiacOutputCount++;
            if (isLumbar) lumbarDrainCount++;
            if (isTci) caseHasTciPump = true;
          }
        }
      }

      if (caseHasTciPump) {
        tciPumpMonitoringCount++;
      }
      if (caseUniqueMonitors.length >= 3) multiMonitor3Count++;
      if (caseUniqueMonitors.length >= 4) multiMonitor4Count++;

      if (hasAge) {
        bool isNeonate = false;
        final unit = (c.ageUnit ?? 'years').toLowerCase();
        if (unit.contains('day')) {
          isNeonate = c.patientAge! <= 28;
        } else if (unit.contains('week')) {
          isNeonate = c.patientAge! <= 4;
        } else if (unit.contains('month')) {
          isNeonate = c.patientAge! < 1;
        } else {
          isNeonate = c.patientAge! <= (28.0 / 365.25);
        }

        if (isNeonate) {
          neonateCount++;
          ageBandsUsed.add('neonate');
        } else if (unit.contains('month')
            ? c.patientAge! <= 12
            : (unit.contains('day') ? c.patientAge! <= 365 : ageYears <= 1.0)) {
          infantCount++;
          ageBandsUsed.add('infant');
        } else if (unit.contains('month')
            ? c.patientAge! <= 36
            : (unit.contains('day')
                ? c.patientAge! <= 365 * 3
                : ageYears <= 3.0)) {
          toddlerCount++;
          ageBandsUsed.add('toddler');
        } else if (ageYears <= 12) {
          childCount++;
          ageBandsUsed.add('child');
        } else if (ageYears < 18) {
          adolescentCount++;
          ageBandsUsed.add('adolescent');
        } else {
          ageBandsUsed.add('adult');
        }

        if (ageYears < 18) pediatricTotalCount++;
        if (ageYears >= 65) {
          elderlyCount++;
          ageBandsUsed.add('elderly');
          if (ageYears >= 80) octogenarianCount++;
          if (ageYears >= 100) centenarianCount++;
        }

        bool isNeonateOrInfant = false;
        if (c.patientAge != null) {
          final unit = c.ageUnit.toLowerCase() ?? 'years';
          if (unit.contains('day') ||
              unit.contains('week') ||
              unit.contains('month')) {
            isNeonateOrInfant = true;
          } else if (unit.contains('year') && c.patientAge! <= 1) {
            isNeonateOrInfant = true;
          }
        }
        if (isNeonateOrInfant && isDifficult) pediatricDifficultAirwayCount++;
        if (ageYears >= 80 && isDifficult) geriatricDifficultAirwayCount++;
      }

      if (c.patientWeight != null && c.patientWeight! > 0) {
        if (ageYears >= 18 && c.patientWeight! < 40) underweightAdultCount++;
        if (c.patientWeight! > 100) heavyweightCount++;
        if (c.patientWeight! > 130) superHeavyweightCount++;
      }

      double? bmiVal = c.bmi;
      if (bmiVal == null &&
          c.patientWeight != null &&
          c.patientWeight! > 0 &&
          c.patientHeight != null &&
          c.patientHeight! > 0) {
        double heightM =
            c.patientHeight! > 3 ? c.patientHeight! / 100 : c.patientHeight!;
        bmiVal = c.patientWeight! / (heightM * heightM);
      }

      if (bmiVal != null) {
        if (bmiVal < 18.5) {
          underweightCount++;
          bmiBandsUsed.add('underweight');
          if (ageYears >= 18) underweightDates.add(c.date);
        } else if (bmiVal >= 18.5 && bmiVal < 25) {
          bmiBandsUsed.add('normal');
        } else if (bmiVal >= 25 && bmiVal < 30) {
          bmiBandsUsed.add('overweight');
        } else if (bmiVal >= 30 && bmiVal < 35) {
          bariatric1Count++;
          bmiBandsUsed.add('bariatric1');
        } else if (bmiVal >= 35 && bmiVal < 40) {
          bariatric2Count++;
          bmiBandsUsed.add('bariatric2');
        } else if (bmiVal >= 40) {
          bariatric3Count++;
          bmiBandsUsed.add('bariatric3');
          superObeseDates.add(c.date);
        }
      } else if (c.patientWeight != null && c.patientWeight! > 0) {
        if (c.patientWeight! < 40) {
          underweightDates.add(c.date);
        }
        if (c.patientWeight! >= 130) {
          superObeseDates.add(c.date);
        }
      }

      if (hasValue(c.specialty)) {
        String specKey = c.specialty.trim();
        String lowerSpec = specKey.toLowerCase();

        if (lowerSpec == 'other') {
          otherSpecialtyCount++;
        }
        if (lowerSpec == 'acute/chronic pain intervention' ||
            lowerSpec == 'pain intervention' ||
            lowerSpec == 'pain management') {
          painInterventionSpecialtyCount++;
        }

        if (lowerSpec == 'other' && hasValue(c.specialtyOther)) {
          specKey = c.specialtyOther!.trim();
        }
        specialtyCounts[specKey] = (specialtyCounts[specKey] ?? 0) + 1;
        allUsedSpecialties.add(specKey.toLowerCase());
      }

      String techLower = c.technique.toLowerCase();
      bool isGa = techLower.contains('general') ||
          techLower.contains('ga') ||
          techLower.contains('volatile') ||
          techLower.contains('inhalational');
      bool isTiva = techLower.contains('tiva');
      bool isSpinal = techLower.contains('spinal') || techLower.contains('sab');
      bool isCse = techLower.contains('cse') ||
          techLower.contains('combined spinal') ||
          techLower.contains('combined spinal-epidural') ||
          techLower.contains('combined spinal epidural') ||
          techLower.contains('spinal-epidural') ||
          techLower.contains('spinal epidural');
      bool isEpidural =
          (techLower.contains('epidural') || techLower.contains('ea')) &&
              !isCse;
      bool isMac = techLower.contains('mac') || techLower.contains('sedation');
      bool isLocalOnly = techLower == 'local only' ||
          techLower == 'local' ||
          techLower.contains('local only');
      bool isPnb = techLower.contains('peripheral nerve block') ||
          techLower.contains('pnb');
      bool isTci =
          techLower.contains('tci') || techLower.contains('target controlled');

      if (isGa) gaCount++;
      if (isTiva) tivaCount++;
      if (isGa || isTiva) gaOrTivaCount++;
      if (isCse) cseCount++;
      if (isSpinal) spinalCount++;
      if (isEpidural) epiduralCount++;
      if (isMac) macCount++;
      if (isLocalOnly) localOnlyCount++;
      if (isPnb) pnbCount++;
      if (isTci) tciCount++;

      if (hasValue(c.technique)) {
        uniqueTechniques.add(c.technique.trim().toLowerCase());
      }
      if (isSpinal || isEpidural || isCse || isPnb || isLocalOnly) {
        awakeRegionalCount++;
        regionalPuristCount++;
      }

      // Epidural Queen: primary technique Epidural or CSE, OR regional anaesthesia epidural option chosen
      bool caseHasEpiduralRegional = c.regionalBlocks.any((r) {
        final rName = (r['name']?.toString() ?? '').toLowerCase();
        final rRole = (r['role']?.toString() ?? 'performed').toLowerCase();
        return rName.contains('epidural') && !rRole.contains('situ');
      });
      if (isEpidural || isCse || caseHasEpiduralRegional) {
        epiduralQueenCount++;
      }

      int h = _getStartHour(c);
      if (h >= 0 && h < 5) nightOwlCount++;
      if (h >= 6 && h < 7) earlyBirdCount++;
      if (c.date.weekday >= 6) {
        weekendCount++;
        final satDate = DateTime(
            c.date.year, c.date.month, c.date.day - (c.date.weekday - 6));
        weekendMinsMap[satDate] = (weekendMinsMap[satDate] ?? 0) + anaesM;
      }
      final caseDay = DateTime(c.date.year, c.date.month, c.date.day);
      dailyMinsMap[caseDay] = (dailyMinsMap[caseDay] ?? 0) + anaesM;
      if (surgM > 0 && surgM <= 15) inAndOutCount++;
      if (anaesM > 240) longHaul++;
      if (anaesM > 360) marathon++;
      if (anaesM > 480) ultra++;
      if (anaesM > 600) endless++;
      final aEndM = _parseTimeToMinutes(c.anaesthesiaEndTime);
      final sEndM = _parseTimeToMinutes(c.surgeryEndTime);
      if (aEndM != null && sEndM != null) {
        int diff = aEndM - sEndM;
        if (diff < 0) diff += 1440;
        if (diff >= 0 && diff < 10) {
          quickRecoveryCount++;
        }
      }

      if (h < 4 && (anaesM >= (6 - h) * 60 || anaesM >= 240)) {
        sunriseExtubationCount++;
      }

      final d = c.date;
      final dLocal = c.date.toLocal();
      if ((d.month == 12 && d.day == 25) ||
          (d.month == 1 && d.day == 1) ||
          (dLocal.month == 12 && dLocal.day == 25) ||
          (dLocal.month == 1 && dLocal.day == 1)) {
        holidayCount++;
      }

      if ((d.month == 12 && d.day == 31) ||
          (d.month == 1 && d.day == 1) ||
          (dLocal.month == 12 && dLocal.day == 31) ||
          (dLocal.month == 1 && dLocal.day == 1)) {
        newYearsCount++;
      }

      if (doctorDob != null &&
          ((d.month == doctorDob.month && d.day == doctorDob.day) ||
              (dLocal.month == doctorDob.month &&
                  dLocal.day == doctorDob.day))) {
        birthdayShiftCount++;
      }

      if (asaVal >= 3) {
        riskManagerCount++;
        DateTime d = DateTime(c.date.year, c.date.month, c.date.day);
        acuityDayMap[d] = (acuityDayMap[d] ?? 0) + 1;
        if (hasValue(c.outcome) && c.outcome == 'Uneventful PACU discharge')
          safeHandsHighRisk++;
      }
      if (asaVal >= 4) fearlessCount++;
      if (asaVal >= 4 &&
          hasValue(c.outcome) &&
          c.outcome == 'Uneventful PACU discharge') defyingOddsCount++;
      if (asaVal >= 4 &&
          c.outcome == 'ICU transfer intubated' &&
          !hasComp('death on table')) criticalTransferCount++;
      if (hasValue(c.outcome) && c.outcome == 'Uneventful PACU discharge')
        resilientSystemCount++;

      bool isEmergency = hasValue(c.priority) && c.priority == 'Emergency';
      if (isEmergency) {
        emergencyCount++;
        DateTime caseDateTime = c.date;
        int? startMins = _parseTimeToMinutes(c.anaesthesiaStartTime);
        if (startMins != null) {
          caseDateTime = DateTime(c.date.year, c.date.month, c.date.day,
              startMins ~/ 60, startMins % 60);
        }
        emergencyTimestamps.add(caseDateTime);
        if (hasValue(c.specialty)) emergencySpecialties.add(c.specialty);
        consecutiveEmergency++;
        if (consecutiveEmergency >= 2) doubleTroubleCount++;

        DateTime d = DateTime(c.date.year, c.date.month, c.date.day);
        emergencyDayMap[d] = (emergencyDayMap[d] ?? 0) + 1;
        if (emergencyDayMap[d]! > traumaBayRegularMax) {
          traumaBayRegularMax = emergencyDayMap[d]!;
        }

        if (c.date.weekday >= 6) weekendTraumaCount++;
        if (asaVal == 5) nightmareScenarioCount++;
        if (hasValue(c.outcome) && c.outcome == 'Uneventful PACU discharge') {
          calmUnderPressureCount++;
          ironConstitutionCount++;
        }

        bool hasValidRegional = c.regionalBlocks.any((r) {
          String name = r['name']?.toString() ?? '';
          String role = r['role']?.toString().toLowerCase() ?? 'performed';
          return name.isNotEmpty &&
              name != 'None / Not performed' &&
              role != 'assisted' &&
              role != 'observed' &&
              !role.contains('situ');
        });
        if (hasValidRegional) {
          emergencyRegionalCount++;
          emergencyBlockMasterCount++;
        }

        if (surgM > 0 && surgM <= 30) fastAndFuriousCount++;
        if (methodStr.contains('awake fiberoptic') && !isIntubInSitu) {
          emergencyAwakeCount++;
        }
        if (isDifficult && !isIntubInSitu) emergencyAirwayCount++;

        String specLower = c.specialty.toLowerCase();
        if (specLower.contains('spine')) emergencySpineCount++;
        if (specLower.contains('cardiothoracic') ||
            specLower.contains('cardio')) emergencyHeartCount++;
        if (specLower.contains('obstetric') || specLower.contains('obgyn')) {
          emergencyBabyCount++;
          cesareanRushCount++;
        }
        if (specLower.contains('neuro')) {
          emergencyBrainCount++;
          if (c.procedure.toLowerCase().contains('craniotomy'))
            brainBleedRushCount++;
        }
        if (specLower.contains('trauma')) traumaTeamLeaderCount++;
        if (specLower.contains('orthopedic') || specLower.contains('ortho'))
          boneFractureRushCount++;
        if (specLower.contains('vascular')) vascularClampCount++;
        if (c.procedure.toLowerCase().contains('laparotomy'))
          acuteAbdomenCount++;

        if (h >= 0 && h <= 4) midnightEmergencyCount++;
        if ((c.date.month == 12 && c.date.day == 25) ||
            (c.date.month == 1 && c.date.day == 1)) {
          holidayEmergencyCount++;
        }
        if (c.difficultAirway) airwayRescueCount++;
        if (asaVal == 4 &&
            hasValue(c.outcome) &&
            c.outcome == 'Uneventful PACU discharge') stableInChaosCount++;
        if (hasValue(c.outcome) &&
            c.outcome == 'Uneventful PACU discharge') zeroDramaCount++;

        if (hasAge) {
          if (ageYears < 18) emergencyPediatricCount++;
          if (ageYears > 65) emergencyGeriatricCount++;
        }

        int endMins = _getEndHour(c);
        int? sEndMins = _parseTimeToMinutes(c.surgeryEndTime);
        if ((endMins >= 480 && endMins <= 510) ||
            (sEndMins != null && sEndMins >= 480 && sEndMins <= 510)) {
          savedByTheBellCount++;
        }
      } else {
        consecutiveEmergency = 0;
      }
    }

    int nonStopCrisisCount = 0;
    int ultimateIronManCount = 0;
    int maxEmergenciesIn24h = 0;
    emergencyTimestamps.sort();

    for (int i = 0; i < emergencyTimestamps.length; i++) {
      int in24h = 0;
      for (int j = i; j < emergencyTimestamps.length; j++) {
        if (emergencyTimestamps[j]
                .difference(emergencyTimestamps[i])
                .inHours <=
            24) {
          in24h++;
        } else {
          break;
        }
      }
      if (in24h > maxEmergenciesIn24h) {
        maxEmergenciesIn24h = in24h;
      }
      if (i + 2 < emergencyTimestamps.length) {
        if (emergencyTimestamps[i + 2]
                .difference(emergencyTimestamps[i])
                .inHours <=
            12) {
          nonStopCrisisCount++;
        }
      }
      if (i + 4 < emergencyTimestamps.length) {
        if (emergencyTimestamps[i + 4]
                .difference(emergencyTimestamps[i])
                .inHours <=
            24) {
          ultimateIronManCount++;
        }
      }
    }

    int totalHours = totalMins ~/ 60;
    int extremesOfWeightCount = 0;
    for (final uDate in underweightDates) {
      for (final sDate in superObeseDates) {
        if (uDate.difference(sDate).abs().inDays <= 7) {
          extremesOfWeightCount = 1;
          break;
        }
      }
      if (extremesOfWeightCount > 0) break;
    }

    // --- FATIGUE & SHIFT TRACKING ---
    final sortedByDate = List<CaseRecord>.from(cases)
      ..sort((a, b) => a.date.compareTo(b.date));

    int shift10hCount = 0;
    int shift14hCount = 0;
    int shift16hCount = 0;
    int postCallSanctuaryCount = 0;
    int flawlessUnderPressureCount = 0;
    int flawlessFatigueCount = 0;
    int heavyweightFatigueCount = 0;
    List<DateTime> redShiftDates = [];
    int redRingCenturionHours = 0;

    int shiftIdx = 0;
    while (shiftIdx < sortedByDate.length) {
      final windowStart = sortedByDate[shiftIdx].date;
      final windowEnd = windowStart.add(const Duration(hours: 24));

      int windowAnaesMins = 0;
      bool allWindowCasesUneventful = true;
      bool allWindowCasesHighAcuity = true;
      int windowCasesCount = 0;
      DateTime lastCaseInWindow = windowStart;
      int nextIdx = shiftIdx + 1;

      for (int j = shiftIdx; j < sortedByDate.length; j++) {
        final c = sortedByDate[j];
        if (c.date.isAfter(windowEnd)) break;

        windowCasesCount++;
        windowAnaesMins += _getCaseAnaesthesiaMinutes(c);

        int asaVal = _parseAsa(c.asaGrade);
        if (asaVal < 3) {
          allWindowCasesHighAcuity = false;
        }

        bool isUneventful = c.complications.isEmpty ||
            (c.complications.length == 1 &&
                c.complications.first.toLowerCase().contains('uneventful'));
        if (!isUneventful) {
          allWindowCasesUneventful = false;
        }

        lastCaseInWindow = c.date;
        nextIdx = j + 1;
      }

      if (windowAnaesMins >= 300) {
        greenZoneCruiserCount++;
      }

      if (windowAnaesMins >= 450) {
        amberAlertCount++;
      }

      if (windowAnaesMins >= 600) {
        shift10hCount++;
        redRingAwakeningCount++;
        redShiftDates.add(windowStart);
        redRingCenturionHours += (windowAnaesMins ~/ 60);
        if (allWindowCasesUneventful && windowCasesCount > 0) {
          flawlessUnderPressureCount++;
        }
        if (windowCasesCount >= 5 && allWindowCasesUneventful) {
          flawlessFatigueCount++;
        }
        if (windowCasesCount > 0 && allWindowCasesHighAcuity) {
          heavyweightFatigueCount++;
        }
        if (windowAnaesMins >= 840) {
          shift14hCount++;
        }
        if (windowAnaesMins >= 960) {
          shift16hCount++;
        }

        if (nextIdx < sortedByDate.length) {
          final nextCaseDate = sortedByDate[nextIdx].date;
          if (nextCaseDate.difference(lastCaseInWindow).inHours >= 24) {
            postCallSanctuaryCount++;
          }
        } else {
          if (DateTime.now().difference(lastCaseInWindow).inHours >= 24) {
            postCallSanctuaryCount++;
          }
        }
      }

      shiftIdx = nextIdx > shiftIdx ? nextIdx : shiftIdx + 1;
    }

    final Set<DateTime> redRingDays = {};
    for (final entry in dailyMinsMap.entries) {
      if (entry.value >= 600) {
        redRingDays.add(DateTime(entry.key.year, entry.key.month, entry.key.day));
      }
    }
    for (final d in redShiftDates) {
      redRingDays.add(DateTime(d.year, d.month, d.day));
    }
    final sortedRedDays = redRingDays.toList()..sort();

    int maxRedInWeek = 0;
    for (int i = 0; i < sortedRedDays.length; i++) {
      int count = 0;
      for (int j = i; j < sortedRedDays.length; j++) {
        if (sortedRedDays[j].difference(sortedRedDays[i]).inDays <= 7) {
          count++;
        } else {
          break;
        }
      }
      if (count > maxRedInWeek) {
        maxRedInWeek = count;
      }
    }
    int tripleRedStreakCount = maxRedInWeek >= 3 ? 3 : maxRedInWeek;
    if (redRingDays.length > shift10hCount) {
      shift10hCount = redRingDays.length;
    }

    int weekendGauntletCount =
        weekendMinsMap.values.where((m) => m >= 960).length;
    int greenZoneDays = dailyMinsMap.values.where((m) => m >= 300).length;
    if (greenZoneDays > greenZoneCruiserCount) {
      greenZoneCruiserCount = greenZoneDays;
    }
    try {
      final stats = FatigueService.getFatigueStats(cases);
      if (stats.activeMinutes24h >= 300 && greenZoneCruiserCount == 0) {
        greenZoneCruiserCount = 1;
      }
    } catch (_) {}

    int bonusPoints = await ProfileStorage.getProfileBonusPoints();
    bool profileComplete = bonusPoints > 0;
    int totalPoints = await PointsService.totalWithProfileBonus(cases);

    bool hasHighAcuity3 = acuityDayMap.values.any((v) => v >= 3);
    bool hasHighAcuity5 = acuityDayMap.values.any((v) => v >= 5);
    bool hasBalanced = asaCounts[1]! > 0 &&
        asaCounts[2]! > 0 &&
        asaCounts[3]! > 0 &&
        asaCounts[4]! > 0 &&
        asaCounts[5]! > 0;

    int getMatchingCasesCount(List<String> keywords) {
      int count = 0;
      for (var c in cases) {
        if (!hasValue(c.specialty)) continue;
        String spec = c.specialty.toLowerCase();
        String specOther = c.specialtyOther?.toLowerCase() ?? '';
        String proc = c.procedure.toLowerCase();
        String combined = '$spec $specOther $proc';
        for (var kw in keywords) {
          if (combined.contains(kw.toLowerCase())) {
            count++;
            break;
          }
        }
      }
      return count;
    }

    int getMatchingEmergencyCount(List<String> keywords) {
      int count = 0;
      for (var c in cases) {
        if (c.priority != 'Emergency') continue;
        if (!hasValue(c.specialty)) continue;
        String spec = c.specialty.toLowerCase();
        String specOther = c.specialtyOther?.toLowerCase() ?? '';
        String proc = c.procedure.toLowerCase();
        String diag = c.diagnosis.toLowerCase();
        String combined = '$spec $specOther $proc $diag';
        for (var kw in keywords) {
          if (combined.contains(kw.toLowerCase())) {
            count++;
            break;
          }
        }
      }
      return count;
    }

    for (int i = 0; i < AchievementRegistry.data.length; i++) {
      final item = AchievementRegistry.data[i];
      final title = item['title'] ?? '';
      final lowerTitle =
          title.toLowerCase().trim().replaceAll('’', "'").replaceAll('‘', "'");

      int originalTarget = _determineTarget(title, item['desc'] ?? '');
      int target = originalTarget;
      int current = 0;

      String cat = item['category'] ?? 'Volume';

      if ([
        'midnight emergency',
        'emergency pediatric',
        'emergency geriatric',
        'saved by the bell',
        'dawn relief',
        'holiday emergency',
        'awake regional'
      ].contains(lowerTitle)) {
        target = 1;
      }

      if (['tci tech', 'target controlled', 'tci master']
          .contains(lowerTitle)) {
        current = tciPumpMonitoringCount;
      } else if (cat == 'Volume') {
        if (lowerTitle == 'the veteran' || lowerTitle == 'veteran')
          current = totalCases;
        else
          current = totalCases;
      } else if (cat == 'Time') {
        if (lowerTitle == 'night owl' ||
            lowerTitle == 'midnight oil' ||
            lowerTitle == 'graveyard shift' ||
            lowerTitle == 'vampire shift' ||
            lowerTitle == 'sprint to theatre')
          current = nightOwlCount;
        else if (lowerTitle == 'early bird' || lowerTitle == 'dawn patrol')
          current = earlyBirdCount;
        else if (lowerTitle == 'weekend warrior' ||
            lowerTitle == 'saturday night live' ||
            lowerTitle == 'no days off' ||
            lowerTitle == 'social life extinction')
          current = weekendCount;
        else if (lowerTitle == 'the drive-thru' ||
            lowerTitle == 'the drive thru' ||
            lowerTitle == 'drive-thru' ||
            lowerTitle == 'drive thru' ||
            lowerTitle == 'in and out' ||
            lowerTitle == 'speed runner' ||
            lowerTitle == 'blink and you missed it')
          current = inAndOutCount;
        else if (lowerTitle == 'long haul')
          current = longHaul;
        else if (lowerTitle == 'ceiling tile inspector')
          current = marathon;
        else if (lowerTitle == 'ultra marathon')
          current = ultra;
        else if (lowerTitle == 'endless case')
          current = endless;
        else if (lowerTitle == 'quick recovery' ||
            lowerTitle == 'waking on cue' ||
            lowerTitle == 'gas off, eyes open' ||
            lowerTitle == 'in sync' ||
            lowerTitle == 'perfect alignment' ||
            lowerTitle == 'synchronized sleep' ||
            lowerTitle == 'swiss chronometer' ||
            lowerTitle == 'the atomic clock' ||
            lowerTitle == 'the maestro of emergence' ||
            lowerTitle == 'the quantum chronometer')
          current = quickRecoveryCount;
        else if (lowerTitle == 'holiday shift')
          current = holidayCount;
        else if (lowerTitle == 'auld lang syne' ||
            lowerTitle == "new year's eve" ||
            lowerTitle == 'new years eve')
          current = newYearsCount;
        else if (lowerTitle == 'birthday shift')
          current = birthdayShiftCount;
        else
          current = totalHours;
      } else if (cat == 'Fatigue') {
        if (lowerTitle == 'shift survivor')
          current = shift10hCount;
        else if (lowerTitle == 'the red ring veteran' ||
            lowerTitle == 'red ring veteran')
          current = shift10hCount;
        else if (lowerTitle == 'the 24-hour war horse' ||
            lowerTitle == 'the 24 hour war horse' ||
            lowerTitle == '24-hour war horse' ||
            lowerTitle == '24 hour war horse')
          current = shift16hCount;
        else if (lowerTitle == 'pharmacological survival')
          current = shift10hCount;
        else if (lowerTitle == 'the post-call sanctuary' ||
            lowerTitle == 'post-call sanctuary')
          current = postCallSanctuaryCount;
        else if (lowerTitle == 'flawless under pressure')
          current = flawlessUnderPressureCount;
        else if (lowerTitle == 'sunrise extubation' ||
            lowerTitle == 'dawn relief')
          current = sunriseExtubationCount;
        else if (lowerTitle == 'flawless fatigue')
          current = flawlessFatigueCount;
        else if (lowerTitle == 'the weekend gauntlet' ||
            lowerTitle == 'weekend gauntlet')
          current = weekendGauntletCount;
        else if (lowerTitle == 'the green zone guardian' ||
            lowerTitle == 'green zone cruiser' ||
            lowerTitle == 'the green zone cruiser' ||
            lowerTitle == 'green zone guardian')
          current = greenZoneCruiserCount;
        else if (lowerTitle == 'entering the amber alert' ||
            lowerTitle == 'amber alert')
          current = amberAlertCount;
        else if (lowerTitle == 'red ring awakening')
          current = shift14hCount;
        else if (lowerTitle == 'triple red streak')
          current = tripleRedStreakCount;
        else if (lowerTitle == 'the red ring centurion' ||
            lowerTitle == 'red ring centurion')
          current = redRingCenturionHours;
        else if (lowerTitle == 'heavyweight fatigue')
          current = heavyweightFatigueCount;
        else
          current = totalHours;
      } else if (cat == 'Risk') {
        if (lowerTitle == 'healthy start' ||
            lowerTitle == 'prime health' ||
            lowerTitle == 'fit as a fiddle' ||
            lowerTitle == 'pure wellness' ||
            lowerTitle == 'asa 1 master')
          current = asaCounts[1]!;
        else if (lowerTitle == 'mild systemic' ||
            lowerTitle == 'minor issues' ||
            lowerTitle == 'bread and butter' ||
            lowerTitle == 'bread and butter' ||
            lowerTitle == 'common ground' ||
            lowerTitle == 'asa 2 regular' ||
            lowerTitle == 'asa 2 veteran')
          current = asaCounts[2]!;
        else if (lowerTitle == 'severe systemic' ||
            lowerTitle == 'complex care' ||
            lowerTitle == 'heavy medical history' ||
            lowerTitle == 'asa 3 specialist' ||
            lowerTitle == 'asa 3 expert')
          current = asaCounts[3]!;
        else if (lowerTitle == 'constant threat' ||
            lowerTitle == 'high stakes' ||
            lowerTitle == 'danger zone' ||
            lowerTitle == 'asa 4 guardian' ||
            lowerTitle == 'adrenaline cocktail' ||
            lowerTitle == 'asa 4 master' ||
            lowerTitle == 'master of the brink')
          current = asaCounts[4]!;
        else if (lowerTitle == 'the last hope' ||
            lowerTitle == 'edge of life' ||
            lowerTitle == 'high risk survivor' ||
            lowerTitle == 'asa 5 hero' ||
            lowerTitle == 'ultimate risk')
          current = asaCounts[5]!;
        else if (lowerTitle == 'risk manager')
          current = riskManagerCount;
        else if (lowerTitle == 'defying the odds')
          current = defyingOddsCount;
        else if (lowerTitle == 'critical transfer')
          current = criticalTransferCount;
        else if (lowerTitle == 'routine check' ||
            lowerTitle == 'unbroken streak')
          current = maxConsecutiveASA12;
        else if (lowerTitle == 'high acuity day')
          current = hasHighAcuity3 ? 3 : 0;
        else if (lowerTitle == 'heavy duty day')
          current = hasHighAcuity5 ? 5 : 0;
        else if (lowerTitle == 'balanced portfolio')
          current = hasBalanced ? 1 : 0;
        else if (lowerTitle == 'safe hand on high risk')
          current = safeHandsHighRisk;
        else if (lowerTitle == 'fearless')
          current = fearlessCount;
        else if (lowerTitle == 'resilient system')
          current = resilientSystemCount;
      } else if (cat == 'Emergency') {
        if (lowerTitle == 'drop everything' ||
            lowerTitle == 'adrenaline rush' ||
            lowerTitle == 'adrenaline junkie' ||
            lowerTitle == 'fast response' ||
            lowerTitle == 'olympic decathlon (trauma edition)' ||
            lowerTitle == 'sprint to theatre' ||
            lowerTitle == 'crisis manager' ||
            lowerTitle == 'firefighter in scrubs' ||
            lowerTitle == 'emergency expert' ||
            lowerTitle == 'unfazed' ||
            lowerTitle == 'century of carnage' ||
            lowerTitle == 'trauma veteran' ||
            lowerTitle == 'automatic pilot' ||
            lowerTitle == 'emergency master' ||
            lowerTitle == 'pager slayer' ||
            lowerTitle == 'the fixer' ||
            lowerTitle == 'unstoppable force') {
          current = emergencyCount;
        } else if (lowerTitle == 'trauma bay regular' ||
            lowerTitle == 'full moon madness')
          current = max(traumaBayRegularMax, maxEmergenciesIn24h);
        else if (lowerTitle == 'double trouble')
          current = doubleTroubleCount;
        else if (lowerTitle == 'nightmare scenario')
          current = nightmareScenarioCount;
        else if (lowerTitle == 'calm under pressure')
          current = calmUnderPressureCount;
        else if (lowerTitle == 'emergency regional')
          current = emergencyRegionalCount;
        else if (lowerTitle == 'emergency block master')
          current = emergencyBlockMasterCount;
        else if (lowerTitle == 'the bronchoscopy ballet')
          current = emergencyAwakeCount;
        else if (lowerTitle == 'fast and furious')
          current = fastAndFuriousCount;
        else if (lowerTitle == 'emergency awake')
          current = emergencyAwakeCount;
        else if (lowerTitle == 'emergency spine')
          current = emergencySpineCount;
        else if (lowerTitle == 'carpentry and ketamine')
          current = boneFractureRushCount;
        else if (lowerTitle == 'emergency heart')
          current = emergencyHeartCount;
        else if (lowerTitle == 'stork in a hurricane' ||
            lowerTitle == 'cesarean rush')
          current = cesareanRushCount;
        else if (lowerTitle == 'emergency baby')
          current = emergencyBabyCount;
        else if (lowerTitle == 'zero drama delivery')
          current = zeroDramaCount;
        else if (lowerTitle == 'emergency brain' ||
            lowerTitle == 'brain landlord')
          current = emergencyBrainCount;
        else if (lowerTitle == 'midnight emergency')
          current = midnightEmergencyCount;
        else if (lowerTitle == 'holiday emergency')
          current = holidayEmergencyCount;
        else if (lowerTitle == 'weekend trauma')
          current = weekendTraumaCount;
        else if (lowerTitle == 'airway rescue')
          current = airwayRescueCount;
        else if (lowerTitle == 'stable in chaos')
          current = stableInChaosCount;
        else if (lowerTitle == 'emergency pediatric')
          current = emergencyPediatricCount;
        else if (lowerTitle == 'emergency geriatric')
          current = emergencyGeriatricCount;
        else if (lowerTitle == 'saved by the bell' ||
            lowerTitle == 'dawn relief')
          current = savedByTheBellCount;
        else if (lowerTitle == 'non-stop crisis')
          current = nonStopCrisisCount;
        else if (lowerTitle == 'iron constitution')
          current = ironConstitutionCount;
        else if (lowerTitle == 'trauma team leader')
          current = traumaTeamLeaderCount;
        else if (lowerTitle == 'acute abdomen')
          current = acuteAbdomenCount;
        else if (lowerTitle == 'bone fracture rush')
          current = boneFractureRushCount;
        else if (lowerTitle == 'brain bleed rush')
          current = brainBleedRushCount;
        else if (lowerTitle == 'vascular clamp')
          current = vascularClampCount;
        else if (lowerTitle == 'master of chaos' ||
            lowerTitle == 'universal defender')
          current = emergencySpecialties.length;
        else if (lowerTitle == 'the ultimate iron man')
          current = ultimateIronManCount;
        else
          current = emergencyCount;
      } else if (cat == 'Specialties') {
        if ([
          'generalist',
          'general surgeon\'s shadow',
          'general mastery',
          'appendix collector',
          'master of the midline'
        ].contains(lowerTitle)) {
          current = getMatchingCasesCount(
              ['General Surgery', 'Gen Surg', 'General surgery']);
        } else if ([
          'bone mechanic',
          'orthopedic regular',
          'bone master',
          'ortho heavyweight'
        ].contains(lowerTitle)) {
          current = getMatchingCasesCount(
              ['Orthopedics', 'Orthopaedics', 'Orthopaedic', 'Orthopedic']);
        } else if ([
          'baby deliverer',
          'obstetrician\'s ally',
          'labour ward legend'
        ].contains(lowerTitle)) {
          current =
              getMatchingCasesCount(['Obstetrics', 'Maternity', 'Labour']);
        } else if (['women\'s health'].contains(lowerTitle)) {
          current = getMatchingCasesCount(['Gynaecology', 'Gynecology']);
        } else if (['obgyn heavyweight'].contains(lowerTitle)) {
          current = getMatchingCasesCount(
              ['Obstetrics', 'Gynaecology', 'Gynecology', 'ObGyn']);
        } else if ([
          'brain trust',
          'neuro anesthetist',
          'skull base expert',
          'neuro heavyweight'
        ].contains(lowerTitle)) {
          current = getMatchingCasesCount(
              ['Neurosurgery', 'Neuro surgery', 'Cranial', 'Craniotomy']);
        } else if ([
          'welcome to the pump',
          'heart of the matter',
          'cardio regular',
          'open heart',
          'cardio heavyweight'
        ].contains(lowerTitle)) {
          current = getMatchingCasesCount(
              ['Cardiothoracic', 'Cardiac', 'Cardiothoracic Surgery']);
        } else if ([
          'breathe easy',
          'shared airway guru',
          'shared airway gladiator',
          'the tonsil trap',
          'airway real estate',
          'dry field diplomat',
          'the throat pack paranoia',
          'ent heavyweight',
          'the graft protector',
        ].contains(lowerTitle)) {
          current = getMatchingCasesCount([
            'ENT',
            'Otorhinolaryngology',
            'Ear Nose Throat',
            'Ear, Nose & Throat',
            'Otolaryngology',
            'Tonsil',
            'Adenoid',
            'Sinus',
            'FESS',
            'Tympanoplasty',
            'Mastoidectomy',
            'Laryngoscopy',
            'Microlaryngeal',
          ]);
        } else if (['bleeding tonsil survivor'].contains(lowerTitle)) {
          current = getMatchingEmergencyCount([
            'ENT',
            'Otorhinolaryngology',
            'Ear Nose Throat',
            'Ear, Nose & Throat',
            'Otolaryngology',
            'Tonsil',
            'Adenoid',
            'Sinus',
            'FESS',
            'Bleed',
          ]);
        } else if ([
          'master plumber',
          'plumbing check',
          'uro heavyweight'
        ].contains(lowerTitle)) {
          current = getMatchingCasesCount(['Urology']);
        } else if (['plastic fantastic', 'plastics heavyweight']
            .contains(lowerTitle)) {
          current = getMatchingCasesCount(['Plastic surgery', 'Plastics']);
        } else if ([
          'teddy bear induction',
          'tiny patients, big surgeries',
          'paediatric pro',
          'paeds heavyweight'
        ].contains(lowerTitle)) {
          current = getMatchingCasesCount([
            'Paediatric Surgery',
            'Pediatric Surgery',
            'Paediatrics',
            'Pediatrics'
          ]);
        } else if (['trauma specialist'].contains(lowerTitle)) {
          current = getMatchingCasesCount(['Trauma surgery', 'Trauma']);
        } else if ([
          'eye whisperer',
          'eye see you',
          'ophthal heavyweight'
        ].contains(lowerTitle)) {
          current = getMatchingCasesCount(['Ophthalmology', 'Eye']);
        } else if ([
          'the prone position',
          'prone position',
          'the pancake flip',
          'pancake flip',
          'spine aligner',
          'spine specialist',
          'spine heavyweight'
        ].contains(lowerTitle)) {
          current = getMatchingCasesCount(['Spine Surgery', 'Spine']);
        } else if (['maxillofacial maestro'].contains(lowerTitle)) {
          current = getMatchingCasesCount([
            'Head and Neck',
            'Maxillofacial',
            'Oral',
            'Maxillofacial Surgery'
          ]);
        } else if ([
          'the whipple endurance',
          'whipple endurance',
          'liver whisperer',
          'liver and pancreas',
          'hpb specialist'
        ].contains(lowerTitle)) {
          current =
              getMatchingCasesCount(['HPB surgery', 'HPB', 'Hepatobiliary']);
        } else if (['gut feeling'].contains(lowerTitle)) {
          current = getMatchingCasesCount(['Upper GI', 'Colorectal']);
        } else if ([
          'colorectal pro',
          'colorectal specialist',
          'rearguard action'
        ].contains(lowerTitle)) {
          current = getMatchingCasesCount(['Colorectal', 'Colorectal Surgery']);
        } else if (['upper gi pro', 'upper gi specialist']
            .contains(lowerTitle)) {
          current = getMatchingCasesCount(['Upper GI', 'Upper GI Surgery']);
        } else if (['gland master'].contains(lowerTitle)) {
          current = getMatchingCasesCount(['Endocrine surgery', 'Endocrine']);
        } else if (['dark room duty'].contains(lowerTitle)) {
          current = darkRoomDutyCount;
        } else if (['pain relief'].contains(lowerTitle)) {
          current = painInterventionSpecialtyCount;
        } else if ([
          'fertility helper',
          'the stork\'s assistant',
          'stork\'s assistant'
        ].contains(lowerTitle)) {
          current = getMatchingCasesCount(
              ['RMU', 'Fertility', 'Reproductive', 'IVF']);
        } else if (['oncology support'].contains(lowerTitle)) {
          current = getMatchingCasesCount([
            'Gynae-oncology',
            'Gynecologic oncology',
            'Gynae oncology',
            'Gyn oncology'
          ]);
        } else if (['delicate touch'].contains(lowerTitle)) {
          current = getMatchingCasesCount([
            'Hand and reconstructive',
            'Hand surgery',
            'HLRS',
            'Reconstructive surgery'
          ]);
        } else if (['paediatric bone'].contains(lowerTitle)) {
          current = getMatchingCasesCount([
            'paediatric orthopedics',
            'pediatric orthopedics',
            'paediatric orthopaedics',
            'pediatric orthopaedics',
            'paediatric ortho',
            'pediatric ortho',
            'paediatric bone',
            'pediatric bone',
            'paediatric orthopedic',
            'pediatric orthopedic'
          ]);
        } else if ([
          'jack of all trades',
          'polymath',
          'universal specialist',
          'renaissance doctor'
        ].contains(lowerTitle)) {
          current = allUsedSpecialties.length;
        } else if (['niche operator'].contains(lowerTitle)) {
          current = otherSpecialtyCount;
        } else if ([
          'open wide',
          'imf veteran',
          'jaw breaker',
          'dental debut',
          'oral airway ally',
          'maxillo regular',
          'maxillo specialist',
          'face and airway',
          'jaw wire veteran',
          'maxillo century track',
          'oral surgery ally',
          'shared airway ace'
        ].contains(lowerTitle)) {
          current = dentalMaxilloCount;
        } else if (['dental block combo'].contains(lowerTitle)) {
          current = dentalBlockComboCount;
        } else if (['dental emergency'].contains(lowerTitle)) {
          current = dentalEmergencyCount;
        } else if (['imf night'].contains(lowerTitle)) {
          current = dentalEmergencyNightCount;
        } else if ([
          'maxillo difficult airway',
          'maxillo with difficult airway flag'
        ].contains(lowerTitle)) {
          current = maxilloDifficultAirwayCount;
        } else if (['wired quiet'].contains(lowerTitle)) {
          current = maxilloUneventfulCount;
        } else if ([
          'nasal preferrer',
          'maxillo nasal century path',
          'dental nasal ace'
        ].contains(lowerTitle)) {
          current = dentalNasalCount;
        } else if ([
          'ear to sternal notch',
          'ramp ready',
          'bariatric beginner',
          'bariatric list regular',
          'bariatric list specialist',
          'sleeve and bypass king',
          'ramp master general',
          'metabolic theatre',
          'bariatric heavyweight',
          'bariatric century track'
        ].contains(lowerTitle)) {
          current = bariatricSurgCount;
        } else if ([
          'bariatric emergency',
          'heavyweight crisis',
          'new specialty emergency'
        ].contains(lowerTitle)) {
          current = bariatricEmergencyCount;
        } else if ([
          'difficult bariatric airway',
          'bariatric airway plan',
          'plan a through z'
        ].contains(lowerTitle)) {
          current = bariatricDifficultAirway;
        } else if ([
          'bariatric and regional',
          'bariatric regional hero'
        ].contains(lowerTitle)) {
          current = bariatricRegionalCount;
        } else if ([
          'ultrasound deep dive',
          'bariatric art line',
          'bariatric with art line'
        ].contains(lowerTitle)) {
          current = bariatricWithArtLineCount;
        } else if (['bariatric vl preferrer'].contains(lowerTitle)) {
          current = bariatricVlCount;
        } else if (['bariatric desat rescue'].contains(lowerTitle)) {
          current = bariatricDesatCount;
        } else if (['bariatric uneventful'].contains(lowerTitle)) {
          current = bariatricUneventful;
        } else if ([
          'dark room debut',
          'ir apprentice',
          'creature of the dark room',
          'fluoro friend',
          'ir regular',
          'lead apron fashionista',
          'ir specialist',
          'ir century track',
          'ir lead fashion'
        ].contains(lowerTitle)) {
          current = irCount;
        } else if ([
          'emergency ir',
          'coiling the catastrophe'
        ].contains(lowerTitle)) {
          current = emergencyIrCount;
        } else if ([
          'ir arterial access',
          'ir with art line'
        ].contains(lowerTitle)) {
          current = irWithArtLineCount;
        } else if (['ir night shift'].contains(lowerTitle)) {
          current = irNightShiftCount;
        } else if (['ir trauma assist'].contains(lowerTitle)) {
          current = irTraumaCount;
        } else if (['paediatric ir'].contains(lowerTitle)) {
          current = paediatricIrCount;
        } else if ([
          'lead apron workout',
          'long wire day',
          'ir long case',
          'ir long uneventful'
        ].contains(lowerTitle)) {
          current = irLongCase;
        } else if (['angio suite hostage'].contains(lowerTitle)) {
          current = ir4hCase;
        } else if (['cath lab calm', 'ir contrast caution'].contains(lowerTitle)) {
          current = irUneventful;
        } else if ([
          'beam me up',
          'beam me up, scotty',
          'radio regular',
          'mask fit mindset',
          'thermoplastic master',
          'bunker tv',
          'groundhog day: bunker edition',
          'the radiation sentinel',
          'rt specialist',
          'rt heavy',
          'rt stillness master',
          'remote monitor',
          'repeat sitter'
        ].contains(lowerTitle)) {
          current = radiotherapyCount;
        } else if ([
          'the gentle beam',
          'tiny astronauts',
          'paediatric beam',
          'rt paeds series'
        ].contains(lowerTitle)) {
          current = paediatricRtCount;
        } else if (['rt early start'].contains(lowerTitle)) {
          current = rtEarlyStartCount;
        } else if (['rt mac mindset'].contains(lowerTitle)) {
          current = rtMacCount;
        } else if ([
          'zero movement streak',
          'rt uneventful',
          'rt with uneventful'
        ].contains(lowerTitle)) {
          current = rtUneventful;
        } else if ([
          'tiny heart',
          'paeds cardiac debut',
          'honey i shrunk the patient',
          'little circuit',
          'the congenital awakening',
          'paeds cardiac regular',
          'paeds cardiac specialist',
          'paeds cardiac heavy',
          'paeds cardiac mentor energy',
          'congenital series',
          'bypass buddy jr',
          'the tiny pump',
          'single ventricle support',
          'the broken blueprint'
        ].contains(lowerTitle)) {
          current = paedsCardiacCount;
        } else if ([
          'sweating in pediatrics',
          'paeds cardiac emergency'
        ].contains(lowerTitle)) {
          current = paedsCardiacEmergencyCount;
        } else if ([
          'spaghetti junction',
          'paeds cardiac lines',
          'congenital lines ace'
        ].contains(lowerTitle)) {
          current = paedsCardiacLinesCount;
        } else if (['paeds cardiac night'].contains(lowerTitle)) {
          current = paedsCardiacNightCount;
        } else if (['neonatal heart'].contains(lowerTitle)) {
          current = paedsCardiacNeonateCount;
        } else if ([
          'congenital calm',
          'paeds cardiac uneventful pack'
        ].contains(lowerTitle)) {
          current = paedsCardiacUneventful;
        } else if (['paeds cardiac and nicu'].contains(lowerTitle)) {
          current = (paedsCardiacCount > 0 && neonateCount > 0) ? 1 : 0;
        } else if (['specialty starter pack', 'new frontier five'].contains(lowerTitle)) {
          current = newSpecialtySet.length;
        } else if (['dark room and beam'].contains(lowerTitle)) {
          current = (irCount > 0 ? 1 : 0) + (radiotherapyCount > 0 ? 1 : 0);
        } else if (['airway adjacent specialist'].contains(lowerTitle)) {
          current = dentalMaxilloCount +
              getMatchingCasesCount(['Head and Neck', 'ENT', 'Otolaryngology']);
        } else if (['maxillo spine crossover'].contains(lowerTitle)) {
          current =
              (dentalMaxilloCount > 0 && getMatchingCasesCount(['Spine']) > 0)
                  ? 1
                  : 0;
        } else if (['specialty polyglot', 'list diversifier'].contains(lowerTitle)) {
          current = allUsedSpecialties.length;
        } else if ([
          'new specialty regular',
          'mixed frontier 25',
          'mixed frontier 100',
          'frontier anaesthetist',
          'documentation maximalist',
          'frontier legend',
          'new specialty emergency',
          'night frontier',
          'weekend frontier',
          'paeds frontier',
          'elderly frontier',
          'asa3 frontier',
          'asa4 frontier'
        ].contains(lowerTitle)) {
          current = newSpecialtyCombined;
        } else if (['modern logbook'].contains(lowerTitle)) {
          current = newSpecialtySet.length;
        } else if (['all new specialties x5'].contains(lowerTitle)) {
          final mins = [
            dentalMaxilloCount,
            bariatricSurgCount,
            irCount,
            radiotherapyCount,
            paedsCardiacCount
          ];
          current = mins.where((e) => e >= 5).length == 5
              ? 5
              : mins.where((e) => e >= 5).length;
        } else if (['multi frontier day'].contains(lowerTitle)) {
          current = newSpecialtySet.length >= 2 ? 2 : newSpecialtySet.length;
        } else if ([
          'complete new set',
          'triple explorer',
          'expansion complete badge',
          'cross pollinator'
        ].contains(lowerTitle)) {
          int parts = 0;
          if (newSpecialtyCombined > 0) parts++;
          if (fasciaIliacaCount + psoasPlaneCount > 0) parts++;
          if (newComplicationEventTotal > 0) parts++;
          current = parts;
        } else if (['balanced expansion'].contains(lowerTitle)) {
          current = [
            newSpecialtyCombined,
            fasciaIliacaCount + psoasPlaneCount,
            newComplicationEventTotal
          ].map((e) => e >= 25 ? 25 : e).reduce((a, b) => a < b ? a : b);
        } else if (['etherlog expansionist'].contains(lowerTitle)) {
          current = newSpecialtyCombined +
              fasciaIliacaCount +
              psoasPlaneCount +
              newComplicationEventTotal;
        } else if (['ir with art line', 'ir arterial access'].contains(lowerTitle)) {
          current = irWithArtLineCount;
        } else if (['bariatric with art line', 'bariatric art line', 'ultrasound deep dive'].contains(lowerTitle)) {
          current = bariatricWithArtLineCount;
        } else if (['maxillo with difficult airway flag', 'maxillo difficult airway'].contains(lowerTitle)) {
          current = maxilloDifficultAirwayCount;
        } else if (['next chapter'].contains(lowerTitle)) {
          current = totalCases;
        } else if (['registry explorer'].contains(lowerTitle)) {
          current = newSpecialtyCombined >= 10 ? 10 : newSpecialtyCombined;
        } else if (['quiet excellence', 'outcome first'].contains(lowerTitle)) {
          current = uneventfulCount;
        } else if (['bariatric vl preferrer'].contains(lowerTitle)) {
          current = bariatricSurgCount;
        } else {
          current = getMatchingCasesCount([title]);
        }
      } else if (cat == 'Techniques') {
        if ([
          'gas man/woman',
          'volatile regular',
          'inhalational expert',
          'volatile master'
        ].contains(lowerTitle)) {
          current = gaCount;
        } else if ([
          'white milk',
          'white magic',
          'propofol pro',
          'tiva specialist',
          'total intravenous master',
          'tiva innovator'
        ].contains(lowerTitle)) {
          current = tivaCount;
        } else if ([
          'the overachiever',
          'overachiever',
          'half and half',
          'cse regular',
          'cse expert'
        ].contains(lowerTitle)) {
          current = cseCount;
        } else if ([
          'spinal pioneer',
          'sab regular',
          'spinal master',
          'spinal king'
        ].contains(lowerTitle)) {
          current = spinalCount;
        } else if ([
          'epidural explorer',
          'epidural regular',
          'epidural expert',
          'epidural queen'
        ].contains(lowerTitle)) {
          if (lowerTitle == 'epidural queen') {
            current = epiduralQueenCount;
          } else {
            current = epiduralCount;
          }
        } else if ([
          'mac daddy',
          'smooth sedation',
          'sedation master',
          'mac specialist'
        ].contains(lowerTitle)) {
          current = macCount;
        } else if (['local hero', 'standby mode'].contains(lowerTitle)) {
          current = localOnlyCount;
        } else if (['peripheral primary', 'nerve block specialist']
            .contains(lowerTitle)) {
          current = pnbCount;
        } else if (['versatile anaesthetist'].contains(lowerTitle)) {
          current = uniqueTechniques.length;
        } else if (['awake regional'].contains(lowerTitle)) {
          current = awakeRegionalCount;
        } else if (['regional purist'].contains(lowerTitle)) {
          current = regionalPuristCount;
        } else if (['deep sleep 100', 'deep sleep 250', 'deep sleep 500']
            .contains(lowerTitle)) {
          current = gaOrTivaCount;
        } else {
          current = totalCases;
        }
      } else if (cat == 'Airway') {
        if ([
          'tube is in',
          'tube beginner',
          'tube regular',
          'master of the tube',
          'ett veteran',
          'ett grandmaster',
          'intubation performed'
        ].contains(lowerTitle)) {
          current = ettCount;
        } else if ([
          'mask on',
          'lma beginner',
          'lma regular',
          'lma enthusiast',
          'lma veteran',
          'lma performed'
        ].contains(lowerTitle)) {
          current = lmaCount;
        } else if (['bare minimum', 'just bagging'].contains(lowerTitle)) {
          current = facemaskOnlyCount;
        } else if (['surgical airway', 'trach team'].contains(lowerTitle)) {
          current = tracheostomyCount;
        } else if (['high pressure'].contains(lowerTitle)) {
          current = jetVentilationCount;
        } else if (['lung isolation', 'thoracic airway', 'dlt expert']
            .contains(lowerTitle)) {
          current = dltCount;
        } else if (['bronchial blocker', 'blocker pro'].contains(lowerTitle)) {
          current = bronchialBlockerCount;
        } else if (lowerTitle == 'classic touch') {
          current = _getLmaBrandMatchCount(cases, ['classic', 'cls']);
        } else if (lowerTitle == 'proseal pro') {
          current = _getLmaBrandMatchCount(
              cases, ['proseal', 'pro-seal', 'pro seal', 'psl']);
        } else if (lowerTitle == 'gel fit') {
          current = _getLmaBrandMatchCount(
              cases, ['i-gel', 'igel', 'i gel', 'gelfit']);
        } else if (lowerTitle == 'supreme leader') {
          current = _getLmaBrandMatchCount(cases, ['supreme', 'sup']);
        } else if (lowerTitle == 'ambu airway') {
          current = _getLmaBrandMatchCount(cases, ['ambu', 'ambuaura', 'aura']);
        } else if (lowerTitle == 'fast and flexible') {
          current = _getLmaBrandMatchCount(cases,
              ['fastrach', 'flexible', 'ila', 'fast track', 'fast-track']);
        } else if (lowerTitle == 'nose knows best') {
          current = nasalIntubationCount > 0 ? 1 : 0;
        } else if (lowerTitle == 'nasal navigator') {
          current = nasalIntubationCount;
        } else if (lowerTitle == 'nasal expert') {
          current = nasalIntubationCount;
        } else if (lowerTitle == 'below the chin') {
          current = _getIntubationOptionCount(cases, 'submental intubation');
        } else if ([
          'screen time',
          'video beginner',
          'video star',
          'video master'
        ].contains(lowerTitle)) {
          current = getAirwayMatchingCasesCount(cases, [
            'video',
            'glidescope',
            'cmac',
            'vle',
            'videolaryngoscope',
            'video laryngoscope'
          ]);
        } else if ([
          'awake and aware',
          'awake fos pro',
          'awake master',
          'awake fiberoptic performer'
        ].contains(lowerTitle)) {
          current = awakeFosCount;
        } else if ([
          'asleep fiberoptic',
          'asleep fos pro',
          'asleep fiberoptic performer'
        ].contains(lowerTitle)) {
          current = asleepFosCount;
        } else if (['fiberoptic master'].contains(lowerTitle)) {
          current = awakeFosCount + asleepFosCount;
        } else if (lowerTitle == 'micro manager' ||
            lowerTitle == 'microcuff manager') {
          current = getAirwayMatchingCasesCount(
              cases, ['microcuff', 'micro cuff', 'micro-cuff']);
        } else if (lowerTitle == 'bending the rules') {
          current = getAirwayMatchingCasesCount(cases, [
            'rae',
            'flexometallic',
            'armoured',
            'armored',
            'spiral',
            'reinforced',
            'rae tube',
            'north rae',
            'south rae'
          ]);
        } else if (['cormack grade 1'].contains(lowerTitle)) {
          current = cormack1Count;
        } else if (['cormack grade 2'].contains(lowerTitle)) {
          current = cormack2Count;
        } else if (['blind spot', 'grade 3 collector'].contains(lowerTitle)) {
          current = cormack3Count;
        } else if ([
          'in the dark',
          'grade 4 survivor',
          'the blindfolded archer',
          'blindfolded archer'
        ].contains(lowerTitle)) {
          current = cormack4Count;
        } else if (['first pass success', 'clean pass'].contains(lowerTitle)) {
          current = firstPassSuccessCount;
        } else if ([
          'third time\'s a charm',
          'third times a charm',
          'multi-attempt warrior'
        ].contains(lowerTitle)) {
          current = multiAttemptWarriorCount;
        } else if ([
          'the sweat gland',
          'sweat gland',
          'swear gland',
          'the swear gland',
          'tricky airway',
          'airway apprentice',
          'airway journeyman',
          'airway expert',
          'airway ninja',
          'the lord of the cords',
          'lord of the cords'
        ].contains(lowerTitle)) {
          current = difficultAirwayCount;
        } else if (['uncuffed care', 'uncuffed ett'].contains(lowerTitle)) {
          current = uncuffedEttCount;
        } else if (['cuffed standard', 'cuffed ett'].contains(lowerTitle)) {
          current = cuffedStandardCount;
        } else if (['the sneaky scope', 'sneaky scope'].contains(lowerTitle)) {
          current = asleepFosCount;
        } else if (['assisted airway'].contains(lowerTitle)) {
          current = assistedAirwayCount;
        } else if (['observed airway'].contains(lowerTitle)) {
          current = observedAirwayCount;
        } else if (['airway scholar'].contains(lowerTitle)) {
          current = airwayScholarCount;
        } else if (['airway legend'].contains(lowerTitle)) {
          bool hasEtt = ettCount > 0;
          bool hasLma = lmaCount > 0;
          bool hasVideo = getAirwayMatchingCasesCount(cases, [
                'video',
                'glidescope',
                'cmac',
                'vle',
                'videolaryngoscope',
                'video laryngoscope',
                'mcgrath',
                'king vision',
                'c-mac'
              ]) >
              0;
          bool hasFiberoptic = (awakeFosCount + asleepFosCount) > 0;
          bool hasDifficult = difficultAirwayCount > 0;
          bool hasNasal = nasalIntubationCount > 0;
          current = (hasEtt &&
                  hasLma &&
                  hasVideo &&
                  hasFiberoptic &&
                  hasDifficult &&
                  hasNasal)
              ? 1
              : 0;
        } else if (['emergency airway ace'].contains(lowerTitle)) {
          current = emergencyAirwayCount;
        } else if (lowerTitle == 'paediatric tube') {
          current = paediatricTubeCount > 0 ? 1 : 0;
        } else if (lowerTitle == 'giant tube') {
          current = giantTubeCount > 0 ? 1 : 0;
        } else {
          current = ettCount;
        }
      } else if (cat == 'Regional') {
        if ([
          'liquid gold',
          'spinal beginner',
          'spinal regular',
          'subarachnoid specialist',
          'spinal elite'
        ].contains(lowerTitle)) {
          current = spinalBlockCount;
        } else if ([
          'epidural explorer',
          'epidural regular',
          'epidural expert',
          'epidural master',
          'loss of resistance',
          'the spine whisperer',
          'spine whisperer'
        ].contains(lowerTitle)) {
          current = epiduralBlockCount;
        } else if ([
          'nerve block novice',
          'block beginner',
          'block regular',
          'block boss',
          'block expert',
          'block master',
          'the electrician',
          'electrician'
        ].contains(lowerTitle)) {
          current = peripheralBlockCount;
        } else if ([
          'sound waves',
          'usg beginner',
          'echogenic needle',
          'ultrasonic pro',
          'ultrasound master',
          'the sonographer',
          'sonographer',
          'the gel monster',
          'gel monster'
        ].contains(lowerTitle)) {
          current = usgRegionalCount;
        } else if (['twitcher', 'stimulator pro'].contains(lowerTitle)) {
          current = nerveStimulatorCount;
        } else if ([
          'continuous relief',
          'catheter champion',
          'continuous infusion pro',
          'continuous infusion expert',
          'the drip',
          'drip'
        ].contains(lowerTitle)) {
          current = catheterCount;
        } else if (['brachial plexus pro', 'upper limb legend']
            .contains(lowerTitle)) {
          current = interscaleneCount +
              supraclavicularCount +
              axillaryCount +
              infraclavicularCount;
        } else if (['interscalene specialist'].contains(lowerTitle)) {
          current = interscaleneCount;
        } else if (['supraclavicular specialist'].contains(lowerTitle)) {
          current = supraclavicularCount;
        } else if (['infraclavicular specialist'].contains(lowerTitle)) {
          current = infraclavicularCount;
        } else if (['axillary specialist'].contains(lowerTitle)) {
          current = axillaryCount;
        } else if (['lower limb legend', 'leg day'].contains(lowerTitle)) {
          current = femoralCount +
              sciaticCount +
              poplitealCount +
              adductorCanalCount +
              ankleBlockCount;
        } else if (['femoral specialist'].contains(lowerTitle)) {
          current = femoralCount;
        } else if (['adductor canal'].contains(lowerTitle)) {
          current = adductorCanalCount;
        } else if (['sciatic specialist'].contains(lowerTitle)) {
          current = sciaticCount;
        } else if (['popliteal specialist'].contains(lowerTitle)) {
          current = poplitealCount;
        } else if (lowerTitle == 'core control') {
          // Only TAP, rectus sheath, QL, ESP — as per description
          current = tapCount + rectusSheathCount + qlCount + espCount;
        } else if (lowerTitle == 'trunk tracker') {
          // All trunk/abdominal/chest-wall/paravertebral blocks
          current = tapCount +
              rectusSheathCount +
              qlCount +
              espCount +
              pecsCount +
              serratusCount +
              paravertebralCount;
        } else if (['tap block master', 'the tap dancer', 'tap dancer']
            .contains(lowerTitle)) {
          current = tapCount;
        } else if (['never skip leg day', 'leg day'].contains(lowerTitle)) {
          current = femoralCount +
              adductorCanalCount +
              sciaticCount +
              poplitealCount +
              ankleBlockCount +
              fasciaIliacaCount;
        } else if (['rectus sheath master'].contains(lowerTitle)) {
          current = rectusSheathCount;
        } else if (['ql block master'].contains(lowerTitle)) {
          current = qlCount;
        } else if (['esp block master'].contains(lowerTitle)) {
          current = espCount;
        } else if (['chest wall relief'].contains(lowerTitle)) {
          current = pecsCount + serratusCount;
        } else if (['pecs master'].contains(lowerTitle)) {
          current = pecsCount;
        } else if (['serratus master'].contains(lowerTitle)) {
          current = serratusCount;
        } else if (['paravertebral pro'].contains(lowerTitle)) {
          current = paravertebralCount;
        } else if (['neck and head', 'cervical plexus'].contains(lowerTitle)) {
          current = cervicalPlexusCount;
        } else if (['scalp blockade'].contains(lowerTitle)) {
          current = scalpBlockCount;
        } else if (['paediatric block', 'caudal epidural']
            .contains(lowerTitle)) {
          current = caudalCount;
        } else if (['ankle biter'].contains(lowerTitle)) {
          current = ankleBlockCount;
        } else if (['old school', 'bier block pro'].contains(lowerTitle)) {
          current = bierBlockCount;
        } else if (['plexus master'].contains(lowerTitle)) {
          current = plexusMasterCount;
        } else if (['block collector', 'block connoisseur']
            .contains(lowerTitle)) {
          current = uniqueRegionalTypes.length;
        } else if (['multi-block artist'].contains(lowerTitle)) {
          current = multiBlockCaseCount;
        } else if (['the regional god'].contains(lowerTitle)) {
          current =
              spinalBlockCount + epiduralBlockCount + peripheralBlockCount;
        } else if ([
          'fascia first',
          'fascia iliaca beginner',
          'fascia regular',
          'fascia specialist',
          'fascia master',
          'fascia fifty path',
          'nof blocker',
          'emergency fascia',
          'plane documentation ace'
        ].contains(lowerTitle)) {
          current = fasciaIliacaCount;
        } else if (['fascia usg'].contains(lowerTitle)) {
          current = fasciaUsgCount;
        } else if (['fascia catheter'].contains(lowerTitle)) {
          current = fasciaCatheterCount;
        } else if ([
          'fascia performed',
          'fascia performed fifty',
          'performed plane streak'
        ].contains(lowerTitle)) {
          current = fasciaPerformedCount;
        } else if (['fascia assisted'].contains(lowerTitle)) {
          current = fasciaAssistedCount;
        } else if ([
          'psoas first',
          'psoas beginner',
          'psoas regular',
          'psoas specialist',
          'psoas master',
          'psoas fifty path',
          'emergency psoas'
        ].contains(lowerTitle)) {
          current = psoasPlaneCount;
        } else if (['psoas usg'].contains(lowerTitle)) {
          current = psoasUsgCount;
        } else if (['psoas catheter'].contains(lowerTitle)) {
          current = psoasCatheterCount;
        } else if (['psoas performed', 'psoas performed fifty']
            .contains(lowerTitle)) {
          current = psoasPerformedCount;
        } else if (['psoas assisted'].contains(lowerTitle)) {
          current = psoasAssistedCount;
        } else if (['plane pair', 'iliac to psoas bridge']
            .contains(lowerTitle)) {
          current =
              (fasciaIliacaCount > 0 ? 1 : 0) + (psoasPlaneCount > 0 ? 1 : 0);
        } else if ([
          'lower limb plane day',
          'block for nof',
          'plane and specialty'
        ].contains(lowerTitle)) {
          current = fasciaIliacaCount + psoasPlaneCount > 0 ? 1 : 0;
        } else if (['deep plane duo'].contains(lowerTitle)) {
          current = multiBlockCaseCount;
        } else if (['plane usg pro', 'usg plane streak'].contains(lowerTitle)) {
          current = fasciaUsgCount + psoasUsgCount;
        } else if (['continuous plane'].contains(lowerTitle)) {
          current = fasciaCatheterCount + psoasCatheterCount;
        } else if (['plane and spinal'].contains(lowerTitle)) {
          current = planeWithSpinalCount;
        } else if (['plane collector jr', 'block diversifier']
            .contains(lowerTitle)) {
          current = uniqueRegionalTypes.length;
        } else if ([
          'block board newcomers',
          'regional new wave',
          'regional maximalist',
          'plane legend',
          'plane day list',
          'trauma plane pack',
          'emergency plane pack'
        ].contains(lowerTitle)) {
          current = fasciaIliacaCount + psoasPlaneCount;
        } else if (['plane night shift'].contains(lowerTitle)) {
          current = planeEmergencyCount;
        } else if (['plane in elderly'].contains(lowerTitle)) {
          current = planeElderlyCount;
        } else if (['plane in trauma'].contains(lowerTitle)) {
          current = planeTraumaCount;
        } else if (['bilateral energy'].contains(lowerTitle)) {
          current = multiBlockCaseCount > 0 ? 1 : 0;
        } else if (['plane explorer'].contains(lowerTitle)) {
          current = (fasciaIliacaCount + psoasPlaneCount).clamp(0, 10).toInt();
        } else {
          current =
              spinalBlockCount + epiduralBlockCount + peripheralBlockCount;
        }
      } else if (cat == 'Monitoring') {
        if ([
          'seeing red',
          'art line beginner',
          'art line regular',
          'art line ace',
          '100 beats per minute'
        ].contains(lowerTitle)) {
          current = artLineCount;
        } else if ([
          'central access',
          'dilator discipline',
          'cvc regular',
          'the lumen lord',
          "seldinger's true heir",
          'master of the mediastinum'
        ].contains(lowerTitle)) {
          current = cvcCount;
        } else if ([
          'x-ray vision',
          'ultrasound aficionado',
          'sonographic virtuoso'
        ].contains(lowerTitle)) {
          current = usgVascularCount;
        } else if ([
          'brain waves',
          'target 40 to 60',
          'numbers over vibes',
          'the cortical bouncer'
        ].contains(lowerTitle)) {
          current = bisEntropyCount;
        } else if (lowerTitle == 'infrared vision' ||
            lowerTitle == 'nirs independent') {
          current = nirsCount;
        } else if (lowerTitle == 'advanced brain' ||
            lowerTitle == 'master of the frontal lobe') {
          current = sedLineCount;
        } else if (lowerTitle == 'heart watcher') {
          current = teePaCatheterCount;
        } else if (lowerTitle == 'go with the flow') {
          current = cardiacOutputCount;
        } else if (lowerTitle == 'picco independent') {
          current = piccoCount;
        } else if (lowerTitle == 'this is spinal tap!' ||
            lowerTitle == 'subarachnoid drain pro') {
          current = lumbarDrainCount;
        } else if (lowerTitle == 'the cockpit crew') {
          current = multiMonitor3Count;
        } else if (lowerTitle == 'nasa mission control') {
          current = multiMonitor4Count;
        } else if (lowerTitle == 'line collector' ||
            lowerTitle == 'the omniscient anaesthetist') {
          current = uniqueMonitors.length;
        } else if (lowerTitle == 'arterial line assist') {
          current = artLineAssistCount;
        } else if (lowerTitle == 'guidewire guardian') {
          current = cvcAssistCount;
        } else if (lowerTitle == 'tci pump independent') {
          current = tciPumpMonitoringCount;
        } else if (lowerTitle == 'tee observer') {
          current = teeObserverCount;
        } else if (lowerTitle == 'pa catheter observer') {
          current = paCatheterObserverCount;
        } else {
          current = artLineCount + cvcCount;
        }
      } else if (cat == 'Demographics') {
        if ([
          'the micro-manager',
          'the micromanager',
          'micro-manager',
          'micromanager',
          'tiny patient',
          'nicu regular',
          'neonatal guardian'
        ].contains(lowerTitle)) {
          current = neonateCount;
        } else if ([
          'the pediatrician',
          'pediatrician',
          'infant care',
          'infant specialist'
        ].contains(lowerTitle)) {
          current = infantCount;
        } else if (['the negotiator', 'negotiator', 'toddler time']
            .contains(lowerTitle)) {
          current = toddlerCount;
        } else if (['paediatric pro', 'tiny tot surgeon']
            .contains(lowerTitle)) {
          current = pediatricTotalCount;
        } else if (['child care'].contains(lowerTitle)) {
          current = childCount;
        } else if (['adolescent care'].contains(lowerTitle)) {
          current = adolescentCount;
        } else if ([
          'golden years',
          'the fragile cargo',
          'geriatric guardian',
          'elderly protector',
          'senior specialist',
          'elderly care leader'
        ].contains(lowerTitle)) {
          current = elderlyCount;
        } else if (['octogenarian care', 'octogenarian club']
            .contains(lowerTitle)) {
          current = octogenarianCount;
        } else if (['centenarian'].contains(lowerTitle)) {
          current = centenarianCount;
        } else if (['bariatric basics', 'bariatric regular']
            .contains(lowerTitle)) {
          current = bariatric1Count;
        } else if (['bariatric specialist'].contains(lowerTitle)) {
          current = bariatric2Count;
        } else if (['extreme bmi', 'super bariatric', 'bariatric champion']
            .contains(lowerTitle)) {
          current = bariatric3Count;
        } else if (['the featherweight', 'lightweight', 'underweight expert']
            .contains(lowerTitle)) {
          current = underweightCount;
        } else if (['featherweight'].contains(lowerTitle)) {
          current = underweightAdultCount;
        } else if (['heavyweight'].contains(lowerTitle)) {
          current = heavyweightCount;
        } else if (['super heavyweight'].contains(lowerTitle)) {
          current = superHeavyweightCount;
        } else if (['spectrum of age'].contains(lowerTitle)) {
          current = ageBandsUsed.length;
        } else if (['spectrum of size'].contains(lowerTitle)) {
          current = bmiBandsUsed.length;
        } else if (['extremes of weight'].contains(lowerTitle)) {
          current = extremesOfWeightCount;
        } else if (['extreme age range'].contains(lowerTitle)) {
          current = (neonateCount > 0 && centenarianCount > 0) ? 1 : 0;
        } else if (['paediatric airway ace'].contains(lowerTitle)) {
          current = pediatricDifficultAirwayCount;
        } else if (['geriatric airway ace'].contains(lowerTitle)) {
          current = geriatricDifficultAirwayCount;
        } else {
          current = totalCases;
        }
      } else if (cat == 'Safety' || cat == 'Complications') {
        // --- classic safety ---
        if ([
          'the clean exit',
          'recovery room favorite',
          'pacu perfection',
          'untouchable record'
        ].contains(lowerTitle)) {
          current = perfectOutcomeCount;
        } else if (['the zone', 'untouchable streak', 'flawless month']
            .contains(lowerTitle)) {
          current = maxConsecutivePerfectOutcomeCount;
        } else if (['defying gravity', 'brink walker']
            .contains(lowerTitle)) {
          current = asa4PerfectCount;
        } else if (['miracle worker', 'the impossible standard']
            .contains(lowerTitle)) {
          current = asa5PerfectCount;
        } else if (['calm in the storm', 'storm rider', 'eye of the hurricane']
            .contains(lowerTitle)) {
          current = emergencyPerfectCount;
        } else if (['flawless airway', 'airway artisan', 'airway virtuoso']
            .contains(lowerTitle)) {
          current = difficultAirwayPerfectCount;
        } else if (['prudent pause', 'vigilant observer', 'watchful protector']
            .contains(lowerTitle)) {
          current = extendedMonitoringCount;
        } else if (['smooth handover', 'intensive care liaison']
            .contains(lowerTitle)) {
          current = hduCleanCount;
        } else if (['critical care anchor', 'the stabilizer']
            .contains(lowerTitle)) {
          current = icuCleanCount;
        } else if (['silver lining'].contains(lowerTitle)) {
          current = geriatricPerfectCount;
        } else if (['smooth sailing', 'century of safety', 'bulletproof streak']
            .contains(lowerTitle)) {
          current = uneventfulCount;
        } else if ([
          'the good luck charm',
          "the 'q' word",
          'the q word',
          'safe hands',
          'flawless week'
        ].contains(lowerTitle)) {
          current = maxConsecutiveUneventful;
        } else if (['quick wakeup', 'efficiency expert'].contains(lowerTitle)) {
          current = quickWakeupCount;
        } else if (['the bucket list', 'the exorcist protocol'].contains(lowerTitle)) {
          current = ponvCount;
        } else if (['how low can you go?'].contains(lowerTitle)) {
          current = hypotensionCount;
        } else if (['the iron lungs', "darth vader's chokehold"].contains(lowerTitle)) {
          current = bronchospasmCount;
        } else if (['the deep breath', 'blue moon rising'].contains(lowerTitle)) {
          current = desaturationCount;
        } else if (['safe recovery'].contains(lowerTitle)) {
          current = pacuDischargeCount;
        }
        // --- per-type ladders ---
        else if ([
          'shiver starter',
          'shiver handler',
          'thermal debt collector',
          'thermodynamic sorcerer',
          'shiver legend track'
        ].contains(lowerTitle)) {
          current = shiveringCount;
        } else if ([
          'blow off some steam, bennett!',
          'hypertension tamer',
          'hypertension regular',
          'the high-pressure architect',
          'hypertension legend',
          'the volcano',
          'volcano'
        ].contains(lowerTitle)) {
          current = hypertensionCompCount;
        } else if ([
          "we're gonna need a bigger boat",
          'blood bank vip',
          'bleeding regular',
          "dracula's accountant",
          'bleeding legend',
          'passing the baton'
        ].contains(lowerTitle)) {
          current = bleedingCompCount;
        } else if ([
          'the cold never bothered me anyway',
          'warm bodies',
          'hypothermia regular',
          'hypothermia specialist',
          'hypothermia legend'
        ].contains(lowerTitle)) {
          current = hypothermiaCompCount;
        } else if ([
          'rhythm check',
          'arrhythmia handler',
          'arrhythmia regular',
          'mozart of the monitor',
          'arrhythmia legend',
          'the dj',
          'dj'
        ].contains(lowerTitle)) {
          current = arrhythmiaCompCount;
        } else if (lowerTitle.contains('air where it shouldn') ||
            [
              'flat tire mechanic',
              'the lung whisperer',
              'lord of the pleura',
              'pop goes the pleura'
            ].contains(lowerTitle)) {
          current = pneumothoraxCount;
        } else if ([
          'red alert in theatre',
          'transfusion connoisseur',
          "the blood bank's best customer",
          'total body replacement'
        ].contains(lowerTitle)) {
          current = massiveBloodLossCount;
        } else if ([
          "bad blood (taylor's version)",
          'not on my watch',
          'cross-match critic',
          'hemovigilance officer'
        ].contains(lowerTitle)) {
          current = transfusionReactionCount;
        } else if (['trust the checklist'].contains(lowerTitle)) {
          // Transfusion reaction AND MTP / massive blood loss both logged at least once
          current = (transfusionReactionCount > 0 ? 1 : 0) +
              (massiveBloodLossCount > 0 ? 1 : 0);
        } else if ([
          'air embolus alert',
          'air bender',
          'the entrapment officer',
          'sub-atmospheric ace',
          'bubble trouble'
        ].contains(lowerTitle)) {
          current = vaeCount;
        } else if ([
          'the gastric redemption',
          'the bronchial lifeguard',
          'acid reflux avenger',
          'the alveolar shield'
        ].contains(lowerTitle)) {
          current = aspirationCount;
        } else if (['aspiration avoider energy'].contains(lowerTitle)) {
          // progress toward 10 uneventful after an aspiration event (approximate with uneventful streak if aspiration seen)
          current = aspirationCount > 0
              ? maxConsecutiveUneventful.clamp(0, target)
              : 0;
        } else if ([
          'failed tube',
          'failed intubation handler',
          'failed intubation regular',
          'failed intubation specialist'
        ].contains(lowerTitle)) {
          current = failedIntubationCompCount;
        } else if ([
          'mask trouble',
          'not that dmv!',
          'seal of approval',
          'the grip of steel'
        ].contains(lowerTitle)) {
          current = dmvCount;
        } else if ([
          'complication collector',
          'complication connoisseur',
          'complication scholar'
        ].contains(lowerTitle)) {
          current = newCompTypesSeen.length;
        } else if ([
          'crisis catalogue',
          'crisis catalogue 50',
          'morbidity & mastery',
          'safety net expanded',
          'safety expansion 10',
          'safety expansion 25',
          'safety expansion 75',
          'safety expansion 100',
          'the honest scalpel',
          'no skeletons in the closet',
          'complication teacher',
          'safety explorer',
          ].contains(lowerTitle)) {
          current = newComplicationEventTotal;
        } else if ([
          'boring is beautiful',
          'post event uneventful'
        ].contains(lowerTitle)) {
          current = maxConsecutiveUneventful;
        } else if (['fire & ice'].contains(lowerTitle)) {
          current = (shiveringCount > 0 ? 1 : 0) +
              (hypertensionCompCount > 0 ? 1 : 0);
        } else if (['lethal triad disruptor'].contains(lowerTitle)) {
          current = (bleedingCompCount > 0 ? 1 : 0) +
              (hypothermiaCompCount > 0 ? 1 : 0);
        } else if (['wrong hole, wrong place!'].contains(lowerTitle)) {
          // All three complications must appear somewhere in the logbook
          current = (aspirationCount > 0 ? 1 : 0) +
              (vaeCount > 0 ? 1 : 0) +
              (pneumothoraxCount > 0 ? 1 : 0);
        } else if (['the transparent intubator']
            .contains(lowerTitle)) {
          current =
              (failedIntubationCompCount > 0 ? 1 : 0) + (dmvCount > 0 ? 1 : 0);
        } else if (['complication night'].contains(lowerTitle)) {
          current = newCompNightCount;
        } else if (['complication in asa4'].contains(lowerTitle)) {
          current = newCompAsa4Count;
        } else if (["all's well that ends well"].contains(lowerTitle)) {
          current = newCompUneventfulExit;
        } else if (['multi complication case'].contains(lowerTitle)) {
          current = multiCompCaseCount;
        } else if (['boss fight: phase two'].contains(lowerTitle)) {
          current = compoundAirwayEventCount;
        } else if (['cirque du soleil'].contains(lowerTitle)) {
          current = multiComp3CaseCount;
        } else if (['emergency complication'].contains(lowerTitle)) {
          current = newCompEmergencyCount;
        } else if (['paeds complication'].contains(lowerTitle)) {
          current = newCompPaedsCount;
        } else if (['elderly complication'].contains(lowerTitle)) {
          current = newCompElderlyCount;
        } else if (['bariatric complication'].contains(lowerTitle)) {
          current = newCompBariatricCount;
        } else if (['maxillo complication'].contains(lowerTitle)) {
          current = newCompMaxilloCount;
        } else if (['ir complication'].contains(lowerTitle)) {
          current = newCompIrCount;
        } else if (['paeds cardiac complication'].contains(lowerTitle)) {
          current = newCompPaedsCardiacCount;
        } else if (['protect the plexus'].contains(lowerTitle)) {
          current = positionCompCount;
        } else if (['too high, too slow', 'too high too slow'].contains(lowerTitle)) {
          current = highSpinalCompCount;
        } else {
          current = newComplicationEventTotal;
        }
      } else if (cat == 'Post-Op & ERAS') {
        if ([
          'the morning rounder',
          'ward patrol',
          'the rounding regular',
          'the bedside philosopher',
          'recovery room royalty',
        ].contains(lowerTitle)) {
          current = completedFollowUps;
        } else if ([
          'cast iron stomach',
          'the motion sickness shield',
          'emesis basin extinction',
          'the ironclad gut',
        ].contains(lowerTitle)) {
          current = zeroPonvCount;
        } else if ([
          'whisper of pain',
          'comfort zone',
          'the analgesic architect',
          'pain? what pain?',
        ].contains(lowerTitle)) {
          current = lowRestPainCount;
        } else if ([
          'catheter navigator',
          'the infusion conductor',
          'continuous flow master',
        ].contains(lowerTitle)) {
          current = catheterPlacedCount;
        } else if ([
          'the sensory scout',
          'dermatome detective',
          'block resolution specialist',
          'the regional audit master',
        ].contains(lowerTitle)) {
          current = blockAssessmentCount;
        } else if (lowerTitle == 'dense & direct') {
          current = sensoryBlockDenseCount;
        } else if (lowerTitle == 'motor recovery marshal') {
          current = motorBlockResolvedCount;
        } else if (lowerTitle == 'zero deficit guarantee') {
          current = zeroNerveDeficitCount;
        } else if (lowerTitle == 'eras trailblazer') {
          current = erasTrailblazerCount;
        }
      } else if (cat == 'Mentorship') {
        if ([
          'passing the torch',
          'the guiding light',
          'patience of a saint',
          'the professor of gas',
          'the master mentor',
          'hands in pockets',
          'the college tutor',
          'training programme director',
          'yoda of the airway',
          'the grand chancellor of gas',
          'the dean of narcosis',
        ].contains(lowerTitle)) {
          current = supervisedTraineeCount;
        } else if ([
          'baptism of fire',
          'nightshift guardian',
          'code red wingman',
        ].contains(lowerTitle)) {
          current = supervisedEmergencyCount;
        } else if ([
          'fragile ground',
          'high-stakes shepherd',
          'the hemodynamic zen master',
        ].contains(lowerTitle)) {
          current = supervisedAsa4Count;
        } else if ([
          'the calm in the cords',
          'difficult airway wingman',
        ].contains(lowerTitle)) {
          current = supervisedDifficultAirwayCount;
        } else if (lowerTitle == 'the fiberoptic sherpa') {
          current = supervisedFiberopticCount;
        } else if ([
          'micro-dose mentor',
          'paediatric co-pilot',
        ].contains(lowerTitle)) {
          current = supervisedPaedsCount;
        } else if (lowerTitle == 'the neonatal whisperer guide') {
          current = supervisedNeonateCount;
        } else if ([
          'flashback sherpa',
          'vascular navigator',
        ].contains(lowerTitle)) {
          current = supervisedInvasiveLinesCount;
        } else if ([
          'probe & needle sensei',
          'the fascial plane coach',
        ].contains(lowerTitle)) {
          current = supervisedRegionalBlocksCount;
        } else if ([
          'rare bird hunter',
          'curator of oddities',
          'cabinet of curiosities',
          'living medical journal',
        ].contains(lowerTitle)) {
          current = starredCount;
        }
      } else if (cat == 'Portfolio') {
        if ([
          'signed, sealed, delivered',
          'the photographic ledger',
          'paperless perfectionist',
          'the forensic archivist',
        ].contains(lowerTitle)) {
          current = caseSheetPhotoCount;
        } else if ([
          'grade a glottis',
          'vocal cord cartographer',
          'the laryngeal scholar',
        ].contains(lowerTitle)) {
          current = cormackLehaneDocumentedCount;
        } else if ([
          'the anatomical scribe',
          'hardware cataloguer',
        ].contains(lowerTitle)) {
          current = hardwareScribeCount;
        } else if ([
          'the meticulous scribe',
          'the clinical essayist',
        ].contains(lowerTitle)) {
          current = detailedNotesCount;
        }
      } else if (cat == 'PAC Clinic') {
        if ([
          'the gatekeeper',
          'gatekeeper',
          'fasting enforcer',
          'mallampati scout',
          'the optimiser',
          'optimiser',
          'century of clearances',
          'clinic workhorse',
          'pre-op veteran',
          'risk stratifier',
          'chief of pre-assessment',
          'the iron stamp',
          'iron stamp',
          'oracle of the clinic',
        ].contains(lowerTitle)) {
          current = totalPacPatients;
        } else if ([
          'warm-up lap',
          'double digits',
          'morning surge',
          'conveyor belt',
          'quarter-century sprint',
          'clinic marathon',
          'pre-op engine',
          'clinical centrifuge',
          'industrial throughput',
          'the village cleared',
          'village cleared',
        ].contains(lowerTitle)) {
          current = maxPacSingleDay;
        } else if ([
          'first clinic call',
          'clinic regular',
          'outpatient rhythm',
          'clinic resident',
          'pre-op anchor',
          'seasoned assessor',
          'century of clinics',
          'master of the waiting room',
          'the permanent fixture',
          'permanent fixture',
          'a year in pre-op',
          'year in pre-op',
        ].contains(lowerTitle)) {
          current = totalPacDays;
        } else {
          current = totalPacPatients;
        }
      } else {
        if (lowerTitle == 'identity verified' || lowerTitle == 'the bureaucrat')
          current = profileComplete ? 1 : 0;
        else if (lowerTitle == 'data scientist')
          current = pdfExportCount.clamp(0, 1);
        else if (lowerTitle == 'paper trail' || lowerTitle == 'the hoarder')
          current = pdfExportCount.clamp(0, 1);
        else if (lowerTitle == 'logbook archivist')
          current = pdfExportCount;
        else if (lowerTitle == 'safety first' ||
            lowerTitle == 'backup fanatic' ||
            lowerTitle == 'the paranoid')
          current = jsonBackupCount;
        else if (lowerTitle == 'points on the board')
          current = totalPoints;
        else if (lowerTitle == 'leveling up' || lowerTitle == 'the high scorer')
          current = totalPoints >= 1000 ? 1000 : totalPoints;
        else if (lowerTitle == 'prestige')
          current = totalPoints >= 5000 ? 5000 : totalPoints;
        else if (lowerTitle == 'etherlog legend')
          current = totalPoints >= 10000 ? 10000 : totalPoints;
        else if (lowerTitle == 'mythical practitioner')
          current = totalPoints >= 25000 ? 25000 : totalPoints;
        else if (lowerTitle == 'logbook ascendant')
          current = totalPoints >= 50000 ? 50000 : totalPoints;
        else if (lowerTitle == 'the singularity')
          current = totalPoints >= 100000 ? 100000 : totalPoints;
        else
          current = totalCases;
      }

      if (current > target) current = target;
      bool unlocked = current >= target;

      final tier = _resolveTier(
        title: title,
        desc: item['desc'] ?? '',
        target: target,
        explicit: item['tier'],
      );
      achievements.add(Achievement(
        id: item['id'] ?? 'ach_$i',
        title: title,
        description: item['desc'] ?? '',
        category: cat,
        icon: _getIconForCategory(cat),
        currentProgress: current,
        maxProgress: target,
        isUnlocked: unlocked,
        tier: tier,
        iconColor: tier.color,
      ));
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final historyStr = prefs.getString('achievement_history_json');
      Map<String, String> history = {};
      if (historyStr != null && historyStr.isNotEmpty) {
        history = Map<String, String>.from(jsonDecode(historyStr));
      }

      bool updated = false;
      final nowStr = DateTime.now().toIso8601String();

      for (int i = 0; i < achievements.length; i++) {
        final a = achievements[i];
        if (a.isUnlocked) {
          if (!history.containsKey(a.id)) {
            history[a.id] = nowStr;
            updated = true;
          }
          achievements[i] = Achievement(
            id: a.id,
            title: a.title,
            description: a.description,
            icon: a.icon,
            isUnlocked: a.isUnlocked,
            currentProgress: a.currentProgress,
            maxProgress: a.maxProgress,
            category: a.category,
            tier: a.tier,
            iconColor: a.iconColor,
            unlockedAt: DateTime.tryParse(history[a.id]!),
          );
        }
      }

      if (updated) {
        await prefs.setString('achievement_history_json', jsonEncode(history));
      }
    } catch (_) {}

    return achievements;
  }
}

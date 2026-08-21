import 'dart:convert';
import 'dart:io';
import 'dart:math';

void main() {
  final random = Random(42);
  final cases = <Map<String, dynamic>>[];
  
  final start = DateTime(2024, 1, 1);
  final end = DateTime(2026, 8, 20);
  final numCases = 1000;
  
  final specialties = [
    'General Surgery', 'Orthopaedics', 'Obstetrics', 'Gynaecology', 
    'ENT', 'Urology', 'Maxillofacial', 'Plastics', 'Ophthalmology', 
    'Cardiothoracic', 'Neurosurgery', 'Vascular', 'Paediatrics', 'Trauma'
  ];
  
  final diagnoses = {
    'Orthopaedics': ['Neck of Femur Fracture', 'Total Knee Replacement', 'Total Hip Replacement', 'Ankle Fracture', 'ACL Reconstruction', 'Shoulder Arthroscopy'],
    'General Surgery': ['Acute Appendicitis', 'Laparoscopic Cholecystectomy', 'Inguinal Hernia', 'Bowel Resection', 'Perforated Ulcer'],
    'Obstetrics': ['Emergency Caesarean Section', 'Elective Caesarean Section', 'Retained Placenta', 'Perineal Tear'],
    'ENT': ['Tonsillectomy', 'Functional Endoscopic Sinus Surgery', 'Mastoidectomy', 'Thyroidectomy', 'Tracheostomy'],
    'Urology': ['TURP', 'TURBT', 'Nephrectomy', 'Cystoscopy', 'Ureteroscopy'],
    'Cardiothoracic': ['CABG', 'Valve Replacement', 'Lobectomy', 'VATS'],
    'Neurosurgery': ['Craniotomy for Tumor', 'Burr Hole', 'Spinal Fusion', 'Laminectomy'],
    'Trauma': ['Polytrauma', 'Open Tib/Fib Fracture', 'Pelvic Binder Application'],
  };
  
  final blocks = [
    'fascia iliaca', 'femoral', 'sciatic', 'popliteal', 'saphenous', 'adductor', 'ankle', 'lumbar plexus', 'sacral plexus', 'obturator', 'ipack',
    'interscalene', 'supraclavicular', 'infraclavicular', 'axillary', 'median', 'ulnar', 'radial', 'bier', 'forearm', 'suprascapular', 'musculocutaneous',
    'tap', 'rectus sheath', 'quadratus lumborum', 'ql', 'ilioinguinal', 'iliohypogastric', 'transversalis', 'erector spinae (lumbar)',
    'pecs', 'serratus', 'intercostal', 'brimp', 'pectointercostal',
    'spinal', 'epidural', 'cse', 'caudal', 'paravertebral', 'esp', 'erector spinae'
  ];
  
  var curr = start;
  var validDates = <DateTime>[];
  var weekendsPerMonth = <String, int>{}; 
  
  while (curr.isBefore(end)) {
    final monthKey = "${curr.year}-${curr.month}";
    weekendsPerMonth[monthKey] ??= 0;
    
    if (curr.weekday == DateTime.saturday || curr.weekday == DateTime.sunday) {
      if (weekendsPerMonth[monthKey]! < 2) {
        validDates.add(curr);
        weekendsPerMonth[monthKey] = weekendsPerMonth[monthKey]! + 1;
      }
    } else {
      validDates.add(curr);
    }
    curr = curr.add(Duration(days: 1));
  }
  
  for (int i=0; i<numCases; i++) {
    final date = validDates[random.nextInt(validDates.length)];
    final isEmergencyDay = date.weekday == DateTime.wednesday; 
    
    final specIndex = date.millisecondsSinceEpoch % specialties.length;
    final spec = specialties[specIndex];
    
    final diagList = diagnoses[spec] ?? ['Exploratory Laparotomy', 'Abscess Drainage', 'Excision of Lesion'];
    final diag = diagList[random.nextInt(diagList.length)];
    
    final isEmergency = isEmergencyDay || random.nextDouble() < 0.1;
    final priority = isEmergency ? 'Emergency' : 'Elective';
    
    final id = date.millisecondsSinceEpoch + i;
    final bmi = 18.5 + random.nextDouble() * (45.0 - 18.5);
    final cormack = ['1', '2a', '2b', '3', '4'][random.nextInt(10) < 6 ? 0 : random.nextInt(5)]; 
    
    final startHour = isEmergencyDay ? random.nextInt(24) : 8 + random.nextInt(10);
    final startMin = random.nextInt(60);
    final anaesDuration = 30 + random.nextInt(240); 
    final surgDuration = (anaesDuration * 0.8).toInt(); 
    
    final sDate = DateTime(date.year, date.month, date.day, startHour, startMin);
    final eDate = sDate.add(Duration(minutes: anaesDuration));
    
    final formatTime = (DateTime dt) => "${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}";
    final formatDur = (int mins) => "${(mins ~/ 60).toString().padLeft(2,'0')}:${(mins % 60).toString().padLeft(2,'0')}";
    
    final numBlocks = random.nextDouble() < 0.4 ? 1 : 0;
    final usedBlocks = <Map<String, dynamic>>[];
    for(int b=0; b<numBlocks; b++) {
      final tRand = random.nextDouble();
      final technique = tRand < 0.8 ? 'Ultrasound' : (tRand < 0.95 ? 'Nerve Stimulator' : 'Landmark');
      usedBlocks.add({
        "name": blocks[random.nextInt(blocks.length)],
        "technique": technique
      });
    }
    
    final outRand = random.nextDouble();
    String outcome = "Uneventful Recovery";
    List<String> complications = [];
    if (outRand < 0.05) {
      outcome = "HDU/ICU Admission";
      complications.add("Postoperative Nausea and Vomiting (PONV)");
    } else if (outRand < 0.1) {
      outcome = "Prolonged PACU Stay";
      complications.add("Desaturation");
    } else if (outRand < 0.12) {
      outcome = "Death / Major Morbidity";
      complications.add("Cardiac Arrest");
    }
    
    String airway = 'LMA';
    if (usedBlocks.isNotEmpty && random.nextDouble() < 0.5) airway = 'None (Regional)';
    if (isEmergency || surgDuration > 120 || spec == 'Cardiothoracic' || spec == 'Neurosurgery' || spec == 'ENT') airway = 'Endotracheal Tube';
    
    final invasives = <Map<String, dynamic>>[];
    if (spec == 'Cardiothoracic' || spec == 'Neurosurgery' || (isEmergency && random.nextDouble() < 0.2)) {
      invasives.add({"name": "Arterial Line", "site": "Radial"});
      if (random.nextDouble() < 0.5) invasives.add({"name": "Central Venous Catheter", "site": "Internal Jugular"});
    }

    cases.add({
      "id": id.toString(),
      "date": date.toIso8601String(),
      "patientAge": 18 + random.nextInt(70),
      "patientGender": random.nextBool() ? "Male" : "Female",
      "asaGrade": ["ASA 1", "ASA 2", "ASA 3", "ASA 4", "ASA 5"][random.nextInt(10) < 5 ? 1 : random.nextInt(5)],
      "priority": priority,
      "specialty": spec,
      "diagnosis": diag,
      "procedure": diag,
      "anaesthesiaTechniques": usedBlocks.isNotEmpty ? ["Regional"] : ["General"],
      "airwayManagement": airway,
      "cormackLehane": cormack,
      "bmi": double.parse(bmi.toStringAsFixed(1)),
      "anaesthesiaStartTime": formatTime(sDate),
      "anaesthesiaEndTime": formatTime(eDate),
      "anaesthesiaDuration": formatDur(anaesDuration),
      "surgeryStartTime": formatTime(sDate.add(Duration(minutes: 15))),
      "surgeryEndTime": formatTime(eDate.subtract(Duration(minutes: 10))),
      "surgeryDuration": formatDur(surgDuration),
      "regionalBlocks": usedBlocks,
      "invasiveMonitoring": invasives,
      "outcome": outcome,
      "complications": complications,
      "notes": isEmergency ? "Emergency call." : "Routine."
    });
  }
  
  final jsonStr = jsonEncode(cases);
  final outPath = r'C:\Users\joepe\.gemini\antigravity\brain\a97e5855-ccd7-4106-a5ee-98c9f8fc295e\realistic_logbook_v4.json';
  File(outPath).writeAsStringSync(jsonStr);
  print('Done generating 1000 cases at \$outPath');
}

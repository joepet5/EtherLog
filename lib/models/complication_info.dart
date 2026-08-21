class ComplicationInfo {
  final String title;
  final String overview;
  final List<String> immediateActions;
  final List<String> differentialDiagnosis;
  final List<String> references;

  const ComplicationInfo({
    required this.title,
    required this.overview,
    required this.immediateActions,
    required this.differentialDiagnosis,
    required this.references,
  });

  static ComplicationInfo getInfo(String complicationName) {
    final key = complicationName.toLowerCase().trim();

    if (key.contains('difficult bag') || key.contains('mask ventilation') || key.contains('difficult mask')) {
      return const ComplicationInfo(
        title: 'Difficult Bag and Mask Ventilation',
        overview: 'Inability of an unassisted clinician to maintain arterial oxygen saturation >90% or to prevent/reverse signs of inadequate ventilation during positive-pressure face mask ventilation.',
        immediateActions: [
          '1. Call for help immediately in accordance with Difficult Airway Society (DAS) protocols.',
          '2. Optimize head position (sniffing position) and apply an effective two-handed jaw thrust with a two-person bag-valve-mask technique.',
          '3. Insert an oropharyngeal (Guedel) or nasopharyngeal airway to relieve upper airway soft tissue obstruction.',
          '4. Check mask seal and eliminate air leaks; consider using a smaller or differently contoured face mask.',
          '5. If mask ventilation remains inadequate, immediately transition to a supraglottic airway device (e.g., LMA) or proceed to endotracheal intubation.'
        ],
        differentialDiagnosis: [
          'Edentulous patient architecture causing poor mask seal',
          'Obesity (high BMI) and obstructive sleep apnea (OSA)',
          'Facial hair, beard, or anatomical facial irregularities',
          'Upper airway soft tissue obstruction or pharyngeal collapse',
          'Advanced age and reduced lung compliance'
        ],
        references: [
          'Miller’s Anesthesia, 9th Edition - Chapter 43: Management of the Difficult Airway',
          'Difficult Airway Society (DAS) Guidelines for Unanticipated Difficult Airway Management'
        ],
      );
    }

    if (key.contains('cardiac arrest')) {
      return const ComplicationInfo(
        title: 'Perioperative Cardiac Arrest',
        overview: 'Cessation of mechanical cardiac activity confirmed by the absence of signs of circulation, requiring immediate, structured cardiopulmonary resuscitation and advanced life support.',
        immediateActions: [
          '1. Call for emergency assistance, initiate high-quality chest compressions immediately, and secure/verify airway with 100% oxygen ventilation.',
          '2. Connect defibrillator/monitor promptly and analyze cardiac rhythm (shockable vs. non-shockable).',
          '3. Administer Epinephrine 1 mg IV every 3-5 minutes for non-shockable rhythms (PEA/Asystole) or following the second shock for VF/pVT.',
          '4. Identify and treat reversible causes (H\'s and T\'s: Hypoxia, Hypovolemia, Hydrogen ion, Hypo/Hyperkalemia, Hypothermia, Tension pneumothorax, Tamponade, Toxins, Thrombosis).',
          '5. Temporarily pause or terminate surgical intervention if appropriate.'
        ],
        differentialDiagnosis: [
          'Massive hemorrhage / profound hypovolemic shock',
          'Tension pneumothorax or cardiac tamponade (obstructive shock)',
          'Severe acute hypoxia or airway obstruction',
          'Massive pulmonary embolism or coronary thrombosis',
          'Severe hyperkalemia or local anesthetic systemic toxicity (LAST)'
        ],
        references: [
          'Miller’s Anesthesia, 9th Edition - Chapter 89: Perioperative Cardiac Arrest and Resuscitation',
          'AHA / ERC Advanced Cardiac Life Support (ACLS) Guidelines'
        ],
      );
    }

    if (key.contains('death on table') || key.contains('mortality')) {
      return const ComplicationInfo(
        title: 'On-Table Mortality / Perioperative Death',
        overview: 'Catastrophic terminal event occurring intraoperatively or within the surgical suite due to overwhelming physiological failure, catastrophic surgical trauma, or acute anesthetic mishap.',
        immediateActions: [
          '1. Continue active resuscitation under ACLS algorithms unless valid, documented DNR orders or unsurvivable catastrophic injury (e.g., massive head trauma/cardiac rupture) exists.',
          '2. Secure airway, verify 100% oxygenation, and aggressively manage refractory shock or hemorrhage.',
          '3. Document a meticulous, chronological timeline of all vital signs, administered drugs, and interventions.',
          '4. Notify institutional clinical governance, department leadership, and initiate required medico-legal reporting protocols.'
        ],
        differentialDiagnosis: [
          'Catastrophic surgical hemorrhage or vascular injury',
          'Massive pulmonary embolism or amniotic fluid embolism',
          'Acute myocardial infarction or cardiac rupture',
          'Severe anaphylactic shock refractory to treatment',
          'Malignant hyperthermia crisis or tension pneumothorax'
        ],
        references: [
          'Miller’s Anesthesia, 9th Edition - Perioperative Mortality and Safety Governance',
          'National Audit Projects (NAP) on Perioperative Mortality (Royal College of Anaesthetists)'
        ],
      );
    }

    if (key.contains('position')) {
      return const ComplicationInfo(
        title: 'Perioperative Positioning Complications',
        overview: 'Neuromuscular injuries, ischemic skin breakdown, compartment syndrome, or ocular complications resulting from prolonged mechanical pressure, nerve stretch, or malpositioning.',
        immediateActions: [
          '1. Re-evaluate and immediately correct patient positioning if malpositioning is identified intraoperatively.',
          '2. Ensure meticulous joint padding and pressure-point relief (protecting ulnar nerve, common peroneal nerve, and brachial plexus).',
          '3. Perform a thorough neurological examination postoperatively if a nerve deficit or localized pain is reported.',
          '4. Request urgent neurology, physiotherapy, or specialized consultation for persistent deficits.'
        ],
        differentialDiagnosis: [
          'Ulnar neuropathy secondary to elbow pressure or pronation',
          'Brachial plexus stretch injury from excessive arm abduction (>90 degrees)',
          'Common peroneal nerve compression against leg supports',
          'Pressure-induced rhabdomyolysis or acute compartment syndrome',
          'Ischemic optic neuropathy secondary to prone positioning'
        ],
        references: [
          'Miller’s Anesthesia, 9th Edition - Chapter 37: Positioning and Associated Risks',
          'ASA Practice Advisory for the Prevention of Perioperative Peripheral Neuropathies'
        ],
      );
    }

    if (key.contains('shivering')) {
      return const ComplicationInfo(
        title: 'Post-Anaesthetic Shivering (PAS)',
        overview: 'Involuntary, rhythmic muscular activity occurring during emergence and recovery from anesthesia, significantly increasing oxygen consumption, metabolic rate, and myocardial workload.',
        immediateActions: [
          '1. Apply active forced-air warming systems (e.g., Bair Hugger) and warm cotton blankets immediately.',
          '2. Administer pharmacological anti-shivering agents (e.g., Pethidine/Meperidine 12.5-25 mg IV, Clonidine, or Tramadol).',
          '3. Provide supplemental oxygen via face mask to compensate for increased metabolic demand.',
          '4. Measure core body temperature and verify aggressive patient rewarming.'
        ],
        differentialDiagnosis: [
          'Perioperative core hypothermia',
          'Postoperative pain or nociceptive surgical stimulation',
          'Post-anesthetic emergence delirium',
          'Drug withdrawal or early allergic hypersensitivity reaction'
        ],
        references: [
          'Miller’s Anesthesia, 9th Edition - Chapter 90: Postoperative Recovery and PACU Management',
          'British Journal of Anaesthesia: Pathophysiology and Treatment of Post-Anaesthetic Shivering'
        ],
      );
    }

    if (key.contains('transfusion reaction')) {
      return const ComplicationInfo(
        title: 'Acute Transfusion Reaction',
        overview: 'Adverse immunological or non-immunological physiological response occurring during or following blood product administration, ranging from mild urticaria to fatal acute hemolytic reactions or TRALI.',
        immediateActions: [
          '1. Immediately stop the blood transfusion, disconnect tubing, and maintain IV access with normal saline.',
          '2. Re-verify patient identification band, blood unit label, and compatibility paperwork.',
          '3. Notify the blood bank immediately and return the blood bag alongside post-reaction blood and urine samples.',
          '4. Provide supportive resuscitation: IV fluid boluses and vasopressors for hypotension, loop diuretics for fluid overload, and bronchodilators for bronchospasm.'
        ],
        differentialDiagnosis: [
          'Acute hemolytic transfusion reaction (AHTR)',
          'Febrile non-hemolytic transfusion reaction (FNHTR)',
          'Allergic / Anaphylactic transfusion reaction',
          'Transfusion-associated acute lung injury (TRALI)',
          'Transfusion-associated circulatory overload (TACO)',
          'Bacterial contamination and septic transfusion reaction'
        ],
        references: [
          'Miller’s Anesthesia, 9th Edition - Chapter 48: Blood Management and Transfusion Reactions',
          'AABB Standards for Blood Banks and Transfusion Services'
        ],
      );
    }

    if (key.contains('massive blood loss') || key.contains('massive hemorrhage')) {
      return const ComplicationInfo(
        title: 'Massive Blood Loss & Hemorrhagic Shock',
        overview: 'Rapid, catastrophic loss of blood volume (exceeding one blood volume in 24 hours, or >50% in 3 hours) causing profound tissue hypoperfusion, metabolic acidosis, and acute coagulopathy.',
        immediateActions: [
          '1. Activate institutional Massive Transfusion Protocol (MTP) and request balanced ratios of blood products (PRBCs, FFP, platelets, cryoprecipitate).',
          '2. Direct resuscitation using point-of-care viscoelastic testing (ROTEM/TEG) or serial arterial blood gases.',
          '3. Aggressively prevent and treat the lethal triad: hypothermia, acidosis, and hypocalcemia.',
          '4. Coordinate urgently with the surgical team for immediate control of surgical bleeding sites.'
        ],
        differentialDiagnosis: [
          'Surgical vessel laceration or uncontrolled microvascular bleeding',
          'Dilutional coagulopathy from massive crystalloid/colloid infusion',
          'Disseminated intravascular coagulation (DIC)',
          'Hypothermia, acidosis, and hypocalcemia cascade'
        ],
        references: [
          'Miller’s Anesthesia, 9th Edition - Chapter 48: Blood Management, Coagulation, and Massive Transfusion',
          'European Guidelines on Management of Major Bleeding and Coagulopathy Following Trauma'
        ],
      );
    }

    if (key.contains('multiple intubation') || key.contains('failed intubation')) {
      return const ComplicationInfo(
        title: 'Multiple Intubation Attempts & Failed Intubation',
        overview: 'Inability to successfully place an endotracheal tube within standard clinical attempts, leading to airway trauma, laryngeal edema, hypoxia, and risk of a Cannot-Intubate-Cannot-Oxygenate (CICO) crisis.',
        immediateActions: [
          '1. Restrict intubation attempts to a maximum of 3 attempts by the most experienced operator (plus 1 rescue attempt).',
          '2. Declare a failed intubation and execute the Difficult Airway Society (DAS) Failed Intubation Algorithm.',
          '3. Insert a supraglottic airway device (e.g., LMA) to immediately restore oxygenation and ventilation.',
          '4. If oxygenation fails via rescue devices and SpO₂ drops, perform emergency front-of-neck access (surgical cricothyroidotomy) immediately.',
          '5. Consider waking the patient up if clinical stability and airway parameters permit.'
        ],
        differentialDiagnosis: [
          'Unanticipated difficult airway anatomy (Mallampati III/IV, limited mouth opening)',
          'Severe laryngeal edema, mass lesions, or airway hemorrhage',
          'Inappropriate equipment size or inadequate neuromuscular relaxation',
          'Operator fatigue or poor visualization conditions'
        ],
        references: [
          'Miller’s Anesthesia, 9th Edition - Chapter 43: Airway Management',
          'Difficult Airway Society (DAS) Guidelines for Unanticipated Difficult Intubation'
        ],
      );
    }

    if (key.contains('desaturation') || key.contains('hypoxia')) {
      return const ComplicationInfo(
        title: 'Perioperative Desaturation / Hypoxia',
        overview: 'Acute drop in arterial oxygen saturation (SpO₂) representing impaired systemic oxygenation, ventilation-perfusion mismatch, or absolute intrapulmonary shunting that threatens vital organ perfusion.',
        immediateActions: [
          '1. Immediately switch to 100% inspiratory oxygen and discontinue volatile anesthetic agents.',
          '2. Verify circuit integrity, oxygen supply pipeline pressure, and mechanical ventilator settings.',
          '3. Auscultate bilateral breath sounds and check chest wall expansion to exclude endobronchial intubation or mainstem migration.',
          '4. Check endotracheal tube or LMA position; inspect for kinking, biting, or secretions.',
          '5. Apply recruitment maneuvers and adjust PEEP if atelectasis or low functional residual capacity is suspected.',
          '6. Rule out catastrophic events such as tension pneumothorax, massive pulmonary embolism, or severe aspiration.'
        ],
        differentialDiagnosis: [
          'Endobronchial intubation (typically right mainstem)',
          'Airway obstruction, kinking, or displacement',
          'Aspiration of gastric contents',
          'Severe bronchospasm or laryngospasm',
          'Pneumothorax / Tension pneumothorax',
          'Massive pulmonary embolism or fat embolism',
          'Anesthesia machine or oxygen supply pipeline failure'
        ],
        references: [
          'Miller’s Anesthesia, 9th Edition - Chapter 85: Respiratory Complications in the Postoperative Period',
          'AAGBI Guidelines: Management of Severe Hypoxaemia during Anaesthesia (2015)'
        ],
      );
    }

    if (key.contains('hypotension')) {
      return const ComplicationInfo(
        title: 'Acute Perioperative Hypotension',
        overview: 'Acute reduction in systemic arterial pressure (MAP or SBP < 90 mmHg, or >25-30% drop from baseline) compromising cerebral, coronary, and renal perfusion pressure.',
        immediateActions: [
          '1. Temporarily lighten anesthetic depth by reducing volatile or TIVA infusion rates if appropriate.',
          '2. Inspect the surgical field with the surgical team to rule out acute hemorrhagic blood loss or major fluid shifts.',
          '3. Administer an immediate intravenous fluid bolus (balanced crystalloids) if hypovolemic.',
          '4. Titrate vasoactive support promptly (e.g., ephedrine bolus for combined heart rate/tone support, phenylephrine or noradrenaline infusion for vasodilation).',
          '5. Assess cardiac rhythm and contractility to exclude acute myocardial ischemia, failure, or severe arrhythmias.'
        ],
        differentialDiagnosis: [
          'Hypovolemia (surgical blood loss, preoperative dehydration)',
          'Sympatholysis secondary to neuraxial blockade (spinal/epidural anaesthesia)',
          'Excessive anesthetic depth or vasodilation from agents',
          'Anaphylactic or drug-induced hypersensitivity reaction',
          'Obstructive shock (tension pneumothorax, cardiac tamponade, pulmonary embolism)',
          'Acute myocardial infarction or acute heart failure'
        ],
        references: [
          'Miller’s Anesthesia, 9th Edition - Chapter 40: Hemodynamic Monitoring & Chapter 86: Cardiovascular Complications',
          'ASA Practice Guidelines for Perioperative Hemodynamic Management'
        ],
      );
    }

    if (key.contains('hypertension')) {
      return const ComplicationInfo(
        title: 'Acute Perioperative Hypertension',
        overview: 'Acute elevation in systemic blood pressure (>20-30% above baseline or SBP > 160 mmHg) increasing myocardial oxygen demand, left ventricular workload, and risk of hemorrhage or cerebral event.',
        immediateActions: [
          '1. Assess depth of anesthesia and analgesia (rule out inadequate pain control or light anesthesia).',
          '2. Verify adequacy of ventilation (rule out hypercarbia or hypoxia).',
          '3. Administer short-acting antihypertensive agents (e.g., labetalol, esmolol, nicardipine, or hydralazine).',
          '4. Ensure bladder distension or surgical retraction is not contributing to autonomic response.'
        ],
        differentialDiagnosis: [
          'Inadequate anesthesia or analgesia during stimulation',
          'Hypercarbia or hypoxia',
          'Pre-existing poorly controlled essential hypertension',
          'Hypervolemia or fluid overload',
          'Bladder distension or surgical retractor pressure'
        ],
        references: [
          'Miller’s Anesthesia, 9th Edition - Chapter 86: Cardiovascular Complications',
          'ASA Practice Guidelines for Perioperative Management of Hypertension'
        ],
      );
    }

    if (key.contains('bradycardia')) {
      return const ComplicationInfo(
        title: 'Acute Perioperative Bradycardia',
        overview: 'Heart rate dropping below 60 bpm (or relative bradycardia), potentially reducing cardiac output and coronary perfusion pressure.',
        immediateActions: [
          '1. Stop any triggering stimulus immediately (e.g., surgical traction, peritoneal manipulation, insufflation, or oculocardiac reflex).',
          '2. Administer anticholinergic agents (Atropine 0.01-0.02 mg/kg IV or Glycopyrrolate 0.005-0.01 mg/kg IV).',
          '3. Administer Ephedrine or Epinephrine if refractory or associated with significant hypotension.',
          '4. Check for hypoxia, hypercarbia, or deep volatile anesthetic depth.'
        ],
        differentialDiagnosis: [
          'Oculocardiac or viscerocardiac reflex (traction on peritoneum/mesentery)',
          'High spinal or epidural block affecting cardiac accelerators (T1-T4)',
          'Vagal stimulation or drug overdose (opioids, beta-blockers)',
          'Severe hypoxia or myocardial ischemia'
        ],
        references: [
          'Miller’s Anesthesia, 9th Edition - Perioperative Arrhythmias and Management',
          'ACLS Guidelines for Bradycardia Management'
        ],
      );
    }

    if (key.contains('tachycardia') || key.contains('arrhythmia')) {
      return const ComplicationInfo(
        title: 'Perioperative Tachycardia & Arrhythmias',
        overview: 'Elevated heart rate (>100 bpm) or abnormal cardiac rhythm increasing myocardial oxygen consumption and compromising diastolic ventricular filling time.',
        immediateActions: [
          '1. Assess and treat underlying physiological triggers (pain, light anesthesia, hypovolemia, hypoxia, hypercarbia, fever).',
          '2. Administer cardioselective beta-blockers (e.g., Esmolol, Metoprolol) if rhythm is supraventricular and ischemic risk is elevated.',
          '3. Check and correct serum electrolyte imbalances (K⁺, Mg²⁺).',
          '4. Follow advanced cardiac life support (ACLS) protocols if malignant or unstable arrhythmia occurs.'
        ],
        differentialDiagnosis: [
          'Hypovolemia or acute blood loss',
          'Inadequate analgesia / light anesthesia',
          'Hypercarbia, hypoxia, or sepsis',
          'Malignant hyperthermia early sign',
          'Electrolyte derangement (hypokalemia, hypomagnesemia)',
          'Drug-induced (anticholinergics, ephedrine, sympathomimetics)'
        ],
        references: [
          'Miller’s Anesthesia, 9th Edition - Perioperative Cardiac Arrest and Arrhythmias',
          'ACC/AHA Perioperative Cardiovascular Evaluation and Management Guidelines'
        ],
      );
    }

    if (key.contains('bronchospasm')) {
      return const ComplicationInfo(
        title: 'Acute Bronchospasm',
        overview: 'Acute constriction of airway smooth muscle resulting in elevated peak inspiratory pressures, expiratory wheezing, characteristic "shark-fin" capnography waveform, and dynamic alveolar hyperinflation.',
        immediateActions: [
          '1. Deepen anaesthesia immediately with propofol or volatile agents (sevoflurane/isoflurane are potent bronchodilators).',
          '2. Deliver short-acting inhaled beta-2 agonists via ETT (e.g., Salbutamol 4-8 puffs via metered-dose inhaler with spacer or inline nebulizer).',
          '3. Administer intravenous adjuncts (e.g., Magnesium sulfate 2g IV over 20 minutes, Hydrocortisone, or Dexamethasone).',
          '4. Prolong expiratory time on the ventilator to prevent air-trapping and dynamic auto-PEEP.',
          '5. Exclude mechanical tube kinking, mucus plugging, or endobronchial intubation via direct auscultation and suctioning.'
        ],
        differentialDiagnosis: [
          'Light plane of anaesthesia with nociceptive surgical stimulation',
          'Endobronchial intubation or bronchial migration',
          'Mucus plug or kinked endotracheal tube',
          'Aspiration of gastric contents',
          'Allergic drug reaction / Anaphylaxis',
          'Underlying reactive airway disease (asthma or COPD exacerbation)'
        ],
        references: [
          'Miller’s Anesthesia, 9th Edition - Chapter 65: Anesthesia for Patients with Respiratory Disease',
          'NICE Guidelines: Perioperative Airway Management and Complications'
        ],
      );
    }

    if (key.contains('laryngospasm')) {
      return const ComplicationInfo(
        title: 'Acute Laryngospasm',
        overview: 'Involuntary, sustained reflex closure of the true vocal cords causing partial or complete upper airway obstruction, most commonly precipitated during light planes of general anaesthesia during induction or emergence.',
        immediateActions: [
          '1. Immediately administer 100% oxygen via a tight-fitting face mask with high-flow continuous positive airway pressure (CPAP).',
          '2. Deepen anaesthesia immediately if intravenous access is functional (e.g., propofol 0.5-1 mg/kg IV).',
          '3. Apply firm manual pressure at the laryngospasm notch (Larson’s maneuver) combined with an effective jaw thrust.',
          '4. If refractory or oxygen desaturation occurs rapidly, administer a short-acting muscle relaxant (succinylcholine 0.5-1 mg/kg IV, or rocuronium if sux is contraindicated).',
          '5. Suction the pharynx gently and monitor closely for negative pressure pulmonary edema.'
        ],
        differentialDiagnosis: [
          'Foreign body, blood, or secretions in the upper airway',
          'Light plane of general anaesthesia with sensory stimulation',
          'Inadequate anesthetic depth during extubation sequence',
          'Upper airway anatomical obstruction'
        ],
        references: [
          'Miller’s Anesthesia, 9th Edition - Chapter 43: Management of the Difficult Airway',
          'Difficult Airway Society (DAS) Guidelines for Extubation and Emergence'
        ],
      );
    }

    if (key.contains('aspiration')) {
      return const ComplicationInfo(
        title: 'Pulmonary Aspiration of Gastric Contents',
        overview: 'Inhalation of solid or liquid gastric contents into the lower respiratory tract, leading to chemical pneumonitis (Mendelson syndrome), mechanical airway occlusion, or secondary bacterial infection.',
        immediateActions: [
          '1. Immediately place the patient in a head-down, lateral tilt position to promote gravity-mediated drainage away from the trachea.',
          '2. If the airway is unsecure, immediately secure the airway with a cuffed endotracheal tube and suction the tracheobronchial tree before initiating positive pressure ventilation.',
          '3. Administer 100% oxygen and assess gas exchange via pulse oximetry and arterial blood gases.',
          '4. Provide supportive intensive care management (PEEP titration, bronchodilators). Routine prophylactic antibiotics and steroids are generally withheld unless infection or severe ARDS develops.',
          '5. Transfer to ICU for ongoing respiratory monitoring and ventilatory support.'
        ],
        differentialDiagnosis: [
          'Non-aspirated intraoperative atelectasis or hypoxemia',
          'Cardiogenic or non-cardiogenic pulmonary edema',
          'Severe bronchospasm or mucous plugging',
          'Pulmonary embolism'
        ],
        references: [
          'Miller’s Anesthesia, 9th Edition - Chapter 85: Pulmonary Complications',
          'ASA Practice Guidelines for Preoperative Fasting and Aspiration Prophylaxis'
        ],
      );
    }

    if (key.contains('delayed') || key.contains('awakening') || key.contains('emergence')) {
      return const ComplicationInfo(
        title: 'Delayed Emergence from Anaesthesia',
        overview: 'Failure to regain consciousness or respond purposefully to verbal commands within the expected clinical timeframe (>30-45 minutes following cessation of general anesthetic delivery).',
        immediateActions: [
          '1. Ensure patent airway, stable hemodynamics, and adequate alveolar ventilation (monitor EtCO₂).',
          '2. Assess depth of neuromuscular blockade with a peripheral nerve stimulator; reverse residual paralysis completely with sugammadex or neostigmine/glycopyrrolate.',
          '3. Measure core body temperature and treat moderate-to-severe hypothermia (< 35°C).',
          '4. Check capillary blood glucose to rule out severe hypoglycemia.',
          '5. Review pharmacological history: prolonged action of opioids, benzodiazepines, or residual high-concentration volatile agents.',
          '6. Perform focused neurological exam or arrange urgent neuroimaging if central nervous system pathology is suspected.'
        ],
        differentialDiagnosis: [
          'Residual neuromuscular blockade or anesthetic drug overdose',
          'Severe hypothermia or metabolic derangements (hypoglycemia, severe hyponatremia)',
          'Central nervous system event (stroke, intracranial hemorrhage, hypoxic encephalopathy)',
          'Carbon dioxide narcosis (severe hypercarbia)',
          'Severe hepatic or renal encephalopathy'
        ],
        references: [
          'Miller’s Anesthesia, 9th Edition - Chapter 87: Neurological Complications and Postoperative Recovery',
          'British Journal of Anaesthesia: Evaluation and Management of Delayed Emergence'
        ],
      );
    }

    if (key.contains('anaphylaxis') || key.contains('allergic')) {
      return const ComplicationInfo(
        title: 'Perioperative Anaphylaxis',
        overview: 'Severe, life-threatening systemic hypersensitivity reaction characterized by acute cardiovascular collapse, bronchospasm, mucocutaneous flushing, and generalized urticaria.',
        immediateActions: [
          '1. Immediately discontinue all suspected trigger agents (antibiotics, neuromuscular blocking agents, colloids, latex).',
          '2. Call for senior assistance, secure airway, and ventilate with 100% oxygen.',
          '3. Administer Intramuscular Adrenaline (Epinephrine) 0.5 mg (0.5 mL of 1:1000) immediately; repeat every 5 minutes as needed. Start an IV adrenaline infusion if refractory.',
          '4. Rapid volume resuscitation with balanced crystalloid infusions (20 mL/kg bolus).',
          '5. Administer secondary adjunctive therapy (IV antihistamines and corticosteroids) once hemodynamics are stabilized.'
        ],
        differentialDiagnosis: [
          'Vasovagal syncope or profound regional block hypotension',
          'Severe acute asthma or COPD bronchospasm exacerbation',
          'Pulmonary aspiration pneumonitis',
          'Malignant hyperthermia crisis'
        ],
        references: [
          'Miller’s Anesthesia, 9th Edition - Chapter 39: Allergy and Anaphylaxis',
          'AAGBI Guidelines: Suspected Anaphylactic Reactions Associated with Anaesthesia (2021)'
        ],
      );
    }

    if (key.contains('malignant hyperthermia') || key.contains('mh')) {
      return const ComplicationInfo(
        title: 'Malignant Hyperthermia (MH) Crisis',
        overview: 'Rare, life-threatening pharmacogenetic hypermetabolic disorder triggered by volatile anaesthetic agents and succinylcholine, presenting with hypercapnia, tachycardia, muscle rigidity, and rapid hyperthermia.',
        immediateActions: [
          '1. Immediately discontinue all volatile agents and succinylcholine. Switch anesthesia machine to TIVA and flush system with 100% O₂ at > 10 L/min for at least 20 minutes.',
          '2. Call for help and request the Malignant Hyperthermia Cart.',
          '3. Administer Dantrolene sodium 2.5 mg/kg IV rapidly; repeat as necessary until symptoms subside.',
          '4. Initiate active cooling measures (cold IV saline, ice packs to groin/axillae).',
          '5. Correct hyperkalemia and metabolic acidosis aggressively. Transfer to ICU for ongoing monitoring.'
        ],
        differentialDiagnosis: [
          'Thyroid storm or pheochromocytoma crisis',
          'Neuroleptic malignant syndrome (NMS)',
          'Sepsis or acute blood transfusion reaction',
          'Inadequate depth of anaesthesia with hypercarbia'
        ],
        references: [
          'Miller’s Anesthesia, 9th Edition - Chapter 35: Malignant Hyperthermia',
          'Malignant Hyperthermia Association of the United States (MHAUS) Protocols'
        ],
      );
    }

    if (key.contains('pneumothorax')) {
      return const ComplicationInfo(
        title: 'Tension / Intraoperative Pneumothorax',
        overview: 'Accumulation of air within the pleural space leading to progressive lung collapse, mediastinal shift, and acute cardiovascular and respiratory compromise.',
        immediateActions: [
          '1. Discontinue nitrous oxide immediately if in use and switch 100% oxygen on.',
          '2. Inspect for asymmetric chest wall expansion, absent breath sounds on the affected side, and tracheal deviation.',
          '3. If tension pneumothorax is suspected, perform immediate needle decompression (2nd intercostal space, mid-clavicular line) or emergent chest tube insertion.',
          '4. Confirm expansion via bedside ultrasound or urgent chest radiography.'
        ],
        differentialDiagnosis: [
          'Mainstem intubation or bronchial obstruction',
          'Severe bronchospasm or tube kinking',
          'Pulmonary embolism or acute cardiac failure'
        ],
        references: [
          'Miller’s Anesthesia, 9th Edition - Chapter 74: Anesthesia for Thoracic Surgery',
          'ATLS Guidelines: Management of Thoracic Trauma and Pneumothorax'
        ],
      );
    }

    if (key.contains('nausea') || key.contains('vomiting') || key.contains('ponv')) {
      return const ComplicationInfo(
        title: 'Postoperative Nausea and Vomiting (PONV)',
        overview: 'Nausea, retching, or vomiting occurring in the immediate postoperative recovery window, causing patient distress, dehydration, electrolyte imbalance, and suture strain.',
        immediateActions: [
          '1. Administer rescue antiemetics from a different pharmacological class than prophylaxis (e.g., Ondansetron 4mg IV, Droperidol, Dexamethasone, or Prochlorperazine).',
          '2. Ensure adequate hydration with IV fluid boluses.',
          '3. Administer supplemental oxygen.',
          '4. Avoid postoperative opioids if possible and utilize multimodal non-opioid analgesia.'
        ],
        differentialDiagnosis: [
          'Opioid-induced nausea and vomiting',
          'Residual volatile anesthetic effects or nitrous oxide use',
          'Surgical procedure type (laparoscopy, gynecological, middle ear surgery)',
          'Vestibular stimulation or gastroparesis / full stomach'
        ],
        references: [
          'Miller’s Anesthesia, 9th Edition - Chapter 91: Postoperative Nausea and Vomiting',
          'APSF Guidelines for Management of PONV'
        ],
      );
    }

    if (key.contains('headache') || key.contains('pdph')) {
      return const ComplicationInfo(
        title: 'Post-Dural Puncture Headache (PDPH)',
        overview: 'Orthostatic headache resulting from cerebrospinal fluid (CSF) leakage through a dural defect following spinal anesthesia or inadvertent dural puncture during epidural placement.',
        immediateActions: [
          '1. Conservative management: Strict bed rest, adequate hydration, oral analgesics (caffeine, NSAIDs, paracetamol).',
          '2. Administer sphenopalatine ganglion block if indicated for acute relief.',
          '3. If symptoms persist >24-48 hours and are debilitating, perform an autologous epidural blood patch (EBP) using 15-20 mL of sterile autologous blood.'
        ],
        differentialDiagnosis: [
          'Post-lumbar puncture headache',
          'Pneumocephalus',
          'Migraine or tension headache',
          'Meningitis or intracranial pathology (subdural hematoma)'
        ],
        references: [
          'Miller’s Anesthesia, 9th Edition - Chapter 58: Post-Dural Puncture Headache',
          'SOAP Consensus Guidelines for Post-Dural Puncture Headache'
        ],
      );
    }

    if (key.contains('awareness')) {
      return const ComplicationInfo(
        title: 'Intraoperative Awareness with Recall',
        overview: 'Inadvertent explicit recall of sensory perceptions and events occurring during general anesthesia due to inadequate anesthetic depth relative to surgical stimulation.',
        immediateActions: [
          '1. Immediately deepen anesthesia if detected intraoperatively.',
          '2. Postoperatively, provide empathetic, non-judgmental listening, validate the patient experience, and document timeline details.',
          '3. Initiate psychological support and specialized counseling referral.',
          '4. Report to institutional risk management and review anesthetic delivery equipment/dosing logs.'
        ],
        differentialDiagnosis: [
          'Inadequate anesthetic dosing or vaporizer delivery failure',
          'Patient resistance or high pharmacological tolerance',
          'Deliberate light anesthesia utilized during severe cardiovascular instability'
        ],
        references: [
          'Miller’s Anesthesia, 9th Edition - Chapter 87: Awareness Under General Anesthesia',
          'ASA Practice Advisory for Intraoperative Awareness and Brain Function Monitoring'
        ],
      );
    }

    if (key.contains('dental') || key.contains('tooth')) {
      return const ComplicationInfo(
        title: 'Perioperative Dental Injury',
        overview: 'Damage, loosening, or avulsion of teeth during direct laryngoscopy, airway manipulation, or extubation, typically involving pre-existing compromised dentition.',
        immediateActions: [
          '1. Retrieve any dislodged dental fragments from the oropharynx immediately to prevent airway aspiration.',
          '2. Inspect the airway, pharynx, and esophagus for bleeding or mucosal laceration.',
          '3. Document the precise nature, location, and extent of the injury in the medical record.',
          '4. Inform the patient and surgical team; arrange prompt dental or maxillofacial consultation.'
        ],
        differentialDiagnosis: [
          'Pre-existing poor dental health, caries, or periodontal disease',
          'Difficult direct laryngoscopy or limited mouth opening',
          'Use of rigid airway adjuncts or biting during extubation'
        ],
        references: [
          'Miller’s Anesthesia, 9th Edition - Chapter 43: Airway Management and Complications',
          'ASA Closed Claims Project on Perioperative Dental Damage'
        ],
      );
    }

    if (key.contains('nerve') || key.contains('neuropathy')) {
      return const ComplicationInfo(
        title: 'Postoperative Peripheral Nerve Injury',
        overview: 'Postoperative nerve damage resulting from mechanical compression, stretching, ischemia, or direct surgical trauma during patient positioning and regional/general anesthesia.',
        immediateActions: [
          '1. Perform and document exact neurological deficits thoroughly (motor and sensory distribution).',
          '2. Request urgent neurology consultation and electromyography (EMG) studies if indicated.',
          '3. Provide supportive physical therapy and neuropathic pain management.',
          '4. Review intraoperative positioning, padding, and retractor application protocols.'
        ],
        differentialDiagnosis: [
          'Improper surgical positioning and inadequate padding',
          'Excessive surgical retractor pressure',
          'Pre-existing subclinical neuropathy (e.g., diabetic neuropathy)',
          'Tourniquet-induced ischemia or direct surgical trauma'
        ],
        references: [
          'Miller’s Anesthesia, 9th Edition - Chapter 88: Perioperative Peripheral Neuropathies',
          'ASA Practice Advisory for the Prevention of Perioperative Peripheral Neuropathies'
        ],
      );
    }

    if (key.contains('hemorrhage') || key.contains('bleeding') || key.contains('coagulopathy')) {
      return const ComplicationInfo(
        title: 'Massive Hemorrhage & Acquired Coagulopathy',
        overview: 'Acute, massive blood loss or acquired coagulopathy leading to hemorrhagic shock, microvascular bleeding, and dilutional coagulopathy.',
        immediateActions: [
          '1. Activate the hospital massive hemorrhage protocol (MHP) and request urgent blood bank products (PRBCs, FFP, platelets, cryoprecipitate).',
          '2. Guide ongoing resuscitation using point-of-care testing (ROTEM/TEG or serial ABG/coagulation profiles).',
          '3. Maintain normothermia, correct metabolic acidosis, and maintain ionized calcium levels.',
          '4. Coordinate with the surgical team for immediate control of bleeding sources.'
        ],
        differentialDiagnosis: [
          'Surgical bleeding source',
          'Dilutional coagulopathy from massive crystalloid/colloid infusion',
          'Disseminated intravascular coagulation (DIC)',
          'Hypothermia, acidosis, and hypocalcemia triad',
          'Congenital or acquired bleeding disorders'
        ],
        references: [
          'Miller’s Anesthesia, 9th Edition - Chapter 48: Blood Management and Coagulopathy',
          'European Guidelines on Management of Major Bleeding and Coagulopathy Following Trauma'
        ],
      );
    }

    if (key.contains('air embolism')) {
      return const ComplicationInfo(
        title: 'Vascular Air Embolism',
        overview: 'Entry of atmospheric air into the venous or arterial circulation (e.g., neurosurgery in sitting position, hysteroscopy, central line manipulation), causing acute cardiovascular collapse or stroke.',
        immediateActions: [
          '1. Immediately flood the surgical field with sterile saline and seal any open venous sinuses or vessels.',
          '2. Discontinue nitrous oxide and switch 100% oxygen on immediately.',
          '3. Place patient in Trendelenburg and left lateral decubitus position (Durant maneuver) to trap air in the right ventricular apex.',
          '4. Aspirate air via a central venous catheter if available; initiate CPR and cardiovascular support if cardiac arrest occurs.'
        ],
        differentialDiagnosis: [
          'Tension pneumothorax',
          'Acute myocardial infarction or coronary air embolism',
          'Sudden severe hypovolemia or anaphylactic shock',
          'Cardiac tamponade'
        ],
        references: [
          'Miller’s Anesthesia, 9th Edition - Chapter 86: Vascular and Embolic Complications',
          'ASA Standards for Intraoperative Monitoring'
        ],
      );
    }

    if (key.contains('hypothermia')) {
      return const ComplicationInfo(
        title: 'Perioperative Hypothermia',
        overview: 'Core body temperature dropping below 36.0°C due to redistribution of core body heat, cold operating theater environment, and administration of unheated intravenous fluids or cold gases.',
        immediateActions: [
          '1. Initiate active forced-air warming systems (e.g., Bair Hugger) immediately.',
          '2. Warm all intravenous fluids and irrigation solutions using approved fluid warmers.',
          '3. Increase ambient operating room temperature.',
          '4. Monitor core temperature continuously using approved sensors (tympanic, esophageal, or nasopharyngeal).'
        ],
        differentialDiagnosis: [
          'Environmental theatre heat loss',
          'Redistribution hypothermia secondary to anesthetic vasodilation',
          'Prolonged surgical exposure of body cavities',
          'Infusion of unwarmed intravenous fluids and cold blood products'
        ],
        references: [
          'Miller’s Anesthesia, 9th Edition - Chapter 41: Temperature Regulation and Monitoring',
          'NICE Clinical Guidelines on Perioperative Hypothermia'
        ],
      );
    }

    // Comprehensive clinical profile fallback for any custom or minor text entries
    return ComplicationInfo(
      title: complicationName,
      overview: 'An acute perioperative event associated with "$complicationName" requiring targeted physiological evaluation, structured resuscitation, and ongoing clinical vigilance.',
      immediateActions: [
        '1. Ensure immediate patient safety and stabilize ABCs (Airway, Breathing, Circulation).',
        '2. Verify all vital physiological parameters, monitor integrity, and review recent drug administration.',
        '3. Inform the surgical team and request senior clinical assistance if instability persists.',
        '4. Document the precise timeline of events, clinical interventions, and patient responses in the medical record.'
      ],
      differentialDiagnosis: [
        'Pharmacological drug side effects, toxicity, or hypersensitivity',
        'Surgical site or systemic physiological stress response',
        'Underlying patient co-morbidities and baseline vulnerability'
      ],
      references: [
        'Miller’s Anesthesia, 9th Edition - Perioperative Clinical Management and Complications',
        'Standard Operating Procedures in Clinical Anaesthesiology'
      ],
    );
  }
}
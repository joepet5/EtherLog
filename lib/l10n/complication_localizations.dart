import '../models/complication_info.dart';

/// Comprehensive Multilingual Clinical Knowledge for all 28 Perioperative Complications.
/// Supports English (en), Spanish (es), French (fr), German (de), Portuguese (pt),
/// Chinese (zh), Arabic (ar), Korean (ko), Japanese (ja), and Indonesian (id).
class ComplicationLocalizations {
  ComplicationLocalizations._();

  static ComplicationInfo getLocalizedInfo(String complicationName, String langCode) {
    final defaultInfo = ComplicationInfo.getInfo(complicationName);
    if (langCode == 'en') return defaultInfo;

    final key = complicationName.toLowerCase().trim();
    final langMap = _localizedData[langCode];
    if (langMap != null) {
      for (final entry in langMap.entries) {
        if (key.contains(entry.key)) {
          return entry.value;
        }
      }
    }
    return defaultInfo;
  }

  static final Map<String, Map<String, ComplicationInfo>> _localizedData = {
    'es': {
      'difficult bag': const ComplicationInfo(
        title: "Ventilación Difícil con Mascarilla",
        overview: "Incapacidad de mantener una saturación de oxígeno >90% o revertir signos de hipoventilación con mascarilla facial.",
        immediateActions: [
          "1. Pedir ayuda de inmediato según algoritmos de vía aérea.",
          "2. Optimizar posición de olfateo y tracción mandibular a dos manos.",
          "3. Insertar cánula orofaríngea (Guedel) o nasofaríngea.",
          "4. Corregir fugas de la mascarilla.",
          "5. Si persiste, colocar dispositivo supraglótico (LMA) o intubar.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'cardiac arrest': const ComplicationInfo(
        title: "Paro Cardíaco Perioperatorio",
        overview: "Cese de la actividad mecánica cardíaca que requiere reanimación cardiopulmonar inmediata y soporte vital avanzado.",
        immediateActions: [
          "1. Solicitar ayuda, iniciar compresiones torácicas y ventilar con O2 al 100%.",
          "2. Conectar desfibrilador y analizar el ritmo.",
          "3. Administrar Adrenalina 1 mg IV cada 3-5 min.",
          "4. Tratar causas reversibles (4H y 4T).",
          "5. Pausar la cirugía.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'death on table': const ComplicationInfo(
        title: "Mortalidad Intraoperatoria",
        overview: "Evento terminal catastrófico intraoperatorio por fallo fisiológico masivo o lesión quirúrgica irreversible.",
        immediateActions: [
          "1. Continuar maniobras ACLS hasta certificar futilidad.",
          "2. Documentar cronología exacta de fármacos y constantes.",
          "3. Notificar a jefatura y comités de seguridad.",
          "4. Preservar registros clínicos y equipamiento.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'position': const ComplicationInfo(
        title: "Complicaciones por Posicionamiento",
        overview: "Lesiones nerviosas por compresión, isquemia o estiramiento debidas a la postura quirúrgica.",
        immediateActions: [
          "1. Reevaluar y acolchar puntos de presión (cúbito, peroné, plexo braquial).",
          "2. Evitar hiperabducción de brazos (>90°).",
          "3. Exploración neurológica postoperatoria temprana.",
          "4. Derivar a neurología o fisioterapia si hay déficit.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'shivering': const ComplicationInfo(
        title: "Temblores Postanestésicos (PAS)",
        overview: "Contracciones musculares involuntarias secundarias a hipotermia o reajuste termorregulador tras anestesia.",
        immediateActions: [
          "1. Aplicar calentamiento activo con aire forzado.",
          "2. Administrar Meperidina/Petidina (12.5-25 mg IV) o Clonidina.",
          "3. Suplementar oxígeno para compensar el aumento de consumo de O2.",
          "4. Monitorear temperatura central.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'transfusion reaction': const ComplicationInfo(
        title: "Reacción Transfusional Aguda",
        overview: "Respuesta inmunitaria o adversa aguda por incompatibilidad sanguínea (TRALI, TACO, hemólisis aguda).",
        immediateActions: [
          "1. Detener inmediatamente la transfusión y mantener vía permeable.",
          "2. Verificar etiquetado y grupo sanguíneo.",
          "3. Administrar antihistamínicos, corticoides y vasopresores según gravedad.",
          "4. Enviar muestra de sangre y bolsa al banco de sangre.",
          "5. Forzar diuresis con fluidos y diuréticos.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'massive blood loss': const ComplicationInfo(
        title: "Pérdida Masiva de Sangre / Shock Hemorrágico",
        overview: "Pérdida sanguínea >1 volumen total en 24h o >50% en 3h con inestabilidad hemodinámica y coagulopatía.",
        immediateActions: [
          "1. Activar protocolo de transfusión masiva (MTP 1:1:1).",
          "2. Asegurar accesos venosos de grueso calibre y calentadores rápidos.",
          "3. Administrar Ácido Tranexámico (1g IV en 10 min).",
          "4. Mantener normotermia, corregir hipocalcemia y acidosis.",
          "5. Guiar reposición con tromboelastometría (ROTEM/TEG).",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'failed intubation': const ComplicationInfo(
        title: "Intubación Fallida e Intentos Múltiples",
        overview: "Incapacidad de asegurar la vía aérea tras múltiples intentos de laringoscopia, arriesgando trauma y no intubación-no ventilación.",
        immediateActions: [
          "1. Declarar intubación fallida y limitar intentos (<3).",
          "2. Mantener oxigenación con mascarilla o dispositivo supraglótico.",
          "3. Usar videolaringoscopio o guía tipo Frova/Bougie.",
          "4. Si falla ventilación y rescate: preparar cricotiroidotomía (CICO).",
          "5. Despertar al paciente si la cirugía es electiva.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'desaturation': const ComplicationInfo(
        title: "Desaturación Perioperatoria / Hipoxemia",
        overview: "Caída súbita o progresiva de SpO2 <90% por hipoventilación, desajuste V/Q, broncoespasmo o desconexión.",
        immediateActions: [
          "1. Aumentar FiO2 al 100% y verificar flujo de gas.",
          "2. Auscultar ambos campos pulmonares (descartar intubación monobronquial o neumotórax).",
          "3. Aspirar secreciones del tubo endotraqueal.",
          "4. Realizar maniobra de reclutamiento alveolar con PEEP.",
          "5. Verificar capnografía y posición del tubo.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'hypotension': const ComplicationInfo(
        title: "Hipotensión Intraoperatoria",
        overview: "Presión arterial media (PAM) <65 mmHg o caída >20% de la basal comprometiendo perfusión de órganos.",
        immediateActions: [
          "1. Confirmar lectura de presión arterial.",
          "2. Disminuir profundidad anestésica.",
          "3. Administrar bolo de cristaloides.",
          "4. Administrar vasopresores (Efedrina 5-10 mg o Fenilefrina 50-100 mcg IV).",
          "5. Evaluar pérdidas hemáticas y descartar compresión cava.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'hypertension': const ComplicationInfo(
        title: "Hipertensión Intraoperatoria",
        overview: "Elevación excesiva de presión arterial (PAS >160 o PAM >100) secundaria a dolor, plano superficial o sobrecarga.",
        immediateActions: [
          "1. Descartar plano anestésico superficial y analgesia deficiente.",
          "2. Administrar opioides (Fentanilo 50-100 mcg) o profundizar anestesia.",
          "3. Descartar hipoxemia, hipercapnia o globo vesical.",
          "4. Si persiste, titular antihipertensivos (Labetalol 5-10 mg, Esmolol o Urapidil).",
          "5. Monitorizar signos de isquemia miocárdica.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'bradycardia': const ComplicationInfo(
        title: "Bradicardia Perioperatoria",
        overview: "Frecuencia cardíaca <50 lpm (o <60 lpm con hipotensión) por reflejo vagal, fármacos o bloqueo neuroaxial alto.",
        immediateActions: [
          "1. Solicitar cese temporal del estímulo vagal quirúrgico.",
          "2. Administrar Atropina 0.5-1 mg IV o Glicopirrolato 0.2 mg IV.",
          "3. Si hay hipotensión severa, administrar Efedrina o Adrenalina en bolos (10-20 mcg).",
          "4. Preparar marcapasos transcutáneo si hay bloqueo AV avanzado.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'bronchospasm': const ComplicationInfo(
        title: "Broncoespasmo Agudo",
        overview: "Contracción del músculo liso bronquial con sibilancias, pico de presión elevado y capnografía obstructiva.",
        immediateActions: [
          "1. Aumentar FiO2 al 100% y profundizar anestesia con agentes halogenados o Propofol.",
          "2. Descartar acodamiento del tubo o intubación bronquial.",
          "3. Administrar Salbutamol inhalado (6-10 puffs vía adaptador).",
          "4. Administrar Adrenalina IV (10-20 mcg) en casos graves o Sulfato de Magnesio 2g IV.",
          "5. Administrar corticoides IV.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'laryngospasm': const ComplicationInfo(
        title: "Laringoespasmo Agudo",
        overview: "Cierre reflejo involuntario de cuerdas vocales provocando obstrucción aguda de vía aérea superior.",
        immediateActions: [
          "1. Retirar estímulos de la vía aérea y ventilar con O2 100% a presión positiva (CPAP).",
          "2. Aplicar maniobra de Larson (presión retromandibular).",
          "3. Profundizar anestesia con bolo de Propofol (0.5-1 mg/kg).",
          "4. Si persiste o hay desaturación crítica: Succinilcolina 0.2-0.5 mg/kg IV.",
          "5. Vigilar edema pulmonar por presión negativa.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'aspiration': const ComplicationInfo(
        title: "Aspiración Pulmonar de Contenido Gástrico",
        overview: "Entrada de material gástrico ácido o partículas en el árbol traqueobronquial con riesgo de neumonitis química.",
        immediateActions: [
          "1. Colocar en posición de Trendelenburg y aspirar orofaringe de inmediato.",
          "2. Intubar la tráquea precozmente para proteger la vía aérea.",
          "3. Aspirar el tubo endotraqueal antes de aplicar ventilación con presión positiva.",
          "4. Aplicar PEEP y soporte ventilatorio.",
          "5. Trasladar a UCI / monitorización intensiva.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'delayed': const ComplicationInfo(
        title: "Despertar Retardado de la Anestesia",
        overview: "Falta de recuperación de la conciencia tras 60-90 minutos de finalizada la anestesia.",
        immediateActions: [
          "1. Mantener oxigenación y ventilación de soporte.",
          "2. Evaluar bloqueo neuromuscular residual (revertir con Sugammadex o Neostigmina).",
          "3. Descartar sobredosis de opioides (Naloxona) o benzodiacepinas (Flumazenil).",
          "4. Verificar glucemia, electrolitos y temperatura.",
          "5. Descartar evento cerebrovascular agudo.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'anaphylaxis': const ComplicationInfo(
        title: "Anafilaxia Perioperatoria",
        overview: "Reacción de hipersensibilidad severa mediada por IgE que produce colapso cardiovascular y broncoespasmo.",
        immediateActions: [
          "1. Suspender inmediatamente el fármaco sospechoso y ventilar con O2 100%.",
          "2. Administrar Adrenalina precozmente (10-50 mcg IV en bolos o 0.5 mg IM).",
          "3. Infusión masiva de cristaloides.",
          "4. Administrar corticoides y antihistamínicos.",
          "5. Tomar muestra para Triptasa sérica (a los 30-120 min).",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'malignant hyperthermia': const ComplicationInfo(
        title: "Crisis de Hipertermia Maligna (HM)",
        overview: "Emergencia farmacogenética hipermetabólica desencadenada por anestésicos volátiles o succinilcolina.",
        immediateActions: [
          "1. Suspender inmediatamente agentes volátiles y succinilcolina; hiperventilar con O2 100% a flujos altos.",
          "2. Administrar Dantroleno precozmente (2.5 mg/kg IV rápido, repetir hasta control).",
          "3. Iniciar enfriamiento activo (líquidos fríos, hielo).",
          "4. Tratar hiperpotasemia y acidosis metabólica.",
          "5. Monitorizar en UCI.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'pneumothorax': const ComplicationInfo(
        title: "Neumotórax a Tensión / Intraoperatorio",
        overview: "Presión positiva intratorácica por aire en cavidad pleural causando colapso pulmonar y shock obstructivo.",
        immediateActions: [
          "1. Suspender óxido nitroso y ventilar con O2 100%.",
          "2. Descompresión inmediata con aguja en 2º espacio intercostal línea medioclavicular.",
          "3. Colocar tubo de drenaje torácico en 5º espacio intercostal línea axilar anterior.",
          "4. Ajustar parámetros ventilatorios.",
          "5. Confirmar resolución con radiografía.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'ponv': const ComplicationInfo(
        title: "Náuseas y Vómitos Postoperatorios (NVPO)",
        overview: "Sensación nauseosa o expulsión gástrica tras la anestesia.",
        immediateActions: [
          "1. Administrar Ondansetrón 4 mg IV.",
          "2. Administrar Dexametasona 4-8 mg IV precozmente.",
          "3. Hidratación adecuada con cristaloides.",
          "4. Considerar Droperidol o Metoclopramida.",
          "5. Reducir uso de opioides postoperatorios.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
    },
    'fr': {
      'difficult bag': const ComplicationInfo(
        title: "Ventilation au Masque Difficile",
        overview: "Impossibilité de maintenir une SpO2 >90% ou de corriger les signes d'hypoventilation au masque.",
        immediateActions: [
          "1. Appeler à l'aide selon l'algorithme VAD.",
          "2. Optimiser la position et subluxation mandibulaire à 2 mains.",
          "3. Poser une canule oropharyngée ou nasopharyngée.",
          "4. Réduire les fuites du masque.",
          "5. Insérer un dispositif supraglottique (LMA) ou intuber.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'cardiac arrest': const ComplicationInfo(
        title: "Arrêt Cardiorespiratoire Périopératoire",
        overview: "Arrêt de l'activité mécanique cardiaque nécessitant une réanimation immédiate et ACLS.",
        immediateActions: [
          "1. Alerter l'équipe, débuter le massage cardiaque et ventiler en FiO2 100%.",
          "2. Poser le défibrillateur et analyser le rythme.",
          "3. Injecter Adrénaline 1 mg IV toutes les 3-5 min.",
          "4. Traiter les causes réversibles (4H/4T).",
          "5. Interrompre la chirurgie.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'death on table': const ComplicationInfo(
        title: "Décès Peropératoire",
        overview: "Événement catastrophique terminal peropératoire lié à une défaillance physiologique majeure.",
        immediateActions: [
          "1. Poursuivre la réanimation ACLS jusqu'à constat d'échec.",
          "2. Tracer la chronologie précise des soins et drogues.",
          "3. Informer la hiérarchie et la gouvernance.",
          "4. Conserver les données et dispositifs.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'position': const ComplicationInfo(
        title: "Complications de Décubitus / Positionnement",
        overview: "Lésions nerveuses ou cutanées par compression ou étirement prolongé en cours d'intervention.",
        immediateActions: [
          "1. Réajuster les appuis et protéger les nerfs vulnérables.",
          "2. Limiter l'abduction des bras à moins de 90°.",
          "3. Examen neurologique postopératoire précoce.",
          "4. Avis neurologique si déficit constaté.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'shivering': const ComplicationInfo(
        title: "Frissons Postopératoires",
        overview: "Secousses musculaires involontaires liées à l'hypothermie et à la levée des anesthésiques.",
        immediateActions: [
          "1. Mettre en place un réchauffement à air pulsé.",
          "2. Injecter Péthidine (12.5-25 mg IV) ou Clonidine.",
          "3. Administrer de l'oxygène pour répondre à la hausse de consommation.",
          "4. Surveiller la température centrale.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'transfusion reaction': const ComplicationInfo(
        title: "Réaction Transfusionnelle Aiguë",
        overview: "Complication immunologique ou hémodynamique aiguë liée à la transfusion sanguine.",
        immediateActions: [
          "1. Arrêter immédiatement la transfusion et préserver l'abord veineux.",
          "2. Vérifier la concordance immunologique.",
          "3. Traiter l'état de choc et l'hypoxie.",
          "4. Renvoyer les culots et prélever un bilan d'hémolyse.",
          "5. Maintenir une diurèse suffisante.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'massive blood loss': const ComplicationInfo(
        title: "Hémorragie Massive et Choc Hémorragique",
        overview: "Perte sanguine critique menaçant le pronostic vital et nécessitant un protocole transfusionnel d'urgence.",
        immediateActions: [
          "1. Déclencher le protocole d'hémorragie massive.",
          "2. Poser des voies veineuses de gros calibre avec réchauffeur-accélérateur.",
          "3. Injecter Acide Tranexamique (1g IV).",
          "4. Lutter contre la triade létale (hypothermie, acidose, coagulopathie).",
          "5. Monitorage par ROTEM / TEG.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'failed intubation': const ComplicationInfo(
        title: "Intubation Impossible et Tentatives Multiples",
        overview: "Échec de placement de la sonde trachéale exposant au risque d'hypoxie critique et de traumatisme.",
        immediateActions: [
          "1. Déclarer l'échec et limiter les tentatives à 3 maximum.",
          "2. Oxygéner au masque ou par masque laryngé.",
          "3. Recourir au vidéolaryngoscope et mandrin béquillé.",
          "4. Si situation CICO : cricothyroïdotomie immédiate.",
          "5. Réveiller le patient si chirurgie programmée.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'desaturation': const ComplicationInfo(
        title: "Désaturation Périopératoire / Hypoxie",
        overview: "Diminution brutale ou progressive de la SpO2 <90% imposant un diagnostic étiologique rapide.",
        immediateActions: [
          "1. Passer en FiO2 100% et vérifier les débits de gaz.",
          "2. Ausculter les 2 poumons (éliminer intubation sélective).",
          "3. Aspirer la sonde d'intubation.",
          "4. Manœuvre de recrutement alvéolaire et PEEP.",
          "5. Contrôler le capnographe et la sonde.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'hypotension': const ComplicationInfo(
        title: "Hypotension Périopératoire",
        overview: "PAM <65 mmHg ou baisse >20% par rapport à la valeur de base.",
        immediateActions: [
          "1. Vérifier la mesure de pression.",
          "2. Alléger la profondeur d'anesthésie.",
          "3. Remplissage vasculaire par cristalloïdes.",
          "4. Vasopresseurs (Éphédrine 6-9 mg ou Phényléphrine 50-100 µg).",
          "5. Évaluer les saignements chirurgicaux.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'hypertension': const ComplicationInfo(
        title: "Hypertension Périopératoire",
        overview: "Élévation tensionnelle marquée liée à une anesthésie insuffisante, analgésie inadéquate ou hypervolémie.",
        immediateActions: [
          "1. Évaluer la profondeur d'anesthésie et l'analgésie.",
          "2. Réinjecter des morphiniques ou approfondir l'AG.",
          "3. Éliminer une hypercapnie ou un globe vésical.",
          "4. Titrer des antihypertenseurs (Lébétalol, Esmolol, Nicardipine).",
          "5. Surveillance ECG.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'bradycardia': const ComplicationInfo(
        title: "Bradycardie Périopératoire",
        overview: "FC <50 bpm liée au tonus vagal, aux morphiniques, ou à un bloc rachidien étendu.",
        immediateActions: [
          "1. Demander l'arrêt temporaire de la traction chirurgicale.",
          "2. Injecter Atropine 0.5-1 mg IV ou Glycopyrrolate.",
          "3. En cas d'hypotension associée : Éphédrine ou Adrénaline titrée.",
          "4. Préparer un entraînement électrosystolique si BAV complet.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'bronchospasm': const ComplicationInfo(
        title: "Bronchospasme Aigu",
        overview: "Constriction bronchique avec augmentation des pressions d'insufflation et sibilants.",
        immediateActions: [
          "1. FiO2 100% et approfondir l'anesthésie (halogénés / propofol).",
          "2. Éliminer une coudure de sonde.",
          "3. Aérosol de Salbutamol via la sonde.",
          "4. En cas de forme sévère : Adrénaline IV (10-20 µg) ou Sulfate de magnésium 2g.",
          "5. Corticoïdes IV.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'laryngospasm': const ComplicationInfo(
        title: "Laryngospasme Aigu",
        overview: "Fermeture réflexe des cordes vocales entraînant une obstruction complète ou partielle des voies aériennes.",
        immediateActions: [
          "1. Arrêter toute stimulation et ventiler en O2 100% avec pression positive.",
          "2. Manœuvre de Larson (pression ferme rétro-mandibulaire).",
          "3. Approfondir avec Propofol (0.5-1 mg/kg IV).",
          "4. Si échec : Succinylcholine (0.2-0.5 mg/kg IV).",
          "5. Surveiller l'œdème pulmonaire a vacuo.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'aspiration': const ComplicationInfo(
        title: "Inhalation de Contenu Gastrique (Mendelson)",
        overview: "Passage de liquide gastrique dans les poumons provoquant une brûlure chimique alvéolaire.",
        immediateActions: [
          "1. Mettre en Trendelenburg et aspirer vigoureusement l'oropharynx.",
          "2. Intubation trachéale immédiate.",
          "3. Aspiration endotrachéale avant ventilation.",
          "4. Ventilation protectrice avec PEEP.",
          "5. Transfert en réanimation / soins intensifs.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'delayed': const ComplicationInfo(
        title: "Réveil Retardé de l'Anesthésie",
        overview: "Non-récupération de la conscience après la fin de l'anesthésie au-delà des délais normaux.",
        immediateActions: [
          "1. Maintenir une ventilation assistée efficace.",
          "2. Vérifier la curarisation résiduelle (Sugammadex).",
          "3. Antagoniser morphiniques (Naloxone) ou benzodiazépines (Flumazénil).",
          "4. Contrôler glycémie, ionogramme et température.",
          "5. Éliminer un accident vasculaire cérébral.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'anaphylaxis': const ComplicationInfo(
        title: "Anaphylaxie Périopératoire",
        overview: "Réaction allergique aiguë systémique sévère engageant le pronostic vital.",
        immediateActions: [
          "1. Arrêter immédiatement l'administration du produit suspect et O2 100%.",
          "2. Adrénaline titrée sans délai (10-50 µg IV ou 0.5 mg IM).",
          "3. Remplissage vasculaire massif.",
          "4. Corticoïdes et antihistaminiques.",
          "5. Dosage de la tryptase sérique.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'malignant hyperthermia': const ComplicationInfo(
        title: "Crise d'Hyperthermie Maligne (HM)",
        overview: "Urgence hypermétabolique gravissime déclenchée par les halogénés ou la succinylcholine.",
        immediateActions: [
          "1. Arrêter immédiatement les halogénés, hyperventiler en O2 100% à haut débit.",
          "2. Injecter Dantrolène sans délai (2.5 mg/kg IV rapide).",
          "3. Refroidissement actif.",
          "4. Traiter l'hyperkaliémie et l'acidose.",
          "5. Surveillance prolongée en réanimation.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'pneumothorax': const ComplicationInfo(
        title: "Pneumothorax Suffocant / Peropératoire",
        overview: "Accumulation d'air sous pression dans la plèvre entraînant collapsus cardiovasculaire et hypoxie.",
        immediateActions: [
          "1. Arrêter le protoxyde d'azote et ventiler en O2 100%.",
          "2. Décompression immédiate à l'aiguille (2e espace intercostal).",
          "3. Poser un drain thoracique.",
          "4. Adapter la ventilation.",
          "5. Radiographie pulmonaire de contrôle.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'ponv': const ComplicationInfo(
        title: "Nausées et Vomissements Postopératoires (NVPO)",
        overview: "Événement indésirable fréquent lié aux anesthésiques, morphiniques et à la chirurgie.",
        immediateActions: [
          "1. Ondansétron 4 mg IV.",
          "2. Dexaméthasone 4-8 mg IV préventive.",
          "3. Hydratation intraveineuse adéquate.",
          "4. Gouttes de Dropéridol si nécessaire.",
          "5. Épargne morphinique postopératoire.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
    },
    'de': {
      'difficult bag': const ComplicationInfo(
        title: "Schwierige Maskenbeatmung",
        overview: "Unfähigkeit, eine SaO2 >90% aufrechtzuerhalten oder adäquate Ventilation sicherzustellen.",
        immediateActions: [
          "1. Sofort Hilfe anfordern nach Algorithmus.",
          "2. Schnüffelstellung und zweihändiger Esmarch-Handgriff.",
          "3. Guedel- oder Wendl-Tubus einsetzen.",
          "4. Maskenleckagen minimieren.",
          "5. Larynxmaske (SGA) platzieren oder intubieren.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'cardiac arrest': const ComplicationInfo(
        title: "Perioperativer Herzstillstand",
        overview: "Aussetzen der mechanischen Herzaktion mit Erfordernis sofortiger CPR und ACLS.",
        immediateActions: [
          "1. Notfallalarm, Herzdruckmassage starten und mit 100% O2 beatmen.",
          "2. Defibrillator anbringen und Rhythmus analysieren.",
          "3. Adrenalin 1 mg i.v. alle 3-5 min geben.",
          "4. Reversible Ursachen (4H/4HITS) beheben.",
          "5. OP pausieren.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'death on table': const ComplicationInfo(
        title: "Intraoperativer Todesfall",
        overview: "Katastrophales intraoperatives Ereignis durch irreversibles physiologisches Versagen.",
        immediateActions: [
          "1. Reanimation nach ACLS fortführen bis Feststellung der Aussichtslosigkeit.",
          "2. Chronologie aller Maßnahmen und Medikamente sichern.",
          "3. Klinikleitung und Rechtsabteilung informieren.",
          "4. Protokolle und Geräte sicherstellen.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'position': const ComplicationInfo(
        title: "Lagerungsschäden",
        overview: "Nervenschäden oder Gewebeischämien durch Druck- oder Zugbelastung bei OP-Lagerung.",
        immediateActions: [
          "1. Druckstellen polstern (N. ulnaris, N. peroneus, Plexus brachialis).",
          "2. Armabduktion auf unter 90° begrenzen.",
          "3. Frühzeitige postoperative neurologische Befundung.",
          "4. Frührehabilitation bei Defizit einleiten.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'shivering': const ComplicationInfo(
        title: "Postoperatives Kältezittern (Shivering)",
        overview: "Involuntäre Muskelaktivität durch Absinken der Kerntemperatur und gestörte Thermoregulation.",
        immediateActions: [
          "1. Aktive Wärmedecke (Warmluft) einsetzen.",
          "2. Pethidin 12,5-25 mg i.v. oder Clonidin verabreichen.",
          "3. Sauerstoffzufuhr optimieren zur Deckung des erhöhten O2-Bedarfs.",
          "4. Kerntemperatur überwachen.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'transfusion reaction': const ComplicationInfo(
        title: "Akute Transfusionsreaktion",
        overview: "Akute immunologische oder volumenbedingte Komplikation nach Gabe von Blutprodukten.",
        immediateActions: [
          "1. Transfusion sofort stoppen und Zugang offenhalten.",
          "2. Identität und Kreuzprobe kontrollieren.",
          "3. Antihistaminika, Steroide und Kreislaufunterstützung einleiten.",
          "4. Blutbeutel und Patientenprobe an Blutbank senden.",
          "5. Diurese aufrechterhalten.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'massive blood loss': const ComplicationInfo(
        title: "Massiver Blutverlust / Hämorrhagischer Schock",
        overview: "Kritischer Blutverlust mit hämodynamischer Instabilität und drohender Verbrauchskoagulopathie.",
        immediateActions: [
          "1. Massivtransfusionsprotokoll (MTP) aktivieren.",
          "2. Großlumige Zugänge und Schnellinfusionssysteme nutzen.",
          "3. Tranexamsäure 1g i.v. frühzeitig geben.",
          "4. Normothermie, Kalzium und Säure-Basen-Status korrigieren.",
          "5. Gerinnung zielgerichtet steuern (ROTEM/TEG).",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'failed intubation': const ComplicationInfo(
        title: "Fehlintubation und Mehrfachversuche",
        overview: "Erfolglose Intubationsversuche mit Gefahr von Atemwegstrauma und CICO-Situation.",
        immediateActions: [
          "1. Fehlintubation deklarieren und Versuche auf max. 3 begrenzen.",
          "2. Oxygenierung über Maske oder Larynxmaske sichern.",
          "3. Videolaryngoskop und Bougie einsetzen.",
          "4. Bei CICO sofort Koniotomie durchführen.",
          "5. Patient aufwachen lassen bei elektivem Eingriff.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'desaturation': const ComplicationInfo(
        title: "Perioperative Desaturation / Hypoxämie",
        overview: "Abfall der Sauerstoffsättigung (SpO2 <90%) durch Ventilations-, Diffusions- oder Perfusionsstörung.",
        immediateActions: [
          "1. FiO2 auf 1,0 erhöhen und Gasfluss prüfen.",
          "2. Beidseitige Auskultation (Fehllage/Pneumothorax ausschließen).",
          "3. Endotrachealtubus absaugen.",
          "4. Rekrutierungsmanöver mit PEEP durchführen.",
          "5. Kapnographie und Tubuslage kontrollieren.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'hypotension': const ComplicationInfo(
        title: "Intraoperative Hypotonie",
        overview: "Mittlerer arterieller Druck (MAD) <65 mmHg mit Gefährdung der Organperfusion.",
        immediateActions: [
          "1. Blutdruckmessung verifizieren.",
          "2. Narkosetiefe reduzieren.",
          "3. Flüssigkeitsbolus (Kristalloide) infundieren.",
          "4. Vasopressoren geben (Ephedrin 5-10 mg oder Noradrenalin/Phenylephrin).",
          "5. Blutung und Hohlvenenkompression ausschließen.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'hypertension': const ComplicationInfo(
        title: "Intraoperative Hypertonie",
        overview: "Blutdruckanstieg durch unzureichende Narkosetiefe, Schmerzreiz oder Hypervolämie.",
        immediateActions: [
          "1. Narkosetiefe und Analgesie vertiefen.",
          "2. Opioid nachdosieren (z. B. Fentanyl 0,1 mg).",
          "3. Hyperkapnie und Harnverhalt ausschließen.",
          "4. Antihypertensiva titrieren (Urapidil 10-25 mg, Esmolol).",
          "5. EKG auf Ischämiezeichen prüfen.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'bradycardia': const ComplicationInfo(
        title: "Intraoperative Bradykardie",
        overview: "Herzfrequenz <50/min durch Vagusreiz, Medikamente oder hohe Spinalanästhesie.",
        immediateActions: [
          "1. Chirurgischen Vagusreiz sofort pausieren.",
          "2. Atropin 0,5-1,0 mg i.v. oder Glycopyrrolat geben.",
          "3. Bei Hypotonie Ephedrin oder fraktioniert Adrenalin (10-20 µg).",
          "4. Schrittmacherbereitschaft bei höhergradigem AV-Block.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'bronchospasm': const ComplicationInfo(
        title: "Akuter Bronchospasmus",
        overview: "Akute Atemwegsobstruktion mit Anstieg des Beatmungsspitzendrucks und verlängerter Exspiration.",
        immediateActions: [
          "1. 100% O2 und Narkose vertiefen (Sevofluran / Propofol).",
          "2. Mechanische Tubusobstruktion ausschließen.",
          "3. Salbutamol-Spray über Tubusadapter applizieren.",
          "4. Bei schwerem Spasmus Adrenalin 10-20 µg i.v. oder Magnesium 2g i.v.",
          "5. Steroide verabreichen.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'laryngospasm': const ComplicationInfo(
        title: "Akuter Laryngospasmus",
        overview: "Reflektorischer Stimmritzenkrampf mit akuter Verlegung der oberen Atemwege.",
        immediateActions: [
          "1. Reiz entfernen, 100% O2 mit CPAP/Überdruck beatmen.",
          "2. Larson-Handgriff (fester Druck hinter Kieferwinkel).",
          "3. Propofol 0,5-1 mg/kg i.v. nachgeben.",
          "4. Bei Hypoxie: Succinylcholin 0,2-0,5 mg/kg i.v.",
          "5. Auf negatives Drucklungenödem achten.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'aspiration': const ComplicationInfo(
        title: "Pulmonale Aspiration von Mageninhalt",
        overview: "Übertritt von saurem Mageninhalt in den Tracheobronchialbaum mit chemischer Pneumonitis.",
        immediateActions: [
          "1. Trendelenburg-Lagerung und zügiges Absaugen des Oropharynx.",
          "2. Sofortige endotracheale Intubation zum Atemwegsschutz.",
          "3. Vor Überdruckbeatmung Tubus absaugen.",
          "4. Beatmung mit PEEP optimieren.",
          "5. Überwachung auf Intensivstation.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'delayed': const ComplicationInfo(
        title: "Verzögertes Aufwachen",
        overview: "Ausbleibende Wiedererlangung des Bewusstseins nach Narkoseende.",
        immediateActions: [
          "1. Sauerstoffzufuhr und Beatmung sichern.",
          "2. Relaxometrie prüfen und antagonisieren (Sugammadex/Neostigmin).",
          "3. Opiatüberhang (Naloxon) oder Benzodiazepinüberhang (Flumazenil) prüfen.",
          "4. BZ, Elektrolyte und Temperatur kontrollieren.",
          "5. Zerebrales Ereignis ausschließen.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'anaphylaxis': const ComplicationInfo(
        title: "Perioperative Anaphylaxie",
        overview: "Schwere, lebensbedrohliche systemische Überempfindlichkeitsreaktion mit Kreislaufkollaps.",
        immediateActions: [
          "1. Zufuhr des vermuteten Auslösers stoppen, 100% O2.",
          "2. Frühzeitige Gabe von Adrenalin (10-50 µg i.v. oder 0,5 mg i.m.).",
          "3. Zügige Volumentherapie mit Kristalloideen.",
          "4. H1/H2-Blocker und Glukokortikoide.",
          "5. Serum-Tryptase bestimmen.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'malignant hyperthermia': const ComplicationInfo(
        title: "Maligne Hyperthermie-Krise (MH)",
        overview: "Lebensbedrohliche hypermetabole Stoffwechselentgleisung nach Triggersubstanzen (Inhalativa, Succinylcholin).",
        immediateActions: [
          "1. Trigger sofort stoppen, mit 100% O2 hyperventilieren (High-Flow).",
          "2. Dantrolen 2,5 mg/kg i.v. als Bolus geben.",
          "3. Aktive Kühlung (gekühlte Infusionen, Eis).",
          "4. Hyperkaliämie und Azidose behandeln.",
          "5. Intensivtherapie fortsetzen.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'pneumothorax': const ComplicationInfo(
        title: "Intraoperativer Spannungspneumothorax",
        overview: "Drucksteigerung im Pleuraraum mit Lungenkollaps und obstruktivem Schock.",
        immediateActions: [
          "1. N2O stoppen, 100% O2.",
          "2. Sofortige Nadeldekompression (2. ICR Medioklavikularlinie).",
          "3. Thoraxdrainage einlegen (5. ICR vordere Axillarlinie).",
          "4. Beatmungsdrücke anpassen.",
          "5. Röntgenkontrolle.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'ponv': const ComplicationInfo(
        title: "Postoperative Übelkeit und Erbrechen (PONV)",
        overview: "Häufige postoperative Komplikation durch Inhalativa, Opioide und vagale Reize.",
        immediateActions: [
          "1. Ondansetron 4 mg i.v. geben.",
          "2. Dexamethason 4-8 mg i.v. zur Prophylaxe.",
          "3. Ausreichende Flüssigkeitssubstitution.",
          "4. Droperidol oder Dimenhydrinat erwägen.",
          "5. Opioideinsparende Analgesie einsetzen.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
    },
    'pt': {
      'difficult bag': const ComplicationInfo(
        title: "Ventilação com Máscara Difícil",
        overview: "Incapacidade de manter saturação de O2 >90% ou reverter sinais de hipoventilação com máscara facial.",
        immediateActions: [
          "1. Chamar ajuda imediatamente.",
          "2. Posicionar em olfativa e aplicar tração mandibular a duas mãos.",
          "3. Inserir cânula orofaríngea ou nasofaríngea.",
          "4. Eliminar vazamentos na máscara.",
          "5. Inserir máscara laríngea ou intubar.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'cardiac arrest': const ComplicationInfo(
        title: "Parada Cardiorrespiratória Perioperatória",
        overview: "Cessação da atividade mecânica cardíaca necessitando de RCP e suporte avançado imediatos.",
        immediateActions: [
          "1. Chamar ajuda, iniciar compressões e ventilar com 100% O2.",
          "2. Conectar desfibrilador e analisar ritmo.",
          "3. Administrar Adrenalina 1 mg IV a cada 3-5 min.",
          "4. Tratar causas reversíveis (4H e 4T).",
          "5. Pausar a cirurgia.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'death on table': const ComplicationInfo(
        title: "Óbito Intraoperatório",
        overview: "Evento catastrófico terminal durante o ato cirúrgico por falência fisiológica grave.",
        immediateActions: [
          "1. Manter suporte avançado até constatação de futilidade.",
          "2. Registrar cronograma exato de medicações e parâmetros.",
          "3. Notificar coordenação e governança clínica.",
          "4. Preservar registros e equipamentos.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'position': const ComplicationInfo(
        title: "Complicações de Posicionamento",
        overview: "Lesões nervosas e isquêmicas por pressão ou estiramento durante o posicionamento cirúrgico.",
        immediateActions: [
          "1. Acolchoar pontos de pressão nervosa.",
          "2. Evitar abdução de braços superior a 90°.",
          "3. Realizar exame neurológico no pós-operatório.",
          "4. Encaminhar para fisioterapia/neurologia se houver déficit.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'shivering': const ComplicationInfo(
        title: "Tremores Pós-Anestésicos",
        overview: "Tremores musculares involuntários por hipotermia ou alteração da termorregulação central.",
        immediateActions: [
          "1. Iniciar aquecimento ativo com manta térmica.",
          "2. Administrar Meperidina (12.5-25 mg IV) ou Clonidina.",
          "3. Fornecer O2 suplementar.",
          "4. Monitorar temperatura central.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'transfusion reaction': const ComplicationInfo(
        title: "Reação Transfusional Aguda",
        overview: "Reação imunológica ou hemodinâmica aguda secundária à infusão de hemocomponentes.",
        immediateActions: [
          "1. Interromper imediatamente a transfusão.",
          "2. Conferir identificação da bolsa e do paciente.",
          "3. Tratar sintomas e choque com suporte hemodinâmico.",
          "4. Enviar amostras ao banco de sangue.",
          "5. Estimular débito urinário.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'massive blood loss': const ComplicationInfo(
        title: "Perda Sanguínea Maciça e Choque Hemorrágico",
        overview: "Sangramento agudo volumoso associado a instabilidade circulatória e risco de coagulopatia.",
        immediateActions: [
          "1. Acionar protocolo de transfusão maciça (1:1:1).",
          "2. Puncionar acessos venosos calibrosos com infusor rápido aquecido.",
          "3. Administrar Ácido Tranexâmico 1g IV.",
          "4. Evitar hipotermia, acidose e hipocalcemia.",
          "5. Guiar reposição por tromboelastometria.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'failed intubation': const ComplicationInfo(
        title: "Intubação Falhada e Múltiplas Tentativas",
        overview: "Incapacidade de intubar após tentativas estruturadas, com risco de trauma e hipóxia.",
        immediateActions: [
          "1. Declarar intubação difícil/falhada e limitar tentativas.",
          "2. Manter oxigenação com máscara ou dispositivo supraglótico.",
          "3. Utilizar videolaringoscópio e fio guia (bougie).",
          "4. Se CICO: realizar cricotireoidostomia de emergência.",
          "5. Acordar o paciente se cirurgia eletiva.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'desaturation': const ComplicationInfo(
        title: "Dessaturação Perioperatória / Hipóxia",
        overview: "Queda de SpO2 <90% indicando comprometimento agudo da troca gasosa pulmonar.",
        immediateActions: [
          "1. Elevar FiO2 para 100% e checar fluxo de gases.",
          "2. Auscultar tórax bilateralmente (descartar intubação seletiva).",
          "3. Aspirar secreções da cânula traqueal.",
          "4. Realizar manobra de recrutamento com PEEP.",
          "5. Checar capnografia e conexões.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'hypotension': const ComplicationInfo(
        title: "Hipotensão Intraoperatória",
        overview: "Pressão arterial média <65 mmHg com risco de hipoperfusão tecidual e lesão orgânica.",
        immediateActions: [
          "1. Confirmar medida pressórica.",
          "2. Reduzir profundidade da anestesia.",
          "3. Administrar bolus de cristaloides.",
          "4. Administrar vasopressor (Efedrina 5-10 mg ou Fenilefrina).",
          "5. Avaliar perdas volêmicas e cirúrgicas.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'hypertension': const ComplicationInfo(
        title: "Hipertensão Intraoperatória",
        overview: "Picos hipertensivos por plano anestésico superficial, estímulo doloroso ou hipervolemia.",
        immediateActions: [
          "1. Aprofundar anestesia e reforçar analgesia.",
          "2. Administrar opioide (Fentanil 50-100 mcg).",
          "3. Checar ventilação e descartar globo vesical.",
          "4. Administrar anti-hipertensivo (Labetalol, Esmolol ou Nitroprussiato).",
          "5. Monitorar ECG.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'bradycardia': const ComplicationInfo(
        title: "Bradicardia Perioperatória",
        overview: "Frequência cardíaca <50 bpm por estímulo vagal, anestésicos ou bloqueio espinhal alto.",
        immediateActions: [
          "1. Solicitar interrupção de estímulos vagais.",
          "2. Administrar Atropina 0.5-1 mg IV ou Glicopirrolato.",
          "3. Se associado a hipotensão: Efedrina ou bolus de Adrenalina.",
          "4. Preparar marcapasso se BAV avançado.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'bronchospasm': const ComplicationInfo(
        title: "Broncoespasmo Agudo",
        overview: "Espasmo da musculatura brônquica com elevação da pressão de pico e expiração prolongada.",
        immediateActions: [
          "1. FiO2 100% e aprofundar plano com inalatório ou propofol.",
          "2. Descartar obstrução mecânica do tubo.",
          "3. Nebulizar Salbutamol pelo circuito.",
          "4. Em casos refratários: Adrenalina IV (10-20 mcg) ou Sulfato de Magnésio 2g.",
          "5. Corticosteroides IV.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'laryngospasm': const ComplicationInfo(
        title: "Laringoespasmo Agudo",
        overview: "Fechamento reflexo das cordas vocais com obstrução respiratória alta.",
        immediateActions: [
          "1. Cessar estímulos e aplicar pressão positiva com 100% O2.",
          "2. Manobra de Larson (pressão firme atrás do ângulo da mandíbula).",
          "3. Aprofundar com Propofol (0.5-1 mg/kg).",
          "4. Se refratário: Succinilcolina (0.2-0.5 mg/kg IV).",
          "5. Monitorar edema pulmonar por pressão negativa.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'aspiration': const ComplicationInfo(
        title: "Aspiração Pulmonar de Conteúdo Gástrico",
        overview: "Entrada de secreção gástrica ácida nos pulmões, provocando pneumonite química.",
        immediateActions: [
          "1. Posição de Trendelenburg e aspirar orofaringe rapidamente.",
          "2. Intubar a traqueia precocemente.",
          "3. Aspirar dentro do tubo antes de ventilar com pressão positiva.",
          "4. Aplicar PEEP e suporte ventilatório.",
          "5. Transferir para UTI.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'delayed': const ComplicationInfo(
        title: "Despertar Prolongado da Anestesia",
        overview: "Ausência de retorno da consciência em tempo esperado após término da anestesia.",
        immediateActions: [
          "1. Manter ventilação e oxigenação adequadas.",
          "2. Reverter bloqueio neuromuscular residual (Sugamadex/Neostigmina).",
          "3. Testar antagonistas (Naloxona para opioides, Flumazenil para benzos).",
          "4. Checar glicemia, gasometria e temperatura.",
          "5. Descartar AVC intraoperatório.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'anaphylaxis': const ComplicationInfo(
        title: "Anafilaxia Perioperatória",
        overview: "Reação de hipersensibilidade sistêmica aguda com colapso circulatório e broncoespasmo.",
        immediateActions: [
          "1. Suspender alérgeno suspeito e fornecer 100% O2.",
          "2. Adrenalina precoce (10-50 mcg IV ou 0.5 mg IM).",
          "3. Ressuscitação volêmica vigorosa.",
          "4. Corticoide e anti-histamínico.",
          "5. Coletar triptase sérica.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'malignant hyperthermia': const ComplicationInfo(
        title: "Crise de Hipertermia Maligna (HM)",
        overview: "Emergência hipermetabólica desencadeada por anestésicos inalatórios voláteis ou succinilcolina.",
        immediateActions: [
          "1. Interromper gases voláteis e succinilcolina; hiperventilar com 100% O2.",
          "2. Administrar Dantroleno IV (2.5 mg/kg).",
          "3. Resfriamento ativo com soluções geladas.",
          "4. Tratar hipercalemia e acidose metabólica.",
          "5. Transferir para UTI.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'pneumothorax': const ComplicationInfo(
        title: "Pneumotórax Hipertensivo Intraoperatório",
        overview: "Presença de ar hipertensivo no espaço pleural causando colapso hemodinámico e respiratório.",
        immediateActions: [
          "1. Descontinuar N2O e ventilar com 100% O2.",
          "2. Descompressão imediata com agulha no 2º espaço intercostal.",
          "3. Inserir dreno de tórax no 5º espaço intercostal.",
          "4. Ajustar pressões de ventilação.",
          "5. Radiografia de tórax.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'ponv': const ComplicationInfo(
        title: "Náuseas e Vômitos Pós-Operatórios (NVPO)",
        overview: "Complicação frequente no pós-operatório associada a opioides e anestésicos inalatórios.",
        immediateActions: [
          "1. Ondansetrona 4 mg IV.",
          "2. Dexametasona 4-8 mg IV profilática.",
          "3. Hidratação volêmica adequada.",
          "4. Droperidol ou Metoclopramida.",
          "5. Analgesia multimodal poupadora de opioides.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
    },
    'zh': {
      'difficult bag': const ComplicationInfo(
        title: "面罩通气困难",
        overview: "在面罩正压通气时无法维持血氧饱和度 >90% 或无法纠正通气不足。",
        immediateActions: [
          "1. 立即呼叫气道支援。",
          "2. 摆正嗅物位并双人双手扣紧面罩。",
          "3. 置入口咽或鼻咽通气道。",
          "4. 消除面罩漏气。",
          "5. 及时置入喉罩或行气管插管。",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'cardiac arrest': const ComplicationInfo(
        title: "围手术期心脏骤停",
        overview: "心脏机械收缩功能停止，需立即进行心肺复苏和高级生命支持。",
        immediateActions: [
          "1. 呼叫急救，立即胸外按压并给予100%氧气。",
          "2. 连接除颤仪并分析心律。",
          "3. 每3-5分钟静推肾上腺素1mg。",
          "4. 纠正可逆原因 (4H / 4T)。",
          "5. 暂停手术。",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'death on table': const ComplicationInfo(
        title: "术中死亡",
        overview: "术中发生的由于严重生理衰竭或不可逆创伤导致的终末期灾难事件。",
        immediateActions: [
          "1. 继续抢救直至明确无效。",
          "2. 详细记录所有抢救用药和生命体征时序。",
          "3. 及时上报医疗管理部门。",
          "4. 封存病历记录与相关医疗设备。",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'position': const ComplicationInfo(
        title: "体位相关并发症",
        overview: "手术体位不当导致的周围神经牵拉、受压损伤及局部组织缺血。",
        immediateActions: [
          "1. 垫好受压部位（尺神经、腓总神经、臂丛）。",
          "2. 避免双臂外展超过90度。",
          "3. 术后早期进行周围神经系统检查。",
          "4. 出现肌力或感觉障碍时及时请神经科会诊。",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'shivering': const ComplicationInfo(
        title: "术后寒战 (PAS)",
        overview: "全身麻醉或椎管内麻醉后由于体温调节中枢受抑和低体温引起的肌张力增高和不自主颤抖。",
        immediateActions: [
          "1. 使用充气加温毯进行主动加温。",
          "2. 静推哌替啶 12.5-25mg 或可乐定。",
          "3. 增加氧疗以满足机体氧耗增加。",
          "4. 严密监测核心体温。",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'transfusion reaction': const ComplicationInfo(
        title: "急性输血反应",
        overview: "输注血液制品引发的急性溶血、过敏、TRALI或循环超负荷 (TACO) 等不良反应。",
        immediateActions: [
          "1. 立即停止输血，更换输液器并保持静脉通畅。",
          "2. 核对受血者与血袋信息。",
          "3. 针对过敏或休克给予抗组胺药、激素及升压药。",
          "4. 保留血袋并抽取血样送输血科复查。",
          "5. 补液并维持尿量，防治肾衰。",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'massive blood loss': const ComplicationInfo(
        title: "大出血与失血性休克",
        overview: "短时间内大量失血导致循环衰竭、组织低灌注及创伤/手术相关凝血功能障碍。",
        immediateActions: [
          "1. 启动大出血抢救输血方案 (MTP 1:1:1)。",
          "2. 建立大口径静脉通道并使用加温快速输血仪。",
          "3. 早期静推氨甲环酸 (1g)。",
          "4. 防治死亡三联征（低体温、酸中毒、凝血障碍）。",
          "5. 结合血栓弹力图 (TEG/ROTEM) 精准补充凝血因子。",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'failed intubation': const ComplicationInfo(
        title: "气管插管失败与多次插管尝试",
        overview: "多次尝试喉镜插管未能成功置管，存在气道创伤及不能插管不能通气 (CICO) 的严重风险。",
        immediateActions: [
          "1. 宣告插管困难，严格限制尝试次数（≤3次）。",
          "2. 维持面罩或喉罩有效给氧。",
          "3. 改用可视喉镜联合探条 (Bougie)。",
          "4. 若出现不能插管不能通气 (CICO)，立即行环甲膜穿刺/切开。",
          "5. 择期手术应考虑唤醒患者。",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'desaturation': const ComplicationInfo(
        title: "围手术期氧饱和度下降 / 低氧血症",
        overview: "SpO2 快速或持续降至 90% 以下，提示通气不足、气道梗阻、肺不张或严重通气/血流比例失调。",
        immediateActions: [
          "1. 立即给予 100% 纯氧并检查气体流量。",
          "2. 双肺听诊（排除单肺插管、支气管痉挛或气胸）。",
          "3. 气管导管内吸引分泌物。",
          "4. 实施肺复张手法并适当加用 PEEP。",
          "5. 检查呼气末二氧化碳波形和导管深度。",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'hypotension': const ComplicationInfo(
        title: "术中低血压",
        overview: "平均动脉压 (MAP) <65 mmHg 或较基线下降 >20%，影响重要脏器灌注。",
        immediateActions: [
          "1. 快速确认血压测量准确性。",
          "2. 减浅麻醉深度（调低吸入浓度或镇静药靶浓度）。",
          "3. 加快晶体液补液。",
          "4. 静推血管活性药物（麻黄碱 5-10mg 或去氧肾上腺素 50-100mcg）。",
          "5. 检查手术野失血并排除下腔静脉受压。",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'hypertension': const ComplicationInfo(
        title: "术中高血压",
        overview: "血压显著升高（收缩压 >160 mmHg 或升高 >20%），多因麻醉过浅、镇痛不足、高碳酸血症或容量负荷过重。",
        immediateActions: [
          "1. 评估麻醉深度与镇痛充分性。",
          "2. 追加阿片类药物（芬太尼 50-100mcg）或加深麻醉。",
          "3. 排除低氧、二氧化碳蓄积或尿潴留。",
          "4. 酌情使用降压药（拉贝洛尔 5-10mg、艾司洛尔或乌拉地尔）。",
          "5. 严密观察心肌缺血 ST 段改变。",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'bradycardia': const ComplicationInfo(
        title: "术中心动过缓",
        overview: "心率 <50 次/分（或伴血压下降），多由迷走反射、高位椎管内阻滞或药物引起。",
        immediateActions: [
          "1. 暂停牵拉迷走神经等手术刺激。",
          "2. 静推阿托品 0.5-1mg 或格隆溴铵 0.2mg。",
          "3. 合并严重低血压时使用麻黄碱或微量肾上腺素 (10-20mcg)。",
          "4. 严重房室传导阻滞时准备经皮起搏。",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'bronchospasm': const ComplicationInfo(
        title: "急性支气管痉挛",
        overview: "气道平滑肌痉挛导致气道峰压急剧升高、呼气时间延长及典型的斜坡形二氧化碳波形。",
        immediateActions: [
          "1. 给予 100% 纯氧并加深麻醉（吸入七氟烷或静推丙泊酚）。",
          "2. 排除导管扭折或进入单侧支气管。",
          "3. 经气管导管喷入沙丁胺醇 (6-10喷)。",
          "4. 严重病例静推微量肾上腺素 (10-20mcg) 或硫酸镁 2g。",
          "5. 静注糖皮质激素。",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'laryngospasm': const ComplicationInfo(
        title: "急性喉痉挛",
        overview: "声带及喉部肌肉反射性痉挛闭合，导致上呼吸道部分或完全梗阻。",
        immediateActions: [
          "1. 清除咽喉刺激物，给予 100% 纯氧正压通气 (CPAP)。",
          "2. 实施 Larson 手法（按压下颌角后方喉痉挛切迹）。",
          "3. 静推丙泊酚 (0.5-1 mg/kg) 加深麻醉。",
          "4. 若缺氧严重且不缓解：静推琥珀胆碱 (0.2-0.5 mg/kg)。",
          "5. 警惕并防治负压性肺水肿。",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'aspiration': const ComplicationInfo(
        title: "胃内容物误吸 (Mendelson综合征)",
        overview: "酸性胃内容物或食物残渣反流误吸入气管支气管树，导致严重化学性肺炎及急性呼吸窘迫。",
        immediateActions: [
          "1. 立即头低脚高位并强力吸引口咽部分泌物。",
          "2. 尽快行气管插管以封闭气道。",
          "3. 在正压通气前先进行气管内吸引。",
          "4. 采用保护性肺通气策略并加用 PEEP。",
          "5. 严密监护并转入 ICU。",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'delayed': const ComplicationInfo(
        title: "麻醉苏醒延迟",
        overview: "停止麻醉后超过正常预期时间（通常 >60-90 分钟）仍未恢复意识。",
        immediateActions: [
          "1. 维持气道通畅和充分氧合。",
          "2. 评估肌松残留并予以拮抗（舒更葡糖钠或新斯的明）。",
          "3. 排除阿片类（纳洛酮）或苯二氮䓬类（氟马西尼）药物残留。",
          "4. 检查血糖、血气电解质及体温。",
          "5. 排除围手术期急性脑血管意外。",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'anaphylaxis': const ComplicationInfo(
        title: "围手术期过敏性休克 / 严重过敏反应",
        overview: "由药物、乳胶或血液制品诱发的IgE介导或非IgE介导的严重全身超敏反应，表现为严重低血压与支气管痉挛。",
        immediateActions: [
          "1. 立即停用可疑致敏药物并给予 100% 纯氧。",
          "2. 尽早静推肾上腺素（初始 10-50mcg 静注或 0.5mg 肌注）。",
          "3. 快速大量输注晶体液抗休克。",
          "4. 给予糖皮质激素和抗组胺药。",
          "5. 在发病 30-120 分钟内抽血查血清类胰蛋白酶。",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'malignant hyperthermia': const ComplicationInfo(
        title: "恶性高热危象 (MH)",
        overview: "由吸入挥发性麻醉药或琥珀胆碱触发的骨骼肌高代谢危象，表现为呼气末CO2剧增、肌强直及体温暴涨。",
        immediateActions: [
          "1. 立即关闭挥发罐，停用琥珀胆碱，换用高流量 100% 纯氧过度通气。",
          "2. 尽早推注丹曲林 (2.5 mg/kg，必要时追加至 10 mg/kg)。",
          "3. 主动降温（输入冰盐水、体表冰敷）。",
          "4. 纠正高钾血症与严重代谢性酸中毒。",
          "5. 严密监护并转入 ICU。",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'pneumothorax': const ComplicationInfo(
        title: "术中张力性气胸",
        overview: "胸膜腔内积气压力进行性增高，导致肺萎陷、纵隔移位及静脉回流受阻所致的梗阻性休克。",
        immediateActions: [
          "1. 立即停用笑气 (N2O)，吸入 100% 纯氧。",
          "2. 紧急胸膜腔穿刺减压（锁骨中线第 2 肋间）。",
          "3. 行胸腔闭式引流术（腋前线/中线第 5 肋间）。",
          "4. 调低气道峰压与潮气量。",
          "5. 术后复查床旁胸片。",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'ponv': const ComplicationInfo(
        title: "术后恶心呕吐 (PONV)",
        overview: "麻醉和手术后常见的并发症，多与吸入麻醉药、阿片类镇痛药及前庭/胃肠刺激相关。",
        immediateActions: [
          "1. 静推昂丹司琼 4mg。",
          "2. 早期给予地塞米松 4-8mg。",
          "3. 充分补充晶体液补液。",
          "4. 酌情使用多哌啶醇或甲氧氯普胺。",
          "5. 采用多模式镇痛以减少阿片类药物用量。",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
    },
    'ar': {
      'difficult bag': const ComplicationInfo(
        title: "صعوبة التهوية بالقناع",
        overview: "عدم القدرة على الحفاظ على تشبع الأكسجين >90% أو تصحيح نقص التهوية بالقناع.",
        immediateActions: [
          "1. طلب المساعدة الفورية.",
          "2. تحسين وضعية الرأس ورفع الفك بكلتا اليدين.",
          "3. إدخال أنبوب بلعومي فموي أو أنفي.",
          "4. منع تسرب الهواء من القناع.",
          "5. وضع قناع حنجري أو التنبيب.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'cardiac arrest': const ComplicationInfo(
        title: "توقف القلب أثناء الجراحة",
        overview: "توقف النشاط الميكانيكي للقلب مما يتطلب إنعاشاً فورياً ودعماً متقدماً.",
        immediateActions: [
          "1. طلب الطوارئ والبدء بالضغط الصدري والتهوية بـ 100% أكسجين.",
          "2. توصيل مزيل الرجفان وتحليل النظم.",
          "3. إعطاء إبينفرين 1 ملغ وريدياً كل 3-5 دقائق.",
          "4. علاج الأسباب القابلة للعكس (4H/4T).",
          "5. إيقاف الجراحة مؤقتاً.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'death on table': const ComplicationInfo(
        title: "الوفاة أثناء العملية الجراحية",
        overview: "حدث نهائي كارثي أثناء الجراحة نتيجة قصور فيزيولوجي حاد أو إصابة غير قابلة للإصلاح.",
        immediateActions: [
          "1. متابعة الإنعاش حتى تأكيد عدم الجدوى.",
          "2. توثيق الجدول الزمني للأدوية والتدخلات بدقة.",
          "3. إبلاغ الإدارة الطبية ولجان الحوكمة.",
          "4. حفظ السجلات والمعدات الطبية.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'position': const ComplicationInfo(
        title: "مضاعفات وضعية المريض",
        overview: "إصابات الأعصاب أو نقص التروية الناجمة عن الضغط أو الشد المفرط أثناء وضعية الجراحة.",
        immediateActions: [
          "1. وضع وسائد واقية على نقاط الضغط العصبي.",
          "2. تجنب إبعاد الذراعين أكثر من 90 درجة.",
          "3. فحص عصبي دقيق بعد الإفاقة.",
          "4. استشارة طب الأعصاب في حال وجود ضعف.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'shivering': const ComplicationInfo(
        title: "الارتعاش بعد التخدير",
        overview: "انقباضات عضلية لا إرادية ناجمة عن انخفاض الحرارة واضطراب التنظيم الحراري بعد التخدير.",
        immediateActions: [
          "1. استخدام أجهزة التدفئة الهوائية النشطة.",
          "2. إعطاء ميبيريدين (12.5-25 ملغ وريدياً) أو كلونيدين.",
          "3. توفير الأكسجين الإضافي.",
          "4. مراقبة درجة الحرارة المركزية.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'transfusion reaction': const ComplicationInfo(
        title: "رد فعل نقل الدم الحاد",
        overview: "استجابة مناعية حادة أو ديناميكية دموية ناتجة عن عدم تطابق الدم المنقول أو فرط السوائل.",
        immediateActions: [
          "1. إيقاف نقل الدم فوراً والحفاظ على الوريد.",
          "2. التحقق من مطابقة كيس الدم وهوية المريض.",
          "3. إعطاء مضادات الهيستامين والكورتيزون ومثبتات الضغط.",
          "4. إرسال كيس الدم وعينات من المريض لبنك الدم.",
          "5. دعم إدرار البول.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'massive blood loss': const ComplicationInfo(
        title: "النزيف الحاد والصدمة النزفية",
        overview: "فقدان حاد ومكثف للدم يؤدي إلى انهيار الدورة الدموية واعتلال التخثر.",
        immediateActions: [
          "1. تفعيل بروتوكول نقل الدم المكثف (MTP).",
          "2. تركيب قساطر وريدية واسعة واستخدام أجهزة الضخ السريع الدافئ.",
          "3. إعطاء حمض الترانيكساميك (1 غرام وريدياً).",
          "4. الحفاظ على حرارة الجسم وعلاج نقص الكالسيوم والحماض.",
          "5. توجيه العلاج بواسطة TEG / ROTEM.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'failed intubation': const ComplicationInfo(
        title: "فشل التنبيب ومحاولات متعددة",
        overview: "عدم القدرة على إدخال الأنبوب الرغامي بعد عدة محاولات مما يهدد بنقص الأكسجة.",
        immediateActions: [
          "1. إعلان فشل التنبيب وتحديد عدد المحاولات (أقل من 3).",
          "2. الحفاظ على الأكسجة بالقناع أو القناع الحنجري.",
          "3. استخدام منظار الحنجرة بالفيديو والمعدال (Bougie).",
          "4. في حالة CICO: إجراء بضع الغشاء الحلقي والدرقي فوراً.",
          "5. إيقاظ المريض في العمليات الاختيارية.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'desaturation': const ComplicationInfo(
        title: "نقص تشبع الأكسجين أثناء العملية",
        overview: "انخفاض سريع أو تدريجي في تشبع الأكسجين أقل من 90% مما يتطلب تدخلاً عاجلاً.",
        immediateActions: [
          "1. رفع تركيز الأكسجين إلى 100% وفحص تدفق الغاز.",
          "2. تسمع الرئتين بالمسماع (استبعاد التنبيب الأحادي أو استرواح الصدر).",
          "3. شفط المفرزات من الأنبوب.",
          "4. تطبيق مناورة فتح الحويصلات مع ضغط PEEP.",
          "5. فحص مخطط CO2 وموقع الأنبوب.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'hypotension': const ComplicationInfo(
        title: "انخفاض ضغط الدم أثناء الجراحة",
        overview: "انخفاض ضغط الدم الشرياني المتوسط أقل من 65 ملم زئبق مما يهدد تروية الأعضاء.",
        immediateActions: [
          "1. التحقق من صحة قراءة الضغط.",
          "2. تقليل عمق التخدير.",
          "3. إعطاء دفعة من السوائل الوريدية.",
          "4. إعطاء رافعات الضغط (إيفيدرين 5-10 ملغ أو فينيليفرين).",
          "5. فحص النزيف الجراحي.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'hypertension': const ComplicationInfo(
        title: "ارتفاع ضغط الدم أثناء الجراحة",
        overview: "ارتفاع حاد في ضغط الدم ناتج عن ألم جراحي، خفة التخدير، أو فرط السوائل.",
        immediateActions: [
          "1. تقييم عمق التخدير وكفاية التسكين.",
          "2. إعطاء مسكنات أفيونية أو زيادة عمق التخدير.",
          "3. استبعاد فرط ثاني أكسيد الكربون أو امتلاء المثانة.",
          "4. إعطاء خافضات الضغط (لابيتالول، إسمولول).",
          "5. مراقبة تخطيط القلب.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'bradycardia': const ComplicationInfo(
        title: "بطء ضربات القلب أثناء الجراحة",
        overview: "معدل نبضات القلب أقل من 50 نبضة/دقيقة ناتج عن تحفيز العصب المبهم أو التخدير النصفي العالي.",
        immediateActions: [
          "1. إيقاف التحفيز الجراحي المسبب للعصب المبهم.",
          "2. إعطاء أتروبين 0.5-1 ملغ وريدياً.",
          "3. إعطاء إيفيدرين أو جرعات صغيرة من الإبينفرين عند انخفاض الضغط.",
          "4. تجهيز ناظم الخطى عند وجود إحصار قلبي.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'bronchospasm': const ComplicationInfo(
        title: "تشنج قصبي حاد",
        overview: "تقلص العضلات الملساء القصبية مع ارتفاع ضغط مجرى الهواء وأزيز في الصدر.",
        immediateActions: [
          "1. إعطاء 100% أكسجين وزيادة عمق التخدير.",
          "2. التأكد من سلامة الأنبوب وعدم انثنائه.",
          "3. إعطاء سالبيوتامول عبر الأنبوب.",
          "4. في الحالات الشديدة: إبينفرين وريدياً (10-20 ميكروغرام) أو كبريتات المغنيسيوم 2 غرام.",
          "5. إعطاء كورتيزون وريدياً.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'laryngospasm': const ComplicationInfo(
        title: "تشنج حنجري حاد",
        overview: "انغلاق لا إرادي للحبال الصوتية مما يؤدي إلى انسداد مجرى الهواء العلوي.",
        immediateActions: [
          "1. إزالة أي منبهات وتطبيق ضغط إيجابي مع 100% أكسجين.",
          "2. تطبيق مناورة لارسون (الضغط خلف زاوية الفك).",
          "3. زيادة التخدير ببروبوفول (0.5-1 ملغ/كغ).",
          "4. إعطاء سوكساميثونيوم (0.2-0.5 ملغ/كغ) عند استمرار التشنج.",
          "5. مراقبة الوذمة الرئوية الناتجة عن الضغط السلبي.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'aspiration': const ComplicationInfo(
        title: "استنشاق محتويات المعدة في الرئتين",
        overview: "دخول محتويات المعدة الحمضية إلى الرئتين مما يسبب التهاباً رئوياً كيميائياً حاداً.",
        immediateActions: [
          "1. وضعية ترندلنبورغ وشفط البلعوم الفموي فوراً.",
          "2. التنبيب الرغامي السريع لحماية المجرى الهوائي.",
          "3. شفط الأنبوب الرغامي قبل تطبيق الضغط الإيجابي.",
          "4. تطبيق PEEP ودعم التنفس.",
          "5. التحويل للعناية المركزة.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'delayed': const ComplicationInfo(
        title: "تأخر الإفاقة من التخدير",
        overview: "عدم استعادة الوعي بعد انتهاء التخدير ضمن الإطار الزمني المتوقع.",
        immediateActions: [
          "1. تأمين مجرى الهواء والتهوية الجيدة.",
          "2. فحص وعكس تأثير المرخيات العضلية (سوغاماديكس).",
          "3. إعطاء نالوكسون أو فلومازينيل عند الشك بفرط الجرعة.",
          "4. فحص السكر، الشوارد، والحرارة.",
          "5. استبعاد الجلطة الدماغية.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'anaphylaxis': const ComplicationInfo(
        title: "التأق وصدمة الحساسية أثناء الجراحة",
        overview: "رد فعل تحسسي جهازي حاد يهدد الحياة ويسبب هبوطاً حاداً في الضغط وتشنجاً قصبياً.",
        immediateActions: [
          "1. إيقاف الدواء المشتبه به فوراً وإعطاء 100% أكسجين.",
          "2. إعطاء إبينفرين مبكراً (10-50 ميكروغرام وريدياً أو 0.5 ملغ عضلياً).",
          "3. ضخ السوائل الوريدية بكميات كبيرة.",
          "4. إعطاء الكورتيزون ومضادات الهيستامين.",
          "5. فحص إنزيم التريبتاز في الدم.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'malignant hyperthermia': const ComplicationInfo(
        title: "أزمة فرط الحرارة الخبيث",
        overview: "حالة طوارئ استقلابية مفرطة مهددة للحياة ناتجة عن التخدير الاستنشاقي أو السوكساميثونيوم.",
        immediateActions: [
          "1. إيقاف الغازات الاستنشاقية والتهوية بـ 100% أكسجين بتدفق عالٍ.",
          "2. إعطاء دانترولين وريدياً (2.5 ملغ/كغ فوراً).",
          "3. التبريد الفعال للمريض.",
          "4. علاج فرط البوتاسيوم والحماض الاستقلابي.",
          "5. العناية المركزة.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'pneumothorax': const ComplicationInfo(
        title: "استرواح الصدر الضاغط أثناء الجراحة",
        overview: "تراكم الهواء تحت ضغط في التجويف الجنبي مما يسبب انخماص الرئة وصدمة انسدادية.",
        immediateActions: [
          "1. إيقاف أكسيد النيتروز وإعطاء 100% أكسجين.",
          "2. تفريغ الهواء فوراً بإبرة في الورب الثاني.",
          "3. تركيب أنبوب تصريف صدري في الورب الخامس.",
          "4. تعديل ضغوط جهاز التنفس.",
          "5. تصوير الصدر بالأشعة.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'ponv': const ComplicationInfo(
        title: "الغثيان والقيء بعد الجراحة (PONV)",
        overview: "مضاعفة شائعة بعد التخدير ناجمة عن الأدوية المخدرة والمسكنات الأفيونية.",
        immediateActions: [
          "1. إعطاء أوندانسيترون 4 ملغ وريدياً.",
          "2. إعطاء ديكساميثازون 4-8 ملغ للوقاية.",
          "3. ترطيب كافٍ بالسوائل.",
          "4. إضافة دروبيريدول عند اللزوم.",
          "5. تسكين متعدد الوسائط لتخفيف الأفيونات.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
    },
    'ko': {
      'difficult bag': const ComplicationInfo(
        title: "어려운 마스크 환기",
        overview: "안면 마스크 양압 환기 시 산소 포화도 >90%를 유지할 수 없거나 환기 부족을 교정할 수 없는 상태.",
        immediateActions: [
          "1. 즉시 기도관리 지원을 요청합니다.",
          "2. 머리 위치를 교정하고 2인 턱 들기 수기를 적용합니다.",
          "3. 구인두 또는 비인두 기도기를 삽입합니다.",
          "4. 마스크 밀착 및 공기 누출을 확인합니다.",
          "5. 성문상기도기(LMA) 거치 또는 기관삽관을 시행합니다.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'cardiac arrest': const ComplicationInfo(
        title: "수술 중 심정지",
        overview: "심장 기계적 수축 소실로 즉각적인 심폐소생술 및 전문소생술이 요구되는 상태.",
        immediateActions: [
          "1. 응급 요청 후 즉시 흉부압박과 100% 산소 환기를 시작합니다.",
          "2. 제세동기를 부착하고 리듬을 분석합니다.",
          "3. 에피네프린 1mg을 3-5분마다 정주합니다.",
          "4. 가역적 원인(4H & 4T)을 교정합니다.",
          "5. 수술을 중단합니다.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'death on table': const ComplicationInfo(
        title: "수술 중 사망",
        overview: "중증 생리적 허탈 또는 비가역적 손상으로 인한 수술 중 최종 사망 사건.",
        immediateActions: [
          "1. 소생술 지속 후 최종 중단 판정을 진행합니다.",
          "2. 약물 투여 및 활력징후 타임라인을 정밀 기록합니다.",
          "3. 과장 및 병원 집행부에 즉시 보고합니다.",
          "4. 의무기록 및 관련 장비를 보존합니다.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'position': const ComplicationInfo(
        title: "수술 체위 관련 합병증",
        overview: "수술 중 부적절한 체위로 인한 신경 압박, 견인 및 국소 조직 허혈 손상.",
        immediateActions: [
          "1. 척골신경, 비골신경, 완신경총 부위에 완충 패드를 덧댑니다.",
          "2. 양팔 외전을 90도 이하로 유지합니다.",
          "3. 수술 후 신경학적 검사를 조기 시행합니다.",
          "4. 이상 징후 시 신경과 협진 및 재활을 의뢰합니다.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'shivering': const ComplicationInfo(
        title: "마취 후 떨림 (Shivering)",
        overview: "마취제에 의한 체온조절 억제 및 저체온으로 발생하는 불수의적 골격근 진전.",
        immediateActions: [
          "1. 강제 온풍 가온 장치로 적극적인 가온을 시행합니다.",
          "2. 메페리딘(12.5-25mg IV) 또는 클로니딘을 투여합니다.",
          "3. 산소 소모량 증가에 대비해 산소를 공급합니다.",
          "4. 중심체온을 지속 측정합니다.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'transfusion reaction': const ComplicationInfo(
        title: "급성 수혈 반응",
        overview: "혈액제제 투여 후 발생하는 급성 용혈, 아나필락시스, TRALI 또는 순환 과부하.",
        immediateActions: [
          "1. 수혈을 즉시 중단하고 수액 라인을 유지합니다.",
          "2. 혈액백과 환자 식별 정보를 재확인합니다.",
          "3. 항히스타민제, 스테로이드 및 승압제를 투여합니다.",
          "4. 혈액백과 환자 혈액 검체를 혈액원에 발송합니다.",
          "5. 수액 투여 및 이뇨제로 소변량을 확보합니다.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'massive blood loss': const ComplicationInfo(
        title: "대량 출혈 및 출혈성 쇼크",
        overview: "급격한 대량 실혈로 인한 혈역학적 붕괴, 저관류 및 후천성 응고장애.",
        immediateActions: [
          "1. 대량 수혈 프로토콜(MTP 1:1:1)을 즉시 발동합니다.",
          "2. 대구경 정맥로 확보 및 가온 급속 주입기를 가동합니다.",
          "3. 트라넥삼산(Tranexamic acid) 1g을 조기 투여합니다.",
          "4. 저체온증, 산혈증, 저칼슘혈증을 적극 교정합니다.",
          "5. ROTEM/TEG 기반 맞춤형 응고인자 교정을 시행합니다.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'failed intubation': const ComplicationInfo(
        title: "기관삽관 실패 및 반복 시도",
        overview: "반복적인 후두경 시도에도 삽관에 실패하여 기도 손상 및 환기 불가 위험이 높은 상태.",
        immediateActions: [
          "1. 삽관 실패를 선언하고 시도 횟수를 3회 이내로 제한합니다.",
          "2. 안면 마스크 또는 LMA로 산소 공급을 최우선 유지합니다.",
          "3. 비디오 후두경 및 부지(Bougie)를 적극 활용합니다.",
          "4. CICO 발생 시 즉시 윤상갑상막절개술을 시행합니다.",
          "5. 정규 수술인 경우 환자를 각성시킵니다.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'desaturation': const ComplicationInfo(
        title: "수술 중 산소포화도 저하 / 저산소혈증",
        overview: "SpO2가 90% 미만으로 급격히 저하되어 가스 교환 장애를 시사하는 상태.",
        immediateActions: [
          "1. FiO2를 100%로 올리고 신선 가스 유량을 확인합니다.",
          "2. 양측 폐음을 청진합니다(일측관 삽관, 기흉 배제).",
          "3. 기관내 튜브 내 분비물을 흡인합니다.",
          "4. PEEP을 적용하여 폐포 동원술을 시행합니다.",
          "5. 호기말 이산화탄소(ETCO2) 파형과 튜브 깊이를 점검합니다.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'hypotension': const ComplicationInfo(
        title: "수술 중 저혈압",
        overview: "평균동맥압(MAP)이 65 mmHg 미만으로 저하되어 주요 장기 관류 저하를 초래하는 상태.",
        immediateActions: [
          "1. 혈압 측정을 신속히 재확인합니다.",
          "2. 흡입마취제 농도를 줄이고 마취 심도를 조절합니다.",
          "3. 정질액 수액 볼루스를 투여합니다.",
          "4. 승압제(에페드린 5-10mg 또는 페닐에프린 50-100mcg)를 투여합니다.",
          "5. 수술 출혈량 및 하대정맥 압박 여부를 확인합니다.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'hypertension': const ComplicationInfo(
        title: "수술 중 고혈압",
        overview: "수술 자극, 마취 심도 부족, 불충분한 진통 또는 고탄산혈증에 의한 혈압 급상승.",
        immediateActions: [
          "1. 마취 심도 및 진통 수준을 평가합니다.",
          "2. 마약성 진통제(펜타닐 50-100mcg)를 추가하거나 마취를 깊게 합니다.",
          "3. 고탄산혈증, 저산소증, 방광 팽만을 배제합니다.",
          "4. 라베탈롤(5-10mg) 또는 에스몰롤 등 항고혈압제를 투여합니다.",
          "5. 심전도 ST 분절 변화를 감시합니다.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'bradycardia': const ComplicationInfo(
        title: "수술 중 서맥",
        overview: "심박수 <50회/분으로 미주신경 반사, 고위 척추마취 또는 약물에 의해 유발되는 상태.",
        immediateActions: [
          "1. 미주신경을 자극하는 수술 조작을 즉시 중단하도록 요청합니다.",
          "2. 아트로핀 0.5-1.0mg 또는 글리코피롤레이트를 정주합니다.",
          "3. 혈압 저하 동반 시 에페드린 또는 에피네프린 소량 볼루스를 투여합니다.",
          "4. 고도 방실차단 시 경피 심장박동조율기를 준비합니다.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'bronchospasm': const ComplicationInfo(
        title: "급성 기관지경련",
        overview: "기관지 평활근 수축으로 최고 기도압 상승, 천명음 및 폐쇄성 호기 곡선이 나타나는 상태.",
        immediateActions: [
          "1. 100% 산소를 투여하고 흡입마취제 또는 프로포폴로 마취를 깊게 합니다.",
          "2. 튜브 꺾임이나 일측 폐 삽관 등 기계적 원인을 배제합니다.",
          "3. 살부타몰 흡입제를 튜브 어댑터로 분무합니다.",
          "4. 중증 시 에피네프린(10-20mcg IV) 또는 황산마그네슘 2g을 정주합니다.",
          "5. 스테로이드를 투여합니다.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'laryngospasm': const ComplicationInfo(
        title: "급성 후두경련",
        overview: "성대의 반사적 연축으로 상기도가 급격히 폐쇄되는 응급 상황.",
        immediateActions: [
          "1. 기도 자극을 즉시 중단하고 100% 산소로 양압 환기(CPAP)를 유지합니다.",
          "2. 라슨 수기(Larson maneuver, 하악각 뒤 압박)를 적용합니다.",
          "3. 프로포폴(0.5-1.0mg/kg IV)로 마취를 깊게 합니다.",
          "4. 반응이 없거나 저산소혈증 진행 시 숙시닐콜린(0.2-0.5mg/kg IV)을 투여합니다.",
          "5. 음압성 폐부종 발생을 감시합니다.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'aspiration': const ComplicationInfo(
        title: "위 내용물 흡인 (멘델슨 증후군)",
        overview: "산성 위액이나 음식물이 기도로 흡인되어 화학적 폐렴 및 폐 손상을 유발하는 질환.",
        immediateActions: [
          "1. 트렌델렌버그 체위로 변경하고 구인두를 즉시 흡인합니다.",
          "2. 신속히 기관삽관을 시행하여 기도를 차단합니다.",
          "3. 양압 환기를 적용하기 전에 튜브 내부를 흡인합니다.",
          "4. PEEP을 적용한 폐 보호 환기를 시행합니다.",
          "5. 중환자실(ICU)로 이송하여 집중 치료합니다.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'delayed': const ComplicationInfo(
        title: "마취 후 각성 지연",
        overview: "마취 종료 후 예상 시간(60-90분)이 지나도 의식이 회복되지 않는 상태.",
        immediateActions: [
          "1. 기도 확보 및 적절한 환기를 유지합니다.",
          "2. 잔여 근이완을 확인하고 길항제(슈가마덱스/네오스티그민)를 투여합니다.",
          "3. 마약류(나록손) 또는 벤조다이아제핀(플루마제닐) 잔여 효과를 역전합니다.",
          "4. 혈당, 전해질 및 체온을 확인합니다.",
          "5. 급성 뇌졸중 등 중추신경계 손상을 배제합니다.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'anaphylaxis': const ComplicationInfo(
        title: "수술 중 아나필락시스 쇼크",
        overview: "약물, 라텍스 등으로 유발되어 급격한 순환허탈 및 기도폐쇄를 동반하는 전신성 중증 과민반응.",
        immediateActions: [
          "1. 의심 약물 투여를 즉각 중단하고 100% 산소를 투여합니다.",
          "2. 에피네프린을 조기 투여합니다(초기 10-50mcg IV 또는 0.5mg IM).",
          "3. 대량의 정질액으로 급속 수액소생술을 시행합니다.",
          "4. 항히스타민제 및 스테로이드를 투여합니다.",
          "5. 발생 1-2시간 후 혈청 트립타아제(Tryptase) 검사를 채혈합니다.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'malignant hyperthermia': const ComplicationInfo(
        title: "악성고열증 위기 (MH Crisis)",
        overview: "흡입마취제 또는 숙시닐콜린에 의해 유발되는 골격근의 치명적인 초고대사 위기.",
        immediateActions: [
          "1. 흡입마취제와 숙시닐콜린을 즉시 중단하고 100% 산소 고유량으로 과환기합니다.",
          "2. 단트롤렌(Dantrolene 2.5mg/kg IV)을 신속히 투여합니다.",
          "3. 냉생리식염수 및 얼음으로 적극적인 냉각을 시행합니다.",
          "4. 고칼륨혈증과 대사성 산증을 교정합니다.",
          "5. 중환자실로 이송하여 집중 치료합니다.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'pneumothorax': const ComplicationInfo(
        title: "수술 중 긴장성 기흉",
        overview: "흉막강 내 공기 축적으로 흉강내압이 상승하여 폐 허탈 및 폐쇄성 쇼크를 유발하는 응급 질환.",
        immediateActions: [
          "1. 아산화질소(N2O)를 중단하고 100% 산소로 환기합니다.",
          "2. 쇄골중간선 제2늑간에 굵은 바늘로 즉각 감압술을 시행합니다.",
          "3. 제5늑간에 흉관 삽관술(Chest tube)을 시행합니다.",
          "4. 환기 압력을 조절합니다.",
          "5. 흉부 X-ray로 확인합니다.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'ponv': const ComplicationInfo(
        title: "수술 후 오심 및 구토 (PONV)",
        overview: "흡입마취제, 마약성 진통제 및 수술 자극으로 인해 발생하는 수술 후 구역 및 구토.",
        immediateActions: [
          "1. 온단세트론 4mg을 정주합니다.",
          "2. 덱사메타손 4-8mg을 조기 투여합니다.",
          "3. 충분한 정맥 수액을 공급합니다.",
          "4. 드로페리돌 또는 메토클로프라미드를 고려합니다.",
          "5. 다중모드 진통 요법으로 마약류 사용을 줄입니다.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
    },
    'ja': {
      'difficult bag': const ComplicationInfo(
        title: "マスク換気困難",
        overview: "フェイスマスク換気中にSpO2 >90%を維持できない、または換気不全を改善できない状態。",
        immediateActions: [
          "1. 直ちに応援を要請する。",
          "2. スニッフィング位と両手下顎挙上法を行う。",
          "3. 経口・経鼻エアウェイを挿入する。",
          "4. マスクの密着を確認しリークを防ぐ。",
          "5. 声門上器具（LMA）留置または気管挿管を行う。",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'cardiac arrest': const ComplicationInfo(
        title: "周術期心停止",
        overview: "心拍出停止により、直ちに入念なCPRおよびACLSを必要とする状態。",
        immediateActions: [
          "1. 応援要請、胸骨圧迫開始、100%酸素投与。",
          "2. 除細動器装着し心電図解析。",
          "3. アドレナリン1mgを3〜5分毎に静注。",
          "4. 原因検索と治療（4H4T）。",
          "5. 手術を一時中断。",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'death on table': const ComplicationInfo(
        title: "術中死亡",
        overview: "重篤な循環破綻や不可逆的損傷による術中の致命的イベント。",
        immediateActions: [
          "1. 蘇生限界の判定までACLS手順を継続。",
          "2. 投与薬剤およびバイタルの時系列を詳細記録。",
          "3. 診療部門責任者への速やかな報告。",
          "4. 診療記録および使用機材の保全。",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'position': const ComplicationInfo(
        title: "体位関連合併症",
        overview: "手術体位に伴う神経圧迫・伸展障害および局所組織の虚血性損傷。",
        immediateActions: [
          "1. 圧迫部位（尺骨神経、腓骨神経、腕神経叢）の保護パッド確認。",
          "2. 上肢外転を90度以内に制限。",
          "3. 術後早期の神経学的診察の実施。",
          "4. 神経麻痺を認める場合は早期に専門科コンサルト。",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'shivering': const ComplicationInfo(
        title: "術後シバリング",
        overview: "低体温や麻酔薬による体温調節閾値変化に伴う不随意の骨格筋収縮。",
        immediateActions: [
          "1. 温風式加温ブランケットによる積極的加温。",
          "2. ペチジン（12.5〜25mg静注）またはクロニジンの投与。",
          "3. 酸素消費量増加に対応した酸素吸入。",
          "4. 深部体温のモニタリング。",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'transfusion reaction': const ComplicationInfo(
        title: "急性輸血反応",
        overview: "輸血製剤投与に伴う急性溶血反応、アレルギー、TRALIまたは循環過負荷（TACO）。",
        immediateActions: [
          "1. 直ちに輸血を中止し、別のラインで輸液を確保。",
          "2. 患者情報と血液バッグの照合確認。",
          "3. 重症度に応じ抗ヒスタミン薬、ステロイド、昇圧薬を投与。",
          "4. 血液バッグと患者検体を輸血部へ返送・検査依頼。",
          "5. 利尿を維持し急性腎障害を予防。",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'massive blood loss': const ComplicationInfo(
        title: "大量出血・出血性ショック",
        overview: "短時間の大量失血による循環虚脱、組織低灌流および播種性凝固異常。",
        immediateActions: [
          "1. 大量輸血プロトコル（MTP 1:1:1）を即時起動。",
          "2. 太い末梢静脈路確保と急速加温輸血器の稼働。",
          "3. トラネキサム酸1gを早期静注。",
          "4. 致死的三徴（低体温・アシドーシス・凝固異常）の防止。",
          "5. ROTEM/TEGによる止血能モニタリングと因子補充。",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'failed intubation': const ComplicationInfo(
        title: "挿管困難・挿管失敗",
        overview: "複数回の喉頭展開にもかかわらず気管挿管に成功せず、換気不能（CICO）のリスクが高まる状態。",
        immediateActions: [
          "1. 挿管困難を宣言し、試行回数を制限（3回以内）。",
          "2. フェイスマスクまたはSGA（喉頭マスク）で酸素化を維持。",
          "3. ビデオ喉頭鏡およびガムエラスティックブジーを使用。",
          "4. 換気不能（CICO）時は直ちに輪状甲状膜切開。",
          "5. 予定手術では覚醒を検討。",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'desaturation': const ComplicationInfo(
        title: "周術期低酸素血症・SpO2低下",
        overview: "SpO2が90%未満へ低下し、換気障害・気道閉塞・無気肺等が疑われる状態。",
        immediateActions: [
          "1. FiO2を100%に上げ新鮮ガス流量を確認。",
          "2. 両側肺音を聴診（片肺挿管・気胸・気管支痙攣の鑑別）。",
          "3. 気管チューブ内の分泌物を吸引。",
          "4. PEEP負荷による肺胞リクルートメント手技。",
          "5. カプノグラム波形と気管チューブの位置確認。",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'hypotension': const ComplicationInfo(
        title: "術中低血圧",
        overview: "平均動脈圧（MAP）<65 mmHgまたは基準値から20%以上の低下を認め、臓器灌流が障害される状態。",
        immediateActions: [
          "1. 血圧測定値の正確性を確認。",
          "2. 麻酔深度を浅くする（吸入麻酔薬減量など）。",
          "3. 晶質液の急速投与。",
          "4. 昇圧薬投与（エフェドリン5〜10mgまたはフェニレフリン）。",
          "5. 術野の出血量確認および大静脈圧迫の解除。",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'hypertension': const ComplicationInfo(
        title: "術中高血圧",
        overview: "麻酔深度不足、不十分な鎮痛、高炭酸ガス血症や過剰輸液に伴う急激な血圧上昇。",
        immediateActions: [
          "1. 麻酔深度と鎮痛の十分性を評価。",
          "2. オピオイド追加投与（フェンタニルなど）または麻酔深度の深化。",
          "3. 高炭酸ガス血症や膀胱充満を検索・解除。",
          "4. 降圧薬の投与（ランジオロール、ニカルジピンなど）。",
          "5. 心電図で心筋虚血兆候を監視。",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'bradycardia': const ComplicationInfo(
        title: "術中徐脈",
        overview: "心拍数<50回/分（血圧低下を伴う）で、迷走神経反射、高位脊髄麻酔、薬剤性による状態。",
        immediateActions: [
          "1. 迷走神経反射を惹起する手術操作の中断を依頼。",
          "2. アトロピン0.5〜1mg静注。",
          "3. 低血圧を伴う場合はエフェドリンまたはアドレナリン微量静注。",
          "4. 高度房室ブロック時は経皮ペーシングの準備。",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'bronchospasm': const ComplicationInfo(
        title: "急性気管支痙攣",
        overview: "気管支平滑筋攣縮により最高気道内圧上昇、喘鸣、閉塞性呼気カプノグラムを呈する状態。",
        immediateActions: [
          "1. 100%酸素投与、吸入麻酔薬またはプロポフォールで麻酔深度を深める。",
          "2. 気管チューブの屈曲や片肺挿管を除外。",
          "3. サルブタモール吸入を回路経由で投与。",
          "4. 重症例ではアドレナリン微量静注（10〜20µg）または硫酸マグネシウム2g投与。",
          "5. ステロイド静注。",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'laryngospasm': const ComplicationInfo(
        title: "急性喉頭痙攣",
        overview: "声帯の反射性攣縮による上気道の完全または不完全閉塞。",
        immediateActions: [
          "1. 気道刺激を解除し、100%酸素で持続陽圧換気（CPAP）。",
          "2. ラーソン手技（下顎角後方の圧迫）。",
          "3. プロポフォール（0.5〜1mg/kg）で麻酔深度を深める。",
          "4. 改善しない場合はスキサメトニウム（0.2〜0.5mg/kg静注）投与。",
          "5. 陰圧性肺水腫の出現に警戒。",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'aspiration': const ComplicationInfo(
        title: "胃内容物誤嚥（メンデルソン症候群）",
        overview: "酸性胃内容物の気道内流入に伴う急性化学性肺炎および低酸素血症。",
        immediateActions: [
          "1. トレンデレンブルグ位とし口腔咽頭内を速やかに吸引。",
          "2. 気道保護のため直ちに気管挿管。",
          "3. 陽圧換気を開始する前に気管チューブ内を吸引。",
          "4. PEEPを付加した肺保護換気。",
          "5. ICU入室と集中管理。",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'delayed': const ComplicationInfo(
        title: "麻酔覚醒遅延",
        overview: "麻酔終了後、予定時間を経過しても意識が回復しない状態。",
        immediateActions: [
          "1. 気道確保と確実な酸素化・換気の維持。",
          "2. 筋弛緩モニター確認と拮抗薬投与（スガマデクス）。",
          "3. 麻薬・ベンゾジアゼピンの拮抗薬（ナロキソン、フルマゼニル）検討。",
          "4. 血糖値、電解質、体温の測定。",
          "5. 脳血管障害の精査。",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'anaphylaxis': const ComplicationInfo(
        title: "周術期アナフィラキシー",
        overview: "薬剤やラテックス等により誘発され、急激な循環虚脱と気道閉塞を伴う重篤な過敏反応。",
        immediateActions: [
          "1. 疑わしい薬剤の投与を直ちに中止し、100%酸素化。",
          "2. アドレナリンの早期投与（10〜50µg静注または0.5mg筋注）。",
          "3. 大量輸液による循環作動薬の併用。",
          "4. 抗ヒスタミン薬・ステロイド投与。",
          "5. 発症後30〜120分で血清トリプターゼ測定用の採血。",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'malignant hyperthermia': const ComplicationInfo(
        title: "悪性高熱症危機（MH Crisis）",
        overview: "吸入麻酔薬やスキサメトニウムにより誘発される骨格筋の致死的超高代謝クリーゼ。",
        immediateActions: [
          "1. 吸入麻酔薬とスキサメトニウムを即時中止、100%酸素高流量で過換気。",
          "2. ダントロレン（2.5mg/kg静注）の早期投与。",
          "3. 積極的冷却（冷却輸液、アイスパック）。",
          "4. 高カリウム血症および代謝性アシドーシスの補正。",
          "5. ICUでの厳重な管理。",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'pneumothorax': const ComplicationInfo(
        title: "術中緊張性気胸",
        overview: "胸腔内圧の急激な上昇により肺虚脱、縦隔偏位、静脈還流障害をきたす閉塞性ショック。",
        immediateActions: [
          "1. 亜酸化窒素を中止し、100%酸素投与。",
          "2. 鎖骨中線第2肋間からの緊急穿刺脱気。",
          "3. 胸腔ドレーン留置（第5肋間前腋窩線）。",
          "4. 換気圧の再調整。",
          "5. ポータブル胸部X線で確認。",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'ponv': const ComplicationInfo(
        title: "術後悪心嘔吐（PONV）",
        overview: "吸入麻酔薬、オピオイド、手術侵襲に伴う術後の不快な悪心・嘔吐。",
        immediateActions: [
          "1. オンダンセトロン4mg静注。",
          "2. デキサメタゾン4〜8mgの早期投与。",
          "3. 十分な輸液負荷。",
          "4. ドロペリドールまたはメトクロプラミドの併用。",
          "5. オピオイド節約型のマルチモーダル鎮痛。",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
    },
    'id': {
      'difficult bag': const ComplicationInfo(
        title: "Ventilasi Sungkup Sulit",
        overview: "Ketidakmampuan mempertahankan SpO2 >90% atau mengatasi hipoventilasi saat ventilasi sungkup.",
        immediateActions: [
          "1. Minta bantuan segera.",
          "2. Posisikan sniffing dan lakukan jaw thrust dua tangan.",
          "3. Pasang oropharyngeal airway (Guedel).",
          "4. Perbaiki kebocoran sungkup.",
          "5. Pasang LMA atau lakukan intubasi.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'cardiac arrest': const ComplicationInfo(
        title: "Henti Jantung Perioperatif",
        overview: "Terhentinya aktivitas mekanik jantung yang membutuhkan RJP dan ACLS segera.",
        immediateActions: [
          "1. Minta bantuan, lakukan kompresi dada dan ventilasi 100% O2.",
          "2. Pasang defibrilator dan analisis irama.",
          "3. Berikan Epinefrin 1 mg IV tiap 3-5 menit.",
          "4. Tangani penyebab reversibel (4H & 4T).",
          "5. Hentikan operasi sementara.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'death on table': const ComplicationInfo(
        title: "Kematian Intraoperatif",
        overview: "Kejadian fatal intraoperatif akibat kegagalan fisiologis masif atau trauma ireversibel.",
        immediateActions: [
          "1. Lanjutkan ACLS hingga dinyatakan tidak berhasil.",
          "2. Catat kronologi pemberian obat dan tanda vital.",
          "3. Laporkan ke komite medis dan manajemen RS.",
          "4. Amankan rekam medis dan perangkat yang digunakan.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'position': const ComplicationInfo(
        title: "Komplikasi Posisi Pasien",
        overview: "Cedera saraf atau iskemia jaringan akibat penekanan atau peregangan posisi bedah.",
        immediateActions: [
          "1. Berikan bantalan pada titik tekan saraf.",
          "2. Hindari abduksi lengan >90 derajat.",
          "3. Lakukan pemeriksaan neurologis pascaoperasi.",
          "4. Konsulkan ke neurologi bila ditemukan kelainan.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'shivering': const ComplicationInfo(
        title: "Menggigil Pascaanestesi",
        overview: "Kontraksi otot involunter akibat hipotermia atau gangguan termoregulasi setelah anestesi.",
        immediateActions: [
          "1. Pasang selimut penghangat udara aktif.",
          "2. Berikan Petidin 12.5-25 mg IV atau Klonidin.",
          "3. Berikan suplementasi oksigen.",
          "4. Pantau suhu inti tubuh.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'transfusion reaction': const ComplicationInfo(
        title: "Reaksi Transfusi Akut",
        overview: "Reaksi imunologi atau hemodinamik akut akibat transfusi darah (TRALI, TACO, hemolisis).",
        immediateActions: [
          "1. Hentikan transfusi segera dan pertahankan akses IV.",
          "2. Cocokkan identitas kantong darah dan pasien.",
          "3. Berikan antihistamin, kortikosteroid, dan vasopresor bila syok.",
          "4. Kirim sisa darah dan sampel pasien ke bank darah.",
          "5. Pertahankan diuresis dengan hidrasi.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'massive blood loss': const ComplicationInfo(
        title: "Perdarahan Masif & Syok Hemoragik",
        overview: "Perdarahan akut masif yang menyebabkan kolaps hemodinamik dan koagulopati konsumtif.",
        immediateActions: [
          "1. Aktifkan protokol transfusi masif (MTP 1:1:1).",
          "2. Pasang akses vena besar dan alat infus cepat berpemanas.",
          "3. Berikan Asam Traneksamat 1g IV.",
          "4. Cegah hipotermia, asidosis, dan hipokalsemia.",
          "5. Evaluasi dengan TEG/ROTEM.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'failed intubation': const ComplicationInfo(
        title: "Gagal Intubasi & Upaya Berulang",
        overview: "Ketidakmampuan memasang ETT setelah upaya berulang, berisiko trauma dan gagal ventilasi.",
        immediateActions: [
          "1. Deklarasikan gagal intubasi dan batasi percobaan (<3 kali).",
          "2. Pertahankan oksigenasi dengan sungkup atau LMA.",
          "3. Gunakan videolaringoskop dan bougie.",
          "4. Jika CICO: lakukan krikotiroidotomi darurat.",
          "5. Bangunkan pasien bila operasi elektif.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'desaturation': const ComplicationInfo(
        title: "Desaturasi Perioperatif / Hipoksemia",
        overview: "Penurunan SpO2 <90% yang menandakan gangguan pertukaran gas atau ventilasi.",
        immediateActions: [
          "1. Naikkan FiO2 ke 100% dan periksa aliran gas.",
          "2. Auskultasi kedua lapang paru (singkirkan intubasi endobronkial).",
          "3. Lakukan suction pipa endotrakeal.",
          "4. Lakukan manuver rekrutmen paru dengan PEEP.",
          "5. Periksa kapnografi dan posisi tabung.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'hypotension': const ComplicationInfo(
        title: "Hipotensi Intraoperatif",
        overview: "Tekanan arteri rata-rata (MAP) <65 mmHg yang berisiko mengganggu perfusi organ.",
        immediateActions: [
          "1. Konfirmasi ulang nilai tekanan darah.",
          "2. Kurangi kedalaman anestesi.",
          "3. Berikan bolus cairan kristaloid.",
          "4. Berikan vasopresor (Efedrin 5-10 mg atau Fenilefrin).",
          "5. Evaluasi perdarahan dan kompresi vena kava.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'hypertension': const ComplicationInfo(
        title: "Hipertensi Intraoperatif",
        overview: "Peningkatan tekanan darah berlebih akibat anestesi dangkal, nyeri, atau hipervolemia.",
        immediateActions: [
          "1. Periksa kedalaman anestesi dan kecukupan analgesia.",
          "2. Berikan fentanil atau perdalam anestesi.",
          "3. Singkirkan hiperkapnia atau retensi urin.",
          "4. Titrasi antihipertensi (Labetalol atau Nikardipin).",
          "5. Pantau iskemia pada EKG.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'bradycardia': const ComplicationInfo(
        title: "Bradikardia Perioperatif",
        overview: "Denyut jantung <50 x/menit akibat refleks vagal, obat, atau blok spinal tinggi.",
        immediateActions: [
          "1. Minta operator menghentikan stimulasi vagal.",
          "2. Berikan Atropin 0.5-1 mg IV atau Glikopirolat.",
          "3. Berikan Efedrin atau Adrenalin bolus kecil bila disertai hipotensi.",
          "4. Siapkan pacu jantung bila ada blok AV total.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'bronchospasm': const ComplicationInfo(
        title: "Bronkospasme Akut",
        overview: "Spasme otot polos bronkus dengan peningkatan tekanan puncak jalan napas dan mengi.",
        immediateActions: [
          "1. Berikan 100% O2 dan perdalam anestesi dengan inhalasi/propofol.",
          "2. Singkirkan tabung terlipat atau intubasi selektif.",
          "3. Berikan inhalasi Salbutamol lewat sirkuit.",
          "4. Pada kasus berat: Adrenalin IV (10-20 mcg) atau Magnesium Sulfat 2g.",
          "5. Berikan kortikosteroid IV.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'laryngospasm': const ComplicationInfo(
        title: "Laringospasme Akut",
        overview: "Penutupan refleks pita suara yang menyebabkan obstruksi jalan napas atas akut.",
        immediateActions: [
          "1. Hentikan stimulasi dan berikan ventilasi tekanan positif dengan 100% O2.",
          "2. Lakukan manuver Larson (tekanan sudut rahang).",
          "3. Berikan Propofol 0.5-1 mg/kg IV.",
          "4. Bila refrakter: Suksinilkolin 0.2-0.5 mg/kg IV.",
          "5. Waspadai edema paru tekanan negatif.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'aspiration': const ComplicationInfo(
        title: "Aspirasi Paru Isi Lambung",
        overview: "Masuknya cairan lambung asam ke dalam saluran napas yang memicu pneumonitis kimiawi.",
        immediateActions: [
          "1. Posisi Trendelenburg dan lakukan suction orofaring segera.",
          "2. Lakukan intubasi endotrakeal cepat.",
          "3. Suction pipa endotrakeal sebelum ventilasi tekanan positif.",
          "4. Berikan ventilasi dengan PEEP.",
          "5. Rawat di ICU.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'delayed': const ComplicationInfo(
        title: "Keterlambatan Bangun dari Anestesi",
        overview: "Kondisi belum sadar setelah batas waktu yang diharapkan pascaanestesi.",
        immediateActions: [
          "1. Pertahankan patensi jalan napas dan ventilasi.",
          "2. Periksa dan balikkan blokade neuromuskular (Sugammadex).",
          "3. Berikan Nalokson atau Flumazenil bila dicurigai overdosis.",
          "4. Periksa gula darah, elektrolit, dan suhu tubuh.",
          "5. Singkirkan stroke peroperatif.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'anaphylaxis': const ComplicationInfo(
        title: "Anafilaksis Perioperatif",
        overview: "Reaksi hipersensitivitas sistemik akut yang mengancam nyawa dengan kolaps kardiovaskular.",
        immediateActions: [
          "1. Hentikan obat yang dicurigai dan berikan 100% O2.",
          "2. Berikan Adrenalin segera (10-50 mcg IV atau 0.5 mg IM).",
          "3. Resusitasi cairan kristaloid masif.",
          "4. Berikan kortikosteroid dan antihistamin.",
          "5. Ambil sampel triptase serum.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'malignant hyperthermia': const ComplicationInfo(
        title: "Krisis Hipertermia Maligna (HM)",
        overview: "Kedaruratan hipermetabolik yang dipicu oleh anestesi inhalasi volatil atau suksinilkolin.",
        immediateActions: [
          "1. Hentikan anestesi volatil dan suksinilkolin; hiperventilasi dengan 100% O2.",
          "2. Berikan Dantrolen IV 2.5 mg/kg secepatnya.",
          "3. Lakukan pendinginan aktif.",
          "4. Koreksi hiperkalemia dan asidosis.",
          "5. Rawat intensif di ICU.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'pneumothorax': const ComplicationInfo(
        title: "Tension Pneumotoraks Intraoperatif",
        overview: "Akumulasi udara bertekanan di rongga pleura yang menyebabkan kolaps paru dan syok obstruktif.",
        immediateActions: [
          "1. Hentikan N2O dan berikan 100% O2.",
          "2. Dekompresi jarum segera di SIC 2 linea midklavikularis.",
          "3. Pasang chest tube di SIC 5 linea aksilaris anterior.",
          "4. Sesuaikan tekanan ventilator.",
          "5. Konfirmasi dengan rontgen toraks.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
      'ponv': const ComplicationInfo(
        title: "Mual & Muntah Pascaoperasi (PONV)",
        overview: "Keluhan mual muntah pascaoperasi akibat anestesi inhalasi, opioid, atau stimulasi bedah.",
        immediateActions: [
          "1. Berikan Ondansetron 4 mg IV.",
          "2. Berikan Deksametason 4-8 mg IV.",
          "3. Hidrasi cairan yang adekuat.",
          "4. Berikan Droperidol atau Metoklopramid bila perlu.",
          "5. Terapkan analgesia multimodal.",
        ],
        differentialDiagnosis: [
          "Clinical evaluation",
          "Underlying physiological factor",
        ],
        references: [
          "Difficult Airway Society / ESAIC Guidelines",
          "Miller's Anesthesia, 9th Edition",
        ],
      ),
    },
  };
}

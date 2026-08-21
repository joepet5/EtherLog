import 'dart:io';

void main() {
  var file = File('lib/screens/regional_heatmap_screen.dart');
  var content = file.readAsStringSync();

  content = content.replaceAll(RegExp(r"AnatomicalZone\.lowerLimbs: \[.*?\]", dotAll: true), "AnatomicalZone.lowerLimbs: ['fascia iliaca', 'femoral', 'sciatic', 'popliteal', 'saphenous', 'adductor', 'ankle', 'lumbar plexus', 'sacral plexus', 'obturator', 'ipack']");
  
  content = content.replaceAll(RegExp(r"AnatomicalZone\.chest: \[.*?\]", dotAll: true), "AnatomicalZone.chest: ['pecs', 'serratus', 'intercostal', 'brimp', 'pectointercostal']");
  
  content = content.replaceAll(RegExp(r"AnatomicalZone\.neuraxial: \[.*?\]", dotAll: true), "AnatomicalZone.neuraxial: ['spinal', 'epidural', 'cse', 'caudal', 'paravertebral', 'esp', 'erector spinae']");
  
  content = content.replaceAll(RegExp(r"if \(lowerName\.contains\('erector spinae'\)\) \{[\s\S]*?\} else if"), "if");
  
  file.writeAsStringSync(content);
}

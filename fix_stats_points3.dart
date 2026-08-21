import 'dart:io';

void main() {
  var file = File('lib/screens/statistics_screen.dart');
  var content = file.readAsStringSync();
  
  content = content.replaceFirst(
    RegExp(r"const SizedBox\(height: 12\),\s*Container\("),
    "const SizedBox(height: 12),\n          GestureDetector(onTap: () => AppPageRoute.push(context, const PointsBreakdownScreen()), child: Container("
  );
  
  file.writeAsStringSync(content);
}

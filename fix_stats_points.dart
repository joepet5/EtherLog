import 'dart:io';

void main() {
  var file = File('lib/screens/statistics_screen.dart');
  var content = file.readAsStringSync();
  
  content = content.replaceFirst("import '../widgets/animated_gradient_background.dart';", "import '../widgets/animated_gradient_background.dart';\nimport 'points_breakdown_screen.dart';\nimport '../utils/page_transitions.dart';");
  
  content = content.replaceFirst(
    "          const SizedBox(height: 12),\n          Container(\n            width: double.infinity,",
    "          const SizedBox(height: 12),\n          GestureDetector(\n            onTap: () => AppPageRoute.push(context, const PointsBreakdownScreen()),\n            child: Container(\n              width: double.infinity,"
  );
  
  content = content.replaceFirst(
    "                    ],\n                  ),\n                ],\n              ),\n            ),",
    "                    ],\n                  ),\n                  const Spacer(),\n                  Icon(Icons.chevron_right, color: AppTheme.primary),\n                ],\n              ),\n            ),\n          ),"
  );
  
  file.writeAsStringSync(content);
}

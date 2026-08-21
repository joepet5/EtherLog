import 'dart:io';

void main() {
  var file = File('lib/screens/statistics_screen.dart');
  var content = file.readAsStringSync();
  
  content = content.replaceFirst(
    "          const SizedBox(height: 12),\n          Container(",
    "          const SizedBox(height: 12),\n          GestureDetector(onTap: () => AppPageRoute.push(context, const PointsBreakdownScreen()), child: Container("
  );
  
  content = content.replaceFirst(
    "                    ],\n                  ),\n                ],\n              ),\n            ),",
    "                    ],\n                  ),\n                ],\n              ),\n            ),\n          ),"
  );
  
  file.writeAsStringSync(content);
}

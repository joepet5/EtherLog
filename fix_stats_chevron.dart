import 'dart:io';

void main() {
  var file = File('lib/screens/statistics_screen.dart');
  var content = file.readAsStringSync();
  
  content = content.replaceFirst(
    "                      style: TextStyle(\n                        fontSize: 18,\n                        fontWeight: FontWeight.w700,\n                        color: AppTheme.textPrimary,\n                      ),\n                    ),\n                  ],\n                ),",
    "                      style: TextStyle(\n                        fontSize: 18,\n                        fontWeight: FontWeight.w700,\n                        color: AppTheme.textPrimary,\n                      ),\n                    ),\n                  ],\n                ),\n                const SizedBox(width: 8),\n                Icon(Icons.chevron_right, color: AppTheme.primary),"
  );
  
  file.writeAsStringSync(content);
}

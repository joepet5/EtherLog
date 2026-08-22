import 'dart:io';

void main() {
  var file = File('lib/screens/dashboard_screen.dart');
  var content = file.readAsStringSync();

  var lines = content.split(RegExp(r'\r?\n'));
  int startIndex = -1;
  int endIndex = -1;

  for (int i = 0; i < lines.length; i++) {
    if (lines[i].contains('return _CaseCard(')) {
      startIndex = i;
    }
    // _CaseCard( ... ); ends when we see ); at indentation level of return.
    if (startIndex != -1 && i > startIndex && lines[i].contains(');') && lines[i].trim() == ');') {
      endIndex = i;
      break;
    }
  }

  if (startIndex != -1 && endIndex != -1) {
    var replacement = '''
                      final isLast = index == _filteredCases.length - 1;
                      return IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(
                              width: 32,
                              child: Stack(
                                alignment: Alignment.topCenter,
                                children: [
                                  Positioned(
                                    top: 0,
                                    bottom: isLast ? null : 0,
                                    height: isLast ? 31 : null,
                                    child: Container(
                                      width: 2,
                                      color: AppTheme.surfaceLight,
                                    ),
                                  ),
                                  Positioned(
                                    top: 24,
                                    child: Container(
                                      width: 14,
                                      height: 14,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: _getAsaColor(c.asaGrade),
                                        border: Border.all(color: AppTheme.background, width: 3),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: _CaseCard(
                                caseRecord: c,
                                points: PointsService.forCase(c),
                                onTap: () async {
                                  await AppHaptics.light();
                                  if (!mounted) return;
                                  final result = await AppPageRoute.push(context, CaseDetailScreen(caseRecord: c), noAnimation: true);
                                  if (result == true || result == 'celebrate') {
                                    await _loadData();
                                  }
                                  if (result == 'celebrate' && mounted) {
                                    await _triggerCelebration();
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      );
''';
    lines.replaceRange(startIndex, endIndex + 1, [replacement]);
    
    // Also inject _getAsaColor before Widget build(BuildContext context) {
    int buildIndex = lines.indexWhere((l) => l.contains('Widget build(BuildContext context) {'));
    if (buildIndex != -1) {
      lines.insert(buildIndex - 1, '''
  Color _getAsaColor(String asa) {
    if (asa == 'ASA I') return AppTheme.success;
    if (asa == 'ASA II') return AppTheme.primary;
    if (asa == 'ASA III') return AppTheme.warning;
    if (asa == 'ASA IV') return AppTheme.danger;
    if (asa == 'ASA V') return AppTheme.danger.withValues(alpha: 0.5);
    return AppTheme.textSecondary;
  }
''');
    }
    
    file.writeAsStringSync(lines.join('\n'));
    print('Injected successfully');
  } else {
    print('Could not find _CaseCard');
  }
}

import 'dart:io';

void main() {
  var file = File('lib/screens/dashboard_screen.dart');
  var content = file.readAsStringSync();

  var newCelebrationOverlay = '''
class _CelebrationOverlay extends StatelessWidget {
  const _CelebrationOverlay();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Container(
          color: AppTheme.background.withValues(alpha: 0.85),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Lottie.asset(
                'assets/animations/celebration.json',
                repeat: false,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.surface,
                      border: Border.all(color: AppTheme.primary, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withValues(alpha: 0.6),
                          blurRadius: 40,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(Icons.workspace_premium_rounded, size: 80, color: Colors.amber),
                    ),
                  ).animate().scale(duration: 800.ms, curve: Curves.elasticOut).shimmer(delay: 400.ms, duration: 1200.ms),
                  const SizedBox(height: 32),
                  Text(
                    'MILESTONE UNLOCKED!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      color: AppTheme.textPrimary,
                    ),
                  ).animate().fade(delay: 300.ms, duration: 600.ms).slideY(begin: 0.5),
                  const SizedBox(height: 8),
                  Text(
                    'Incredible work. Keep logging!',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.textSecondary,
                    ),
                  ).animate().fade(delay: 600.ms, duration: 600.ms),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
''';

  var oldCelebrationOverlayRegex = RegExp(r'class _CelebrationOverlay extends StatelessWidget \{[\s\S]*?\n\}');
  content = content.replaceFirst(oldCelebrationOverlayRegex, newCelebrationOverlay);
  file.writeAsStringSync(content);
}

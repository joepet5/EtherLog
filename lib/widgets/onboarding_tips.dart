import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/onboarding_service.dart';

/// Shows the next undismissed tip. Call once after dashboard load.
Future<void> maybeShowOnboardingTip(BuildContext context) async {
  final id = await OnboardingService.nextTipId();
  if (id == null || !context.mounted) return;
  final copy = OnboardingService.tipCopy[id];
  if (copy == null) return;

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      return AlertDialog(
        backgroundColor: AppTheme.surfaceSolid,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.lightbulb_outline, color: AppTheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                copy['title']!,
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          copy['body']!,
          style: TextStyle(color: AppTheme.textSecondary, height: 1.45, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              // Skip remaining tips
              for (final tip in OnboardingService.tipIds) {
                await OnboardingService.markTipDone(tip);
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Text('Skip all', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              await OnboardingService.markTipDone(id);
              if (ctx.mounted) Navigator.pop(ctx);
              // Chain next tip after a short beat
              if (context.mounted) {
                await Future.delayed(const Duration(milliseconds: 350));
                if (context.mounted) maybeShowOnboardingTip(context);
              }
            },
            child: const Text('Got it'),
          ),
        ],
      );
    },
  );
}

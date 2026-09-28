import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../utils/app_haptics.dart';

class HelpGuideScreen extends StatelessWidget {
  const HelpGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: Text(l10n.helpTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          _introCard(l10n),
          const SizedBox(height: 12),
          _section(
            l10n: l10n,
            icon: Icons.lock_outline,
            title: l10n.helpSecGettingStarted,
            bullets: [l10n.helpGs1, l10n.helpGs2, l10n.helpGs3],
          ),
          _section(
            l10n: l10n,
            icon: Icons.add_circle_outline,
            title: l10n.helpSecLogging,
            bullets: [
              l10n.helpLog1,
              l10n.helpLog2,
              l10n.helpLog3,
              l10n.helpLog4,
              l10n.helpLog5,
              l10n.helpLog6,
              l10n.helpLog7,
            ],
          ),
          _section(
            l10n: l10n,
            icon: Icons.dashboard_outlined,
            title: l10n.helpSecDashboard,
            bullets: [
              l10n.helpDash1,
              l10n.helpDash2,
              l10n.helpDash4,
              l10n.helpDash6,
            ],
          ),
          _section(
            l10n: l10n,
            icon: Icons.filter_alt_outlined,
            title: l10n.helpSecCaseMix,
            bullets: [
              l10n.helpMix1,
              l10n.helpMix2,
              l10n.helpMix3,
              l10n.helpMix4,
              l10n.helpMix5,
              l10n.helpMix6,
            ],
          ),
          _section(
            l10n: l10n,
            icon: Icons.bar_chart_outlined,
            title: l10n.helpSecStats,
            bullets: [l10n.helpStats1, l10n.helpStats2, l10n.helpStats3],
          ),
          _section(
            l10n: l10n,
            icon: Icons.emoji_events_outlined,
            title: l10n.helpSecAchievements,
            bullets: [
              l10n.helpAch1,
              l10n.helpAch2,
              l10n.helpAch3,
              l10n.helpAch4,
            ],
          ),
          _section(
            l10n: l10n,
            icon: Icons.qr_code_2_outlined,
            title: l10n.helpSecQr,
            bullets: [l10n.helpQr1, l10n.helpQr2, l10n.helpQr3],
          ),
          _section(
            l10n: l10n,
            icon: Icons.picture_as_pdf_outlined,
            title: l10n.helpSecPdf,
            bullets: [l10n.helpPdf1, l10n.helpPdf2, l10n.helpPdf3],
          ),
          _section(
            l10n: l10n,
            icon: Icons.tips_and_updates_outlined,
            title: l10n.helpSecTips,
            bullets: [
              l10n.helpTip2,
              l10n.helpTip3,
              l10n.helpTip4,
              l10n.helpTip5,
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l10n.helpFooter,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton.icon(
              icon: Icon(Icons.gavel_rounded, size: 14, color: AppTheme.primary),
              label: Text(
                'Open Source Licenses',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onPressed: () {
                showLicensePage(
                  context: context,
                  applicationName: 'EtherLog',
                  applicationVersion: 'v2.12.0',
                  applicationLegalese: 'Made by an Anaesthetist.\n© ${DateTime.now().year} EtherLog. All rights reserved.\n\nAnatomical atlas illustrations based on work by Ryan Graves (CC BY 4.0).',
                  applicationIcon: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        'assets/icon/app_icon.png',
                        width: 52,
                        height: 52,
                        errorBuilder: (_, __, ___) => const Icon(Icons.medical_services, size: 48),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _introCard(AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.menu_book_outlined, color: AppTheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.helpIntroTitle,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            l10n.helpIntroBody,
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _section({
    required AppLocalizations l10n,
    required IconData icon,
    required String title,
    required List<String> bullets,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Theme(
        data: ThemeData().copyWith(dividerColor: Colors.transparent),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.surfaceLight),
          ),
          child: ExpansionTile(
            leading: Icon(icon, color: AppTheme.primary, size: 22),
            title: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
                fontSize: 15,
              ),
            ),
            iconColor: AppTheme.primary,
            collapsedIconColor: AppTheme.textSecondary,
            childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
            onExpansionChanged: (open) {
              if (open) AppHaptics.selection();
            },
            children: [
              ...bullets.map((b) => _Bullet(b)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  final String text;
  const _Bullet(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '•  ',
            style: TextStyle(
              color: AppTheme.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                height: 1.35,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

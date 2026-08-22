import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../services/template_storage.dart';
import '../utils/app_haptics.dart';
import '../l10n/app_localizations.dart';
import '../widgets/animated_gradient_background.dart';

class TemplatesScreen extends StatefulWidget {
  const TemplatesScreen({super.key});

  @override
  State<TemplatesScreen> createState() => _TemplatesScreenState();
}

class _TemplatesScreenState extends State<TemplatesScreen> {
  AppLocalizations get l10n => AppLocalizations.of(context);
  List<CaseTemplate> _templates = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await TemplateStorage.getAll();
    if (!mounted) return;
    setState(() {
      _templates = list;
      _loading = false;
    });
  }

  Future<void> _delete(CaseTemplate t) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceSolid,
        title: Text(l10n.deleteTemplate, style: TextStyle(color: AppTheme.textPrimary)),
        content: Text(
          l10n.deleteTemplateConfirm.replaceAll('{name}', t.name),
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.delete, style: TextStyle(color: AppTheme.danger)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await TemplateStorage.delete(t.id);
    await AppHaptics.selection();
    _load();
  }

  Future<void> _rename(CaseTemplate t) async {
    final ctrl = TextEditingController(text: t.name);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceSolid,
        title: Text(l10n.renameTemplate, style: TextStyle(color: AppTheme.textPrimary)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(hintText: l10n.templateName),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    await TemplateStorage.rename(t.id, name);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: Text(l10n.caseTemplates)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _templates.isEmpty
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bookmark_border, size: 48, color: AppTheme.textSecondary),
              const SizedBox(height: 12),
              Text(
                l10n.noTemplatesSaved,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.templatesEmptyHint,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary, height: 1.4),
              ),
            ],
          ),
        ),
      )
          : ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _templates.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final t = _templates[i];
          final dateStr = DateFormat('dd MMM yyyy').format(t.createdAt);
          return Container(
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.surfaceLight),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              title: Text(
                t.name,
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  [
                    l10n.term(t.specialty),
                    l10n.term(t.technique),
                    l10n.term(t.priority),
                    t.asaGrade,
                    if (t.procedure != null && t.procedure!.isNotEmpty) l10n.term(t.procedure!),
                  ].join(' · '),
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              trailing: PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'rename') _rename(t);
                  if (v == 'delete') _delete(t);
                  if (v == 'use') Navigator.pop(context, t);
                },
                itemBuilder: (_) => [
                  PopupMenuItem(value: 'use', child: Text(l10n.useTemplate)),
                  PopupMenuItem(value: 'rename', child: Text(l10n.rename)),
                  PopupMenuItem(value: 'delete', child: Text(l10n.delete)),
                ],
              ),
              onTap: () => Navigator.pop(context, t),
            ),
          );
        },
      ),
    );
  }
}

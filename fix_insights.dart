import 'dart:io';

void main() {
  var file = File('lib/screens/insights_screen.dart');
  var content = file.readAsStringSync();

  var pattern = RegExp(r"body: _loading[\s\S]*?delegate: SliverChildListDelegate\(\[");
  
  var replace = '''appBar: AppBar(
        title: Text(l10n.insights, style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            tooltip: l10n.previousYear,
            onPressed: () {
              setState(() => _year--);
              _load();
            },
            icon: const Icon(Icons.chevron_left),
          ),
          Center(
            child: Text(
              '\\\',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          IconButton(
            tooltip: l10n.nextYear,
            onPressed: _year >= DateTime.now().year
                ? null
                : () {
                    setState(() => _year++);
                    _load();
                  },
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : (_data == null || _data!.totalCases == 0)
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      l10n.noCasesLoggedYearYet(_year),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.textSecondary, height: 1.4),
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                  children: [''';

  content = content.replaceFirst(pattern, replace);
  
  var endPattern = RegExp(r"\]\),\s*\),\s*\)\s*\]\s*\),\s*\]\s*\)"); // Wait, let's just replace the exact end of CustomScrollView
  content = content.replaceFirst(
    RegExp(r"\]\),\s*\),\s*\)\s*\],\s*\),"), 
    "],\n                ),"
  );

  file.writeAsStringSync(content);
}

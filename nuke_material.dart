import 'dart:io';

void main() {
  var file = File('lib/main.dart');
  var content = file.readAsStringSync();
  
  // Replace Checkbox
  content = content.replaceFirst(
    RegExp(r"SizedBox\(\s*width: 24,\s*height: 24,\s*child: Checkbox\([\s\S]*?\}\s*,\s*\),\s*\),"),
    '''Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: _agreedToConfidentiality ? primary : Colors.transparent,
                          border: Border.all(color: _agreedToConfidentiality ? primary : Colors.grey.shade400, width: 2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: _agreedToConfidentiality
                            ? const Icon(Icons.check, size: 18, color: Colors.white)
                            : null,
                      ),'''
  );

  // Replace ElevatedButton
  content = content.replaceFirst(
    RegExp(r"SizedBox\(\s*width: double\.infinity,\s*height: 50,\s*child: ElevatedButton\([\s\S]*?\}\s*,\s*style: ElevatedButton\.styleFrom\([\s\S]*?\),\s*child: Text\(t\.getStarted, style: const TextStyle\(fontSize: 16\)\),\s*\),\s*\),"),
    '''GestureDetector(
                onTap: () {
                  if (_agreedToConfidentiality) widget.onAccepted();
                },
                child: Container(
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                    color: _agreedToConfidentiality ? primary : Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  alignment: Alignment.center,
                  child: Text(t.getStarted, style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),'''
  );
  
  file.writeAsStringSync(content);
}

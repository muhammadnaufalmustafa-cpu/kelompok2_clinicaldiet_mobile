import 'dart:io';

void main() {
  final dir = Directory(r'e:\Documents\GitHub\kelompok2_clinicaldiet_mobile\lib');
  
  // A regex to match sequence of mojibake characters often seen like ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ...
  // We can just match words starting with Ã and having non-ascii characters
  final regex = RegExp(r'[ÃÂ¢â€š¬Ã‚ÂƒÆ’Å¡][ÃÂ¢â€š¬Ã‚ÂƒÆ’Å¡\w]*');
  
  // actually a better approach is to use a regular expression that targets these specific blocks:
  // "ÃƒÆ’Ã‚Â¢..." or "ÃƒÂ¢..."
  // since they are mostly inside comments, let's just replace any Ã... sequence.
  final exactRegex = RegExp(r'Ã[^a-zA-Z0-9\s]{1,50}');
  
  for (final entity in dir.listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      final content = entity.readAsStringSync();
      if (content.contains('Ã') || content.contains('â')) {
        print('Fixing ${entity.path}');
        
        // Let's replace the common headers
        var newContent = content;
        
        // This regex tries to capture the weird characters that represent borders
        // e.g. ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â...
        newContent = newContent.replaceAll(RegExp(r'[ÃÂ¢â€š¬Ã‚ÂƒÆ’Å¡Œ]{5,}'), '---');
        newContent = newContent.replaceAll(RegExp(r'Ã[ƒÂ¢Ã¢â€šÂ¬]+'), '-');
        newContent = newContent.replaceAll(RegExp(r'â[€œ”\-\│]+'), '-');
        
        // Some specific strings
        newContent = newContent.replaceAll('ÃƒÂ°Ã…Â¸Ã¢â‚¬ËœÃ‚Â¤', '[USER]');
        newContent = newContent.replaceAll('ÃƒÂ¢Ã…â€œÃ¢â‚¬Â¦', '[SUCCESS]');
        newContent = newContent.replaceAll('ÃƒÂ¢Ã‚Â Ã…â€™', '[FAILED]');
        
        // Remove all remaining Ã and â characters and following non-ascii
        newContent = newContent.replaceAll(RegExp(r'[Ãâ][^\x00-\x7F]*'), '');
        
        // Clean up Â½ -> 1/2, Â¼ -> 1/4 which are common in recipes
        newContent = newContent.replaceAll('Â½', '1/2');
        newContent = newContent.replaceAll('Â¼', '1/4');
        newContent = newContent.replaceAll('Â¾', '3/4');
        
        entity.writeAsStringSync(newContent);
      }
    }
  }
}

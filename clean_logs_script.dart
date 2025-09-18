import 'dart:io';

void main() async {
  // List of files to clean
  final filesToClean = [
    'lib/services/ai_service.dart',
    'lib/screens/home_screen.dart',
    'lib/screens/dashboard_screen.dart',
    'lib/utils/app_common.dart',
    'lib/screens/payment_screen.dart',
    'lib/screens/payment_scheduled_screen.dart',
    'lib/components/tab_payment.dart',
    'lib/extensions/html_widget.dart',
    'lib/main.dart',
  ];

  for (final filePath in filesToClean) {
    await cleanLogsFromFile(filePath);
  }
  
  print('✅ All logging statements cleaned from specified files');
}

Future<void> cleanLogsFromFile(String filePath) async {
  try {
    final file = File(filePath);
    if (!await file.exists()) {
      print('⚠️ File not found: $filePath');
      return;
    }

    final lines = await file.readAsLines();
    final cleanedLines = <String>[];
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final trimmedLine = line.trim();
      
      // Skip lines that are logging statements
      if (shouldRemoveLine(trimmedLine)) {
        print('🗑️ Removing log from $filePath:${i + 1}: ${trimmedLine.substring(0, trimmedLine.length > 50 ? 50 : trimmedLine.length)}...');
        continue;
      }
      
      cleanedLines.add(line);
    }
    
    // Write cleaned content back to file
    await file.writeAsString(cleanedLines.join('\n'));
    print('✅ Cleaned logs from: $filePath');
    
  } catch (e) {
    print('❌ Error cleaning $filePath: $e');
  }
}

bool shouldRemoveLine(String line) {
  // Remove lines that are pure logging statements
  final logPatterns = [
    RegExp(r'^\s*print\s*\('),
    RegExp(r'^\s*debugPrint\s*\('),
    RegExp(r'^\s*log\s*\('),
    RegExp(r'^\s*console\.log\s*\('),
  ];
  
  for (final pattern in logPatterns) {
    if (pattern.hasMatch(line)) {
      return true;
    }
  }
  
  return false;
}

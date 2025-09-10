#!/usr/bin/env dart

import 'dart:io';

/// Script to automatically fix common Flutter lint issues
/// Usage: dart fix_lint_issues.dart

void main() async {
  print('🚀 Starting automatic code quality fixes...');

  await fixDeprecatedWithOpacity();
  await replaceDebugPrintWithLogger();
  await fixUnusedImports();
  await fixConstConstructors();

  print('✅ Code quality fixes completed!');
  print('📋 Run "flutter analyze" to check remaining issues');
}

/// Fix deprecated withOpacity calls with withValues
Future<void> fixDeprecatedWithOpacity() async {
  print('🔧 Fixing deprecated withOpacity usage...');

  final libDir = Directory('lib');
  if (!libDir.existsSync()) {
    print('❌ lib directory not found');
    return;
  }

  await for (final file in libDir.list(recursive: true)) {
    if (file is File && file.path.endsWith('.dart')) {
      try {
        String content = await file.readAsString();

        // Replace withOpacity patterns
        final patterns = [
          RegExp(r'\.withOpacity\((\d+\.?\d*)\)'),
        ];

        bool modified = false;
        for (final pattern in patterns) {
          if (content.contains(pattern)) {
            content = content.replaceAllMapped(pattern, (match) {
              final alphaValue = match.group(1);
              return '.withValues(alpha: $alphaValue)';
            });
            modified = true;
          }
        }

        if (modified) {
          await file.writeAsString(content);
          print('✅ Fixed: ${file.path}');
        }
      } catch (e) {
        print('❌ Error processing ${file.path}: $e');
      }
    }
  }
}

/// Replace print statements with proper logging
Future<void> replaceDebugPrintWithLogger() async {
  print('🔧 Replacing print statements with logger...');

  final libDir = Directory('lib');
  if (!libDir.existsSync()) return;

  await for (final file in libDir.list(recursive: true)) {
    if (file is File && file.path.endsWith('.dart')) {
      try {
        String content = await file.readAsString();
        bool modified = false;

        // Skip main.dart background handler
        if (file.path.contains('main.dart')) continue;

        // Replace print with debugPrint or logger
        if (content.contains('print(')) {
          // Add import if not present
          if (!content.contains('import \'package:flutter/foundation.dart\'') &&
              !content.contains('import \'package:flutter/widgets.dart\'')) {
            content = content.replaceFirst(
                RegExp(r'^(import .+\.dart.*;)$', multiLine: true),
                r'$1' '\nimport \'package:flutter/foundation.dart\';');
          }

          // Replace print with debugPrint
          content = content.replaceAllMapped(
              RegExp(r'print\((.+?)\);?', multiLine: true, dotAll: true),
              (match) => 'debugPrint(${match.group(1)});');

          modified = true;
        }

        if (modified) {
          await file.writeAsString(content);
          print('✅ Fixed logging: ${file.path}');
        }
      } catch (e) {
        print('❌ Error processing ${file.path}: $e');
      }
    }
  }
}

/// Fix unused imports
Future<void> fixUnusedImports() async {
  print('🔧 Analyzing unused imports...');

  // This would require more complex AST parsing
  // For now, we'll just log that this needs manual review
  print('ℹ️  Unused imports require manual review');
  print('   Run: dart fix --apply to auto-fix some issues');
}

/// Fix const constructor suggestions
Future<void> fixConstConstructors() async {
  print('🔧 Adding const constructors...');

  final libDir = Directory('lib');
  if (!libDir.existsSync()) return;

  await for (final file in libDir.list(recursive: true)) {
    if (file is File && file.path.endsWith('.dart')) {
      try {
        String content = await file.readAsString();
        bool modified = false;

        // Add const to common constructors
        final patterns = [
          'SizedBox(',
          'EdgeInsets.',
          'Offset(',
          'Duration(',
          'TextStyle(',
        ];

        for (final pattern in patterns) {
          final regex = RegExp('(?<!const\\s)($pattern)', multiLine: true);
          if (content.contains(regex)) {
            content = content.replaceAll(regex, 'const \$1');
            modified = true;
          }
        }

        if (modified) {
          await file.writeAsString(content);
          print('✅ Added const: ${file.path}');
        }
      } catch (e) {
        print('❌ Error processing ${file.path}: $e');
      }
    }
  }
}

#!/usr/bin/env dart

import 'dart:io';

/// Script to setup development environment and git hooks
void main() async {
  print('🚀 Setting up FireDNS development environment...');

  await setupGitHooks();
  await installDependencies();
  await generateCode();
  await runInitialChecks();

  print('✅ Development environment setup complete!');
  print('');
  print('📋 Next steps:');
  print('  1. Review the code with: flutter analyze');
  print('  2. Run tests with: flutter test');
  print('  3. Start development server with: flutter run');
  print('');
  print('💡 Git hooks are now active and will run automatically on commit');
}

Future<void> setupGitHooks() async {
  print('🔧 Setting up Git hooks...');

  final gitDir = Directory('.git');
  if (!gitDir.existsSync()) {
    print('❌ Not a git repository. Please run: git init');
    exit(1);
  }

  final hooksDir = Directory('.git/hooks');
  if (!hooksDir.existsSync()) {
    await hooksDir.create(recursive: true);
  }

  // Create pre-commit hook
  final preCommitHook = File('.git/hooks/pre-commit');
  const preCommitContent = '''#!/bin/sh
# Pre-commit hook for Flutter projects
echo "🔍 Running pre-commit checks..."

# Format code
echo "🎨 Formatting code..."
if ! flutter format --output=none --set-exit-if-changed .; then
    echo "❌ Code formatting issues found. Run 'flutter format .' to fix."
    exit 1
fi

# Analyze code
echo "🔍 Analyzing code..."
if ! flutter analyze --fatal-infos; then
    echo "❌ Code analysis failed. Please fix issues before committing."
    exit 1
fi

echo "✅ Pre-commit checks passed!"
''';

  await preCommitHook.writeAsString(preCommitContent);

  // Make executable on Unix-like systems
  if (Platform.isLinux || Platform.isMacOS) {
    await Process.run('chmod', ['+x', '.git/hooks/pre-commit']);
  }

  print('✅ Git hooks configured');
}

Future<void> installDependencies() async {
  print('📦 Installing dependencies...');

  final result = await Process.run('flutter', ['pub', 'get']);
  if (result.exitCode != 0) {
    print('❌ Failed to install dependencies');
    print(result.stderr);
    exit(1);
  }

  print('✅ Dependencies installed');
}

Future<void> generateCode() async {
  print('🏗️  Generating code...');

  // Check if build_runner is needed
  final pubspec = File('pubspec.yaml');
  final pubspecContent = await pubspec.readAsString();

  if (pubspecContent.contains('build_runner')) {
    final result = await Process.run('flutter', [
      'packages',
      'pub',
      'run',
      'build_runner',
      'build',
      '--delete-conflicting-outputs'
    ]);
    if (result.exitCode != 0) {
      print('⚠️  Code generation failed, continuing anyway...');
      print(result.stderr);
    } else {
      print('✅ Code generated');
    }
  } else {
    print('ℹ️  No code generation needed');
  }
}

Future<void> runInitialChecks() async {
  print('🧪 Running initial checks...');

  // Run analysis
  var result = await Process.run('flutter', ['analyze']);
  if (result.exitCode != 0) {
    print('⚠️  Code analysis found issues:');
    print(result.stdout);
  } else {
    print('✅ Code analysis passed');
  }

  // Run tests
  result = await Process.run('flutter', ['test']);
  if (result.exitCode != 0) {
    print('⚠️  Some tests failed:');
    print(result.stdout);
  } else {
    print('✅ All tests passed');
  }
}

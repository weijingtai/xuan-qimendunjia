import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Returns true if [source] contains a forbidden import of package:xuan_config.
/// Matches actual `import` statements only (not arbitrary text references).
bool containsForbiddenImport(String source) {
  return RegExp(r'''import\s+['"]package:xuan_config/''').hasMatch(source);
}

/// Walks all .dart files under [dir] and returns those that contain
/// a forbidden package:xuan_config import.
List<File> filesWithForbiddenImport(Directory dir) {
  final offenders = <File>[];
  for (final entity in dir.listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      final content = entity.readAsStringSync();
      if (containsForbiddenImport(content)) {
        offenders.add(entity);
      }
    }
  }
  return offenders;
}

void main() {
  group('Theme token governance', () {
    test('production widgets do not import xuan_config', () {
      final libDir = Directory(
        '${Directory.current.path}/lib/redesign_ui',
      );

      // Non-empty scan assertion
      expect(libDir.existsSync(), isTrue, reason: 'lib/redesign_ui must exist');
      final dartFiles = libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .toList();
      expect(dartFiles, isNotEmpty, reason: 'must scan at least one .dart file');

      // GREEN predicate proof: the migrated files must be clean.
      final gridSource = File(
        'lib/redesign_ui/layouts/smart_grid.dart',
      ).readAsStringSync();
      expect(
        containsForbiddenImport(gridSource),
        isFalse,
        reason: 'GREEN: smart_grid.dart must not import xuan_config',
      );

      // RED predicate proof: a known-bad import statement should be detected.
      const sep = 'xuan_config';
      expect(
        containsForbiddenImport("import 'package:$sep/foo.dart';"),
        isTrue,
        reason: 'RED: predicate must detect package:xuan_config import',
      );

      // Actual governance check
      final offenders = filesWithForbiddenImport(libDir);
      expect(
        offenders,
        isEmpty,
        reason:
            'No production widget may import package:xuan_config. '
            'Offenders: ${offenders.map((f) => f.path).join(', ')}',
      );
    });

    test('scan path self-proves RED via temp dir with offender', () {
      final tmpDir = Directory.systemTemp.createTempSync('governance_red_');
      try {
        File('${tmpDir.path}/offender.dart').writeAsStringSync(
          "import 'package:xuan_config/xuan_config.dart';\nvoid main() {}\n",
        );

        final offenders = filesWithForbiddenImport(tmpDir);
        expect(offenders, hasLength(1));
        expect(offenders.first.path, contains('offender.dart'));
      } finally {
        tmpDir.deleteSync(recursive: true);
      }
    });

    test('migrated component ids present in source', () {
      final expected = <String, String>{
        'lib/redesign_ui/layouts/smart_grid.dart': "component('qimen_palace_grid')",
      };

      final gridSource = File('lib/redesign_ui/layouts/smart_grid.dart')
          .readAsStringSync();

      expect(
        gridSource,
        contains("component('qimen_palace_grid')"),
        reason:
            'smart_grid.dart must contain component(\'qimen_palace_grid\') '
            'after migration',
      );
      expect(
        gridSource,
        contains("component('qimen_palace_cell')"),
        reason:
            'smart_grid.dart must contain component(\'qimen_palace_cell\') '
            'after migration',
      );
    });
  });
}

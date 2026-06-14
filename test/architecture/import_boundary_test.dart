import 'dart:io';

import 'package:test/test.dart';

/// Architecture boundary test for xuan-qimendunjia.
///
/// Verifies that UI-layer files do not import forbidden patterns
/// (legacy calculators, data sources, service locator, legacy models).
///
/// Part of QPRE-3: boundary test harness for decouple-qimendunjia-ui-mvvm-usecase.
void main() {
  // Deny list for pages/ and widgets/ (full UI layer)
  const uiDenyList = [
    'ChaiBuCalculator',
    'ZhiRunCalculator',
    'MaoShanCalculator',
    'YinPanCalculator',
    'QiMenCalculatorRepository',
    'QimendunjiaOfficialRuleRepository',
    'repository_interface_qimendunjia',
    'serviceLocator',
    'ReadDataUtils',
    'officialRuleReader',
    'model/shi_jia_qi_men.dart',
    'model/shi_jia_ju.dart',
    'ShiJiaQiMen(',
    // QPRE-4: DataSource deny-list additions
    'qimen_calculator_data_source',
    'QiMenCalculatorDataSource',
    'ChaiBuCalculatorDataSource',
    'ZhiRunCalculatorDataSource',
    'MaoShanCalculatorDataSource',
    'YinPanCalculatorDataSource',
  ];

  // Deny list for viewmodels/ (presentation layer)
  const viewModelDenyList = [
    'ChaiBuCalculator',
    'ZhiRunCalculator',
    'MaoShanCalculator',
    'YinPanCalculator',
    'ReadDataUtils',
    'officialRuleReader',
    'rootBundle',
    'QimendunjiaOfficialRuleRepository',
    'QiMenCalculatorRepositoryImpl',
    'ShiJiaQiMen(',
    // QPRE-4: DataSource deny-list additions
    'qimen_calculator_data_source',
    'QiMenCalculatorDataSource',
    'ChaiBuCalculatorDataSource',
    'ZhiRunCalculatorDataSource',
    'MaoShanCalculatorDataSource',
    'YinPanCalculatorDataSource',
  ];

  /// Scan .dart files under [dir] and check each line against [patterns].
  /// Returns a list of violation descriptions.
  List<String> _scanDirectory(String dir, List<String> patterns) {
    final violations = <String>[];
    final directory = Directory(dir);
    if (!directory.existsSync()) return violations;

    for (final entity in directory.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final lines = entity.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        // Skip comments
        if (line.trimLeft().startsWith('//')) continue;
        for (final pattern in patterns) {
          if (line.contains(pattern)) {
            violations.add(
              '${entity.path}:${i + 1} contains forbidden pattern "$pattern"',
            );
          }
        }
      }
    }
    return violations;
  }

  group('UI layer import boundaries', () {
    test('lib/pages/** does not import forbidden patterns', () {
      final violations = _scanDirectory('lib/pages', uiDenyList);
      expect(
        violations,
        isEmpty,
        reason: 'Forbidden imports in lib/pages/:\n${violations.join('\n')}',
      );
    });

    test('lib/widgets/** does not import forbidden patterns', () {
      final violations = _scanDirectory('lib/widgets', uiDenyList);
      expect(
        violations,
        isEmpty,
        reason: 'Forbidden imports in lib/widgets/:\n${violations.join('\n')}',
      );
    });

    test('lib/presentation/pages/** does not import forbidden patterns', () {
      final violations =
          _scanDirectory('lib/presentation/pages', uiDenyList);
      expect(
        violations,
        isEmpty,
        reason:
            'Forbidden imports in lib/presentation/pages/:\n${violations.join('\n')}',
      );
    });

    test('lib/presentation/viewmodels/** does not import forbidden patterns',
        () {
      final violations =
          _scanDirectory('lib/presentation/viewmodels', viewModelDenyList);
      expect(
        violations,
        isEmpty,
        reason:
            'Forbidden imports in lib/presentation/viewmodels/:\n${violations.join('\n')}',
      );
    });
  });
}

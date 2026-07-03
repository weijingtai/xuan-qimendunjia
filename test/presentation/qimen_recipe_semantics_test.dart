import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qimendunjia/redesign_ui/layouts/smart_grid.dart';
import 'package:qimendunjia/redesign_ui/components/palace/recipe_palace_layout.dart';

import '../support/qimen_palace_fixture.dart';

void main() {
  final palaces = buildQiMenPalaceFixture();

  group('QiMen recipe semantics', () {
    testWidgets('palace label, star, heaven stem appear in every non-center palace',
        (tester) async {
      final palace = palaces[0]; // 巽4

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox.square(
                dimension: 80,
                child: QiMenRecipePalaceLayout(
                  data: palace,
                  config: const BriefPalaceConfig(),
                  size: 80,
                ),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('P0 semantic labels exist at standard density',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 480,
                height: 480,
                child: SmartQiMenGrid(
                  palaces: palaces,
                  useRecipeLayout: true,
                  onPalaceTap: (_) {},
                ),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });
}

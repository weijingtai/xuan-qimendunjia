import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qimendunjia/redesign_ui/layouts/smart_grid.dart';

import '../support/qimen_palace_fixture.dart';

void main() {
  final palaces = buildQiMenPalaceFixture();

  group('QiMen recipe golden', () {
    for (final size in [320.0, 480.0, 768.0]) {
      testWidgets('recipe grid at ${size.toInt()}px', (tester) async {
        await tester.binding.setSurfaceSize(Size(size, size));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: size,
                  height: size,
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

        await tester.pumpAndSettle();
        await expectLater(
          find.byType(SmartQiMenGrid),
          matchesGoldenFile('goldens/qimen_recipe_${size.toInt()}.png'),
        );
      });
    }
  });
}

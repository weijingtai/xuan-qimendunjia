import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qimendunjia/redesign_ui/layouts/smart_grid.dart';
import 'package:qimendunjia/redesign_ui/components/palace/brief_palace_config.dart';

import '../support/qimen_palace_fixture.dart';

Widget testApp(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: SizedBox.square(dimension: 480, child: child),
      ),
    ),
  );
}

void main() {
  final fixturePalaces = buildQiMenPalaceFixture();

  testWidgets('recipe mode renders P0 symbols and preserves palace tap',
      (tester) async {
    var tapped = -1;
    await tester.pumpWidget(testApp(
      SmartQiMenGrid(
        palaces: fixturePalaces,
        useRecipeLayout: true,
        onPalaceTap: (index) => tapped = index,
      ),
    ));

    // P0 star symbols should be visible
    expect(find.text('辅'), findsWidgets);
    expect(find.text('英'), findsWidgets);
    expect(find.text('芮'), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('qimen-palace-0')));
    expect(tapped, 0);
  });

  testWidgets('legacy mode remains the default', (tester) async {
    await tester.pumpWidget(testApp(
      SmartQiMenGrid(
        palaces: fixturePalaces,
        onPalaceTap: (_) {},
      ),
    ));
    expect(find.byType(BriefPalaceLayout), findsNWidgets(9));
  });
}

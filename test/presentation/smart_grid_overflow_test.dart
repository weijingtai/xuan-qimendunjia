import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qimendunjia/redesign_ui/layouts/smart_grid.dart';

void main() {
  testWidgets('brief palace grid fits the actual cell width', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox.square(
              dimension: 480,
              child: SmartQiMenGrid(
                palaces: PalaceData.generateSampleData(),
                onPalaceTap: (_) {},
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(BriefPalaceLayout), findsNWidgets(9));
    expect(tester.takeException(), isNull);
  });
}

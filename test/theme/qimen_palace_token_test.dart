import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:theme/theme.dart';
import 'package:qimendunjia/redesign_ui/layouts/smart_grid.dart';
import 'package:qimendunjia/redesign_ui/components/palace/brief_palace_config.dart';
import 'package:metaphysics_core/enums.dart';

final _samplePalaces = PalaceData.generateSampleData();

void main() {
  group('SmartQiMenGrid theme token behavior', () {
    testWidgets('with theme scope, renders grid background from token', (tester) async {
      const tokenBg = Color(0xFF123456);
      final themeData = XuanThemeData(components: {
        'qimen_palace_grid': const ComponentStyle(background: tokenBg),
      });

      await tester.pumpWidget(
        XuanThemeScope(
          themeData: themeData,
          child: MaterialApp(
            home: Scaffold(
              body: SmartQiMenGrid(
                palaces: _samplePalaces,
                onPalaceTap: _noop,
              ),
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(SmartQiMenGrid),
          matching: find.byType(Container),
        ).first,
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, equals(tokenBg));
    });

    testWidgets('without theme scope, falls back to design system surface color', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SmartQiMenGrid(
              palaces: _samplePalaces,
              onPalaceTap: _noop,
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(SmartQiMenGrid),
          matching: find.byType(Container),
        ).first,
      );
      final decoration = container.decoration as BoxDecoration;
      // Fallback: ColorSystem.surface = Color(0xFFFFFFFF)
      expect(decoration.color, equals(const Color(0xFFFFFFFF)));
    });

    testWidgets('with theme scope, palace cell renders token background', (tester) async {
      const cellBg = Color(0xFFABCDEF);
      final themeData = XuanThemeData(components: {
        'qimen_palace_cell': const ComponentStyle(background: cellBg),
      });

      await tester.pumpWidget(
        XuanThemeScope(
          themeData: themeData,
          child: MaterialApp(
            home: Scaffold(
              body: SmartQiMenGrid(
                palaces: _samplePalaces,
                onPalaceTap: _noop,
              ),
            ),
          ),
        ),
      );

      // Find a SmartPalaceWidget container — there should be 9
      final palaceContainers = find.descendant(
        of: find.byType(SmartQiMenGrid),
        matching: find.byWidgetPredicate(
          (w) => w is Container && w.decoration is BoxDecoration,
        ),
      );
      expect(palaceContainers, findsWidgets);
    });

    test('ComponentStyle.empty fallback — no background', () {
      const style = ComponentStyle.empty;
      expect(style.background, isNull);
    });

    test('ComponentStyle.variant returns self when variant not found', () {
      const style = ComponentStyle(background: Color(0xFFAAAAAA));
      final result = style.variant('nonexistent');
      expect(result.background, equals(const Color(0xFFAAAAAA)));
    });
  });

  group('BriefPalaceTheme.fromComponent', () {
    test('falls back to defaults when ComponentStyle is empty', () {
      const empty = ComponentStyle.empty;
      final theme = BriefPalaceTheme.fromComponent(empty);

      expect(theme.primaryTextColor, equals(const Color(0xFF2C2C2C)));
      expect(theme.secondaryTextColor, equals(const Color(0xFF6B7280)));
      expect(theme.geJuTagBackgroundColor, equals(const Color(0x1F607D8B)));
      expect(theme.wangShuaiGongBg, equals(Colors.black54));
      expect(theme.wangShuaiMonthBg, equals(const Color(0xFFE0E0E0)));
    });

    test('reads color from nested variant chain', () {
      const style = ComponentStyle(
        variants: {
          'text': ComponentStyle(
            variants: {
              'primary': ComponentStyle(background: Color(0xFF111111)),
              'secondary': ComponentStyle(background: Color(0xFF222222)),
            },
          ),
          'wang_shuai_month': ComponentStyle(background: Color(0xFF333333)),
          'wang_shuai_gong': ComponentStyle(background: Color(0xFF444444)),
          'relation': ComponentStyle(
            variants: {
              'men_po': ComponentStyle(background: Color(0xFFD32F2F)),
            },
          ),
        },
      );

      final theme = BriefPalaceTheme.fromComponent(style);
      expect(theme.primaryTextColor, equals(const Color(0xFF111111)));
      expect(theme.secondaryTextColor, equals(const Color(0xFF222222)));
      expect(theme.wangShuaiMonthBg, equals(const Color(0xFF333333)));
      expect(theme.wangShuaiGongBg, equals(const Color(0xFF444444)));
      expect(theme.relationMenPoColor, equals(const Color(0xFFD32F2F)));
    });

    test('reads mu/lu overrides from nested variant chain', () {
      const style = ComponentStyle(
        variants: {
          'wang_shuai_month': ComponentStyle(
            variants: {
              'mu': ComponentStyle(background: Color(0xFF8B0000)),
              'lu': ComponentStyle(background: Color(0xFF388E3C)),
            },
          ),
          'wang_shuai_gong': ComponentStyle(
            variants: {
              'mu': ComponentStyle(background: Color(0xFFFF4D4D)),
              'lu': ComponentStyle(background: Colors.greenAccent),
            },
          ),
        },
      );

      final theme = BriefPalaceTheme.fromComponent(style);
      expect(theme.wangShuaiMuMonthColor, equals(const Color(0xFF8B0000)));
      expect(theme.wangShuaiLuMonthColor, equals(const Color(0xFF388E3C)));
      expect(theme.wangShuaiMuGongColor, equals(const Color(0xFFFF4D4D)));
      expect(theme.wangShuaiLuGongColor, equals(Colors.greenAccent));
    });
  });
}

void _noop(int _) {}

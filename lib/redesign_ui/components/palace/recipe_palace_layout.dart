import 'package:flutter/widgets.dart';
import 'package:metaphysics_chart_ui/src/gong/gong_cell.dart';
import 'package:metaphysics_chart_ui/src/gong/gong_cell_spec.dart';
import 'package:metaphysics_chart_ui/src/gong/gong_token.dart';
import 'package:qimendunjia/presentation/adapters/qimen_gong_adapter.dart';
import 'package:qimendunjia/presentation/adapters/qimen_gong_recipe.dart';
import 'package:qimendunjia/presentation/adapters/qimen_gong_ids.dart';
import 'package:qimendunjia/redesign_ui/components/palace/brief_palace_config.dart';
import 'package:qimendunjia/redesign_ui/layouts/smart_grid.dart';
import 'package:metaphysics_core/enums.dart';

class QiMenRecipePalaceLayout extends StatelessWidget {
  const QiMenRecipePalaceLayout({
    super.key,
    required this.data,
    required this.config,
    required this.size,
  });

  final PalaceData data;
  final BriefPalaceConfig config;
  final double size;

  @override
  Widget build(BuildContext context) {
    const adapter = QiMenGongAdapter();
    final nodes = adapter.buildNodes(data, config);

    final index = data.number.isNotEmpty ? data.number : '0';
    final isCenter = data.gongEnum == HouTianGua.Center;
    final recipe = isCenter
        ? QiMenGongRecipes.centerHub(index)
        : QiMenGongRecipes.defaultPalace(index);

    return SizedBox(
      width: size,
      height: size,
      child: GongCell.recipe(
        spec: GongCellSpec.recipe(nodes: nodes, recipe: recipe),
        tokenTheme: const GongTokenTheme.fallback(),
      ),
    );
  }
}

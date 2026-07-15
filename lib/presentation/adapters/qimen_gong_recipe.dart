import 'package:flutter/widgets.dart';
import 'package:metaphysics_chart_ui/metaphysics_chart_ui.dart';
import 'qimen_gong_ids.dart';

abstract final class QiMenGongRecipes {
  QiMenGongRecipes._();

  static GongLayoutRecipe defaultPalace(String index) {
    return GongLayoutRecipe(
      id: 'qimen-palace-$index',
      root: GongRecipe.stack([
        _palaceContent(index),
      ]),
    );
  }

  static GongLayoutRecipe centerHub(String index) {
    return GongLayoutRecipe(
      id: 'qimen-center-$index',
      root: GongRecipe.stack([
        _centerContent(index),
      ]),
    );
  }

  static GongRecipeNode _palaceContent(String index) {
    return GongRecipe.inset(
      const EdgeInsets.all(2),
      GongRecipe.column([
        GongRecipe.bind('${QiMenGongIds.deityPrimary}-$index'),
        GongRecipe.row([
          GongRecipe.bind('${QiMenGongIds.starPrimary}-$index'),
          GongRecipe.column([
            _stemWithAnnotations(index),
            GongRecipe.bind('${QiMenGongIds.stemEarth}-$index'),
          ]),
        ]),
        GongRecipe.bind('${QiMenGongIds.doorPrimary}-$index'),
        _secondaryWrap(index),
      ]),
    );
  }

  static GongRecipeNode _centerContent(String index) {
    return GongRecipe.inset(
      const EdgeInsets.all(2),
      GongRecipe.column([
        GongRecipe.optional('${QiMenGongIds.deityPrimary}-$index'),
        GongRecipe.row([
          GongRecipe.bind('${QiMenGongIds.starPrimary}-$index'),
          GongRecipe.column([
            _stemWithAnnotations(index),
            GongRecipe.bind('${QiMenGongIds.stemEarth}-$index'),
          ]),
        ]),
        GongRecipe.optional('${QiMenGongIds.doorPrimary}-$index'),
        _secondaryWrap(index),
      ]),
    );
  }

  static GongRecipeNode _stemWithAnnotations(String index) {
    return GongRecipe.stack([
      GongRecipe.bind('${QiMenGongIds.stemHeaven}-$index'),
      GongRecipe.anchor(
        Alignment.topRight,
        GongRecipe.optional('${QiMenGongIds.markDunjiaHeaven}-$index'),
      ),
      GongRecipe.anchor(
        Alignment.bottomRight,
        GongRecipe.optional('${QiMenGongIds.markPunishmentHeaven}-$index'),
      ),
    ]);
  }

  static GongRecipeNode _secondaryWrap(String index) {
    return GongRecipe.wrap([
      GongRecipe.optional('${QiMenGongIds.stemHidden}-$index'),
      GongRecipe.optional('${QiMenGongIds.statusChief}-$index'),
      GongRecipe.optional('${QiMenGongIds.statusHorse}-$index'),
      GongRecipe.optional('${QiMenGongIds.statusVoid}-$index'),
      GongRecipe.optional('${QiMenGongIds.deityEarth}-$index'),
    ]);
  }
}

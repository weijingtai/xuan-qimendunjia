import 'package:metaphysics_chart_ui/metaphysics_chart_ui.dart';
import 'package:qimendunjia/redesign_ui/components/palace/brief_palace_config.dart';
import 'package:qimendunjia/redesign_ui/layouts/smart_grid.dart';
import 'qimen_gong_ids.dart';

class QiMenGongAdapter {
  const QiMenGongAdapter();

  List<GongContentNode> buildNodes(
    PalaceData data,
    BriefPalaceConfig config,
  ) {
    final nodes = <GongContentNode>[];
    final index = data.number.isNotEmpty ? data.number : '0';

    // P0: palace label (watermark)
    nodes.add(GongContentNode(
      id: '${QiMenGongIds.palaceLabel}-$index',
      content: GlyphContent(
        text: data.name,
        inkRole: InkRole.watermark,
        semanticRole: SemanticColorRole.neutral,
      ),
      priority: Tier.p1,
    ));

    // P0: deity primary
    if (data.showGod && data.god.isNotEmpty) {
      nodes.add(GongContentNode(
        id: '${QiMenGongIds.deityPrimary}-$index',
        content: GlyphContent(text: data.god, shortText: data.god),
        priority: Tier.p0,
      ));
    }

    // P0: star primary
    if (data.star.isNotEmpty) {
      nodes.add(GongContentNode(
        id: '${QiMenGongIds.starPrimary}-$index',
        content: GlyphContent(text: data.star, shortText: data.star),
        priority: Tier.p0,
      ));
    }

    // P0: door primary
    if (data.showDoor && data.door.isNotEmpty) {
      nodes.add(GongContentNode(
        id: '${QiMenGongIds.doorPrimary}-$index',
        content: GlyphContent(text: data.door, shortText: data.door),
        priority: Tier.p0,
      ));
    }

    // P0: heaven stem
    if (data.tianPanGan.isNotEmpty) {
      nodes.add(GongContentNode(
        id: '${QiMenGongIds.stemHeaven}-$index',
        content: GlyphContent(text: data.tianPanGan),
        priority: Tier.p0,
      ));
    }

    // P0: earth stem
    if (data.diPanGan.isNotEmpty) {
      nodes.add(GongContentNode(
        id: '${QiMenGongIds.stemEarth}-$index',
        content: GlyphContent(text: data.diPanGan),
        priority: Tier.p0,
      ));
    }

    // P1: hidden stems
    if (data.yinGan != null && data.yinGan!.isNotEmpty) {
      nodes.add(GongContentNode(
        id: '${QiMenGongIds.stemHidden}-$index',
        content: GlyphContent(text: data.yinGan!, shortText: data.yinGan!),
        priority: Tier.p1,
      ));
    }

    if (data.tianPanAnGan != null && data.tianPanAnGan!.isNotEmpty) {
      nodes.add(GongContentNode(
        id: '${QiMenGongIds.stemHiddenHeaven}-$index',
        content:
            GlyphContent(text: data.tianPanAnGan!, shortText: data.tianPanAnGan!),
        priority: Tier.p1,
      ));
    }

    if (data.renPanAnGan != null && data.renPanAnGan!.isNotEmpty) {
      nodes.add(GongContentNode(
        id: '${QiMenGongIds.stemHiddenHuman}-$index',
        content:
            GlyphContent(text: data.renPanAnGan!, shortText: data.renPanAnGan!),
        priority: Tier.p1,
      ));
    }

    // P2: earth deity
    if (config.showDiGod && data.diGod.isNotEmpty) {
      nodes.add(GongContentNode(
        id: '${QiMenGongIds.deityEarth}-$index',
        content: GlyphContent(
            text: data.diGod, inkRole: InkRole.mark),
        priority: Tier.p2,
      ));
    }

    // Host stems (P1)
    if (data.tianPanJiGan != null && data.tianPanJiGan!.isNotEmpty) {
      nodes.add(GongContentNode(
        id: '${QiMenGongIds.stemHostHeaven}-$index',
        content: GlyphContent(
            text: data.tianPanJiGan!, shortText: data.tianPanJiGan!),
        priority: Tier.p1,
      ));
    }

    if (data.diPanJiGan != null && data.diPanJiGan!.isNotEmpty) {
      nodes.add(GongContentNode(
        id: '${QiMenGongIds.stemHostEarth}-$index',
        content: GlyphContent(
            text: data.diPanJiGan!, shortText: data.diPanJiGan!),
        priority: Tier.p1,
      ));
    }

    // Dunjia marks
    if (data.isTianPanDunjia) {
      nodes.add(GongContentNode(
        id: '${QiMenGongIds.markDunjiaHeaven}-$index',
        content:
            GlyphContent(text: '遁', inkRole: InkRole.mark),
        priority: Tier.p1,
      ));
    }

    if (data.isDiPanDunjia) {
      nodes.add(GongContentNode(
        id: '${QiMenGongIds.markDunjiaEarth}-$index',
        content:
            GlyphContent(text: '遁', inkRole: InkRole.mark),
        priority: Tier.p1,
      ));
    }

    if (data.isTianJiGanDunjia) {
      nodes.add(GongContentNode(
        id: '${QiMenGongIds.markDunjiaHostHeaven}-$index',
        content:
            GlyphContent(text: '遁', inkRole: InkRole.mark),
        priority: Tier.p1,
      ));
    }

    if (data.isDiJiGanDunjia) {
      nodes.add(GongContentNode(
        id: '${QiMenGongIds.markDunjiaHostEarth}-$index',
        content:
            GlyphContent(text: '遁', inkRole: InkRole.mark),
        priority: Tier.p1,
      ));
    }

    // Punishment marks
    if (data.isTianPanJiXing) {
      nodes.add(GongContentNode(
        id: '${QiMenGongIds.markPunishmentHeaven}-$index',
        content:
            GlyphContent(text: '刑', inkRole: InkRole.mark),
        priority: Tier.p1,
      ));
    }

    if (data.isDiPanJiXing) {
      nodes.add(GongContentNode(
        id: '${QiMenGongIds.markPunishmentEarth}-$index',
        content:
            GlyphContent(text: '刑', inkRole: InkRole.mark),
        priority: Tier.p1,
      ));
    }

    if (data.isTianJiGanJiXing) {
      nodes.add(GongContentNode(
        id: '${QiMenGongIds.markPunishmentHostHeaven}-$index',
        content:
            GlyphContent(text: '刑', inkRole: InkRole.mark),
        priority: Tier.p1,
      ));
    }

    if (data.isDiJiGanJiXing) {
      nodes.add(GongContentNode(
        id: '${QiMenGongIds.markPunishmentHostEarth}-$index',
        content:
            GlyphContent(text: '刑', inkRole: InkRole.mark),
        priority: Tier.p1,
      ));
    }

    // Status marks
    for (final mark in data.marks) {
      switch (mark) {
        case '值符':
          nodes.add(GongContentNode(
            id: '${QiMenGongIds.statusChief}-$index',
            content:
                GlyphContent(text: '符', inkRole: InkRole.focalAccent),
            priority: Tier.p1,
            semanticRole: 'statusMark',
          ));
        case '驿马':
          nodes.add(GongContentNode(
            id: '${QiMenGongIds.statusHorse}-$index',
            content:
                GlyphContent(text: '马', inkRole: InkRole.mark),
            priority: Tier.p1,
          ));
        case '空亡':
          nodes.add(GongContentNode(
            id: '${QiMenGongIds.statusVoid}-$index',
            content: GlyphContent(
                text: '空', inkRole: InkRole.mark, voidCircle: true),
            priority: Tier.p1,
          ));
      }
    }

    return nodes;
  }
}

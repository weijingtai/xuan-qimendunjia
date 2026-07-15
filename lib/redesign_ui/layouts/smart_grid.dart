import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:metaphysics_chart_ui/metaphysics_chart_ui.dart';
import '../core/design_system.dart';
import '../components/palace/brief_palace_config.dart';
import '../components/palace/recipe_palace_layout.dart';
import '../../enums/enum_eight_door.dart';
import '../../enums/enum_eight_gods.dart';
import '../../enums/enum_nine_stars.dart';
import 'package:metaphysics_core/enums.dart';
import 'package:theme/theme.dart';
import '../../domain/entities/each_gong.dart';
import '../../domain/entities/qi_men_star.dart';
import '../../enums/enum_six_jia.dart';

part '../components/palace/brief_palace_layout.dart';

/// 智能响应式九宫格布局
/// 根据屏幕尺寸动态调整布局参数
class SmartQiMenGrid extends StatelessWidget {
  final List<PalaceData> palaces;
  final Function(int index) onPalaceTap;
  final int? selectedIndex;
  final double maxGridSize;
  final EdgeInsetsGeometry padding;
  final BriefPalaceConfig briefConfig;
  final bool useRecipeLayout;
  final bool showWASDLabels;

  const SmartQiMenGrid({
    super.key,
    required this.palaces,
    required this.onPalaceTap,
    this.selectedIndex,
    this.maxGridSize = 480.0,
    this.padding = const EdgeInsets.all(16.0),
    this.briefConfig = const BriefPalaceConfig(),
    this.useRecipeLayout = false,
    this.showWASDLabels = false,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 计算最优网格尺寸
        final gridSize = calculateOptimalGridSize(constraints);
        final palaceSize = gridSize / 3;

        final gridStyle = XuanThemeData.maybeOf(context)?.component('qimen_palace_grid');
        final bgColor = gridStyle?.background ?? ColorSystem.surface;
        final gridBorder = gridStyle?.border != null
            ? Border.all(color: gridStyle!.border!.color, width: gridStyle.border!.width)
            : null;
        final gridShadow = gridStyle?.shadow ?? Shadows.md;
        final gridRadius = gridStyle?.radius != null
            ? BorderRadius.all(Radius.circular(gridStyle!.radius!))
            : QiMenRadius.lg;

        return Container(
          width: gridSize,
          height: gridSize,
          padding: padding,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: gridRadius,
            border: gridBorder,
            boxShadow: [gridShadow],
          ),
          child: PalaceGrid(
            gridSize: gridSize - padding.horizontal,
            showWASDLabels: showWASDLabels,
            selectedIndex: selectedIndex,
            onPalaceTap: onPalaceTap,
            crossAxisCount: 3,
            padding: EdgeInsets.zero,
            contentBuilder: (context, ctx) {
              return _buildCellContent(context, ctx);
            },
          ),
        );
      },
    );
  }

  /// 计算最优网格尺寸
  double calculateOptimalGridSize(BoxConstraints constraints) {
    final availableWidth = constraints.maxWidth;
    final availableHeight = constraints.maxHeight;

    // 取可用空间的最小值，确保正方形
    final maxAvailable =
        availableWidth < availableHeight ? availableWidth : availableHeight;

    // 根据可用空间选择预设尺寸
    if (maxAvailable >= Dimensions.gridLarge) {
      return Dimensions.gridLarge;
    } else if (maxAvailable >= Dimensions.gridMedium) {
      return Dimensions.gridMedium;
    } else {
      return Dimensions.gridSmall;
    }
  }

  /// 构建单个宫格的内容 — cell装饰 + 业务内容。
  Widget _buildCellContent(BuildContext context, PalaceContext ctx) {
    final cellStyle =
        XuanThemeData.maybeOf(context)?.component('qimen_palace_cell');
    final border = cellStyle?.border;
    final cellRadius = cellStyle?.radius != null
        ? BorderRadius.all(Radius.circular(cellStyle!.radius!))
        : const BorderRadius.all(Radius.circular(3));

    return Container(
      decoration: BoxDecoration(
        color: ctx.isCenter
            ? (cellStyle?.background ?? const Color(0xFFDDE8F4))
            : (cellStyle?.background ?? const Color(0xFFE8F0F8)),
        borderRadius: cellRadius,
        border: Border.all(
          color: ctx.index == selectedIndex
              ? (border?.color ?? const Color(0xFF4A90E2))
              : (border?.color ?? const Color(0xFFB8CCE0)),
          width: border?.width ?? (ctx.index == selectedIndex ? 1.5 : 0.8),
        ),
      ),
      child: useRecipeLayout
          ? QiMenRecipePalaceLayout(
              data: palaces[ctx.index],
              config: briefConfig,
              size: ctx.cellSize,
            )
          : BriefPalaceLayout(
              data: palaces[ctx.index],
              config: briefConfig,
              size: ctx.cellSize,
            ),
    );
  }
}

/// 智能宫位组件
class SmartPalaceWidget extends StatefulWidget {
  final int index;
  final double size;
  final PalaceData data;
  final bool isCenter;
  final bool isSelected;
  final BriefPalaceConfig config;
  final VoidCallback onTap;
  final bool useRecipeLayout;

  const SmartPalaceWidget({
    super.key,
    required this.index,
    required this.size,
    required this.data,
    this.isCenter = false,
    this.isSelected = false,
    this.config = const BriefPalaceConfig(),
    required this.onTap,
    this.useRecipeLayout = false,
  });

  @override
  State<SmartPalaceWidget> createState() => _SmartPalaceWidgetState();
}

class _SmartPalaceWidgetState extends State<SmartPalaceWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Animations.durationNormal,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Animations.curveDefault),
    );

    _elevationAnimation = Tween<double>(begin: 0.0, end: 8.0).animate(
      CurvedAnimation(parent: _controller, curve: Animations.curveDefault),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: ValueKey('qimen-palace-${widget.index}'),
      onTapDown: (_) {
        _controller.forward();
      },
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () {
        _controller.reverse();
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: _buildDecoration(),
              child: child,
            ),
          );
        },
        child: _buildContent(),
      ),
    );
  }

  /// 构建装饰 — 浅蓝背景风格
  BoxDecoration _buildDecoration() {
    final cellStyle = XuanThemeData.maybeOf(context)?.component('qimen_palace_cell');
    final bg = cellStyle?.background;
    final border = cellStyle?.border;
    final cellRadius = cellStyle?.radius != null
        ? BorderRadius.all(Radius.circular(cellStyle!.radius!))
        : const BorderRadius.all(Radius.circular(3));
    final cellShadow = cellStyle?.shadow;
    return BoxDecoration(
      color: _getPalaceBackgroundColor(bg),
      borderRadius: cellRadius,
      border: Border.all(
        color: widget.isSelected
            ? (border?.color ?? const Color(0xFF4A90E2))
            : (border?.color ?? const Color(0xFFB8CCE0)),
        width: border?.width ?? (widget.isSelected ? 1.5 : 0.8),
      ),
      boxShadow: widget.isSelected
          ? (cellShadow != null
              ? [cellShadow]
              : [
                  BoxShadow(
                    color: (border?.color ?? const Color(0xFF4A90E2))
                        .withValues(alpha: 0.2),
                    blurRadius: _elevationAnimation.value,
                    offset: const Offset(0, 2),
                  ),
                ])
          : const [],
    );
  }

  /// 获取宫位背景色 — 浅蓝，中宫略深
  Color _getPalaceBackgroundColor(Color? tokenBg) {
    if (widget.isCenter) return tokenBg ?? const Color(0xFFDDE8F4);
    return tokenBg ?? const Color(0xFFE8F0F8);
  }

  /// 构建内容 — 简介模式三列布局
  Widget _buildContent() {
    if (widget.useRecipeLayout) {
      return QiMenRecipePalaceLayout(
        data: widget.data,
        config: widget.config,
        size: widget.size,
      );
    }
    return BriefPalaceLayout(
      data: widget.data,
      config: widget.config,
      size: widget.size,
    );
  }
}

/// 宫位数据模型
class PalaceData {
  final HouTianGua gongEnum; // 宫位卦象
  final String number; // 宫位数字
  final QiMenStar starEnum; // 九星
  final EightDoorEnum doorEnum; // 八门
  final EightGodsEnum godEnum; // 天盘八神
  final EightGodsEnum? diGodEnum; // 地盘八神
  final TianGan tianPanGanEnum; // 天盘干
  final TianGan diPanGanEnum; // 地盘干
  final String diZhi; // 地支（如：子、丑、寅、卯）
  final String wangShuai; // 旺衰 (暂保留文字，因为涉及多种旺衰计算)
  final String jiXiong; // 吉凶
  final List<String> geJu; // 格局
  final List<String> marks; // 特殊标记
  final bool isYangDun; // 是否阳遁
  final TianGan? yinGanEnum; // 隐干
  final TianGan? tianPanAnGanEnum; // 天盘暗干
  final TianGan? renPanAnGanEnum; // 人盘暗干
  final TianGan? tianPanJiGanEnum; // 天盘寄宫干
  final TianGan? diPanJiGanEnum; // 地盘寄宫干
  final QiMenStar? jiStarEnum; // 寄宫九星
  final bool isTianPanDunjia; // 天盘干是遁甲
  final bool isDiPanDunjia; // 地盘干是遁甲
  final bool isTianJiGanDunjia; // 天盘寄干是遁甲
  final bool isDiJiGanDunjia; // 地盘寄干是遁甲
  final bool isTianPanJiXing; // 天盘干是击刑
  final bool isDiPanJiXing; // 地盘干是击刑
  final bool isTianJiGanJiXing; // 天盘寄干是击刑
  final bool isDiJiGanJiXing; // 地盘寄干是击刑

  /// 是否在该宫位渲染八门
  ///
  /// 月家 / 年家中 5 寄坤 2，只寄星不寄门 — UI 上中 5 不渲染门。
  /// 时家盘默认 true 不受影响。
  final bool showDoor;

  /// 是否在该宫位渲染八神
  ///
  /// 月家 / 年家飞盘八神飞 8 非中宫，中 5 无神 — UI 上中 5 不渲染神。
  final bool showGod;

  // --- 为了 UI 层的平滑过渡，提供字符串 Getter ---
  String get name => gongEnum.name;
  String get star => starEnum.singleCharName;
  String get door => doorEnum.name;
  String get god => godEnum.name;
  String get diGod => diGodEnum?.name ?? '';
  String get tianPanGan => tianPanGanEnum.name;
  String get diPanGan => diPanGanEnum.name;
  String? get yinGan => yinGanEnum?.name;
  String? get tianPanAnGan => tianPanAnGanEnum?.name;
  String? get renPanAnGan => renPanAnGanEnum?.name;
  String? get tianPanJiGan => tianPanJiGanEnum?.name;
  String? get diPanJiGan => diPanJiGanEnum?.name;
  String? get jiStar => jiStarEnum?.singleCharName;

  const PalaceData({
    required this.gongEnum,
    required this.number,
    required this.starEnum,
    required this.doorEnum,
    required this.godEnum,
    this.diGodEnum,
    required this.tianPanGanEnum,
    required this.diPanGanEnum,
    required this.diZhi,
    required this.wangShuai,
    required this.jiXiong,
    required this.geJu,
    this.marks = const [],
    required this.isYangDun,
    this.yinGanEnum,
    this.tianPanAnGanEnum,
    this.renPanAnGanEnum,
    this.tianPanJiGanEnum,
    this.diPanJiGanEnum,
    this.jiStarEnum,
    this.isTianPanDunjia = false,
    this.isDiPanDunjia = false,
    this.isTianJiGanDunjia = false,
    this.isDiJiGanDunjia = false,
    this.isTianPanJiXing = false,
    this.isDiPanJiXing = false,
    this.isTianJiGanJiXing = false,
    this.isDiJiGanJiXing = false,
    this.showDoor = true,
    this.showGod = true,
  });

  /// 核心转换工厂方法：从领域实体转换到 UI 数据
  factory PalaceData.fromEachGong(EachGong domain,
      {bool isYangDun = true,
      List<String> geJu = const [],
      List<String> marks = const [],
      TianGan? xunHeaderGan,
      bool showDoor = true,
      bool showGod = true}) {
    return PalaceData(
      gongEnum: domain.gongGua,
      number: domain.gongNumber.toString(),
      starEnum: domain.star,
      doorEnum: domain.door,
      godEnum: domain.god,
      diGodEnum: domain.diGod,
      tianPanGanEnum: domain.tianPan,
      diPanGanEnum: domain.diPan,
      diZhi: _getDiZhiByGong(domain.gongGua), // 映射地支
      // 旺衰判定使用时家九星专属方法；非时家盘暂返回占位"和"
      wangShuai: (domain.star is NineStarsEnum)
          ? (domain.star as NineStarsEnum).checkWithGongGua(domain.gongGua).name
          : "和",
      jiXiong: "吉", // 待对接规则引擎
      geJu: geJu,
      marks: marks,
      isYangDun: isYangDun,
      yinGanEnum: domain.yinGan,
      tianPanAnGanEnum: domain.tianPanAnGan,
      renPanAnGanEnum: domain.renPanAnGan,
      tianPanJiGanEnum: domain.tianPanJiGan,
      diPanJiGanEnum: domain.diPanJiGan,
      jiStarEnum: domain.isJiTianQin ? NineStarsEnum.QIN : null, // 天禽寄宫
      isTianPanDunjia: xunHeaderGan != null && domain.tianPan == xunHeaderGan,
      isDiPanDunjia: xunHeaderGan != null && domain.diPan == xunHeaderGan,
      isTianJiGanDunjia:
          xunHeaderGan != null && domain.tianPanJiGan == xunHeaderGan,
      isDiJiGanDunjia: xunHeaderGan != null && domain.diPanJiGan == xunHeaderGan,
      isTianPanJiXing: xunHeaderGan != null &&
          domain.tianPan == xunHeaderGan &&
          SixJia.getSixJiaByGan(xunHeaderGan).isSixJiXing(domain.gongGua),
      isDiPanJiXing: xunHeaderGan != null &&
          domain.diPan == xunHeaderGan &&
          SixJia.getSixJiaByGan(xunHeaderGan).isSixJiXing(domain.gongGua),
      isTianJiGanJiXing: xunHeaderGan != null &&
          domain.tianPanJiGan == xunHeaderGan &&
          SixJia.getSixJiaByGan(xunHeaderGan).isSixJiXing(domain.gongGua),
      isDiJiGanJiXing: xunHeaderGan != null &&
          domain.diPanJiGan == xunHeaderGan &&
          SixJia.getSixJiaByGan(xunHeaderGan).isSixJiXing(domain.gongGua),
      showDoor: showDoor,
      showGod: showGod,
    );
  }

  static String _getDiZhiByGong(HouTianGua gong) {
    switch (gong) {
      case HouTianGua.Kan: return "子";
      case HouTianGua.Gen: return "丑寅";
      case HouTianGua.Zhen: return "卯";
      case HouTianGua.Xun: return "辰巳";
      case HouTianGua.Li: return "午";
      case HouTianGua.Kun: return "未申";
      case HouTianGua.Dui: return "酉";
      case HouTianGua.Qian: return "戌亥";
      default: return "";
    }
  }

  static final _mockGeJus = [
    '青龙合会', '飞鸟跌穴', '玉女守门', '青龙折足', '三奇得使', '青龙逃走', 
    '白虎猖狂', '腾蛇夭矫', '大格', '小格', '刑格', '悖格'
  ];

  static List<String> _getRandomGeJus() {
    final rand = math.Random();
    final count = rand.nextInt(4) + 1; // 1 to 4
    final available = List<String>.from(_mockGeJus);
    return List.generate(count, (_) {
      final index = rand.nextInt(available.length);
      return available.removeAt(index);
    });
  }

  /// 创建示例数据
  static List<PalaceData> generateSampleData() {
    return [
      PalaceData(
        gongEnum: HouTianGua.Xun,
        number: '4',
        starEnum: NineStarsEnum.FU,
        doorEnum: EightDoorEnum.DU,
        godEnum: EightGodsEnum.LIU_HE,
        diGodEnum: EightGodsEnum.JIU_TIAN,
        tianPanGanEnum: TianGan.YI,
        diPanGanEnum: TianGan.WU,
        diZhi: '巳',
        wangShuai: '旺',
        jiXiong: '吉',
        geJu: _getRandomGeJus(),
        marks: ['驿马'],
        isYangDun: true,
        isTianPanDunjia: true,
        isTianPanJiXing: true, // Test: 戊 in Xun
        yinGanEnum: TianGan.GENG,
        tianPanAnGanEnum: TianGan.BING,
      ),
      PalaceData(
        gongEnum: HouTianGua.Li,
        number: '9',
        starEnum: NineStarsEnum.YING,
        doorEnum: EightDoorEnum.JING_S,
        godEnum: EightGodsEnum.JIU_TIAN,
        diGodEnum: EightGodsEnum.ZHI_FU,
        tianPanGanEnum: TianGan.BING,
        diPanGanEnum: TianGan.GENG,
        diZhi: '午',
        wangShuai: '相',
        jiXiong: '大吉',
        geJu: _getRandomGeJus(),
        marks: ['值符'],
        isYangDun: true,
        isDiPanDunjia: true,
        isDiPanJiXing: true, // Test: Geng in Li (Not JiXing in real rules, but for UI test)
        yinGanEnum: TianGan.WU,
        tianPanAnGanEnum: TianGan.WU,
      ),
      PalaceData(
        gongEnum: HouTianGua.Kun,
        number: '2',
        starEnum: NineStarsEnum.RUI,
        doorEnum: EightDoorEnum.SI,
        godEnum: EightGodsEnum.JIU_DI,
        diGodEnum: EightGodsEnum.TENG_SHE,
        tianPanGanEnum: TianGan.DING,
        diPanGanEnum: TianGan.REN,
        diZhi: '未',
        wangShuai: '休',
        jiXiong: '平',
        geJu: _getRandomGeJus(),
        marks: [],
        isYangDun: true,
        isTianJiGanDunjia: true,
        isTianJiGanJiXing: true, // Test: JiGan JiXing (Bottom-Right)
        jiStarEnum: NineStarsEnum.QIN, // 天禽寄宫
        tianPanJiGanEnum: TianGan.JI,
        diPanJiGanEnum: TianGan.DING,
        yinGanEnum: TianGan.GUI,
        tianPanAnGanEnum: TianGan.XIN,
      ),
      PalaceData(
        gongEnum: HouTianGua.Zhen,
        number: '3',
        starEnum: NineStarsEnum.CHONG,
        doorEnum: EightDoorEnum.SHANG,
        godEnum: EightGodsEnum.BAI_HU,
        diGodEnum: EightGodsEnum.TAI_YIN,
        tianPanGanEnum: TianGan.WU,
        diPanGanEnum: TianGan.GUI,
        diZhi: '卯',
        wangShuai: '囚',
        jiXiong: '凶',
        geJu: _getRandomGeJus(),
        marks: ['空亡'],
        isYangDun: true,
        yinGanEnum: TianGan.REN,
        tianPanAnGanEnum: TianGan.YI,
      ),
      PalaceData(
        gongEnum: HouTianGua.Center,
        number: '5',
        starEnum: NineStarsEnum.QIN,
        doorEnum: EightDoorEnum.SI,
        godEnum: EightGodsEnum.ZHI_FU,
        diGodEnum: EightGodsEnum.ZHI_FU,
        tianPanGanEnum: TianGan.JI,
        diPanGanEnum: TianGan.DING,
        diZhi: '辰',
        wangShuai: '旺',
        jiXiong: '大吉',
        geJu: _getRandomGeJus(),
        marks: ['值符', '旬首'],
        isYangDun: true,
        yinGanEnum: TianGan.DING,
        tianPanAnGanEnum: TianGan.JI,
      ),
      PalaceData(
        gongEnum: HouTianGua.Dui,
        number: '7',
        starEnum: NineStarsEnum.ZHU,
        doorEnum: EightDoorEnum.JING_W,
        godEnum: EightGodsEnum.TAI_YIN,
        diGodEnum: EightGodsEnum.BAI_HU,
        tianPanGanEnum: TianGan.GENG,
        diPanGanEnum: TianGan.BING,
        diZhi: '酉',
        wangShuai: '相',
        jiXiong: '吉',
        geJu: _getRandomGeJus(),
        marks: [],
        isYangDun: true,
        yinGanEnum: TianGan.YI,
        tianPanAnGanEnum: TianGan.DING,
      ),
      PalaceData(
        gongEnum: HouTianGua.Gen,
        number: '8',
        starEnum: NineStarsEnum.REN,
        doorEnum: EightDoorEnum.SHENG,
        godEnum: EightGodsEnum.LIU_HE,
        diGodEnum: EightGodsEnum.JIU_DI,
        tianPanGanEnum: TianGan.XIN,
        diPanGanEnum: TianGan.YI,
        diZhi: '寅',
        wangShuai: '休',
        jiXiong: '吉',
        geJu: _getRandomGeJus(),
        marks: ['驿马'],
        isYangDun: true,
        yinGanEnum: TianGan.XIN,
        tianPanAnGanEnum: TianGan.GUI,
      ),
      PalaceData(
        gongEnum: HouTianGua.Kan,
        number: '1',
        starEnum: NineStarsEnum.PENG,
        doorEnum: EightDoorEnum.XIU,
        godEnum: EightGodsEnum.XUAN_WU,
        diGodEnum: EightGodsEnum.LIU_HE,
        tianPanGanEnum: TianGan.REN,
        diPanGanEnum: TianGan.XIN,
        diZhi: '子',
        wangShuai: '囚',
        jiXiong: '凶',
        geJu: _getRandomGeJus(),
        marks: ['空亡'],
        isYangDun: true,
        yinGanEnum: TianGan.JIA,
        tianPanAnGanEnum: TianGan.REN,
      ),
      PalaceData(
        gongEnum: HouTianGua.Qian,
        number: '6',
        starEnum: NineStarsEnum.XIN,
        doorEnum: EightDoorEnum.KAI,
        godEnum: EightGodsEnum.TENG_SHE,
        diGodEnum: EightGodsEnum.XUAN_WU,
        tianPanGanEnum: TianGan.GUI,
        diPanGanEnum: TianGan.WU,
        diZhi: '戌',
        wangShuai: '死',
        jiXiong: '大凶',
        geJu: _getRandomGeJus(),
        marks: [],
        isYangDun: true,
        yinGanEnum: TianGan.JI,
        tianPanAnGanEnum: TianGan.GENG,
      ),
    ];
  }
}

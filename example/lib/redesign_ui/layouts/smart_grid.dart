import 'package:flutter/material.dart';
import 'package:qimendunjia/redesign_ui/components/palace/brief_palace_config.dart';
import '../core/design_system.dart';

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

  const SmartQiMenGrid({
    super.key,
    required this.palaces,
    required this.onPalaceTap,
    this.selectedIndex,
    this.maxGridSize = 480.0,
    this.padding = const EdgeInsets.all(16.0),
    this.briefConfig = const BriefPalaceConfig(),
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 计算最优网格尺寸
        final gridSize = calculateOptimalGridSize(constraints);
        final palaceSize = gridSize / 3;

        return Container(
          width: gridSize,
          height: gridSize,
          padding: padding,
          decoration: BoxDecoration(
            color: ColorSystem.surface,
            borderRadius: QiMenRadius.lg,
            boxShadow: [Shadows.md],
          ),
          child: _buildGridView(palaceSize),
        );
      },
    );
  }

  /// 计算最优网格尺寸
  double calculateOptimalGridSize(BoxConstraints constraints) {
    final availableWidth = constraints.maxWidth;
    final availableHeight = constraints.maxHeight;

    // 取可用空间的最小值，确保正方形
    final maxAvailable = availableWidth < availableHeight
        ? availableWidth
        : availableHeight;

    // 根据可用空间选择预设尺寸
    if (maxAvailable >= Dimensions.gridLarge) {
      return Dimensions.gridLarge;
    } else if (maxAvailable >= Dimensions.gridMedium) {
      return Dimensions.gridMedium;
    } else {
      return Dimensions.gridSmall;
    }
  }

  /// 构建网格视图
  Widget _buildGridView(double palaceSize) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.0,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: 9,
      itemBuilder: (context, index) {
        final isCenter = index == 4; // 中宫
        final isSelected = selectedIndex == index;

        return SmartPalaceWidget(
          index: index,
          size: palaceSize,
          data: palaces[index],
          isCenter: isCenter,
          isSelected: isSelected,
          config: briefConfig,
          onTap: () => onPalaceTap(index),
        );
      },
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

  const SmartPalaceWidget({
    super.key,
    required this.index,
    required this.size,
    required this.data,
    this.isCenter = false,
    this.isSelected = false,
    this.config = const BriefPalaceConfig(),
    required this.onTap,
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
    return BoxDecoration(
      color: _getPalaceBackgroundColor(),
      borderRadius: const BorderRadius.all(Radius.circular(3)),
      border: Border.all(
        color: widget.isSelected
            ? const Color(0xFF4A90E2)
            : const Color(0xFFB8CCE0),
        width: widget.isSelected ? 1.5 : 0.8,
      ),
      boxShadow: widget.isSelected
          ? [
              BoxShadow(
                color: const Color(0xFF4A90E2).withValues(alpha: 0.2),
                blurRadius: _elevationAnimation.value,
                offset: const Offset(0, 2),
              ),
            ]
          : const [],
    );
  }

  /// 获取宫位背景色 — 浅蓝，中宫略深
  Color _getPalaceBackgroundColor() {
    if (widget.isCenter) return const Color(0xFFDDE8F4); // 中宫：略深蓝
    return const Color(0xFFE8F0F8); // 宣纸蓝
  }

  /// 构建内容 — 简介模式三列布局
  Widget _buildContent() {
    return BriefPalaceLayout(
      data: widget.data,
      config: widget.config,
      size: widget.size,
    );
  }
}

/// 宫位数据模型
class PalaceData {
  final String name; // 宫位名称
  final String number; // 宫位数字
  final String star; // 九星
  final String door; // 八门
  final String god; // 天盘八神
  final String diGod; // 地盘八神
  final String tianPanGan; // 天盘干
  final String diPanGan; // 地盘干
  final String diZhi; // 地支
  final String wangShuai; // 旺衰
  final String jiXiong; // 吉凶
  final String geJu; // 格局
  final List<String> marks; // 特殊标记（含「驿马」「空亡」等）
  final bool isYangDun; // 是否阳遁
  final String? yinGan; // 隐干（可选流派）
  final String? tianPanAnGan; // 天盘暗干（可选流派）
  final String? renPanAnGan; // 人盘暗干（可选流派）
  final String? tianPanJiGan; // 天盘寄宫干（仅寄宫宫位）
  final String? diPanJiGan; // 地盘寄宫干（仅寄宫宫位）
  final String? jiStar; // 寄宫九星（仅寄宫宫位）

  const PalaceData({
    required this.name,
    required this.number,
    required this.star,
    required this.door,
    required this.god,
    this.diGod = '',
    required this.tianPanGan,
    required this.diPanGan,
    required this.diZhi,
    required this.wangShuai,
    required this.jiXiong,
    required this.geJu,
    this.marks = const [],
    required this.isYangDun,
    this.yinGan,
    this.tianPanAnGan,
    this.renPanAnGan,
    this.tianPanJiGan,
    this.diPanJiGan,
    this.jiStar,
  });

  /// 创建示例数据
  static List<PalaceData> generateSampleData() {
    return [
      PalaceData(
        name: '巽宫',
        number: '4',
        star: '天辅',
        door: '杜门',
        god: '六合',
        diGod: '九天',
        tianPanGan: '乙',
        diPanGan: '戊',
        diZhi: '巳',
        wangShuai: '旺',
        jiXiong: '吉',
        geJu: '青龙合会',
        marks: ['驿马'],
        isYangDun: true,
        yinGan: '庚',
      ),
      PalaceData(
        name: '离宫',
        number: '9',
        star: '天英',
        door: '景门',
        god: '九天',
        diGod: '值符',
        tianPanGan: '丙',
        diPanGan: '庚',
        diZhi: '午',
        wangShuai: '相',
        jiXiong: '大吉',
        geJu: '飞鸟跌穴',
        marks: ['值符'],
        isYangDun: true,
        tianPanAnGan: '戊',
      ),
      PalaceData(
        name: '坤宫',
        number: '2',
        star: '天芮',
        door: '死门',
        god: '九地',
        diGod: '腾蛇',
        tianPanGan: '丁',
        diPanGan: '壬',
        diZhi: '未',
        wangShuai: '休',
        jiXiong: '平',
        geJu: '玉女守门',
        marks: [],
        isYangDun: true,
        // 中五寄坤（阳遁）
        jiStar: '天禽',
        tianPanJiGan: '己',
        diPanJiGan: '丁',
      ),
      PalaceData(
        name: '震宫',
        number: '3',
        star: '天冲',
        door: '伤门',
        god: '白虎',
        diGod: '太阴',
        tianPanGan: '戊',
        diPanGan: '癸',
        diZhi: '卯',
        wangShuai: '囚',
        jiXiong: '凶',
        geJu: '青龙折足',
        marks: ['空亡'],
        isYangDun: true,
        yinGan: '壬',
      ),
      PalaceData(
        name: '中宫',
        number: '5',
        star: '天禽',
        door: '死门',
        god: '值符',
        diGod: '值符',
        tianPanGan: '己',
        diPanGan: '丁',
        diZhi: '辰',
        wangShuai: '旺',
        jiXiong: '大吉',
        geJu: '三奇得使',
        marks: ['值符', '旬首'],
        isYangDun: true,
      ),
      PalaceData(
        name: '兑宫',
        number: '7',
        star: '天柱',
        door: '惊门',
        god: '太阴',
        diGod: '白虎',
        tianPanGan: '庚',
        diPanGan: '丙',
        diZhi: '酉',
        wangShuai: '相',
        jiXiong: '吉',
        geJu: '飞鸟跌穴',
        marks: [],
        isYangDun: true,
      ),
      PalaceData(
        name: '艮宫',
        number: '8',
        star: '天任',
        door: '生门',
        god: '六合',
        diGod: '九地',
        tianPanGan: '辛',
        diPanGan: '乙',
        diZhi: '寅',
        wangShuai: '休',
        jiXiong: '吉',
        geJu: '青龙合会',
        marks: ['驿马'],
        isYangDun: true,
        tianPanAnGan: '癸',
      ),
      PalaceData(
        name: '坎宫',
        number: '1',
        star: '天蓬',
        door: '休门',
        god: '玄武',
        diGod: '六合',
        tianPanGan: '壬',
        diPanGan: '辛',
        diZhi: '子',
        wangShuai: '囚',
        jiXiong: '凶',
        geJu: '青龙逃走',
        marks: ['空亡'],
        isYangDun: true,
        yinGan: '甲',
      ),
      PalaceData(
        name: '乾宫',
        number: '6',
        star: '天心',
        door: '开门',
        god: '腾蛇',
        diGod: '玄武',
        tianPanGan: '癸',
        diPanGan: '戊',
        diZhi: '戌',
        wangShuai: '死',
        jiXiong: '大凶',
        geJu: '白虎猖狂',
        marks: [],
        isYangDun: true,
      ),
    ];
  }
}

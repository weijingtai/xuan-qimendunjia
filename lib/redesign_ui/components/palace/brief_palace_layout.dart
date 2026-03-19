part of '../../layouts/smart_grid.dart';

// ─── Font-size helper ─────────────────────────────────────────────────────────

/// 宫格内通用字号
double _palaceFontSize(double size) => (size * 0.155).clamp(9.0, 15.0);

// ─── BriefPalaceLayout ────────────────────────────────────────────────────────

/// 宫位布局，支持默认（左右）和激活（左中右）两种状态，并包含平滑动画。
///
/// **默认状态 (左右布局):**
/// - 左: 神, 星, 门, 地神
/// - 右: 天盘干, 地盘干
///
/// **激活状态 (左中右布局):**
/// - 左: 隐干, 暗干
/// - 中: 神, 星, 门, 地神 (所有元素居中对齐)
/// - 右: 天盘干, 地盘干
///
class BriefPalaceLayout extends StatelessWidget {
  final PalaceData data;
  final BriefPalaceConfig config;
  final double size;

  const BriefPalaceLayout({
    super.key,
    required this.data,
    required this.config,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final double pad = 8;
    final double fs = 16;
    final fsJi = fs * 0.85;
    const textColor = Color(0xFF2C2C2C);
    const jiColor = Color(0xFF6B7280);

    final style = TextStyle(
        fontSize: fs, color: textColor, fontWeight: FontWeight.w500, height: 1);
    final jiStyle = TextStyle(
        fontSize: fsJi, color: jiColor, fontWeight: FontWeight.w400, height: 1);

    final bool showLeftPart = (config.showYinGan && data.yinGan != null) ||
        (config.showAnGan && data.tianPanAnGan != null);
    final bool shouldTruncate = data.jiStar != null;
    final double totalWidth = size - (pad * 2);
    // final double totalWidth = size - 8;

    // --- PX 计算 ---
    // 根据状态动态计算左、中、右三列的宽度
    // 当前宫位是否有寄宫的现象
    final bool withJi = data.tianPanJiGan != null || data.diPanJiGan != null;
    // 右侧 天地盘干 列宽度，根据是否有寄宫而变化
    final double rightColWidth =
        withJi ? style.fontSize! * 2 + 2 : style.fontSize! + 2;
    final double starDoorGodTextBoxWidth = style.fontSize! * 2 + 2;

    // 左侧有右侧宽度保持一致，此时可以确保 middle 为中心对齐时，神星门等保持中心对齐
    final double leftColWidth = showLeftPart ? rightColWidth : 0;
    // final double middleColWidth =
    //    size + (pad * 2) - leftColWidth - rightColWidth;
    final double middleColWidth = size - leftColWidth - rightColWidth;
    // 格局高度
    final double geJuHeight = 32;
    final double geJuContentHeight = config.showGeJu ? geJuHeight : 0;
    final double mainContentHeight =
        config.showGeJu ? totalWidth - geJuHeight : totalWidth;

    // 主内容始终居中对齐
    // final CrossAxisAlignment middleCrossAxisAlignment =
    // showLeftPart ? CrossAxisAlignment.center : CrossAxisAlignment.start;
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(pad),
      // color: Colors.black87,
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width: totalWidth,
            height: geJuContentHeight,
            color: Colors.blueGrey.withAlpha(50),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width: size,
            height: 18,
            color: Colors.blueGrey.withAlpha(50),
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text("马", style: jiStyle),
                SizedBox(
                  width: 4,
                ),
                Text("⭕️", style: jiStyle),
              ],
            ),
          ),
          Expanded(
            child: Container(
              alignment: Alignment.center,
              color: Colors.red.withAlpha(40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 左列：隐干/暗干
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    width: leftColWidth,
                    color: Colors.blue.withAlpha(50),
                    child: _buildLeftColumn(style),
                  ),

                  // 中列：神/星/门/地神
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    alignment:
                        showLeftPart ? Alignment.center : Alignment.centerLeft,
                    width: middleColWidth,
                    color: Colors.green.withAlpha(50),
                    child: SizedBox(
                      // color: Colors.blue.withAlpha(50),
                      width: starDoorGodTextBoxWidth,
                      child: _buildMainContent(
                        // middleCrossAxisAlignment,
                        shouldTruncate,
                        style,
                        jiStyle,
                        fs,
                        starDoorGodTextBoxWidth,
                      ),
                    ),
                  ),

                  // 右列：天地盘干
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    width: rightColWidth,
                    child: _buildRightGans(style, jiStyle, rightColWidth,
                        withJi: withJi),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建左侧的隐干/暗干列
  Widget _buildLeftColumn(TextStyle style) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          (config.showYinGan && data.yinGan != null) ? data.yinGan! : '',
          style: style,
        ),
        SizedBox(height: 16),
        Text(
          (config.showAnGan && data.tianPanAnGan != null)
              ? data.tianPanAnGan!
              : '',
          style: style,
        ),
      ],
    );
  }

  /// 构建右侧固定的天地盘干（用 FittedBox 解决溢出）
  Widget _buildRightGans(TextStyle style, TextStyle jiStyle, double columnWidth,
      {required bool withJi}) {
    return Container(
      width: columnWidth,
      color: Colors.grey.withAlpha(50),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 八神
          SizedBox(),
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: columnWidth,
                color: Colors.yellow.withAlpha(50),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(data.tianPanGan, style: style),
                    if (data.tianPanJiGan != null) ...[
                      const SizedBox(width: 2),
                      Text(data.tianPanJiGan!, style: jiStyle),
                    ],
                  ],
                ),
              ),
              SizedBox(
                height: 12,
              ),
              Container(
                width: columnWidth,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(data.diPanGan, style: style),
                    if (data.diPanJiGan != null) ...[
                      const SizedBox(width: 2),
                      Text(data.diPanJiGan!, style: jiStyle),
                    ],
                  ],
                ),
              ),
            ],
          )
        ],
      ),
    );
    return Container(
        width: columnWidth,
        color: Colors.grey.withAlpha(50),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: columnWidth,
              color: Colors.yellow.withAlpha(50),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(data.tianPanGan, style: style),
                  if (data.tianPanJiGan != null) ...[
                    const SizedBox(width: 2),
                    Text(data.tianPanJiGan!, style: jiStyle),
                  ],
                ],
              ),
            ),
            Container(
              width: columnWidth,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(data.diPanGan, style: style),
                  if (data.diPanJiGan != null) ...[
                    const SizedBox(width: 2),
                    Text(data.diPanJiGan!, style: jiStyle),
                  ],
                ],
              ),
            ),
          ],
        ));
  }

  /// 构建核心内容（神、星、门、地神）
  Widget _buildMainContent(
    bool shouldTruncate,
    TextStyle style,
    TextStyle jiStyle,
    double fs,
    double width,
  ) {
    String processStarText(String text) {
      if (shouldTruncate && text.startsWith('天')) {
        return text.substring(1);
      }
      return text;
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 八神
        Text(data.god, style: style),
        Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 九星
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(processStarText(data.star), style: style),
                if (data.jiStar != null) ...[
                  const SizedBox(width: 2),
                  Text(processStarText(data.jiStar!), style: jiStyle),
                ],
              ],
            ),
            SizedBox(
              height: 8,
            ),

            // 八门 & 地神
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(data.door, style: style),
                SizedBox(height: 2),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder:
                      (Widget child, Animation<double> animation) {
                    return SizeTransition(
                      sizeFactor: animation,
                      axis: Axis.vertical,
                      child: child,
                    );
                  },
                  child: (config.showDiGod && data.diGod.isNotEmpty)
                      ? Container(
                          width: width,
                          alignment: Alignment.center,
                          child: Text(data.diGod,
                              style: jiStyle.copyWith(
                                  color: const Color(0xFF6B7280)
                                      .withOpacity(0.8))),
                        )
                      : const SizedBox.shrink(key: ValueKey('diGodHidden')),
                ),
              ],
            ),
          ],
        )
      ],
    );
  }
}

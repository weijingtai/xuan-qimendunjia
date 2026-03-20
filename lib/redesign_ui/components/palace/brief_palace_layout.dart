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

  BriefPalaceLayout({
    super.key,
    required this.data,
    required this.config,
    required this.size,
  });

  final double pad = 8;
  final double fs = 18;
  final double fsJi = 15;
  final textColor = Color(0xFF2C2C2C);
  final jiColor = Color(0xFF6B7280);
  TextStyle get primaryStyle => TextStyle(
      fontSize: fs, color: textColor, fontWeight: FontWeight.w500, height: 1);
  TextStyle get secondaryStyle => TextStyle(
      fontSize: fsJi, color: jiColor, fontWeight: FontWeight.w400, height: 1);
  TextStyle get subtitleStyle => TextStyle(
      fontSize: 9, color: jiColor, fontWeight: FontWeight.w100, height: 1);
  @override
  Widget build(BuildContext context) {
    final bool showLeftPart = (config.showYinGan && data.yinGan != null) ||
        (config.showAnGan && data.tianPanAnGan != null);
    final bool shouldTruncate = data.jiStar != null;
    final double totalWidth = size - (pad * 2);
    // final double totalWidth = size - 8;
    final double wangShuaiFontSize = 9;
    final double wangShuaiWidgetWidth = wangShuaiFontSize * 3.6;

    // --- PX 计算 ---
    // 根据状态动态计算左、中、右三列的宽度
    // 当前宫位是否有寄宫的现象
    final bool withJi = data.tianPanJiGan != null || data.diPanJiGan != null;
    // 右侧 天地盘干 列宽度，根据是否有寄宫而变化
    double rightColWidth = withJi
        ? wangShuaiWidgetWidth + (wangShuaiFontSize * 2.6) + 2
        : wangShuaiWidgetWidth;
    // rightColWidth += 6;
    final double starDoorGodTextBoxWidth = primaryStyle.fontSize! * 2 + 2;

    // 左侧有右侧宽度保持一致，此时可以确保 middle 为中心对齐时，神星门等保持中心对齐
    // final double leftColWidth = showLeftPart ? rightColWidth : 0;
    final double expandedLeftColWidth = primaryStyle.fontSize! * 1.6;
    final double leftColWidth = showLeftPart ? expandedLeftColWidth : 0;
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
                Text("马", style: secondaryStyle),
                SizedBox(
                  width: 4,
                ),
                Text("⭕️", style: secondaryStyle),
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
                    clipBehavior: Clip.antiAlias,
                    child: OverflowBox(
                      alignment: Alignment.centerRight,
                      minWidth: expandedLeftColWidth,
                      maxWidth: expandedLeftColWidth,
                      child: _buildLeftColumn(
                          primaryStyle, expandedLeftColWidth, 12),
                    ),
                  ),

                  // 中列：神/星/门/地神
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    // alignment:
                    // showLeftPart ? Alignment.center : Alignment.centerLeft,
                    alignment: Alignment.centerLeft,
                    width: middleColWidth,
                    color: Colors.green.withAlpha(50),
                    child: SizedBox(
                      // color: Colors.blue.withAlpha(50),
                      width: starDoorGodTextBoxWidth + 20,
                      child: _buildMainContent(
                        // middleCrossAxisAlignment,
                        shouldTruncate,
                        primaryStyle,
                        secondaryStyle,
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
                    child: _buildRightGans(primaryStyle, secondaryStyle,
                        rightColWidth, wangShuaiWidgetWidth,
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
  Widget _buildLeftColumn(
      TextStyle style, double columnWidth, double heightSize) {
    bool showYinGan = config.showYinGan && data.yinGan != null;
    bool showAnGan = config.showAnGan && data.tianPanAnGan != null;
    Size size = Size(style.fontSize! + 4, heightSize + style.fontSize! + 2);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox.fromSize(
          size: size,
          child: AnimatedOpacity(
            opacity: showYinGan ? 1 : 0,
            duration: Animations.durationNormal,
            child: _yinAnGanWangShuaiWidget(
                data.yinGan!, null, style, columnWidth, heightSize),
          ),
        ),
        SizedBox(height: 16),
        SizedBox.fromSize(
          size: size,
          child: AnimatedOpacity(
            opacity: showAnGan ? 1 : 0,
            duration: Animations.durationNormal,
            child: _yinAnGanWangShuaiWidget(
                data.tianPanAnGan!, null, style, columnWidth, heightSize),
          ),
        ),
      ],
    );
  }

  /// 构建右侧固定的天地盘干（用 FittedBox 解决溢出）
  Widget _buildRightGans(TextStyle style, TextStyle jiStyle, double columnWidth,
      double wangShuaiWidgetWidth,
      {required bool withJi}) {
    double heightSize = 12;
    return Container(
      width: columnWidth,
      color: Colors.grey.withAlpha(50),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 八神
          // SizedBox(),
          _panGanWangShuaiWidget(
            data.tianPanGan,
            data.tianPanJiGan,
            style,
            columnWidth,
            heightSize,
            wangShuaiWidgetWidth,
            withJi: withJi,
          ),
          // SizedBox(
          //   height: 12,
          // ),
          _panGanWangShuaiWidget(
            data.diPanGan,
            data.diPanJiGan,
            style,
            columnWidth,
            heightSize,
            wangShuaiWidgetWidth,
            withJi: withJi,
          ),
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

  Widget _yinAnGanWangShuaiWidget(String gan, String? jiGan, TextStyle style,
      double columnWidth, double heightSize) {
    return Container(
        width: columnWidth,
        color: Colors.yellow.withAlpha(50),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  children: [
                    Text(gan, style: style),
                    Container(
                        height: heightSize,
                        color: Colors.blue,
                        child: Text("帝'休", style: subtitleStyle))
                  ],
                ),
              ],
            ),
          ],
        ));
  }

  // Widget _panGanWangShuaiWidget(
  //     String ganStr,
  //     String? jiGanStr,
  //     TextStyle style,
  //     double columnWidth,
  //     double heightSize,
  //     double wangShuaiWidgetWidth,
  //     {required bool withJi}) {
  //   return Container(
  //       width: columnWidth,
  //       child: Column(
  //         children: [
  //           Row(
  //             mainAxisAlignment: MainAxisAlignment.center,
  //             children: [
  //               Column(
  //                 children: [
  //                   Container(
  //                     color: Colors.blue,
  //                     height: heightSize,
  //                     width: 8,
  //                   ),
  //                   Text(ganStr, style: style),
  //                   Container(
  //                       height: heightSize,
  //                       color: Colors.blue,
  //                       width: wangShuaiWidgetWidth,
  //                       child: Text("帝'月休", style: subtitleStyle))
  //                 ],
  //               ),
  //               if (jiGanStr != null) ...[
  //                 const SizedBox(width: 2),
  //                 Column(children: [
  //                   Container(
  //                     color: Colors.amber,
  //                     height: heightSize,
  //                     width: subtitleStyle.fontSize! * 2.6,
  //                     child: Text("帝'休", style: subtitleStyle),
  //                   ),
  //                   Text(jiGanStr,
  //                       style: style.copyWith(color: Colors.black54)),
  //                   Container(
  //                     width: style.fontSize!,
  //                     height: heightSize,
  //                     color: Colors.blue,
  //                   )
  //                 ]),
  //               ],
  //             ],
  //           ),
  //         ],
  //       ));
  // }

  Widget _panGanWangShuaiWidget(
      String ganStr,
      String? jiGanStr,
      TextStyle style,
      double columnWidth,
      double heightSize,
      double wangShuaiWidgetWidth,
      {required bool withJi}) {
    return Container(
        width: columnWidth,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              children: [
                Container(
                  color: Colors.blue,
                  height: heightSize,
                  width: 8,
                ),
                Text(ganStr, style: style),
                Container(
                    height: heightSize,
                    color: Colors.blue,
                    width: wangShuaiWidgetWidth,
                    child: Text("帝'月休", style: subtitleStyle))
              ],
            ),
            if (jiGanStr != null) ...[
              const SizedBox(width: 2),
              Column(children: [
                Container(
                  color: Colors.amber,
                  height: heightSize,
                  width: subtitleStyle.fontSize! * 2.6,
                  child: Text("帝'月休", style: subtitleStyle),
                ),
                Text(jiGanStr, style: style.copyWith(color: Colors.black54)),
                Container(
                  width: style.fontSize!,
                  height: heightSize,
                  color: Colors.blue,
                )
              ]),
            ],
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
        Container(
          color: Colors.amber,
          child: Column(children: [
            Text(data.god, style: style),
            Container(
                margin: EdgeInsets.only(top: 2),
                height: subtitleStyle.fontSize!,
                color: Colors.blue,
                child: Text("旺", style: subtitleStyle))
          ]),
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 九星
            data.jiStar == null
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(processStarText(data.star), style: style),
                      Container(
                          margin: EdgeInsets.only(top: 2),
                          height: subtitleStyle.fontSize!,
                          color: Colors.blue,
                          child: Text("休`月旺", style: subtitleStyle))
                    ],
                  )
                : _panGanWangShuaiWidget(
                    data.star.substring(1),
                    data.jiStar!.substring(1),
                    style,
                    subtitleStyle.fontSize! * 3.6 +
                        subtitleStyle.fontSize! * 2.6 +
                        20,
                    subtitleStyle.fontSize!,
                    subtitleStyle.fontSize! * 3.6,
                    withJi: true),
            SizedBox(
              height: 8,
            ),

            // 八门 & 地神
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(data.door, style: style),
                    Container(
                        margin: EdgeInsets.only(top: 2),
                        height: subtitleStyle.fontSize!,
                        color: Colors.blue,
                        width: subtitleStyle.fontSize! * 3.6,
                        alignment: Alignment.bottomCenter,
                        child: Text("休`月旺", style: subtitleStyle))
                  ],
                ),
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
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(data.diGod,
                                  style: jiStyle.copyWith(
                                      color: const Color(0xFF6B7280)
                                          .withOpacity(0.8))),
                              Container(
                                  margin: EdgeInsets.only(top: 2),
                                  height: subtitleStyle.fontSize!,
                                  color: Colors.blue,
                                  // width: subtitleStyle.fontSize! * 3.6,
                                  child: Text("相", style: subtitleStyle))
                            ],
                          ),
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

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

  final double fsJi = 16;
  final double wangShuaiWidgetWidth = 24;

  // double get fs => config.showWangShuai ? 16 : 18;
  // double get fsJi => config.showWangShuai ? 13 : 15;
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
    final bool showLeftPart = (config.showYinGan && data.yinGanEnum != null) ||
        (config.showAnGan && data.tianPanAnGanEnum != null);
    final bool shouldTruncateStar =
        data.jiStarEnum != null || config.showSimpleLayout;
    final String starText = data.jiStarEnum == null
        ? (shouldTruncateStar
            ? data.starEnum.singleCharName
            : data.starEnum.name)
        : (data.starEnum.name.substring(1)); // For jihui, usually shown as '蓬'

    final String doorText =
        config.showSimpleLayout ? data.doorEnum.singleCharName : data.door;
    final String godText =
        config.showSimpleLayout ? data.godEnum.singleCharName : data.god;
    final String diGodText = config.showSimpleLayout
        ? (data.diGodEnum?.singleCharName ?? '')
        : data.diGod;

    final double totalWidth = size - (pad * 2);
    // final double totalWidth = size - 8;
    // final double wangShuaiFontSize = 9;

    // --- PX 计算 ---
    // 根据状态动态计算左、中、右三列的宽度
    // 当前宫位是否有寄宫的现象
    final bool withJi =
        data.tianPanJiGanEnum != null || data.diPanJiGanEnum != null;
    // 右侧 天地盘干 列宽度，根据是否有寄宫而变化
    double rightColWidth =
        withJi ? wangShuaiWidgetWidth * 2 : wangShuaiWidgetWidth;
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
      width: size + 12,
      height: size,
      padding: EdgeInsets.all(pad),
      // color: Colors.black87,
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width: size + 12,
            height: config.showGeJu ? geJuContentHeight : 18,
            // color: Colors.blueGrey.withAlpha(50),
            child: Stack(
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  switchInCurve: Curves.easeInOut,
                  switchOutCurve: Curves.easeInOut,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: child,
                    );
                  },
                  child: config.showGeJu
                      ? AnimatedContainer(
                          key: const ValueKey('geju_visible'),
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              List<String> geJus = data.geJu.take(4).toList();

                              if (geJus.isEmpty) return const SizedBox.shrink();

                              final bool isSingle = geJus.length == 1;
                              final double itemWidth = isSingle
                                  ? constraints.maxWidth
                                  : (constraints.maxWidth - 4) / 2;

                              return Wrap(
                                spacing: 4,
                                runSpacing: 4,
                                children: geJus.map((geJuText) {
                                  return Container(
                                    width: itemWidth,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4, vertical: 4),
                                    // color: Colors.blueGrey.withAlpha(50),
                                    alignment: Alignment.center,
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        geJuText,
                                        style: secondaryStyle.copyWith(
                                            fontSize: isSingle ? 14 : 12),
                                        maxLines: 1,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              );
                            },
                          ),
                        )
                      : const SizedBox.shrink(key: ValueKey('geju_hidden')),
                ),
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  right: config.showGeJu ? 0 : 20,
                  bottom: config.showGeJu ? 18 : 2,
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: Lottie.asset(
                      'assets/lotties/horse_walking.json',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  right: 0,
                  top: config.showGeJu ? 18 : 2,
                  child: SizedBox(
                    width: 14,
                    height: 14,
                    child: ColorFiltered(
                      colorFilter: const ColorFilter.mode(
                        Color(0xFFE53935),
                        BlendMode.srcIn,
                      ),
                      child: Image.asset(
                        'assets/icons/thin-black-ink-circle.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              alignment: Alignment.center,
              width: size,
              // color: Colors.red.withAlpha(40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 左列：隐干/暗干
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    width: leftColWidth,
                    // color: Colors.blue.withAlpha(50),
                    color: Colors.transparent,
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
                    alignment:
                        showLeftPart ? Alignment.center : Alignment.centerLeft,
                    // alignment: Alignment.centerLeft,
                    width: middleColWidth,
                    // color: Colors.green.withAlpha(50),
                    child: SizedBox(
                      // color: Colors.blue.withAlpha(50),
                      width: starDoorGodTextBoxWidth + 20,
                      child: _buildMainContent(
                        // middleCrossAxisAlignment,
                        starDoorGodTextBoxWidth + 20,
                        starText,
                        doorText,
                        godText,
                        diGodText,
                      ),
                    ),
                  ),

                  // 右列：天地盘干
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    width: rightColWidth,
                    // color: Colors.red,
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
    bool showYinGan = config.showYinGan && data.yinGanEnum != null;
    bool showAnGan = config.showAnGan && data.tianPanAnGanEnum != null;
    final double w = style.fontSize! + 4 > wangShuaiWidgetWidth
        ? style.fontSize! + 4
        : wangShuaiWidgetWidth;
    Size size = Size(w, heightSize + style.fontSize! + 2);
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
                data.yinGanEnum!.name, null, style, columnWidth, heightSize),
          ),
        ),
        SizedBox(height: 16),
        SizedBox.fromSize(
          size: size,
          child: AnimatedOpacity(
            opacity: showAnGan ? 1 : 0,
            duration: Animations.durationNormal,
            child: _yinAnGanWangShuaiWidget(data.tianPanAnGanEnum!.name, null,
                style, columnWidth, heightSize),
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
      // color: Colors.grey.withAlpha(50),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 八神
          // SizedBox(),
          _panGanWangShuaiWidget(
            data.tianPanGanEnum.name,
            data.tianPanJiGanEnum?.name,
            style,
            columnWidth,
            heightSize,
            wangShuaiWidgetWidth,
            withJi: withJi,
            isDunjia: data.isTianPanDunjia,
            isJiDunjia: data.isTianJiGanDunjia,
            isJiXing: data.isTianPanJiXing,
            isJiJiXing: data.isTianJiGanJiXing,
          ),
          // SizedBox(
          //   height: 12,
          // ),
          _panGanWangShuaiWidget(
            data.diPanGanEnum.name,
            data.diPanJiGanEnum?.name,
            style,
            columnWidth,
            heightSize,
            wangShuaiWidgetWidth,
            withJi: withJi,
            isDunjia: data.isDiPanDunjia,
            isJiDunjia: data.isDiJiGanDunjia,
            isJiXing: data.isDiPanJiXing,
            isJiJiXing: data.isDiJiGanJiXing,
          ),
        ],
      ),
    );
  }

  Widget _yinAnGanWangShuaiWidget(String gan, String? jiGan, TextStyle style,
      double columnWidth, double heightSize) {
    return Container(
        width: columnWidth,
        // color: Colors.yellow.withAlpha(50),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  children: [
                    _animatedText(gan, style),
                    _buildWangShuaiWidget(gong: "帝", month: "休"),
                    // Container(
                    //     height: heightSize,
                    //     // color: Colors.blue,
                    //     child: Text("帝'休", style: subtitleStyle))
                  ],
                ),
              ],
            ),
          ],
        ));
  }

  Widget _starGanWangShuaiWidget(
      String ganStr,
      String? jiGanStr,
      TextStyle style,
      double columnWidth,
      double heightSize,
      double wangShuaiWidgetWidth,
      {required bool withJi}) {
    return Container(
      width: columnWidth,
      child: Column(
        children: [
          AnimatedContainer(
            duration: Animations.durationNormal,
            width: columnWidth,
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                AnimatedScale(
                    scale: config.showWangShuai ? 0.9 : 1,
                    duration: Animations.durationNormal,
                    child: Text(ganStr, style: style)),
                if (jiGanStr != null) ...[
                  Container(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        AnimatedScale(
                            scale: config.showWangShuai ? 0.9 : 1,
                            duration: Animations.durationNormal,
                            child: Text(jiGanStr,
                                style: style.copyWith(color: Colors.black54))),
                        _buildVerticalWangShuaiWidget(gong: "死", month: "沐"),
                      ],
                    ),
                  )
                ]
              ],
            ),
          ),
          Row(
            children: [
              _buildWangShuaiWidget(gong: "死", month: "沐"),
              // Expanded(child: SizedBox()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _panGanWangShuaiWidget(
      String ganStr,
      String? jiGanStr,
      TextStyle style,
      double columnWidth,
      double heightSize,
      double wangShuaiWidgetWidth,
      {required bool withJi,
      bool isDunjia = false,
      bool isJiDunjia = false,
      bool isJiXing = false,
      bool isJiJiXing = false}) {
    return Container(
      width: columnWidth,
      child: Column(
        children: [
          withJi
              ? Row(
                  children: [
                    Expanded(child: SizedBox()),
                    _buildWangShuaiWidget(gong: "帝", month: "禄"),
                  ],
                )
              : SizedBox(
                  height: subtitleStyle.fontSize,
                ),
          AnimatedContainer(
            duration: Animations.durationNormal,
            width: columnWidth,
            // height: style.fontSize! * (config.showWangShuai ? 0.98 : 1.0),
            // color: Colors.amber,
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    _animatedText(ganStr, style),
                    if (isDunjia) _buildDunjiaMarker(isJi: false),
                    if (isJiXing) _buildJiXingMarker(isJi: false),
                  ],
                ),
                if (jiGanStr != null) ...[
                  const SizedBox(width: 2),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      _animatedText(
                          jiGanStr, style.copyWith(color: Colors.black54)),
                      if (isJiDunjia) _buildDunjiaMarker(isJi: true),
                      if (isJiJiXing) _buildJiXingMarker(isJi: true),
                    ],
                  ),
                ]
              ],
            ),
          ),
          Row(
            children: [
              _buildWangShuaiWidget(gong: "死", month: "沐"),
              // Expanded(child: SizedBox()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildJiXingMarker({required bool isJi}) {
    return Positioned(
      bottom: -3,
      left: isJi ? null : -3,
      right: isJi ? -3 : null,
      child: Opacity(
        opacity: 0.8,
        child: Stack(
          children: [
            Image.asset(
              'assets/icons/ji_xing.png',
              width: 14,
              height: 14,
              color: Colors.red,
              colorBlendMode: BlendMode.srcIn,
              package: 'qimendunjia',
            ),
            // 重叠偏移以增加粗度 / Layering to increase thickness
            Positioned(
              left: 0.5,
              top: 0.5,
              child: Image.asset(
                'assets/icons/ji_xing.png',
                width: 14,
                height: 14,
                color: Colors.red,
                colorBlendMode: BlendMode.srcIn,
                package: 'qimendunjia',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDunjiaMarker({required bool isJi}) {
    return Positioned(
      top: -3,
      left: isJi ? null : -3,
      right: isJi ? -3 : null,
      child: Opacity(
        opacity: 0.8,
        child: Stack(
          children: [
            Image.asset(
              'assets/icons/red-ink-circle.png',
              width: 14,
              height: 14,
              color: Colors.green,
              colorBlendMode: BlendMode.srcIn,
              package: 'qimendunjia',
            ),
            // 重叠偏移以增加粗度 / Layering to increase thickness
            Positioned(
              left: 0.5,
              top: 0.5,
              child: Image.asset(
                'assets/icons/red-ink-circle.png',
                width: 14,
                height: 14,
                color: Colors.green,
                colorBlendMode: BlendMode.srcIn,
                package: 'qimendunjia',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _animatedText(String text, TextStyle style) {
    return AnimatedScale(
      scale: config.showWangShuai ? .8 : 1,
      duration: Animations.durationNormal,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.9, end: 1.0).animate(animation),
              child: child,
            ),
          );
        },
        child: Text(
          text,
          key: ValueKey(text), // Key is crucial for AnimatedSwitcher
          style: style,
        ),
      ),
    );
  }

  Widget _buildAnimateQimenText(
      String full, String single, bool isSimple, TextStyle style) {
    if (full == single) {
      return _animatedText(full, style);
    }

    String prefix = "";
    String common = "";
    String suffix = "";

    if (full.startsWith(single)) {
      common = single;
      suffix = full.substring(single.length);
    } else if (full.endsWith(single)) {
      common = single;
      prefix = full.substring(0, full.length - single.length);
    } else {
      // Fallback for names like "腾蛇" -> "螣"
      return _animatedText(isSimple ? single : full, style);
    }

    return AnimatedScale(
      scale: config.showWangShuai ? .8 : 1,
      duration: Animations.durationNormal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildExpandingChar(prefix, isSimple, style, isLeft: true),
          Text(common, style: style),
          _buildExpandingChar(suffix, isSimple, style, isLeft: false),
        ],
      ),
    );
  }

  Widget _buildExpandingChar(String char, bool isSimple, TextStyle style,
      {required bool isLeft}) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SizeTransition(
            sizeFactor: animation,
            axis: Axis.horizontal,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: Offset(isLeft ? -0.5 : 0.5, 0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          ),
        );
      },
      child: (isSimple || char.isEmpty)
          ? const SizedBox.shrink()
          : Text(char, style: style, key: ValueKey(char)),
    );
  }

  Widget _buildGodMonthWangShuiWidget(String wang) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SizeTransition(
          sizeFactor: animation,
          axis: Axis.vertical,
          child: child,
        ),
      ),
      child: config.showWangShuai
          ? Container(
              key: ValueKey('wang_$wang'),
              margin: const EdgeInsets.only(top: 2),
              height: 12,
              width: 12,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(Radius.circular(6)),
              ),
              child: Text(wang,
                  style: subtitleStyle.copyWith(
                      height: 1.2, color: Colors.black, fontSize: 8)),
            )
          : const SizedBox.shrink(key: ValueKey('wang_hidden')),
    );
  }

  Widget _buildVerticalWangShuaiWidget({
    String? gong,
    String? month,
  }) {
    return AnimatedContainer(
      duration: Animations.durationNormal,
      curve: Curves.easeInOut,
      width: config.showWangShuai ? 11 : 0, // 控制占位空间的展开/收缩
      clipBehavior: Clip.none,
      child: AnimatedSwitcher(
        duration: Animations.durationNormal,
        // 核心：实现滑动 + 透明度动画
        transitionBuilder: (Widget child, Animation<double> animation) {
          Offset startOffset;
          if (config.showWangShuai) {
            // 正在开启：进入的组件从左（-0.8）往右入
            startOffset = const Offset(-0.8, 0);
          } else {
            // 正在关闭：退出的组件从当前位置向右（0.8）滑出
            startOffset = const Offset(0.8, 0);
          }

          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(begin: startOffset, end: Offset.zero)
                  .animate(animation),
              child: child,
            ),
          );
        },
        // 注意：这里的 Key 是触发动画的关键
        child: config.showWangShuai
            ? Column(
                key: const ValueKey('wang_v_visible'),
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (month != null)
                    // AnimatedContainer(
                    // duration: Animations.durationNormal,
                    Container(
                      width: 10,
                      height: gong == null ? 22 : 11,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: gong == null
                              ? const BorderRadius.all(Radius.circular(6))
                              : const BorderRadius.only(
                                  topLeft: Radius.circular(6),
                                  topRight: Radius.circular(6))),
                      child: Text(month,
                          style: subtitleStyle.copyWith(
                              height: 1.3,
                              color: month == "墓"
                                  ? const Color(0xFF8B0000)
                                  : (month == "禄"
                                      ? Colors.green[700]
                                      : Colors.black87),
                              fontSize: 8)),
                    ),
                  if (gong != null)
                    // AnimatedContainer(
                    // duration: Animations.durationNormal,
                    Container(
                      height: month == null ? 22 : 11,
                      width: 10,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: month == null
                              ? const BorderRadius.all(Radius.circular(6))
                              : const BorderRadius.only(
                                  bottomRight: Radius.circular(6),
                                  bottomLeft: Radius.circular(6))),
                      child: Text(gong,
                          style: subtitleStyle.copyWith(
                              height: 1.0,
                              color: gong == "墓"
                                  ? const Color(
                                      0xFFFF4D4D) // On dark background
                                  : (gong == "禄"
                                      ? Colors.greenAccent
                                      : Colors.white70),
                              fontSize: 8)),
                    ),
                ],
              )
            : SizedBox(key: ValueKey('wang_v_hidden')),
      ),
    );
  }

  Widget _buildVerticalWangShuaiWidget_old({
    String? gong,
    String? month,
  }) {
    return Container(
      // duration: Animations.durationNormal,
      // curve: Curves.easeInOut,
      width: config.showWangShuai ? 11 : 0,
      clipBehavior: Clip.none,
      child: AnimatedSwitcher(
        duration: Animations.durationNormal,
        transitionBuilder: (Widget child, Animation<double> animation) {
          // 根据开启/关闭状态选择滑动方向
          final Offset startOffset = config.showWangShuai
              ? const Offset(-0.8, 0) // 开启时：从左往右入
              : const Offset(0.8, 0); // 关闭时：从左往右出

          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(begin: startOffset, end: Offset.zero)
                  .animate(animation),
              child: child,
            ),
          );
        },
        child: config.showWangShuai
            ? Column(
                key: const ValueKey('wangshuai_vertical_visible'),
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (month != null)
                    AnimatedContainer(
                      duration: Animations.durationNormal,
                      width: 10,
                      height: gong == null ? 22 : 11,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: gong == null
                              ? const BorderRadius.all(Radius.circular(6))
                              : const BorderRadius.only(
                                  topLeft: Radius.circular(6),
                                  topRight: Radius.circular(6))),
                      child: Text(month,
                          style: subtitleStyle.copyWith(
                              height: 1.3,
                              color: month == "墓"
                                  ? const Color(0xFF8B0000)
                                  : (month == "禄"
                                      ? Colors.green[700]
                                      : Colors.black87),
                              fontSize: 8)),
                    ),
                  if (gong != null)
                    AnimatedContainer(
                      duration: Animations.durationNormal,
                      height: month == null ? 22 : 11,
                      width: 10,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: month == null
                              ? const BorderRadius.all(Radius.circular(6))
                              : const BorderRadius.only(
                                  bottomRight: Radius.circular(6),
                                  bottomLeft: Radius.circular(6))),
                      child: Text(gong,
                          style: subtitleStyle.copyWith(
                              height: 1.0,
                              color: gong == "墓"
                                  ? const Color(0xFFFF4D4D)
                                  : (gong == "禄"
                                      ? Colors.greenAccent
                                      : Colors.white70),
                              fontSize: 8)),
                    ),
                ],
              )
            : const SizedBox.shrink(key: ValueKey('wangshuai_vertical_hidden')),
      ),
    );
  }

  Widget _buildWangShuaiWidget({
    String? gong,
    String? month,
  }) {
    return AnimatedContainer(
      duration: Animations.durationNormal,
      key: ValueKey('wangshuai_${gong}_$month'),
      // margin: const EdgeInsets.only(top: 2),
      height: config.showWangShuai ? 11 : 0,
      width: wangShuaiWidgetWidth,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (gong != null)
            AnimatedContainer(
              duration: Animations.durationNormal,
              width: gong == null ? wangShuaiWidgetWidth : 12,
              height: 11,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: gong == null
                      ? BorderRadius.all(Radius.circular(6))
                      : BorderRadius.only(
                          topLeft: Radius.circular(6),
                          bottomLeft: Radius.circular(6))),
              child: Text(gong ?? "",
                  style: subtitleStyle.copyWith(
                      height: 1.2,
                      color: gong == "墓"
                          ? const Color(0xFFFF4D4D)
                          : (gong == "禄" ? Colors.greenAccent : Colors.white70),
                      fontSize: 8)),
            ),
          // 月
          if (month != null)
            AnimatedContainer(
              duration: Animations.durationNormal,
              width: gong == null ? wangShuaiWidgetWidth : 12,
              height: 11,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: gong == null
                      ? BorderRadius.all(Radius.circular(6))
                      : BorderRadius.only(
                          topRight: Radius.circular(6),
                          bottomRight: Radius.circular(6))),
              child: Text(month ?? "",
                  style: subtitleStyle.copyWith(
                      height: 1.2,
                      color: month == "墓"
                          ? const Color(0xFF8B0000)
                          : (month == "禄" ? Colors.green[700] : Colors.black87),
                      fontSize: 8)),
            )
        ],
      ),
    );
  }

  Widget _buildMainContent(
    double width,
    String starText,
    String doorText,
    String godText,
    String diGodText,
  ) {
    TextStyle style = primaryStyle;
    TextStyle jiStyle = secondaryStyle;

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
            width: width,
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            child: Stack(children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    child: _buildAnimateQimenText(
                      data.godEnum.name,
                      data.godEnum.singleCharName,
                      config.showSimpleLayout,
                      jiStyle.copyWith(
                          color:
                              const Color(0xFF6B7280).withValues(alpha: 0.8)),
                    ),
                  ),
                ],
              ),
              Positioned(
                left: 6,
                top: 0,
                child: AnimatedOpacity(
                  opacity: config.showWangShuai ? 1 : 0,
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    key: ValueKey('wang_旺'),
                    margin: const EdgeInsets.only(top: 2),
                    height: 12,
                    width: 10,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                    ),
                    child: Text("旺",
                        style: subtitleStyle.copyWith(
                            height: 1.0, color: Colors.black, fontSize: 10)),
                  ),
                ),
              ),
            ])),
        Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 九星
            data.jiStarEnum == null
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildAnimateQimenText(
                        data.starEnum.name,
                        data.starEnum.singleCharName,
                        config.showSimpleLayout,
                        style,
                      ),
                      _buildWangShuaiWidget(gong: "休", month: "旺"),
                    ],
                  )
                : _starGanWangShuaiWidget(
                    data.starEnum.name.substring(1),
                    data.jiStarEnum!.name.substring(1),
                    style,
                    wangShuaiWidgetWidth * 2,
                    11,
                    wangShuaiWidgetWidth,
                    withJi: true),
            SizedBox(
              height: 4,
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
                    Stack(children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _buildAnimateQimenText(
                            data.doorEnum.name,
                            data.doorEnum.singleCharName,
                            config.showSimpleLayout,
                            style,
                          ),
                        ],
                      ),
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 300),
                        left: 4,
                        top: 0,
                        child: AnimatedOpacity(
                          opacity: config.showWangShuai ? 1 : 0,
                          duration: const Duration(milliseconds: 300),
                          child: Builder(builder: (context) {
                            final relation =
                                GongAndDoorRelationship.getRelationship(
                              EightDoorEnum.values.firstWhere(
                                (e) => (config.showSimpleLayout
                                        ? e.singleCharName
                                        : e.name)
                                    .contains(doorText),
                                orElse: () => EightDoorEnum.CENTER,
                              ),
                              HouTianGua.values.firstWhere(
                                (e) =>
                                    data.name.contains(e.name.substring(0, 1)),
                                orElse: () => HouTianGua.Center,
                              ),
                            );
                            if (relation == null) return const SizedBox();
                            return Container(
                              key:
                                  ValueKey('relation_${doorText}_${data.name}'),
                              margin: const EdgeInsets.symmetric(
                                  vertical: 2, horizontal: 1),
                              height: 12,
                              width: 10,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: _getRelationColor(relation),
                                borderRadius:
                                    const BorderRadius.all(Radius.circular(4)),
                              ),
                              child: Text(
                                relation.singleCharName,
                                style: subtitleStyle.copyWith(
                                    height: 1.0,
                                    color: Colors.white,
                                    fontWeight: FontWeight.normal,
                                    fontSize: 8),
                              ),
                            );
                          }),
                        ),
                      ),
                    ]),
                    _buildWangShuaiWidget(gong: "休", month: "旺"),
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
                          clipBehavior: Clip.none,
                          child: Stack(children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  child: _buildAnimateQimenText(
                                    data.diGodEnum?.name ?? '',
                                    data.diGodEnum?.singleCharName ?? '',
                                    config.showSimpleLayout,
                                    jiStyle.copyWith(
                                        color: const Color(0xFF6B7280)
                                            .withValues(alpha: 0.8)),
                                  ),
                                ),
                              ],
                            ),
                            Positioned(
                              left: 6,
                              bottom: 0,
                              child: AnimatedOpacity(
                                opacity: config.showWangShuai ? 1 : 0,
                                duration: const Duration(milliseconds: 300),
                                child: Container(
                                  key: ValueKey('wang_旺'),
                                  margin: const EdgeInsets.only(top: 2),
                                  height: 12,
                                  width: 10,
                                  alignment: Alignment.center,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(4)),
                                  ),
                                  child: Text("旺",
                                      style: subtitleStyle.copyWith(
                                          height: 1.0,
                                          color: Colors.black,
                                          fontSize: 10)),
                                ),
                              ),
                            ),
                          ]))
                      : const SizedBox.shrink(key: ValueKey('diGodHidden')),
                ),
              ],
            ),
          ],
        )
      ],
    );
  }

  Color _getRelationColor(GongAndDoorRelationship? relation) {
    if (relation == null) return Colors.transparent;
    switch (relation) {
      case GongAndDoorRelationship.MEN_PO: // 门迫 - 极凶
        return const Color(0xFFD32F2F);
      case GongAndDoorRelationship.SHOU_ZHI: // 宫制 - 小凶
        return const Color(0xFFBF360C);
      case GongAndDoorRelationship.SHENG_GONG: // 和
      case GongAndDoorRelationship.SHOU_SHEN: // 义
      case GongAndDoorRelationship.BI_HE: // 比和
        return const Color(0xFF2E7D32); // 吉
      case GongAndDoorRelationship.FU_YIN: // 伏吟 - 中性偏忧
        return const Color(0xFF455A64);
      case GongAndDoorRelationship.FAN_YIN: // 反吟 - 动荡
        return const Color(0xFF7B1FA2);
      default:
        if (relation.name.contains('吉')) return const Color(0xFF2E7D32);
        return Colors.grey;
    }
  }
}

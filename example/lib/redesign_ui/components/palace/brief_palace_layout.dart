part of '../../layouts/smart_grid.dart';

// ─── Font-size helper ─────────────────────────────────────────────────────────

double _palaceFontSize(double size) => (size * 0.155).clamp(9.0, 15.0);

// ─── BriefPalaceLayout ────────────────────────────────────────────────────────

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
    final double pad = 6;
    final double fs = 14;
    final double wsFs = fs * 0.65;
    const textColor = Color(0xFF2C2C2C);
    const jiColor = Color(0xFF6B7280);

    final style = TextStyle(
      fontSize: fs,
      color: textColor,
      fontWeight: FontWeight.w500,
      height: 1.1,
    );
    final jiStyle = TextStyle(
      fontSize: fs * 0.85,
      color: jiColor,
      fontWeight: FontWeight.w400,
      height: 1.1,
    );

    final bool showLeftPart =
        (config.showYinGan && data.yinGan != null) ||
        (config.showAnGan && data.tianPanAnGan != null);
    final bool shouldTruncate = data.jiStar != null;
    final bool showWangShuai = config.showWangShuai;

    final bool withJi = data.tianPanJiGan != null || data.diPanJiGan != null;
    final double rightColWidth = withJi ? fs * 2.5 + 4 : fs * 2 + 4;
    final double leftColWidth = showLeftPart ? rightColWidth : 0;
    final double middleColWidth = size - leftColWidth - rightColWidth - pad * 2;
    final double geJuHeight = 28;
    final double geJuContentHeight = config.showGeJu ? geJuHeight : 0;

    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(pad),
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width: size - pad * 2,
            height: geJuContentHeight,
            color: Colors.blueGrey.withAlpha(30),
            alignment: Alignment.center,
            child: config.showGeJu
                ? Text(
                    data.geJu,
                    style: TextStyle(
                      fontSize: fs * 0.8,
                      color: textColor,
                      fontWeight: FontWeight.w400,
                    ),
                    overflow: TextOverflow.ellipsis,
                  )
                : null,
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (leftColWidth > 0)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    width: leftColWidth,
                    child: _buildLeftColumn(style, wsFs, showWangShuai),
                  ),
                SizedBox(width: 4),
                Expanded(
                  child: _buildMainContent(
                    shouldTruncate,
                    style,
                    jiStyle,
                    wsFs,
                    showWangShuai,
                  ),
                ),
                SizedBox(width: 4),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  width: rightColWidth,
                  child: _buildRightGans(style, wsFs, withJi, showWangShuai),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建左侧的隐干/暗干列
  Widget _buildLeftColumn(TextStyle style, double wsFs, bool showWangShuai) {
    final hasYinGan = config.showYinGan && data.yinGan != null;
    final hasAnGan = config.showAnGan && data.tianPanAnGan != null;

    if (!hasYinGan && !hasAnGan) {
      return const SizedBox();
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (hasYinGan) ...[
          _buildZhangShengRow(
            data.yinGan!,
            data.yinGanGongZhangSheng,
            data.yinGanMonthZhangSheng,
            style,
            wsFs,
            showWangShuai,
          ),
        ],
        if (hasAnGan) ...[
          _buildZhangShengRow(
            data.tianPanAnGan!,
            data.tianPanAnGanGongZhangSheng,
            data.tianPanAnGanMonthZhangSheng,
            style,
            wsFs,
            showWangShuai,
          ),
        ],
        if (config.showAnGan && data.renPanAnGan != null) ...[
          _buildZhangShengRow(
            data.renPanAnGan!,
            data.renPanAnGanGongZhangSheng,
            data.renPanAnGanMonthZhangSheng,
            style,
            wsFs,
            showWangShuai,
          ),
        ],
      ],
    );
  }

  /// 构建右侧的天地盘干列（水平排布）
  Widget _buildRightGans(
    TextStyle style,
    double wsFs,
    bool withJi,
    bool showWangShuai,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildTianPanGanRow(
          data.tianPanGan,
          data.tianPanJiGan,
          data.tianPanGongZhangSheng,
          data.tianPanMonthZhangSheng,
          data.tianPanJiGanGongZhangSheng,
          data.tianPanJiGanMonthZhangSheng,
          style,
          wsFs,
          withJi,
          showWangShuai,
        ),
        _buildTianPanGanRow(
          data.diPanGan,
          data.diPanJiGan,
          data.diPanGongZhangSheng,
          data.diPanMonthZhangSheng,
          data.diPanJiGanGongZhangSheng,
          data.diPanJiGanMonthZhangSheng,
          style,
          wsFs,
          withJi,
          showWangShuai,
        ),
      ],
    );
  }

  /// 构建天盘干行（水平排布：干 + 寄宫干）
  Widget _buildTianPanGanRow(
    String gan,
    String? jiGan,
    String? gongZhangSheng,
    String? monthZhangSheng,
    String? jiGanGongZhangSheng,
    String? jiGanMonthZhangSheng,
    TextStyle style,
    double wsFs,
    bool withJi,
    bool showWangShuai,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(gan, style: style),
            if (jiGan != null && withJi) ...[
              const SizedBox(width: 2),
              Text(
                jiGan,
                style: style.copyWith(
                  color: const Color(0xFF6B7280),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ],
        ),
        if (showWangShuai) ...[
          const SizedBox(height: 2),
          _buildZhangShengText(gongZhangSheng, monthZhangSheng, wsFs),
          if (withJi && jiGanGongZhangSheng != null) ...[
            const SizedBox(height: 1),
            _buildZhangShengText(
              jiGanGongZhangSheng,
              jiGanMonthZhangSheng,
              wsFs,
            ),
          ],
        ],
      ],
    );
  }

  /// 构建核心内容（神、星、门、地神）
  Widget _buildMainContent(
    bool shouldTruncate,
    TextStyle style,
    TextStyle jiStyle,
    double wsFs,
    bool showWangShuai,
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
        if (showWangShuai && data.godGongWangShuai != null)
          _buildWangShuaiText(data.godGongWangShuai!, wsFs),
        // 九星
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(processStarText(data.star), style: style),
            if (data.jiStar != null) ...[
              const SizedBox(width: 2),
              Text(
                processStarText(data.jiStar!),
                style: jiStyle.copyWith(fontWeight: FontWeight.w400),
              ),
            ],
          ],
        ),
        if (showWangShuai)
          _buildWangShuaiDoubleText(
            data.starGongWangShuai,
            data.starMonthWangShuai,
            wsFs,
          ),
        // 八门
        Text(data.door, style: style),
        if (showWangShuai)
          _buildWangShuaiDoubleText(
            data.doorGongWangShuai,
            data.doorMonthWangShuai,
            wsFs,
          ),
        // 地八神
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return SizeTransition(
              sizeFactor: animation,
              axis: Axis.vertical,
              child: child,
            );
          },
          child: (config.showDiGod && data.diGod.isNotEmpty)
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      data.diGod,
                      style: jiStyle.copyWith(
                        color: const Color(0xFF6B7280).withOpacity(0.8),
                      ),
                    ),
                    if (showWangShuai &&
                        config.showDiGodWangShuai &&
                        data.diGodGongWangShuai != null) ...[
                      const SizedBox(width: 2),
                      _buildWangShuaiText(data.diGodGongWangShuai!, wsFs),
                    ],
                  ],
                )
              : const SizedBox.shrink(key: ValueKey('diGodHidden')),
        ),
      ],
    );
  }

  /// 构建单个旺衰文字（如：旺）
  Widget _buildWangShuaiText(String wangShuai, double wsFs) {
    final color = WangShuaiColors.getNormalWangShuaiColor(wangShuai);
    return Text(
      wangShuai,
      style: TextStyle(
        fontSize: wsFs,
        color: color,
        fontWeight: FontWeight.w500,
        height: 1,
      ),
    );
  }

  /// 构建双旺衰文字（如：宫旺·月休）
  Widget _buildWangShuaiDoubleText(
    String? gongWangShuai,
    String? monthWangShuai,
    double wsFs,
  ) {
    if (gongWangShuai == null && monthWangShuai == null) {
      return const SizedBox();
    }

    return Text(
      '${gongWangShuai ?? '·'}·${monthWangShuai ?? '·'}',
      style: TextStyle(
        fontSize: wsFs,
        color: WangShuaiColors.normalStrong,
        fontWeight: FontWeight.w500,
        height: 1,
      ),
    );
  }

  /// 构建十二长生文字（如：帝·月衰）
  Widget _buildZhangShengText(
    String? gongZhangSheng,
    String? monthZhangSheng,
    double wsFs,
  ) {
    if (gongZhangSheng == null && monthZhangSheng == null) {
      return const SizedBox();
    }

    final gongColor = gongZhangSheng != null
        ? WangShuaiColors.getZhangShengColorByString(gongZhangSheng)
        : WangShuaiColors.zhangShengWeak;
    final monthColor = monthZhangSheng != null
        ? WangShuaiColors.getZhangShengColorByString(monthZhangSheng)
        : WangShuaiColors.zhangShengWeak;

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          gongZhangSheng ?? '·',
          style: TextStyle(
            fontSize: wsFs,
            color: gongColor,
            fontWeight: FontWeight.w500,
            height: 1,
          ),
        ),
        Text(
          '·',
          style: TextStyle(
            fontSize: wsFs,
            color: const Color(0xFF6B7280),
            fontWeight: FontWeight.w400,
            height: 1,
          ),
        ),
        Text(
          monthZhangSheng ?? '·',
          style: TextStyle(
            fontSize: wsFs,
            color: monthColor,
            fontWeight: FontWeight.w500,
            height: 1,
          ),
        ),
      ],
    );
  }

  /// 构建干+长生行（用于隐干/暗干）
  Widget _buildZhangShengRow(
    String gan,
    String? gongZhangSheng,
    String? monthZhangSheng,
    TextStyle style,
    double wsFs,
    bool showWangShuai,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(gan, style: style),
        if (showWangShuai) ...[
          const SizedBox(height: 1),
          _buildZhangShengText(gongZhangSheng, monthZhangSheng, wsFs),
        ],
      ],
    );
  }
}

part of '../../layouts/smart_grid.dart';

// ─── Font-size helper ─────────────────────────────────────────────────────────

/// 宫格内通用字号
double _palaceFontSize(double size) => (size * 0.155).clamp(9.0, 15.0);

// ─── BriefPalaceLayout ────────────────────────────────────────────────────────

/// 宫位三行布局
///
/// ```
///  值符      己 [己寄]   ← 八神（左） | 天盘干 [+天盘寄干]（右）
///  天柱 [天禽]           ← 九星 [+寄宫星]（左）
///  死门      壬 [壬寄]   ← 八门（左） | 地盘干 [+地盘寄干]（右）
/// ```
/// 中括号内元素仅在 jiStar / tianPanJiGan / diPanJiGan 不为 null 时显示。
class BriefPalaceLayout extends StatelessWidget {
  final PalaceData data;
  final BriefPalaceConfig config;
  final double size;

  const BriefPalaceLayout({
    Key? key,
    required this.data,
    required this.config,
    required this.size,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final pad = (size * 0.09).clamp(5.0, 11.0);
    final fs = _palaceFontSize(size);
    final fsJi = fs * 0.85; // 寄宫元素略小
    const textColor = Color(0xFF2C2C2C);
    const jiColor = Color(0xFF6B7280); // 寄宫元素用灰色区分
    final style = TextStyle(
      fontSize: fs,
      color: textColor,
      fontWeight: FontWeight.w500,
      height: 1.2,
    );
    final jiStyle = TextStyle(
      fontSize: fsJi,
      color: jiColor,
      fontWeight: FontWeight.w400,
      height: 1.2,
    );

    return Padding(
      padding: EdgeInsets.all(pad),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Row 1 — 八神（左）
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [Text(data.god, style: style)],
          ),

          // Row 2 — 九星 [+寄宫星]（左） | 天盘干 [+天盘寄干]（右）
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(data.star, style: style),
                  if (data.jiStar != null) ...[
                    const SizedBox(width: 2),
                    Text(data.jiStar!, style: jiStyle),
                  ],
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(data.tianPanGan, style: style),
                  if (data.tianPanJiGan != null) ...[
                    const SizedBox(width: 2),
                    Text(data.tianPanJiGan!, style: jiStyle),
                  ],
                ],
              ),
            ],
          ),

          // Row 3 — 八门（左）| 地盘干 [+地盘寄干]（右）
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(data.door, style: style),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(data.diPanGan, style: style),
                  if (data.diPanJiGan != null) ...[
                    const SizedBox(width: 2),
                    Text(data.diPanJiGan!, style: jiStyle),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

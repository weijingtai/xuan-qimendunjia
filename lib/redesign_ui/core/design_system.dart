import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// 奇门遁甲UI重设计系统
/// 基于现代设计原则重构传统UI
class QiMenDesignSystem {
  // 私有构造函数，防止实例化
  QiMenDesignSystem._();
}

/// 色彩系统 - 基于传统中国色但现代化处理
class ColorSystem {
  // 主色调
  static const Color primary = Color(0xFF2D344C); // 靛青 - 传统靛蓝现代化
  static const Color secondary = Color(0xFFC4B7A0); // 缃叶 - 古铜金
  static const Color accent = Color(0xFFC23428); // 朱砂 - 朱砂红

  // 中性色
  static const Color background = Color(0xFFF8F6F0); // 宣纸 - 宣纸白
  static const Color surface = Color(0xFFFFFFFF); // 白玉 - 纯白
  static const Color surfaceVariant = Color(0xFFF5F5F5); // 银白

  // 文字颜色
  static const Color textPrimary = Color(0xFF1C1F2D); // 墨黑
  static const Color textSecondary = Color(0xFF6B7280); // 石墨灰
  static const Color textTertiary = Color(0xFF9CA3AF); // 淡墨灰

  // 功能色
  static const Color success = Color(0xFF4A7C59); // 松石绿 - 吉
  static const Color warning = Color(0xFFD4A574); // 琥珀黄 - 警示
  static const Color error = Color(0xFF8B2635); // 胭脂红 - 凶
  static const Color info = Color(0xFF3B82F6); // 瓷蓝 - 信息

  // 新中式 宫位底色系统
  static const Color paperBackground = Color(0xFFF7F2E8); // 宣纸/绢本色
  static const Color paperBorder = Color(0xFFD4C5A9); // 淡金/古铜色
  static const Color stemHeavenly = Color(0xFF2C2C2C); // 天盘干 — 玄漆色
  static const Color stemEarthly = Color(0xFF595959); // 地盘干 — 深灰
  static const Color kongWangStamp = Color(0x40B42828); // 旬空印章 — 淡朱砂

  // 传统元素色彩映射（简化版）
  static const Map<String, Color> traditionalColors = {
    // 八门色彩（新中式调色）
    '休门': Color(0xFF4A90E2), // 天青
    '生门': Color(0xFF4A634A), // 竹绿色
    '伤门': Color(0xFF7B4F9E), // 紫菀（降饱和）
    '杜门': Color(0xFF3A7A6A), // 石绿
    '景门': Color(0xFFB8882A), // 雄黄（降饱和）
    '死门': Color(0xFF5D2E2E), // 赭石色
    '惊门': Color(0xFFB03020), // 朱磦（降饱和）
    '开门': Color(0xFFB09820), // 藤黄（降饱和）
    // 九星色彩
    '天蓬': Color(0xFF2D344C), // 靛青
    '天芮': Color(0xFF8B572A), // 赭石
    '天冲': Color(0xFF7ED321), // 翠绿
    '天辅': Color(0xFF50E3C2), // 石绿
    '天禽': Color(0xFFF5A623), // 雄黄
    '天心': Color(0xFF4A90E2), // 天青
    '天柱': Color(0xFF9013FE), // 紫菀
    '天任': Color(0xFF7ED321), // 翠绿
    '天英': Color(0xFFD0021B), // 朱磦
  };
}

/// 字体系统 - 现代简洁
class QiMenTypography {
  // 主字体 - 苹方现代简洁
  static const String fontFamily = 'PingFang SC';

  // 字体样式层级
  static const TextStyle headlineLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: -0.5,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: -0.3,
  );

  static const TextStyle titleLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: -0.2,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: -0.1,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const TextStyle labelLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );

  static const TextStyle labelMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 10,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );

  // 数字专用字体
  static const TextStyle numberLarge = TextStyle(
    fontFamily: 'SF Pro Display',
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: -0.5,
  );

  static const TextStyle numberMedium = TextStyle(
    fontFamily: 'SF Pro Display',
    fontSize: 18,
    fontWeight: FontWeight.w500,
    height: 1.3,
    letterSpacing: -0.3,
  );
}

/// 间距系统
class Spacing {
  static const double xs = 4.0; // 超小间距
  static const double sm = 8.0; // 小间距
  static const double md = 16.0; // 中间距
  static const double lg = 24.0; // 大间距
  static const double xl = 32.0; // 超大间距
  static const double xxl = 48.0; // 特大间距
}

/// 圆角系统
class QiMenRadius {
  static const BorderRadius sm = BorderRadius.all(Radius.circular(4));
  static const BorderRadius md = BorderRadius.all(Radius.circular(8));
  static const BorderRadius lg = BorderRadius.all(Radius.circular(16));
  static const BorderRadius xl = BorderRadius.all(Radius.circular(24));
  static const BorderRadius xxl = BorderRadius.all(Radius.circular(32));

  static const Radius circularSm = Radius.circular(4);
  static const Radius circularMd = Radius.circular(8);
  static const Radius circularLg = Radius.circular(16);
  static const Radius circularXl = Radius.circular(24);
}

/// 阴影系统
class Shadows {
  static const BoxShadow sm = BoxShadow(
    color: Color(0x0D000000),
    blurRadius: 2,
    offset: Offset(0, 1),
  );

  static const BoxShadow md = BoxShadow(
    color: Color(0x1A000000),
    blurRadius: 8,
    offset: Offset(0, 4),
  );

  static const BoxShadow lg = BoxShadow(
    color: Color(0x26000000),
    blurRadius: 16,
    offset: Offset(0, 8),
  );

  static const BoxShadow xl = BoxShadow(
    color: Color(0x33000000),
    blurRadius: 24,
    offset: Offset(0, 12),
  );
}

/// 动画系统
class Animations {
  static const Duration durationFast = Duration(milliseconds: 150);
  static const Duration durationNormal = Duration(milliseconds: 300);
  static const Duration durationSlow = Duration(milliseconds: 500);

  static const Curve curveDefault = Curves.easeInOut;
  static const Curve curveDecelerate = Curves.decelerate;
  static const Curve curveAccelerate = Curves.easeIn;
  static const Curve curveSharp = Curves.easeInOutCubic;

  // 标准动画过渡
  static Animation<double> standardTransition(AnimationController controller) {
    return CurvedAnimation(
      parent: controller,
      curve: Interval(0.0, 1.0, curve: curveDefault),
    );
  }
}

/// 尺寸系统
class Dimensions {
  // 九宫格标准尺寸
  static const double gridSmall = 240.0;
  static const double gridMedium = 360.0;
  static const double gridLarge = 480.0;

  // 宫位标准尺寸
  static const double palaceSmall = 72.0;
  static const double palaceMedium = 96.0;
  static const double palaceLarge = 120.0;

  // 组件标准尺寸
  static const double buttonHeight = 48.0;
  static const double iconSize = 24.0;
  static const double iconSizeSmall = 16.0;
  static const double iconSizeLarge = 32.0;
}

/// 主题数据
class AppTheme {
  static ThemeData get themeData {
    return ThemeData(
      // 色彩方案
      colorScheme: ColorScheme.fromSeed(
        seedColor: ColorSystem.primary,
        primary: ColorSystem.primary,
        secondary: ColorSystem.secondary,
        surface: ColorSystem.surface,
        background: ColorSystem.background,
        error: ColorSystem.error,
        onPrimary: Colors.white,
        onSecondary: ColorSystem.textPrimary,
        onSurface: ColorSystem.textPrimary,
        onBackground: ColorSystem.textPrimary,
        onError: Colors.white,
      ),

      // 文字主题
      textTheme: const TextTheme(
        headlineLarge: QiMenTypography.headlineLarge,
        headlineMedium: QiMenTypography.headlineMedium,
        titleLarge: QiMenTypography.titleLarge,
        titleMedium: QiMenTypography.titleMedium,
        bodyLarge: QiMenTypography.bodyLarge,
        bodyMedium: QiMenTypography.bodyMedium,
        labelLarge: QiMenTypography.labelLarge,
        labelMedium: QiMenTypography.labelMedium,
      ),

      // 组件主题
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorSystem.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, Dimensions.buttonHeight),
          shape: RoundedRectangleBorder(borderRadius: QiMenRadius.md),
          elevation: 0,
        ),
      ),

      // 输入框主题
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ColorSystem.surface,
        border: OutlineInputBorder(
          borderRadius: QiMenRadius.md,
          borderSide: BorderSide(color: ColorSystem.textTertiary),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: QiMenRadius.md,
          borderSide: BorderSide(
            color: ColorSystem.textTertiary.withValues(alpha: 0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: QiMenRadius.md,
          borderSide: const BorderSide(color: ColorSystem.primary, width: 2),
        ),
      ),

      // 卡片主题
      cardTheme: const CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: QiMenRadius.lg),
        margin: EdgeInsets.zero,
      ),

      // 应用栏主题
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: ColorSystem.surface,
        foregroundColor: ColorSystem.textPrimary,
        centerTitle: true,
        iconTheme: const IconThemeData(color: ColorSystem.textPrimary),
        titleTextStyle: QiMenTypography.titleLarge.copyWith(
          color: ColorSystem.textPrimary,
        ),
      ),

      // 全局动画
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}

/// 传统色彩工具类
class TraditionalColors {
  /// 获取八门颜色
  static Color getBaMenColor(String menName) {
    return ColorSystem.traditionalColors[menName] ?? ColorSystem.textPrimary;
  }

  /// 获取九星颜色
  static Color getJiuXingColor(String xingName) {
    return ColorSystem.traditionalColors[xingName] ?? ColorSystem.textPrimary;
  }

  /// 获取旺衰颜色
  static Color getWangShuaiColor(String wangShuai) {
    switch (wangShuai) {
      case '旺':
        return ColorSystem.success;
      case '相':
        return ColorSystem.accent;
      case '休':
        return ColorSystem.warning;
      case '囚':
      case '死':
        return ColorSystem.error;
      default:
        return ColorSystem.textSecondary;
    }
  }

  /// 获取天干颜色（五行对应色）
  static Color getGanColor(String gan) {
    switch (gan) {
      case '甲':
      case '乙':
        return ColorSystem.success; // 木 — 松石绿
      case '丙':
      case '丁':
        return ColorSystem.accent; // 火 — 朱砂红
      case '戊':
      case '己':
        return ColorSystem.warning; // 土 — 琥珀黄
      case '庚':
      case '辛':
        return ColorSystem.textSecondary; // 金 — 石墨灰
      case '壬':
      case '癸':
        return ColorSystem.primary; // 水 — 靛青
      default:
        return ColorSystem.textPrimary;
    }
  }

  /// 获取吉凶颜色
  static Color getJiXiongColor(String jiXiong) {
    switch (jiXiong) {
      case '大吉':
      case '吉':
        return ColorSystem.success;
      case '小吉':
        return ColorSystem.accent;
      case '凶':
      case '大凶':
        return ColorSystem.error;
      case '平':
        return ColorSystem.warning;
      default:
        return ColorSystem.textSecondary;
    }
  }
}

/// 旺衰色彩系统
/// 支持一般旺衰（旺相休囚死）和十二长生
class WangShuaiColors {
  WangShuaiColors._();

  /// 一般旺衰颜色 - 强（旺/相）
  static const Color normalStrong = Color(0xFF4A7C59);

  /// 一般旺衰颜色 - 弱（休/囚/死/废）
  static const Color normalWeak = Color(0xFF6B9B7A);

  /// 十二长生颜色 - 强（长生到帝旺）
  static const Color zhangShengStrong = Color(0xFF3B82F6);

  /// 十二长生颜色 - 弱（衰到养）
  static const Color zhangShengWeak = Color(0xFF6B7280);

  /// 获取一般旺衰颜色
  static Color getNormalWangShuaiColor(String wangShuai) {
    switch (wangShuai) {
      case '旺':
      case '相':
        return normalStrong;
      case '休':
      case '囚':
      case '死':
      case '废':
        return normalWeak;
      default:
        return ColorSystem.textSecondary;
    }
  }

  /// 十二长生强状态列表
  static const List<String> _strongZhangSheng = ['长', '沐', '冠', '禄', '帝'];

  /// 获取十二长生颜色
  static Color getZhangShengColorByString(String zhangShengName) {
    if (_strongZhangSheng.contains(zhangShengName)) {
      return zhangShengStrong;
    }
    return zhangShengWeak;
  }
}

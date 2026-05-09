# 旧版架构 GUI 布局分析报告

## 1. 项目概述

本项目是一个基于 Flutter 的**奇门遁甲 (Qi Men Dun Jia)** 排盘应用，核心 UI 采用**九宫格 (Nine Palace Grid)** 布局展示盘面信息。旧版架构的 GUI 代码主要分布在 `lib/pages/` 和 `lib/widgets/` 目录中。

### 技术栈
- **Framework**: Flutter/Dart
- **状态管理**: Provider + ValueNotifier
- **字体**: Google Fonts (longCang, maShanZheng, zhiMangXing, notoSerif)
- **动画**: flutter_animate, Lottie, AnimatedContainer/AnimatedSwitcher
- **响应式文本**: auto_size_text
- **路由**: GoRouter (`/qimendunjia`)

---

## 2. 页面架构层级

```
main.dart
 └─ Navigator (GoRouter)
     └─ ScalableShiJiaQiMenViewPage   (主页面)
         ├─ AppBar
         ├─ PanInfoRow                  (盘面信息行)
         ├─ ShiJiaQiMenPan             (九宫盘面)
         │   ├─ ResizableGongWidget×8   (八宫，新版可缩放)
         │   └─ CenterGong             (中宫)
         ├─ 操作按钮区
         ├─ GlassLayer                 (毛玻璃遮罩)
         └─ SelectedGongDetail         (选中宫位详情)
```

### 2.1 主要页面文件

| 文件 | 作用 | 状态 |
|------|------|------|
| `scalable_shi_jia_qi_men_view_page.dart` | 主视图页（可缩放版） | 主要使用 |
| `primary_page.dart` | 早期原型页 | 已弃用 |
| `beatiful_page.dart` | 美化版页面 | 实验性 |

### 2.2 主要Widget文件

| 文件 | 作用 |
|------|------|
| `resizable_gong_widget.dart` | 可缩放版宫位Widget（当前主力） |
| `each_gong_widget.dart` | 固定尺寸宫位Widget（256×256） |
| `gong_widget.dart` | 基础宫位Widget（与each_gong_widget类似） |
| `QiMenGongContentBackground.dart` | 宫位背景内容（卦象、星名、门名） |
| `wang_shuai_hint.dart` | 旺衰提示动画Widget |
| `wang_shuai_hint_top_down.dart` | 上下方向旺衰提示 |
| `ten_gan_ke_ying_ge_ju_detail.dart` | 十干克应格局详情 |
| `ten_gan_ke_ying_yin_zhang.dart` | 十干克应印章Widget |
| `season_24_tag.dart` | 24节气标签 |
| `qi_yi_wang_shuai.dart` | 奇仪旺衰Widget |
| `BounceDialog.dart` | 弹跳对话框 |

---

## 3. 九宫格整体布局

### 3.1 盘面尺寸

```dart
// ScalableShiJiaQiMenViewPage
double baseEachGongSize = 200;  // 每宫基础尺寸 (默认256)
Size panSize = const Size(604, 604);  // 盘面总尺寸 (默认816×816)
double eachPaddingSize = 0;  // 宫间距 (默认8)
```

### 3.2 九宫排列顺序（后天八卦）

```
┌────────┬────────┬────────┐
│  巽(4)  │  离(9)  │  坤(2)  │
├────────┼────────┼────────┤
│  震(3)  │  中(5)  │  兑(7)  │
├────────┼────────┼────────┤
│  艮(8)  │  坎(1)  │  乾(6)  │
└────────┴────────┴────────┘
```

### 3.3 盘面构建方式

使用 `Column > Row` 嵌套 3×3 结构，外层由 `Consumer<ShiJiaQiMenViewModel>` 监听数据变化：

```dart
// 盘面容器
Container(
  width: panSize.width + 36,
  height: panSize.height + 36,
  alignment: Alignment.center,
  child: Consumer<ShiJiaQiMenViewModel>(...)
)
```

### 3.4 阴阳遁背景色区分

```dart
// 阳遁: 一八三四宫(坎艮震巽)为内盘=Colors.black12, 九二七六宫(离坤兑乾)=Colors.white
// 阴遁: 反之
if (pan.yinYangDun.isYang) {
  内盘(坎艮震巽) → backgroundColor = Colors.black12;
  外盘(离坤兑乾) → backgroundColor = Colors.white;
} else {
  内盘(坎艮震巽) → backgroundColor = Colors.white;
  外盘(离坤兑乾) → backgroundColor = Colors.black12;
}
```

---

## 4. 单宫布局详解

单宫存在三个版本，按演化顺序为：`GongWidget` → `EachGongWidget` → `ResizableGongWidget`。

### 4.1 GongWidget / EachGongWidget（固定尺寸版，256×256）

#### 整体结构

```
Container (gongSize × gongSize)
 └─ Stack (alignment: center)
     ├─ Layer 1: buildEachGongMetaContent (背景层 - 九宫元数据)
     ├─ Layer 2: buildGong/buildEachGongContent (前景层 - 动态内容)
     └─ Layer 3: Positioned - 十干克应印章
```

#### 4.1.1 背景层 (buildEachGongMetaContent)

```
Container (padding: EdgeInsets.all(4))
 └─ Column (3行)
     ├─ Row (Expanded) → 上方三格
     │   ├─ _buildLeftTopCorner   (左上: 宫旺衰/天门地户)
     │   ├─ _buildGongTopCenter   (上中: 地支/宫旺衰)
     │   └─ _buildRightTopCorner  (右上: 宫旺衰/天门地户)
     ├─ Row → 中间三格
     │   ├─ Expanded(Row) → 左侧
     │   │   ├─ _buildLeftSideBox (地支/宫旺衰)
     │   │   └─ Expanded(SizedBox)
     │   ├─ Opacity(.5) → 中心 (QiMenGongContentBackground)
     │   └─ Expanded(Row) → 右侧
     │       ├─ Expanded(SizedBox)
     │       └─ _buildRightSideBox (地支/宫旺衰)
     └─ Row (Expanded) → 下方三格
         ├─ _buildLeftBottomCorner  (左下)
         ├─ _buildGongBottomCenter  (下中)
         └─ _buildRightBottomCorner (右下)
```

**边框与装饰**:
```dart
// 带边框时
BoxDecoration(
  color: Colors.white.withOpacity(.1),
  border: Border.fromBorderSide(normalBorderSide),  // grey.shade300, width: 1
  borderRadius: BorderRadius.all(Radius.circular(24))
)

// 无边框时
BoxDecoration(color: Colors.white.withOpacity(.1))
```

**边框类型**:
```dart
nearBorderSide = BorderSide(color: Colors.black, width: 1);
farBorderSide = BorderSide(color: Colors.grey, width: 1);
normalBorderSide = BorderSide(color: Colors.grey.shade300, width: 1);
```

#### 4.1.2 前景层 (buildGong / buildEachGongContent)

EachGongWidget的前景层布局（固定尺寸256高度）:

```
Container (gongSize × gongSize)
 └─ Row (center)
     ├─ SizedBox(width: 30)     ← 左边距
     ├─ 暗干列 (h:256, w:28)    ← 天暗干 + 人暗干
     │   ├─ QiYiWangShuai(tianPanAnGan)
     │   ├─ SizedBox(h:32)
     │   └─ QiYiWangShuai(renPanAnGan)
     ├─ 八神列 (h:256, w:22)
     │   ├─ SizedBox(h:16)
     │   ├─ Stack(八神名 + 值符标记)
     │   └─ SizedBox(h:24, 旺衰提示)
     ├─ 中心列 (h:256, w:80)
     │   ├─ 星区域 (h:70, w:80)
     │   │   ├─ SizedBox(h:24)
     │   │   └─ Stack(值符星标记 + 星名 + 旺衰 + 寄天禽)
     │   ├─ 空白 (h:76, w:80)    ← 为背景层中心内容留空
     │   └─ 门区域 (h:70, w:80)
     │       ├─ Stack(值使门标记 + 门名 + 旺衰 + 门宫关系)
     │       └─ 地盘八神 (h:24)
     ├─ 天地盘干列 (h:256, w:64)
     │   ├─ 天盘干+寄干 (h:48, w:54)
     │   ├─ 隐干 (h:48, w:64)
     │   └─ 地盘干+寄干 (h:48, w:54)
     ├─ SizedBox(h:256, w:0)
     └─ SizedBox(w:16)           ← 右边距
```

### 4.2 ResizableGongWidget（可缩放版）

#### 整体结构

```
AnimatedContainer (cardSize × cardSize, borderRadius: 24)
 └─ Stack
     ├─ Row (主内容区)
     │   ├─ leftSidePanelContent    (左侧地支面板)
     │   ├─ SizedBox (centerWidth × cardSize)
     │   │   └─ Column
     │   │       ├─ topSidePanelContent     (顶部地支面板)
     │   │       ├─ Stack (中心内容区)
     │   │       │   └─ Row
     │   │       │       ├─ yinAnGanColumn   (隐暗干列)
     │   │       │       ├─ AnimatedContainer (中心三层)
     │   │       │       │   └─ Column
     │   │       │       │       ├─ _gods     (八神)
     │   │       │       │       ├─ _stars    (九星)
     │   │       │       │       └─ _doors    (八门 + 地八神)
     │   │       │       └─ 天地盘干 Column
     │   │       │           ├─ tianDiPanGanMarked (天盘干)
     │   │       │           ├─ SizedBox(h:4)
     │   │       │           └─ tianDiPanGanMarked (地盘干)
     │   │       └─ bottomSidePanelContent  (底部地支面板)
     │   └─ rightSidePanelContent   (右侧地支面板)
     ├─ AnimatedPositioned (左下: 十干克应格局印章)
     ├─ AnimatedPositioned (右下: 天盘寄干十干克应)
     ├─ AnimatedPositioned (右下: 天地寄干十干克应)
     ├─ AnimatedPositioned (左上: 宫位格局标签)
     └─ AnimatedPositioned (右侧: 三奇入宫印章)
```

#### 尺寸计算规则（基于cardSize动态缩放）

```dart
double paddingSideWidth = cardSize * .08;  // 侧边面板宽度
if (paddingSideWidth < 12) paddingSideWidth = 0;  // 太小则隐藏

double centerWidth = cardSize - paddingSideWidth * 2;  // 中心区域宽度
double centerBoxWidth = (cardSize * 0.4) * .7;   // 中心内容框宽度
double centerSideWidth = (cardSize * 0.4) * .25 * 1.6;  // 中心侧边宽度

double fontSize = (cardSize * 0.4) * .3;  // 主字体大小
if (fontSize < 16) fontSize = 16;         // 最小16px
double jiFontSize = fontSize * .8;        // 寄干字体
double hintFontSize = jiFontSize * .5;    // 提示字体

bool isHor = (centerBoxWidth + centerSideWidth * 2) <= 120;  // 横向/纵向布局切换
```

---

## 5. 字体设计系统

### 5.1 全局字体定义 (ConstantUiResourcesOfQiMen)

| 字段 | 字体族 | 大小 | 颜色 | 粗细 | 行高 | 阴影 |
|------|--------|------|------|------|------|------|
| `eightGodsTextStyle` | zhiMangXing | 26 | RGBA(68,68,60,1) | - | 1.0 | grey.opacity(.5), blur:2 |
| `twelveDiZhiTextStyle` | longCang | 24 | grey | - | 1 | black12, blur:2 |
| `tianGanTextStyle` | maShanZheng | 28 | black87 | - | 1.0 | black12, blur:2 |
| `eightDoorTextStyle` | maShanZheng | 24 | RGBA(25,44,59,1) | w400 | 1 | grey.opacity(.5), blur:2 |
| `nineStarTextStyle` | zhiMangXing | 28 | RGBA(28,45,37,1) | - | 1 | grey.opacity(.5), blur:2 |
| `menHuLuFangStyle` | zhiMangXing | 16 | black87 | w300 | 1 | grey.opacity(.5), blur:2 |
| `panInfoTextStyle` | maShanZheng | 24 | blueGrey.shade800 | w600 | 1 | - |
| `wangShuaiTextStyle` | 系统默认 | 10 | - | w400 | 1.0 | - |
| `nineGongNameTextStyle` | 系统默认 | 70 | grey | - | 1 | - |
| `nineGongNumberTextStyle` | notoSerif | 20 | grey | - | 1 | - |
| `nineStarsNameTextStyle` | zhiMangXing | 20 | grey | - | 1 | - |
| `eightSkyDoorTextStyle` | maShanZheng | 16 | grey | w600 | 1 | - |
| `eightSeasonTextStyle` | maShanZheng | 16 | grey | - | 1 | - |
| `doorGongtextStyle` | 系统默认 | 10 | black | w600 | 1 | - |

### 5.2 各区域字体应用

#### 地支文字
```dart
GoogleFonts.longCang(
  color: zodiacZhiColors[diZhi].withOpacity(.2),
  fontSize: 24, height: 1, fontWeight: FontWeight.w400,
  shadows: [Shadow(color: grey.opacity(.5), blurRadius: 2)]
)
```

#### 天干文字 (天/地盘)
```dart
ConstantUiResourcesOfQiMen.tianGanTextStyle.copyWith(
  fontSize: fontSize,  // 动态计算
  color: zodiacGanColors[gan],
  shadows: [
    Shadow(color: ganColor.opacity(.4), offset: Offset(1,1), blurRadius: 2),
    Shadow(color: white.opacity(.2), offset: Offset(1,-1), blurRadius: 2)
  ]
)
```

#### 隐暗干文字
```dart
ConstantUiResourcesOfQiMen.tianGanTextStyle.copyWith(
  color: Colors.grey / Colors.blueGrey,
  shadows: [Shadow(color: black12, offset: Offset(1,1), blurRadius: 2)]
)
```

#### 旺衰提示文字
```dart
TextStyle(
  color: Colors.black54,   // 月令旺衰
  // color: Colors.grey,   // 宫位旺衰
  fontWeight: FontWeight.w300, height: 1
)
// AutoSizeText: minFontSize: 8, maxFontSize: 24
```

#### 八神文字 (ResizableGongWidget)
```dart
ConstantUiResourcesOfQiMen.nineStarTextStyle.copyWith(
  fontSize: fontSize,
  shadows: [Shadow(offset: Offset(1,1), blurRadius: 3, color: grey)]
)
```

#### 星名文字
```dart
ConstantUiResourcesOfQiMen.nineStarTextStyle.copyWith(
  fontSize: fontSize,
  shadows: [Shadow(offset: Offset(1,1), blurRadius: 3, color: grey)]
)
```

#### 门名文字
```dart
ConstantUiResourcesOfQiMen.nineStarTextStyle.copyWith(
  fontSize: fontSize,
  shadows: [Shadow(offset: Offset(1,1), blurRadius: 3, color: grey)]
)
```

---

## 6. 配色系统

### 6.1 主题色

```dart
themeColor1 = {
  "backgroundColor": RGBA(45, 52, 76, 1),
  "foregroundColor": RGBA(196, 183, 160, 1),
  "specialColor": RGBA(194, 52, 40, 1)
};
themeColor2 = {
  "backgroundColor": RGBA(115, 28, 35, 1),
  "foregroundColor": RGBA(230, 181, 123, 1),
};
```

### 6.2 八门颜色映射 (eightDoorColorMapper)

| 门 | 颜色 | RGB |
|----|------|-----|
| 休门 | 皇室蓝 | (61, 89, 171) |
| 死门 | 棕褐 | (210, 180, 140) |
| 伤门 | 暗绿 | (120, 146, 98) |
| 杜门 | 暗绿 | (120, 146, 98) |
| 中 | 沙棕 | (244, 164, 96) |
| 开门 | 琥珀 | (228, 158, 0) |
| 景门(惊) | 印度红 | (205, 92, 92) |
| 生门 | 棕褐 | (210, 180, 140) |
| 景门(景) | 琥珀 | (228, 158, 0) |

### 6.3 九星颜色映射 (nineStarsColorMapper)

| 星 | 颜色 | RGB |
|----|------|-----|
| 天蓬 | 钢蓝 | (39, 117, 182) |
| 天芮 | 驼色 | (168, 132, 98) |
| 天冲 | 青绿 | (90, 164, 174) |
| 天辅 | 青绿 | (90, 164, 174) |
| 天禽 | 驼色 | (168, 132, 98) |
| 天心 | 琥珀 | (240, 167, 46) |
| 天柱 | 琥珀 | (240, 167, 46) |
| 天任 | 驼色 | (168, 132, 98) |
| 天英 | 珊瑚红 | (233, 84, 100) |

### 6.4 宫门关系颜色映射 (gongDoorRelationshipColorMapper)

| 关系 | 颜色 | RGB |
|------|------|-----|
| 大吉 | 深绿 | (39, 98, 53) |
| 小吉 | 翠绿 | (40, 140, 62) |
| 大凶 | 深红 | (120, 0, 36) |
| 小凶 | 暗红 | (71, 0, 36) |
| 入墓 | 酱红 | (81, 0, 0) |
| 逼迫 | 鲜红 | (193, 18, 28) |
| 受伤 | 鲜红 | (193, 18, 28) |
| 门破 | 靛蓝 | (36, 54, 125) |
| 生旺 | purple.shade900 | - |
| 泄气 | black87 | - |
| 受制 | 灰棕 | (121, 114, 110) |
| 生宫 | 灰棕 | (121, 114, 110) |
| 伏吟 | orange.shade900 | - |
| 反吟 | blueAccent.shade400 | - |

### 6.5 旺衰颜色体系

| 状态 | 颜色 |
|------|------|
| 旺 (WANG) | purple.shade700 |
| 相 (XIANG) | red.shade700 |
| 休 (QIU/XIU) | blueGrey.shade300 |
| 废/死 (FEI/SI) | grey.shade400 |
| 默认 | black87.opacity(.8) |

### 6.6 页面装饰样式

```dart
// 卡片装饰 (详情展示区)
cardDecoration = BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.all(Radius.circular(16)),
  boxShadow: [
    BoxShadow(color: grey.opacity(.2), blurRadius: 5, spreadRadius: 5)
  ]
);
```

---

## 7. 特殊标记与视觉元素

### 7.1 值符星标记
```dart
// 红色墨线图片（值符星/旬首标记）
ColorFiltered(
  colorFilter: ColorFilter.mode(
    Color.fromRGBO(176, 31, 36, .8),  // 中国红
    BlendMode.srcIn
  ),
  child: Image.asset("assets/icons/wide-black-ink-line.png")
)
// 宽度: 64 (EachGongWidget) / jiFontSize*3 (ResizableGongWidget)
// 高度: width * .2
```

### 7.2 值使门标记
```dart
// 同值符，使用弧线图片
Image.asset("assets/icons/wide-black-ink-radian-line2.png")
// 宽度: 64, 颜色: RGBA(176, 31, 36, .8)
```

### 7.3 旬首（遁甲）标记
```dart
// 红色印章圆环
ColorFiltered(
  colorFilter: ColorFilter.mode(
    zodiacGanColors[TianGan.JIA]!,
    BlendMode.srcIn
  ),
  child: Image.asset("assets/icons/red-ink-circle.png")
)
// 尺寸: fontSize * .8 × fontSize * .8
```

### 7.4 空亡标记
```dart
// 灰色虚圈
ColorFiltered(
  colorFilter: ColorFilter.mode(
    zodiacZhiColors[diZhi]!,  // 对应地支颜色
    BlendMode.srcIn
  ),
  child: Image.asset("assets/icons/thin-black-ink-circle.png")
)
```

### 7.5 驿马标记
```dart
// Lottie 动画 - 行走的马
Lottie.asset("assets/lotties/horse_walking.json",
  delegates: LottieDelegates(values: [
    ValueDelegate.colorFilter(
      ["**"],
      value: ColorFilter.mode(color.withOpacity(1), BlendMode.src),
    )
  ]),
  repeat: true
)
// 尺寸: 24×24 (固定) 或 size×size (动态)
```

### 7.6 入墓标记
```dart
// 墓字图片
ColorFiltered(
  colorFilter: ColorFilter.mode(
    isMuOrKu ? Colors.red.shade800 : Colors.blue.shade600,
    BlendMode.srcIn
  ),
  child: Image.asset("assets/icons/mu.png")
)
// 入墓=红色, 入库=蓝色
```

### 7.7 六仪击刑标记
```dart
ColorFiltered(
  colorFilter: ColorFilter.mode(Colors.blueGrey, BlendMode.srcIn),
  child: Image.asset("assets/icons/ji_xing.png")
)
```

### 7.8 十干克应印章
```dart
// 方形印章
Container(
  width: 48, height: 48,  // EachGongWidget: 38×38
  decoration: BoxDecoration(
    image: DecorationImage(
      image: AssetImage("assets/icons/yin_zhang.png"),
      colorFilter: ColorFilter.mode(
        jiXiongColorMapper[jiXiong]!,  // 吉凶对应颜色
        BlendMode.srcIn
      ),
      fit: BoxFit.cover
    )
  ),
  child: // 2×2 文字布局
)
// 印章内文字: eightSkyDoorTextStyle.copyWith(fontSize: 52*.3, color: white)
// 或 maShanZheng(height: 1.0, fontSize: 14/18, fontWeight: w500, color: white)
```

### 7.9 三奇入宫长条印章
```dart
// 竖向长条印章
SizedBox(
  width: 32, height: 96,
  child: RotatedBox(quarterTurns: 1,
    child: ColorFiltered(
      colorFilter: ColorFilter.mode(
        jiXiongColorMapper[qi.geJuJiXiong]!,
        BlendMode.srcIn
      ),
      child: Image.asset("assets/icons/long_yin_zhang.png", width: 64, height: 20)
    )
  )
)
// 内部文字: maShanZheng(fontSize: 16, height: 1.0, color: white)
```

### 7.10 门宫关系印章 (ResizableGongWidget)
```dart
Container(
  decoration: BoxDecoration(
    image: DecorationImage(
      fit: BoxFit.fill,
      colorFilter: ColorFilter.mode(
        gongDoorRelationshipColorMapper[relationship]!,
        BlendMode.srcIn
      ),
      image: AssetImage("assets/icons/red-ink-background.png")
    ),
    boxShadow: [
      BoxShadow(color: black.opacity(0.2), spreadRadius: 1, blurRadius: 2)
    ]
  ),
  // 文字: white, fontWeight: w200, height: 1
  // AutoSizeText: minFontSize: 8, maxFontSize: 12
)
```

---

## 8. 格局标签 (GeJu Panel Templates)

### 8.1 吉格局标签 (ge_ju_template_small)
```
整体: SizedBox(outerWidth: 120, outerHeight: 32)
 └─ Stack (center)
     ├─ 外层圆点 (20×20, 圆形, boxShadow)
     ├─ 主体矩形 (100×28, borderRadius: 10, boxShadow: color.opacity(.5))
     ├─ 内层圆点 (16×16, 圆形)
     ├─ 内层矩形 (96×24, borderRadius: 8, backColor)
     ├─ 最内圆点 (12×12, 圆形)
     ├─ 核心矩形 (94×22, borderRadius: 8, color)
     │   └─ Row
     │       ├─ SizedBox(w:10)
     │       ├─ AutoSizeText(格局名, maShanZheng, backColor)
     │       └─ Container(印章: ji_xiong_yin_zhang.png, h: outerHeight*.5, w:14)
     ├─ 祥云线左 (12×32, xiang_yun_line_1.png) + scale动画
     ├─ 祥云纹左下 (36×18, xiang_yun_wen_l.png) + moveX动画
     └─ 祥云纹右上 (36×18, xiang_yun_wen_r.png) + moveX动画

颜色 (吉):
  color: RGBA(59, 78, 61, 1) 或 RGBA(32, 50, 54, 1)
  backColor: RGBA(240, 167, 46, 1) 或 RGBA(209, 181, 146, 1)
```

### 8.2 凶格局标签 (GeJuPanelTemplateXiong1)
```
// 用于凶格局和部分特殊格局
size: Size(120, 32)
backgroundColor: RGBA(63, 75, 80, 1)
foregroundColor: RGBA(185, 128, 124, 1)
```

### 8.3 格局标签颜色体系

| 类型 | 主色(color) | 底色(backColor) |
|------|-------------|-----------------|
| 天地盘格局(吉) | RGBA(59,78,61,1) | RGBA(240,167,46,1) |
| 九遁格局 | RGBA(32,50,54,1) | RGBA(209,181,146,1) |
| 诈假格局 | RGBA(25,44,59,1) | RGBA(176,132,88,1) |
| 天地盘格局(凶) | RGBA(63,75,80,1) | RGBA(185,128,124,1) |
| 盘级格局(吉) | RGBA(86,0,79,1) | RGBA(242,190,69,1) |
| 盘级格局(凶)/兵格 | RGBA(130,78,64,1) | RGBA(33,33,33,1) |

---

## 9. 动画系统

### 9.1 主页面动画控制器

```dart
_panScaleController = AnimationController(
  duration: Duration(milliseconds: 400),
  reverseDuration: Duration(milliseconds: 400)
);

_gongAnimationController = AnimationController(
  duration: Duration(milliseconds: 800),
  reverseDuration: Duration(milliseconds: 800)
);

_gongShadowAnimationController = Tween<double>(begin: 0.0, end: 3.0)
    .animate(_gongAnimationController);
```

### 9.2 宫位选中动画

选中宫位时:
1. 宫位从原位置动画移动到左上角 (moveX/moveY, 400ms, Curves.linear)
2. 盘面缩小 (scale 1→0.99, 200ms)
3. 宫位外框阴影渐现 (shadow 0→3)
4. 详情面板从上方滑入 (moveY -128→0, 400ms+, Curves.easeInOutQuint)
5. 详情面板渐显 (fadeIn, 400ms+)

```dart
// 选中宫位的装饰
BoxDecoration(
  color: getGongBackgroundColor(gua, yinYangDun),
  borderRadius: BorderRadius.circular(36),
  boxShadow: [
    BoxShadow(
      color: grey.opacity(shadowValue * .1),
      blurRadius: shadowValue,
      spreadRadius: shadowValue
    )
  ]
)
```

### 9.3 旺衰提示动画 (WangShuaiHint)

```dart
AnimatedContainer(duration: widget.duration)  // 展开/收起
AnimatedSwitcher(duration: widget.duration)    // 内容切换
 └─ SlideTransition(Offset(1,0) → Offset(0,0))  // 从右滑入
     └─ FadeTransition                            // 渐显
```

### 9.4 Lottie动画资源

| 文件 | 用途 | 尺寸 |
|------|------|------|
| `horse_walking.json` | 驿马指示 | 24×24 |
| `arrow_up.json` | 上升箭头 | 16×16 |
| `arrow_down.json` | 下降箭头 | 12×12 / 16×16 |
| `two_down_arrow.json` | 双箭头(相/囚) | 18×18 |
| `three_down_arrow.json` | 三箭头(旺/死) | 14×14 |

---

## 10. 背景内容 (QiMenGongContentBackground)

### 10.1 布局

```
Container (80×80, center)
 └─ Column
     ├─ Flexible(flex: 4) → 星名区
     │   └─ Row(center)
     │       ├─ Expanded(Container)
     │       ├─ Container(星名, 下划线border)
     │       │   └─ AutoSizeText(starName, maxFont:18, minFont:12, fontWeight:w600)
     │       └─ Expanded(Container)
     ├─ Flexible(flex: 12) → 卦象区
     │   └─ Row(center)
     │       ├─ Expanded(Container)
     │       ├─ Flexible(flex:10)
     │       │   └─ EightGuaWidget(yaoSize: Size(56,8), intervalHeight:2, color: grey.opacity(.5))
     │       └─ Expanded(Container)
     └─ Flexible(flex: 4) → 门名区
         └─ Row(center)
             ├─ Expanded(Container)
             ├─ AutoSizeText("「门名」", maxFont:18, minFont:12)
             └─ Expanded(Container)
```

### 10.2 样式覆盖(在EachGongWidget中使用时)

```dart
nineStarsNameTextStyle: pan.isStarFanYin || pan.isStarFuYin
    ? nineStarsNameTextStyle.copyWith(color: Colors.black)  // 反吟/伏吟时加深
    : nineStarsNameTextStyle,

nineGongNameTextStyle: nineGongNameTextStyle.copyWith(
    color: grey.opacity(.6), height: 1, fontWeight: w400,
    shadows: [Shadow(color: grey.opacity(.5), blurRadius: 2)]
),

eightSkyDoorTextStyle: pan.isDoorFanYin || pan.isDoorFuYin
    ? eightSkyDoorTextStyle.copyWith(color: Colors.black)
    : eightSkyDoorTextStyle,
```

**整体透明度**: `Opacity(opacity: .5)` + `Transform.scale(scale: 1)`

---

## 11. 24节气标签 (Season24Tag)

```dart
Container(width: 20, height: 42, borderRadius: 16)
 └─ Container(
      padding: EdgeInsets.symmetric(vertical: 2),
      border: Border.all(color: borderColor, width: isBold ? 2 : 1),
      borderRadius: 16,
      boxShadow: [BoxShadow(color: borderColor.opacity(.2), offset: Offset(1,1), blurRadius: 1)],
      backgroundColor: backgroundColor
    )
     └─ Column → AutoSizeText×N (逐字竖排)

// 字体
fontStyle: GoogleFonts.notoSerif(
    height: 1, fontSize: 14, fontWeight: normal/w600, color: fontColor,
    shadows: [Shadow(color: white.opacity(.2), offset: Offset(1,1), blurRadius: 1)]
)
// AutoSizeText: maxFontSize: 16, minFontSize: 8
```

---

## 12. 十干克应印章 (TenGanKeYingYinZhang)

```dart
Stack(center)
 ├─ SizedBox(48×48)
 │   └─ ColorFiltered(jiXiongColorMapper[jiXiong], srcIn)
 │       └─ Image.asset("assets/icons/yin_zhang.png")
 └─ Container(48×48, padding: EdgeInsets.all(4))
     └─ Row(spaceEvenly)
         ├─ Column(spaceEvenly) → char[2], char[3]
         └─ Column(spaceEvenly) → char[0], char[1]

// 文字
GoogleFonts.maShanZheng(height: 1.0, fontSize: 18, fontWeight: w500, color: white)
// AutoSizeText: maxFontSize: 24, minFontSize: 12
```

---

## 13. 十干克应格局详情 (TenGanKeYingGeJuDetail)

```dart
Column(center, crossAxisAlignment: start)
 ├─ Row(crossAxisAlignment: start)
 │   ├─ Expanded → Column(start, center)
 │   │   ├─ RichText (天盘+地盘格局名)
 │   │   │   style: tianGanTextStyle, 各干对应zodiacGanColors
 │   │   ├─ Divider(height: 4)
 │   │   └─ RichText(格局名列表, 顿号分隔, fontWeight: w600)
 │   ├─ SizedBox(width: 8)
 │   └─ TenGanKeYingYinZhang(48×48, maShanZheng h:1 18px w500 white)
 ├─ SizedBox(height: 8)
 └─ Column(start) → 解释列表
     └─ Text×N (fontWeight: w300, fontSize: 16, height: 1.2)
         间距: SizedBox(height: 8)
```

---

## 14. 数据模型结构

### 14.1 UIEachGongModel (每宫UI模型)

```dart
class UIEachGongModel {
  HouTianGua gua;            // 后天八卦方位
  EachGong gong;              // 宫位数据(星、门、神、天地盘干等)
  EachGongWangShuai gongWangShuai;  // 宫位旺衰信息
  UITenGanKeYingGeJu tenGanKeYingGeJu;  // 十干克应格局
  UIPanMetaModel panMete;     // 盘面元数据
  EachGongGeJu eachGongGeJu;  // 宫位格局(常见格局、九遁等)
  List<QiYiRuGong>? qiYiRuGongList;  // 三奇入宫列表
}
```

### 14.2 UIPanMetaModel (盘面元数据)

```dart
class UIPanMetaModel {
  YinYang yinYangDun;             // 阴阳遁
  EightDoorEnum zhiShiDoor;      // 值使门
  NineStarsEnum zhiFuStar;       // 值符星
  TianGan xunHeaderTianGan;      // 旬首天干
  Tuple2<DiZhi, DiZhi> timeXunKong;  // 时空亡
  DiZhi horseLocation;            // 驿马位
  MonthToken monthToken;          // 月令
}
```

### 14.3 UITenGanKeYingGeJu (十干克应格局UI模型)

```dart
class UITenGanKeYingGeJu {
  TenGanKeYingGeJu tianGeJu;             // 天盘+地盘格局
  TenGanKeYingGeJu? tianPanJiGanGeJu;    // 天盘寄干格局
  TenGanKeYingGeJu? diPanJiGanGeJu;     // 地盘寄干格局
  TenGanKeYingGeJu? tianDiJiGanGeJu;     // 天地寄干格局
  TenGanKeYingGeJu? tianDunJiaGeJu;      // 天盘遁甲格局
  TenGanKeYingGeJu? diDunJiaGeJu;       // 地盘遁甲格局
  TenGanKeYingGeJu? tianJiGanJiaGeJu;    // 天盘寄干甲格局
  TenGanKeYingGeJu? diJiGanJiaGeJu;     // 地盘寄干甲格局
  TenGanKeYingGeJu? tianDiPanGanGeJu;    // 天地盘干格局
  TenGanKeYingGeJu? tianDunJiaDiPanJi;   // 天遁甲+地盘寄
  TenGanKeYingGeJu? tianPanJiGanDiPanJia; // 天盘寄+地盘甲
  TenGanKeYingGeJu? tianDiJiaGanJiaGeJu; // 天地甲干甲格局

  // 判断标志
  bool isTianGanDunJia;      // 天干遁甲
  bool isDiGanDunJia;        // 地干遁甲
  bool isTianJiGanJia;       // 天寄干甲
  bool isDiJiGanJia;         // 地寄干甲
  TianGan? tianPanJiGan;     // 天盘寄干
  TianGan? diPanJiGan;       // 地盘寄干
}
```

### 14.4 QiYiWangShuai (奇仪旺衰Widget参数)

```dart
class QiYiWangShuai {
  TianGan tianGan;
  TwelveZhangSheng monthlyZhangSheng;  // 月令十二长生
  TwelveZhangSheng gongZhangSheng;     // 宫位十二长生
  Size textSize = Size(32, 28);         // 文字区域尺寸
  TextStyle hintTextStyle;  // fontSize:10, w300, black45
  TextStyle textStyle;      // fontSize:24, normal
  bool showHint;
  bool isSixYiJixing;      // 六仪击刑
  bool? isGongRuMuOrKu;    // 入墓/入库
  bool isDunJia;            // 遁甲标记
  bool isYinAnGan;          // 隐暗干标记
}
```

---

## 15. 页面级布局 (ScalableShiJiaQiMenViewPage)

### 15.1 整体结构

```
Scaffold
 ├─ AppBar
 │   ├─ title: RichText("奇门遁甲·时家", panInfoTextStyle)
 │   └─ actions: [AI设置, 人格选择, 更多菜单]
 ├─ endDrawer: Drawer (AI聊天, width: 85%屏幕宽度)
 └─ body: Stack(center)
     ├─ Center → SingleChildScrollView → Column
     │   ├─ PanInfoRow (Consumer<ShiJiaQiMenViewModel>)
     │   ├─ Stack(盘面 + 天门地户标注)
     │   │   ├─ 天门地户人门鬼路 标注
     │   │   └─ Container(panSize.width+36 × panSize.height+36)
     │   │       └─ 九宫盘面
     │   ├─ SizedBox(h: 24)
     │   ├─ Row(操作按钮: 排盘, 清除, 选日期)
     │   ├─ SizedBox(h: 56)
     │   └─ SizedBox(h: 1000)  ← 底部留白
     ├─ GlassLayer (毛玻璃遮罩)
     └─ ValueListenableBuilder(选中宫位详情)
```

### 15.2 操作按钮样式

```dart
ElevatedButton.styleFrom(
  backgroundColor: Colors.white,
  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
  textStyle: TextStyle(fontSize: 18, color: Colors.black87),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
)
```

### 15.3 切换器样式

```dart
switcherInactivatedStyle = TextStyle(fontSize: 16, color: Color(0xff636f7b), height: 1.0);
baseActivatedStyle = TextStyle(
  fontSize: 16, color: Color(0xff636f7b), height: 1.0, fontWeight: w500,
  shadows: [BoxShadow(color: grey.opacity(0.2), blurRadius: 2.0, spreadRadius: 1.0)]
);
zhuanPanActivatedStyle → color: Color(0xff6682c0);  // 转盘蓝
feiPanActivatedStyle → color: Color(0xffdc6c73);    // 飞盘红
```

---

## 16. PrimaryPage（早期原型）

### 16.1 固定尺寸

```dart
每宫: 256×256
盘面: 6 + 256*3 = 774 × 774
边框: Border.all(color: Colors.black, width: 1)
内边距: EdgeInsets.all(8)
```

### 16.2 布局特点

- 使用固定像素值 (256px)
- 背景宫名: fontSize: 96, grey.opacity(.2)
- 天地盘干使用颜色块区分 (白色=天盘, 灰色=隐盘, 黑色=地盘)
- 八神标签: indigoAccent.opacity(.2), borderRadius: 8
- 九星标签: teal.opacity(.2), borderRadius: 8
- 甲子标签: blue[800], borderRadius: 16, boxShadow
- 节气标签: blueAccent.opacity(.2), borderRadius: 8, 24×48

---

## 17. 图片资源清单

| 资源路径 | 用途 | 使用方式 |
|---------|------|---------|
| `assets/icons/yin_zhang.png` | 方形印章底图 | ColorFiltered |
| `assets/icons/long_yin_zhang.png` | 长条印章底图 | ColorFiltered |
| `assets/icons/red-ink-circle.png` | 旬首圆章 | ColorFiltered |
| `assets/icons/thin-black-ink-circle.png` | 空亡圆环 | ColorFiltered |
| `assets/icons/wide-black-ink-line.png` | 值符宽线 | ColorFiltered |
| `assets/icons/wide-black-ink-radian-line2.png` | 值使弧线 | ColorFiltered |
| `assets/icons/red-ink-background.png` | 门宫关系印章底 | ColorFiltered |
| `assets/icons/mu.png` | 入墓标记 | ColorFiltered |
| `assets/icons/ji_xing.png` | 六仪击刑标记 | ColorFiltered |
| `assets/icons/ji_xiong_yin_zhang.png` | 吉凶小印章 | ColorFiltered |
| `assets/icons/xiang_yun_line_1.png` | 祥云线(左上) | ColorFiltered + 动画 |
| `assets/icons/xiang_yun_wen_l.png` | 祥云纹(左下) | ColorFiltered + 动画 |
| `assets/icons/xiang_yun_wen_r.png` | 祥云纹(右上) | ColorFiltered + 动画 |
| `assets/icons/bagua-mirror-64.png` | 八卦镜(原型页) | Opacity(.3) |
| `assets/icons/flash-32.png` | 闪电(八神标签) | 直接使用 |
| `assets/icons/stars-64.png` | 星星(九星标签) | 直接使用 |
| `assets/lotties/horse_walking.json` | 驿马动画 | Lottie |
| `assets/lotties/arrow_up.json` | 上升箭头 | Lottie |
| `assets/lotties/arrow_down.json` | 下降箭头 | Lottie |
| `assets/lotties/two_down_arrow.json` | 双箭头(相/囚) | Lottie |
| `assets/lotties/three_down_arrow.json` | 三箭头(旺/死) | Lottie |

---

## 18. 关键设计模式总结

### 18.1 中国传统美学风格
- 大量使用**水墨风格**图片资源，通过 `ColorFiltered + BlendMode.srcIn` 动态着色
- 印章式标签 (yin_zhang.png) 表达格局吉凶
- 使用中文书法字体 (maShanZheng=马山正, zhiMangXing=志芒星, longCang=隆藏)
- 祥云纹装饰动画
- 阴阳配色对比 (内盘黑底/外盘白底)

### 18.2 响应式设计策略
- `ResizableGongWidget` 通过 `cardSize` 参数驱动所有内部尺寸计算
- `AutoSizeText` 在 `minFontSize` 和 `maxFontSize` 之间自适应
- 当空间不足时 `isHor` 标志自动切换横向/纵向布局
- `paddingSideWidth < 12` 时自动隐藏侧边面板

### 18.3 信息密度管理
- `showHint` 开关控制旺衰/十二长生等辅助信息的显隐
- 动画过渡 (SlideTransition + FadeTransition) 确保信息切换平滑
- 三层Stack叠加: 背景元数据 → 中心卦象 → 前景动态内容
- 选中放大后展示完整解盘信息

### 18.4 动画持续时间约定

| 场景 | 时长 |
|------|------|
| 基础过渡(旺衰提示) | 200ms - 400ms |
| 宫位缩放 | 400ms |
| 宫位选中移动 | 400ms (delay 200ms) |
| 宫位阴影展开 | 800ms |
| 详情面板入场 | 400ms + i*100ms (delay 800ms) |
| 祥云纹动画 | 800ms |
| 格局标签出场 | 200ms |

import 'package:metaphysics_core/enums.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:qimendunjia/domain/entities/each_gong.dart';
import 'package:qimendunjia/domain/entities/ke_jia_ju.dart';
import 'package:qimendunjia/domain/entities/qimen_pan.dart';
import 'package:qimendunjia/domain/entities/ri_jia_ju.dart';
import 'package:qimendunjia/enums/enum_arrange_plate_type.dart';
import 'package:qimendunjia/enums/enum_fu_tou_scheme.dart';
import 'package:qimendunjia/enums/enum_ke_scheme.dart';
import 'package:qimendunjia/enums/enum_qi_men_jia.dart';
import 'package:qimendunjia/presentation/viewmodels/qimen_viewmodel.dart';
import 'package:qimendunjia/redesign_ui/components/palace/brief_palace_config.dart';
import 'package:qimendunjia/redesign_ui/layouts/smart_grid.dart';

/// 多家奇门页面
///
/// 在同一个页面下支持四家排盘，复用既有 [QiMenViewModel]（家维度参数已在 P1-T7 接通）。
///
/// - 时家 / 月家 / 年家：同一组"值符 / 值使 / 三奇六仪 / 八神"语义
/// - 日家：独立机制（飞盘 + day-count 顺飞 + 不布奇仪 + 不用八神 + 以休门为纲），
///   UI 隐藏八神、中5 隐藏门；干字段当前用占位（戊），待后续黄道黑道喜神贵神 Phase
///   接入后再做 UI 精修。
class MultiJiaQiMenPage extends StatefulWidget {
  const MultiJiaQiMenPage({super.key});

  @override
  State<MultiJiaQiMenPage> createState() => _MultiJiaQiMenPageState();
}

class _MultiJiaQiMenPageState extends State<MultiJiaQiMenPage> {
  QiMenJia _jia = QiMenJia.SHI;
  ArrangeType _arrangeType = ArrangeType.CHAI_BU;
  KeSchemeType _keScheme = KeSchemeType.TEN_KE_WU_ZI_JIAN_YUAN;
  FuTouSchemeType _fuTouScheme = FuTouSchemeType.JIA_JI_FU_TOU;
  final PlateType _plateType = PlateType.ZHUAN_PAN;
  DateTime _selectedDateTime = DateTime.now();

  /// 后天八卦的网格顺序：从左上到右下
  /// 4 9 2 / 3 5 7 / 8 1 6（洛书三阶幻方）
  static const List<HouTianGua> _gridOrderedGuas = [
    HouTianGua.Xun,
    HouTianGua.Li,
    HouTianGua.Kun,
    HouTianGua.Zhen,
    HouTianGua.Center,
    HouTianGua.Dui,
    HouTianGua.Gen,
    HouTianGua.Kan,
    HouTianGua.Qian,
  ];

  Future<void> _arrange() async {
    await context.read<QiMenViewModel>().calculateAndArrangePan(
          dateTime: _selectedDateTime,
          jia: _jia,
          arrangeType: _arrangeType,
          plateType: _plateType,
          keScheme: _jia == QiMenJia.KE ? _keScheme : null,
          fuTouScheme: _jia == QiMenJia.KE ? _fuTouScheme : null,
        );
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(1864),
      lastDate: DateTime(2099),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
    );
    if (time == null || !mounted) return;
    setState(() {
      _selectedDateTime = DateTime(
          date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('多家奇门'),
        actions: [
          IconButton(
            tooltip: '说明',
            icon: const Icon(Icons.info_outline),
            onPressed: _showInfoSheet,
          ),
        ],
      ),
      body: Consumer<QiMenViewModel>(
        builder: (context, vm, _) {
          return Column(
            children: [
              _buildControlBar(),
              if (vm.isLoading) const LinearProgressIndicator(),
              if (vm.hasError)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  color: Colors.red.shade50,
                  child: Text(
                    '错误：${vm.errorMessage ?? "未知"}',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              if (vm.hasData) ...[
                _buildPanInfoCard(vm.currentPan!),
                Expanded(child: _buildGrid(vm.currentPan!)),
              ] else
                const Expanded(
                  child: Center(child: Text('选择家与时间，点击"起盘"')),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildControlBar() {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 家选择
            Row(
              children: [
                const Text('家：', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SegmentedButton<QiMenJia>(
                      segments: const [
                        ButtonSegment(value: QiMenJia.SHI, label: Text('时家')),
                        ButtonSegment(value: QiMenJia.KE, label: Text('刻家')),
                        ButtonSegment(value: QiMenJia.RI, label: Text('日家')),
                        ButtonSegment(value: QiMenJia.YUE, label: Text('月家')),
                        ButtonSegment(value: QiMenJia.NIAN, label: Text('年家')),
                      ],
                      selected: {_jia},
                      onSelectionChanged: (s) {
                        setState(() {
                          _jia = s.first;
                          // 切换家时重置起局法到默认（CHAI_BU）
                          // - 时家：CHAI_BU 即拆补法
                          // - 刻家：所有 ArrangeType 等价（内部固定用拆补法起本时辰初局）
                          // - 月家：CHAI_BU 映射到粗分（5年一局）
                          // - 年家 / 日家：所有 ArrangeType 等价
                          _arrangeType = ArrangeType.CHAI_BU;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // 起局法（时家 4 种 / 月家 2 种 / 年家无选择）
            if (_jia == QiMenJia.SHI)
              _buildArrangeTypeSelector(
                label: '起局法',
                options: const [
                  ArrangeType.CHAI_BU,
                  ArrangeType.ZHI_RUN,
                  ArrangeType.MAO_SHAN,
                  ArrangeType.YIN_PAN,
                ],
                labelOf: (t) => t.name,
              ),
            if (_jia == QiMenJia.YUE)
              _buildArrangeTypeSelector(
                label: '定局法',
                options: const [
                  ArrangeType.CHAI_BU,
                  ArrangeType.ZHI_RUN,
                ],
                labelOf: (t) => t == ArrangeType.CHAI_BU
                    ? '粗分（5年一局）'
                    : '细分（10月一局）',
              ),
            if (_jia == QiMenJia.KE) _buildKeSchemeSelector(),
            if (_jia == QiMenJia.KE) _buildFuTouSchemeSelector(),
            const SizedBox(height: 8),
            // 时间 + 起盘
            Row(
              children: [
                const Text('时间：',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_month, size: 18),
                    label: Text(DateFormat('yyyy-MM-dd HH:mm')
                        .format(_selectedDateTime)),
                    onPressed: _pickDateTime,
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  icon: const Icon(Icons.calculate, size: 18),
                  label: const Text('起盘'),
                  onPressed: _arrange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArrangeTypeSelector({
    required String label,
    required List<ArrangeType> options,
    required String Function(ArrangeType) labelOf,
  }) {
    return Row(
      children: [
        Text('$label：',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(width: 8),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: options
                  .map((t) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(labelOf(t)),
                          selected: _arrangeType == t,
                          onSelected: (s) {
                            if (s) {
                              setState(() => _arrangeType = t);
                            }
                          },
                        ),
                      ))
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKeSchemeSelector() {
    return Row(
      children: [
        const Text('刻制：',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(width: 8),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: KeSchemeType.values
                  .map((s) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(s.name),
                          selected: _keScheme == s,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _keScheme = s);
                            }
                          },
                        ),
                      ))
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFuTouSchemeSelector() {
    return Row(
      children: [
        const Text('符头：',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(width: 8),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: FuTouSchemeType.values
                  .map((s) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(s.name),
                          selected: _fuTouScheme == s,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _fuTouScheme = s);
                            }
                          },
                        ),
                      ))
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPanInfoCard(QiMenPan pan) {
    final shiJia = pan.shiJiaJu; // 时家专用 nullable
    final riJia = pan.ju is RiJiaJu ? pan.ju as RiJiaJu : null;
    final keJia = pan.ju is KeJiaJu ? pan.ju as KeJiaJu : null;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 16,
              runSpacing: 4,
              children: [
                _kv('家', pan.ju.jia.name),
                _kv('盘类型', pan.plateType.name),
                _kv('局数', _jiaJuDescription(pan)),
                _kv('阴阳遁', pan.ju.yinYangDun.isYang ? '阳遁' : '阴遁'),
                if (shiJia != null) ...[
                  _kv('旬首', shiJia.fuTouJiaZi.name),
                  _kv('节气', shiJia.jieQiAt.name),
                ],
                if (keJia != null) ...[
                  // 刻家专属：刻干支 / 刻局序号 / 时辰初局 / 节气 / 符头三元
                  _kv('时柱', keJia.shiJiaZi.name),
                  _kv('刻柱', keJia.keJiaZi.name),
                  _kv('刻制', keJia.keScheme.name),
                  _kv('刻序', '第${keJia.keIndex}刻 / ${keJia.totalKeCount}'),
                  _kv('初局', '${keJia.initJuNumber}局'),
                  _kv('旬首', keJia.fuTouJiaZi.name),
                  _kv('三元', keJia.atThreeYuan.name),
                  _kv('节气', keJia.jieQiAt.name),
                ],
                if (riJia != null) ...[
                  // 日家专属：日柱 / 节气 / 休门宫 + 距甲子日天数
                  _kv('日柱', riJia.dayJiaZi.name),
                  _kv('节气', riJia.jieQiAt.name),
                  _kv('休门宫',
                      '${riJia.xiuMenGong.name}${riJia.xiuMenGong.houTianOrder}'),
                  _kv('距甲子', 'd=${riJia.daysSinceJiaZi}'),
                ],
                if (riJia == null)
                  // 日家无值符 / 值使概念 — 仅在非日家时展示
                  _kv('值符', '${pan.zhiFuStar.name}@${pan.zhiFuStarAtGong.name}'),
                if (riJia == null)
                  _kv('值使',
                      '${pan.zhiShiDoor.name}@${pan.zhiShiDoorAtGong.name}'),
                if (riJia != null)
                  // 日家：以太乙落点为"日主星"、休门为纲
                  _kv('日主星',
                      '${pan.zhiFuStar.name}@${pan.zhiFuStarAtGong.name}'),
              ],
            ),
            // 日家神煞 / 时辰吉凶分析(§3-§7)
            if (riJia != null) ...[
              const Divider(height: 16),
              _buildRiJiaAnalysisRow(riJia),
            ],
          ],
        ),
      ),
    );
  }

  /// 日家神煞 / 时辰吉凶分析渲染
  Widget _buildRiJiaAnalysisRow(RiJiaJu riJia) {
    final analysis = riJia.dayAnalysis;
    final xiShen = analysis.xiShenDirection;
    final tianYi =
        analysis.tianYiGuiRenZhi.map((z) => '${z.name}时').join('、');
    final wuBuYu = analysis.wuBuYuShiZhi.map((z) => '${z.name}时').join('、');
    final jieLu = analysis.jieLuKongWangZhi.map((z) => '${z.name}时').join('、');
    return Wrap(
      spacing: 16,
      runSpacing: 4,
      children: [
        _kv('喜神方位', '${xiShen.name}${xiShen.houTianOrder} (${_directionOf(xiShen)})'),
        _kv('天乙贵人', tianYi),
        _kv('五不遇时', wuBuYu),
        _kv('截路空亡', jieLu),
      ],
    );
  }

  /// 后天八卦 → 方位文字
  String _directionOf(HouTianGua gua) {
    switch (gua) {
      case HouTianGua.Kan:
        return '北';
      case HouTianGua.Gen:
        return '东北';
      case HouTianGua.Zhen:
        return '东';
      case HouTianGua.Xun:
        return '东南';
      case HouTianGua.Li:
        return '南';
      case HouTianGua.Kun:
        return '西南';
      case HouTianGua.Dui:
        return '西';
      case HouTianGua.Qian:
        return '西北';
      case HouTianGua.Center:
        return '中';
    }
  }

  String _jiaJuDescription(QiMenPan pan) {
    final shiJia = pan.shiJiaJu;
    if (shiJia != null) return shiJia.juDescription;
    final ju = pan.ju;
    if (ju is KeJiaJu) return ju.juDescription;
    if (ju is RiJiaJu) return ju.juDescription;
    // 月家 / 年家：从 ju 的 fourZhuEightChar 提取家级简介
    return '${ju.jia.name}·${ju.juNumber}局';
  }

  Widget _kv(String k, String v) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$k：',
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
        Text(v, style: const TextStyle(fontSize: 13)),
      ],
    );
  }

  /// 构造时家 / 刻家中5的占位 EachGong
  ///
  /// ShiJiaQiMen 排盘内部跳过中5 EachGong（中5只通过寄宫处理），
  /// 故 [QiMenPan.gongMapper] 在中5位置为 null。
  /// redesign UI 的 `brief_palace_layout` 在 `isCenter && !isFeipan` 时走
  /// `_buildCenterHub` 元数据 hub 渲染（仅读 gongEnum / marks / geJu），
  /// 不读星/门/干/神字段，故全部从已有宫位复用是安全的。
  EachGong _placeholderCenterGong(QiMenPan pan) {
    final any = pan.gongMapper.values.first;
    return any.copyWith(
      gongNumber: 5,
      gongGua: HouTianGua.Center,
    );
  }

  Widget _buildGrid(QiMenPan pan) {
    // 月家 / 年家：中5寄坤2，且"只寄星不寄门"——中5 不渲染门和神
    final isYueOrNian = pan.ju.jia == QiMenJia.YUE || pan.ju.jia == QiMenJia.NIAN;
    // 日家：不用八神（占位 ZHI_FU 是无意义的）— 全宫隐藏八神；中5 也无门
    final isRiJia = pan.ju.jia == QiMenJia.RI;
    // 飞盘家(日/月/年):中宫走"正常宫位渲染"路径(显示九星);
    // 时家中宫保持"元数据 hub"展示(_buildCenterHub)
    final isFeipan = isRiJia || isYueOrNian;

    final palaceData = _gridOrderedGuas.map((gua) {
      final isCenter = gua == HouTianGua.Center;
      // 月年家中5 不渲染门 / 神；日家中5 不渲染门
      final hideDoor = (isYueOrNian && isCenter) || (isRiJia && isCenter);
      // 月年家中5 不渲染神;日家全宫不渲染神（不用八神 → 占位无意义）
      final hideGod = (isYueOrNian && isCenter) || isRiJia;

      // 时家 / 刻家：ShiJiaQiMen 内部跳过中5 EachGong 生成，仅用 settleCenterGongJiGong
      // 把中宫干寄到坤2/艮8。redesign UI 在 isCenter && !isFeipan 时走 _buildCenterHub
      // 元数据 hub 渲染（不读 PalaceData 的星/门/干/神字段），故占位安全。
      final gong = pan.gongMapper[gua] ?? _placeholderCenterGong(pan);

      return PalaceData.fromEachGong(
        gong,
        isYangDun: pan.ju.yinYangDun.isYang,
        geJu: const [],
        marks: [
          if (pan.zhiFuStarAtGong == gua)
            isRiJia ? '日主' : '值符',
          if (pan.zhiShiDoorAtGong == gua && !isRiJia) '值使',
          // 日家以休门为纲，将休门宫单独标记
          if (isRiJia && pan.zhiShiDoorAtGong == gua) '休门纲',
        ],
        xunHeaderGan: TianGan.JIA, // 月年家无旬首；用 JIA 占位
        showDoor: !hideDoor,
        showGod: !hideGod,
      );
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(8),
      child: SmartQiMenGrid(
        palaces: palaceData,
        onPalaceTap: (_) {},
        // 飞盘家中宫走正常宫位渲染（显示九星）;时家保持元数据 hub
        // 日家不布三奇六仪 → 干字段全为占位戊,UI 隐藏天地盘干列
        briefConfig: BriefPalaceConfig(
          isFeipan: isFeipan,
          showGan: !isRiJia,
        ),
      ),
    );
  }

  void _showInfoSheet() {
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('多家奇门说明',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('• 时家：转盘排宫，一时辰一局，阴阳遁均用；起局法可选拆补 / 置润 / 茅山 / 阴盘'),
            Text('• 刻家：时家细分；可选两种刻制——'
                '十刻五子建元（10刻×12分）/ 八刻五马遁（8刻×15分）；'
                '初局沿用本时辰时家局，二局起阳顺阴逆推移；'
                '用刻干支替代时干支推值符 / 值使，刻干阴阳决定八门顺逆'),
            Text('• 日家：飞盘 day-count 顺飞，一日一星；以休门为纲、太乙为日主星；'
                '阴阳遁均用；不布奇仪、不用八神（用黄道黑道喜神贵神，待后续 Phase）'),
            Text('• 月家：飞盘逆飞，恒阴遁；定局法可选粗分（5年一局）/ 细分（10月一局）'),
            Text('• 年家：飞盘逆飞，一年一局，恒阴遁；180 年大三元（1864 起算）'),
            SizedBox(height: 8),
            Text('• 月家 = 年家排盘机制完全一致，仅时间尺度与起局映射不同',
                style: TextStyle(color: Colors.grey)),
            Text('• 日家中5 也填星（与月年家"中5寄坤2"不同）；中5 无门、全盘无八神',
                style: TextStyle(color: Colors.grey)),
            Text('• 日家干字段当前为占位（戊），UI 精修待黄道黑道喜神贵神 Phase',
                style: TextStyle(color: Colors.orange)),
          ],
        ),
      ),
    );
  }
}

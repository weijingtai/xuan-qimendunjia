import 'package:common/enums.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:qimendunjia/domain/entities/qimen_pan.dart';
import 'package:qimendunjia/enums/enum_arrange_plate_type.dart';
import 'package:qimendunjia/enums/enum_qi_men_jia.dart';
import 'package:qimendunjia/presentation/viewmodels/qimen_viewmodel.dart';
import 'package:qimendunjia/redesign_ui/layouts/smart_grid.dart';

/// 多家奇门页面
///
/// 在同一个页面下支持时家 / 月家 / 年家三种排盘，复用既有
/// [QiMenViewModel]（家维度参数已在 P1-T7 接通）。
///
/// 日家因排盘机制独立（飞盘 + day-count + 无值符值使 + 不用八神），
/// 与上述三家展示路径差异较大，本页暂不接入；后续 Phase 2 单独成页。
class MultiJiaQiMenPage extends StatefulWidget {
  const MultiJiaQiMenPage({super.key});

  @override
  State<MultiJiaQiMenPage> createState() => _MultiJiaQiMenPageState();
}

class _MultiJiaQiMenPageState extends State<MultiJiaQiMenPage> {
  QiMenJia _jia = QiMenJia.SHI;
  ArrangeType _arrangeType = ArrangeType.CHAI_BU;
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
                  child: SegmentedButton<QiMenJia>(
                    segments: const [
                      ButtonSegment(value: QiMenJia.SHI, label: Text('时家')),
                      ButtonSegment(value: QiMenJia.YUE, label: Text('月家')),
                      ButtonSegment(value: QiMenJia.NIAN, label: Text('年家')),
                    ],
                    selected: {_jia},
                    onSelectionChanged: (s) {
                      setState(() {
                        _jia = s.first;
                        // 月/年家不分起局法；强制 CHAI_BU 占位
                        if (_jia != QiMenJia.SHI) {
                          _arrangeType = ArrangeType.CHAI_BU;
                        }
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // 起局法（仅时家可选）
            if (_jia == QiMenJia.SHI)
              Row(
                children: [
                  const Text('起局法：',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: ArrangeType.values
                            .where((t) => t != ArrangeType.MANUALLY)
                            .map((t) => Padding(
                                  padding:
                                      const EdgeInsets.only(right: 8),
                                  child: ChoiceChip(
                                    label: Text(t.name),
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
              ),
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

  Widget _buildPanInfoCard(QiMenPan pan) {
    final shiJia = pan.shiJiaJu; // 时家专用 nullable
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
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
            _kv('值符', '${pan.zhiFuStar.name}@${pan.zhiFuStarAtGong.name}'),
            _kv('值使', '${pan.zhiShiDoor.name}@${pan.zhiShiDoorAtGong.name}'),
          ],
        ),
      ),
    );
  }

  String _jiaJuDescription(QiMenPan pan) {
    final shiJia = pan.shiJiaJu;
    if (shiJia != null) return shiJia.juDescription;
    // 月家 / 年家：从 ju 的 fourZhuEightChar 提取家级简介
    return '${pan.ju.jia.name}·${pan.ju.juNumber}局';
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

  Widget _buildGrid(QiMenPan pan) {
    final palaceData = _gridOrderedGuas.map((gua) {
      final gong = pan.gongMapper[gua];
      // GanZhiDrivenQiMenPan 与 ShiJiaQiMen 都已为 9 宫提供 EachGong（中5寄坤2）
      return PalaceData.fromEachGong(
        gong!,
        isYangDun: pan.ju.yinYangDun.isYang,
        geJu: const [],
        marks: [
          if (pan.zhiFuStarAtGong == gua) '值符',
          if (pan.zhiShiDoorAtGong == gua) '值使',
        ],
        xunHeaderGan: TianGan.JIA, // 月年家无旬首；用 JIA 占位
      );
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(8),
      child: SmartQiMenGrid(
        palaces: palaceData,
        onPalaceTap: (_) {},
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
            Text('• 月家：飞盘逆飞，一月一局，恒阴遁；按年支孟仲季三元起局'),
            Text('• 年家：飞盘逆飞，一年一局，恒阴遁；180 年大三元（1864 起算）'),
            SizedBox(height: 8),
            Text('• 月家 = 年家排盘机制完全一致，仅时间尺度与起局映射不同',
                style: TextStyle(color: Colors.grey)),
            Text('• 日家排盘机制独立（无值符值使、不布奇仪），暂未接入',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

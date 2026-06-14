import 'dart:async';

import 'package:metaphysics_core/enums.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import 'package:ai_core/ai/ai_chat_event.dart';
import 'package:ai_core/ai_core.dart' hide AiPersona;
import 'package:ai_core/ai/ai_persona.dart';
import 'package:qimendunjia/ai/pan_serializer.dart';
import 'package:qimendunjia/presentation/viewmodels/qimen_viewmodel.dart';
import 'package:qimendunjia/enums/enum_arrange_plate_type.dart';
import 'package:qimendunjia/enums/enum_nine_stars.dart';
import 'package:qimendunjia/enums/enum_eight_door.dart';
import 'package:qimendunjia/enums/enum_eight_gods.dart';
import 'package:qimendunjia/ai/pan_display_config.dart';
import 'package:qimendunjia/domain/entities/qimen_pan.dart';
import 'package:qimendunjia/redesign_ui/layouts/smart_grid.dart';
import 'package:qimendunjia/redesign_ui/components/palace/brief_palace_config.dart';
import 'package:qimendunjia/redesign_ui/core/design_system.dart';
import 'package:board_datetime_picker/board_datetime_picker.dart';
import 'package:intl/intl.dart';

/// 奇门遁甲 MVVM 架构页面
///
/// 使用新的 MVVM+UseCase 架构实现
class QiMenMvvmPage extends StatefulWidget {
  const QiMenMvvmPage({super.key});

  @override
  State<QiMenMvvmPage> createState() => _QiMenMvvmPageState();
}

class _QiMenMvvmPageState extends State<QiMenMvvmPage> {
  static final _log = Logger('QiMenMvvmPage');

  DateTime? _selectedDateTime;
  ArrangeType _arrangeType = ArrangeType.CHAI_BU;
  PlateType _plateType = PlateType.ZHUAN_PAN;
  AiPersona? _selectedPersona;
  StreamSubscription<AiChatEvent>? _chatEventSub;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _chatEventSub ??= _trySubscribeChatEvents();
  }

  StreamSubscription<AiChatEvent>? _trySubscribeChatEvents() {
    try {
      final aiService = context.read<AiService>();
      _log.info('[_trySubscribeChatEvents] subscribing to chatEvents stream');
      debugPrint('📡 [QiMenMvvmPage] subscribing to chatEvents');
      return aiService.chatEvents.listen((event) {
        debugPrint('📡 [QiMenMvvmPage] received event: ${event.runtimeType}');
        if (event is! ToolResultEvent) return;
        debugPrint(
            '📡 [QiMenMvvmPage] ToolResultEvent: tool="${event.toolName}", hasError=${event.resultData.containsKey("error")}');
        if (event.toolName != 'qimen_tools') return;
        if (event.resultData.containsKey('error')) return;

        _log.info(
            '[chatEvents] received qimen_tools result, session=${event.sessionUuid}');
        try {
          final pan = PanSerializer.fromMap(event.resultData);
          _log.info(
              '[chatEvents] deserialized pan: ${pan.brief}, loading into ViewModel');
          debugPrint('📡 [QiMenMvvmPage] loadExternalPan: ${pan.brief}');
          context.read<QiMenViewModel>().loadExternalPan(pan);
        } catch (e) {
          _log.warning('[chatEvents] failed to deserialize pan: $e');
          debugPrint('📡 [QiMenMvvmPage] deserialize FAILED: $e');
        }
      });
    } catch (e) {
      _log.fine('[_trySubscribeChatEvents] AiService not available: $e');
      debugPrint('📡 [QiMenMvvmPage] AiService not available: $e');
      return null;
    }
  }

  @override
  void dispose() {
    _chatEventSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    AiService? aiService;
    try {
      aiService = context.read<AiService>();
    } catch (_) {}

    return Scaffold(
      endDrawer: aiService != null
          ? Builder(
              builder: (ctx) {
                final vm = ctx.read<QiMenViewModel>();
                return Drawer(
                  width: MediaQuery.of(context).size.width * 0.85,
                  child: KeyedSubtree(
                    key: ValueKey(vm.currentPan?.id ?? 'no-pan'),
                    child: aiService!.buildChatView(
                      ctx,
                      initialContext: vm.buildAiContext(),
                      persona: _selectedPersona,
                    ),
                  ),
                );
              },
            )
          : null,
      appBar: AppBar(
        title: const Text('奇门遁甲·MVVM架构'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              _showArchitectureInfo(context);
            },
          ),
          if (aiService != null)
            Consumer<QiMenViewModel>(
              builder: (context, vm, _) {
                if (!vm.hasData) return const SizedBox.shrink();
                return IconButton(
                  icon: const Icon(Icons.tune),
                  tooltip: 'AI 上下文设置',
                  onPressed: () => _showDisplayConfigSheet(context, vm),
                );
              },
            ),
          if (aiService != null)
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.psychology),
                onPressed: () async {
                  final persona = await aiService!.showPersonaSelector(
                    context: context,
                  );
                  if (persona != null) {
                    setState(() {
                      _selectedPersona = persona;
                    });
                    if (context.mounted) {
                      Scaffold.of(context).openEndDrawer();
                    }
                  }
                },
              ),
            ),
        ],
      ),
      body: Consumer<QiMenViewModel>(
        builder: (context, viewModel, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 架构标识卡片
                _buildArchitectureCard(),
                const SizedBox(height: 24),

                // 配置区域
                _buildConfigSection(viewModel),
                const SizedBox(height: 24),

                // 操作按钮
                _buildActionButtons(viewModel),
                const SizedBox(height: 24),

                // 状态显示
                _buildStateSection(viewModel),
                const SizedBox(height: 24),

                // 盘信息显示
                if (viewModel.currentPan != null) _buildPanInfo(viewModel),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildArchitectureCard() {
    return Card(
      color: Colors.blue.shade50,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.architecture, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Text(
                  'MVVM + UseCase 架构',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              '✓ Domain层: Entity + Repository接口 + UseCase业务逻辑\n'
              '✓ Data层: Repository实现 + DataSource数据源\n'
              '✓ Presentation层: ViewModel + View UI',
              style: TextStyle(fontSize: 12, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigSection(QiMenViewModel viewModel) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '排盘配置',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            const SizedBox(height: 8),

            // 时间选择
            Row(
              children: [
                const Text('起盘时间：'),
                Expanded(
                  child: Text(
                    _selectedDateTime != null
                        ? DateFormat('yyyy-MM-dd HH:mm')
                            .format(_selectedDateTime!)
                        : '未选择',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final result = await showBoardDateTimePicker(
                      context: context,
                      pickerType: DateTimePickerType.datetime,
                    );
                    if (result != null) {
                      setState(() {
                        _selectedDateTime = result;
                      });
                    }
                  },
                  child: const Text('选择时间'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 起盘方式
            const Text('起盘方式：'),
            Wrap(
              spacing: 8,
              children: ArrangeType.values.map((type) {
                return ChoiceChip(
                  label: Text(type.name),
                  selected: _arrangeType == type,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _arrangeType = type;
                      });
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // 盘类型
            const Text('盘类型：'),
            Wrap(
              spacing: 8,
              children: PlateType.values.map((type) {
                return ChoiceChip(
                  label: Text(type.name),
                  selected: _plateType == type,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _plateType = type;
                      });
                    }
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(QiMenViewModel viewModel) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton.icon(
          onPressed: viewModel.isLoading
              ? null
              : () async {
                  final dateTime = _selectedDateTime ?? DateTime.now();
                  await viewModel.calculateAndArrangePan(
                    dateTime: dateTime,
                    arrangeType: _arrangeType,
                    plateType: _plateType,
                  );
                },
          icon: const Icon(Icons.calculate),
          label: const Text('排盘'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          ),
        ),
        OutlinedButton.icon(
          onPressed: viewModel.isLoading
              ? null
              : () {
                  viewModel.reset();
                  setState(() {
                    _selectedDateTime = null;
                  });
                },
          icon: const Icon(Icons.clear),
          label: const Text('清除'),
        ),
      ],
    );
  }

  Widget _buildStateSection(QiMenViewModel viewModel) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  '当前状态：',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                _buildStateIndicator(viewModel.state),
              ],
            ),
            if (viewModel.isLoading) ...[
              const SizedBox(height: 16),
              const LinearProgressIndicator(),
            ],
            if (viewModel.hasError) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        viewModel.errorMessage ?? '未知错误',
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStateIndicator(QiMenViewState state) {
    Color color;
    String text;
    IconData icon;

    switch (state) {
      case QiMenViewState.initial:
        color = Colors.grey;
        text = '初始';
        icon = Icons.radio_button_unchecked;
        break;
      case QiMenViewState.calculating:
        color = Colors.orange;
        text = '计算局数中';
        icon = Icons.calculate;
        break;
      case QiMenViewState.arranging:
        color = Colors.blue;
        text = '排盘中';
        icon = Icons.grid_on;
        break;
      case QiMenViewState.loadingGongDetail:
        color = Colors.purple;
        text = '加载宫位详情中';
        icon = Icons.info;
        break;
      case QiMenViewState.success:
        color = Colors.green;
        text = '成功';
        icon = Icons.check_circle;
        break;
      case QiMenViewState.error:
        color = Colors.red;
        text = '错误';
        icon = Icons.error;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildPanInfo(QiMenViewModel viewModel) {
    final pan = viewModel.currentPan!;
    final ju = viewModel.currentJu!;
    final config = viewModel.displayConfig;

    // 将 QiMenPan 数据转换为 SmartQiMenGrid 所需的 PalaceData 列表
    final palaceDataList = _buildPalaceDataList(pan, config);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── 盘头信息 ──────────────────────────────────────────────────
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Wrap(
              spacing: 24,
              runSpacing: 4,
              children: [
                _buildInfoRow('盘类型', pan.plateType.name ?? '未知'),
                _buildInfoRow('局数', ju.juDescription ?? '未知'),
                _buildInfoRow('旬首', ju.fuTouJiaZi.name ?? '未知'),
                _buildInfoRow('节气', ju.jieQiAt.name ?? '未知'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // ── 九宫格（简介模式） ──────────────────────────────────────
        Center(
          child: Container(
            decoration: BoxDecoration(
              color: ColorSystem.surface,
              borderRadius: QiMenRadius.lg,
              boxShadow: [Shadows.md],
            ),
            padding: const EdgeInsets.all(12),
            child: SmartQiMenGrid(
              palaces: palaceDataList,
              selectedIndex: viewModel.selectedGong == null
                  ? null
                  : _gridOrderedGuas.indexOf(viewModel.selectedGong!.gongGua),
              briefConfig: BriefPalaceConfig(
                showDiGod: config.showDiGod,
                showYinGan: config.showYinGan,
                showAnGan: config.showAnGan,
                showSimpleLayout: config.showSimpleLayout,
                isFeipan: pan.plateType == PlateType.FEI_PAN,
              ),
              onPalaceTap: (index) {
                final gua = _gridOrderedGuas[index];
                final gong = pan.gongMapper[gua];
                if (gong != null) viewModel.selectGong(gong);
              },
            ),
          ),
        ),
        const SizedBox(height: 16),

        // ── 选中宫位详情 ──────────────────────────────────────────────
        if (viewModel.selectedGong != null) _buildSelectedGongCard(viewModel),
      ],
    );
  }

  /// 选中宫位详情卡片
  Widget _buildSelectedGongCard(QiMenViewModel viewModel) {
    final gong = viewModel.selectedGong!;
    final detail = viewModel.gongDetailInfo;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '${gong.gongGua.name}宫',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Text(
                  '${gong.star.name} · ${gong.door.name} · ${gong.god.name}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: viewModel.unselectGong,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 4,
              children: [
                _buildInfoRow('天盘干', gong.tianPan.name),
                _buildInfoRow('地盘干', gong.diPan.name),
                _buildInfoRow('地盘八神', gong.diGod.name),
              ],
            ),
            if (viewModel.isLoading) ...[
              const SizedBox(height: 8),
              const LinearProgressIndicator(),
            ],
            if (detail != null) ...[
              const Divider(height: 20),
              if (detail.tenGanKeYing != null)
                Text(detail.tenGanKeYing!.tianDiKeYing.shortExplain,
                    style: const TextStyle(fontSize: 12)),
              if (detail.doorStarKeYing != null)
                Text(detail.doorStarKeYing!.description,
                    style: const TextStyle(fontSize: 12)),
            ],
          ],
        ),
      ),
    );
  }

  // ── 排盘数据转换 ────────────────────────────────────────────────────────────

  /// 九宫格显示顺序（左上到右下，行优先）
  static const List<HouTianGua> _gridOrderedGuas = [
    HouTianGua.Xun, // 0: 巽4
    HouTianGua.Li, // 1: 离9
    HouTianGua.Kun, // 2: 坤2
    HouTianGua.Zhen, // 3: 震3
    HouTianGua.Center, // 4: 中5
    HouTianGua.Dui, // 5: 兑7
    HouTianGua.Gen, // 6: 艮8
    HouTianGua.Kan, // 7: 坎1
    HouTianGua.Qian, // 8: 乾6
  ];

  /// 将 [QiMenPan] 转换为 [PalaceData] 列表（按网格顺序）
  List<PalaceData> _buildPalaceDataList(QiMenPan pan, PanDisplayConfig config) {
    // 时家盘才有"旬空"概念（依赖 fuTouJiaZi）；非时家盘退化为无空亡
    final shiJiaJu = pan.shiJiaJu;
    final kongWangSet = <DiZhi>{};
    if (shiJiaJu != null) {
      final kongWang = shiJiaJu.fuTouJiaZi.getKongWang();
      kongWangSet.addAll([kongWang.item1, kongWang.item2]);
    }

    final xunHeaderGan = pan.gongMapper.values
        .map((g) => g.sixJiaXunHeader?.gan)
        .firstWhere((gan) => gan != null, orElse: () => null);

    return _gridOrderedGuas.map((gua) {
      final gong = pan.gongMapper[gua];
      if (gong == null) {
        return PalaceData(
          gongEnum: gua,
          number: gua.houTianOrder.toString(),
          starEnum: NineStarsEnum.PENG,
          doorEnum: EightDoorEnum.XIU,
          godEnum: EightGodsEnum.ZHI_FU,
          tianPanGanEnum: TianGan.WU,
          diPanGanEnum: TianGan.JI,
          diZhi: '',
          wangShuai: '',
          jiXiong: 'N/A',
          geJu: const [],
          isYangDun: true,
        );
      }

      final isYiMa = gong.gongGua.diZhi1 == pan.horseLocation ||
          gong.gongGua.diZhi2 == pan.horseLocation;
      final isKongWang = kongWangSet.contains(gong.gongGua.diZhi1) ||
          (gong.gongGua.diZhi2 != null &&
              kongWangSet.contains(gong.gongGua.diZhi2));

      final marks = <String>[
        if (isYiMa) '驿马',
        if (isKongWang) '空亡',
        if (gong.sixJiaXunHeader != null) '旬首',
        if (pan.zhiFuStarAtGong == gua) '值符',
      ];

      return PalaceData.fromEachGong(
        gong,
        isYangDun: pan.ju.yinYangDun.isYang,
        geJu: const [],
        marks: marks,
        xunHeaderGan: xunHeaderGan ??
            shiJiaJu?.fuTouJiaZi.xunHeader.gan ??
            TianGan.JIA, // 非时家盘无旬首概念，回退甲
      );
    }).toList();
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label：',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ),
        ],
      ),
    );
  }

  void _showDisplayConfigSheet(BuildContext context, QiMenViewModel viewModel) {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            var config = viewModel.displayConfig;
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'AI 上下文可选字段',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '选择发送给 AI 的可选盘信息',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const Divider(),
                  CheckboxListTile(
                    title: const Text('简版显示'),
                    subtitle: const Text('宫位内元素使用单字显示（如：天蓬->蓬、休门->休）'),
                    value: config.showSimpleLayout,
                    onChanged: (v) {
                      viewModel.updateDisplayConfig(
                          config.copyWith(showSimpleLayout: v));
                      setSheetState(() {
                        config = viewModel.displayConfig;
                      });
                    },
                  ),
                  const Divider(),
                  CheckboxListTile(
                    title: const Text('暗干'),
                    subtitle: const Text('阴盘奇门中的天盘/人盘暗干'),
                    value: config.showAnGan,
                    onChanged: (v) {
                      viewModel
                          .updateDisplayConfig(config.copyWith(showAnGan: v));
                      setSheetState(() {
                        config = viewModel.displayConfig;
                      });
                    },
                  ),
                  CheckboxListTile(
                    title: const Text('隐干'),
                    subtitle: const Text('特殊流派使用的隐干信息'),
                    value: config.showYinGan,
                    onChanged: (v) {
                      viewModel
                          .updateDisplayConfig(config.copyWith(showYinGan: v));
                      setSheetState(() {
                        config = viewModel.displayConfig;
                      });
                    },
                  ),
                  CheckboxListTile(
                    title: const Text('格局列表'),
                    subtitle: const Text('盘级别的常见格局（如五不遇时等）'),
                    value: config.showGeJuList,
                    onChanged: (v) {
                      viewModel.updateDisplayConfig(
                          config.copyWith(showGeJuList: v));
                      setSheetState(() {
                        config = viewModel.displayConfig;
                      });
                    },
                  ),
                  CheckboxListTile(
                    title: const Text('地盘八神'),
                    subtitle: const Text('各宫地盘八神信息'),
                    value: config.showDiGod,
                    onChanged: (v) {
                      viewModel
                          .updateDisplayConfig(config.copyWith(showDiGod: v));
                      setSheetState(() {
                        config = viewModel.displayConfig;
                      });
                    },
                  ),
                  CheckboxListTile(
                    title: const Text('六甲旬首'),
                    subtitle: const Text('各宫的六甲旬首'),
                    value: config.showSixJiaXunHeader,
                    onChanged: (v) {
                      viewModel.updateDisplayConfig(
                          config.copyWith(showSixJiaXunHeader: v));
                      setSheetState(() {
                        config = viewModel.displayConfig;
                      });
                    },
                  ),
                  CheckboxListTile(
                    title: const Text('寄干'),
                    subtitle: const Text('中五宫天盘/地盘寄干'),
                    value: config.showJiGan,
                    onChanged: (v) {
                      viewModel
                          .updateDisplayConfig(config.copyWith(showJiGan: v));
                      setSheetState(() {
                        config = viewModel.displayConfig;
                      });
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showArchitectureInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('架构说明'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'MVVM + UseCase 架构',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Text(
                '📦 Domain层（业务核心）',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('• Entity: 业务实体类'),
              Text('• Repository接口: 定义数据操作契约'),
              Text('• UseCase: 业务用例逻辑'),
              SizedBox(height: 12),
              Text(
                '📦 Data层（数据处理）',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('• Repository实现: 实现数据操作'),
              Text('• DataSource: 数据源（JSON/计算器）'),
              SizedBox(height: 12),
              Text(
                '📦 Presentation层（界面展示）',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('• ViewModel: 界面状态管理'),
              Text('• View: Flutter UI组件'),
              SizedBox(height: 12),
              Text(
                '🔧 依赖注入',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('• ServiceLocator: 管理依赖关系'),
              Text('• 使用Provider进行状态管理'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }
}

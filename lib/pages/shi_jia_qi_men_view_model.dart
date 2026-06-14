import 'package:ai_core/ai/ai_context.dart';
import 'package:ai_core/ai/ai_entity.dart';
import 'package:metaphysics_core/enums.dart';
import 'package:flutter/cupertino.dart';
import 'package:logging/logging.dart';
import 'package:qimendunjia/ai/pan_display_config.dart';
import 'package:qimendunjia/ai/pan_serializer.dart';

import 'package:qimendunjia/domain/entities/qimen_pan.dart';
import 'package:qimendunjia/enums/enum_most_popular_ge_ju.dart';
import 'package:qimendunjia/ui_models/ui_each_gong_model.dart';

import '../enums/enum_arrange_plate_type.dart';
import '../enums/enum_eight_door.dart';
import '../enums/enum_nine_stars.dart';
import '../model/door_star_ke_ying.dart';
import '../model/each_gong.dart';
import '../model/each_gong_ge_ju.dart';
import '../model/eight_door_ke_ying.dart';
import '../model/pan_arrange_settings.dart';
import '../model/qi_yi_ru_gong.dart';
import '../presentation/adapters/qimen_legacy_display_bridge.dart';
import '../model/ten_gan_ke_ying.dart';
import '../model/ten_gan_ke_ying_ge_ju.dart';
import '../ui_models/ui_pan_meta_model.dart';
import '../ui_models/ui_ten_gan_key_ying_ge_ju.dart';
import '../domain/entities/shi_jia_ju.dart' as entity;
import '../domain/repositories/qimen_data_repository.dart';
import '../model/shi_jia_qi_men.dart';

class ShiJiaQiMenViewModel extends ChangeNotifier {
  static final _log = Logger('ShiJiaQiMenViewModel');

  BuildContext context;
  final QiMenDataRepository _qiMenDataRepository;

  // DateTime? _dateTime;
  // DateTime? get dateTime => _dateTime;
  // set dateTime(DateTime? value) {
  //   _dateTime = value;
  //   notifyListeners();
  // }
  UIPanMetaModel? _uiPanMetaModel;
  UIPanMetaModel? get uiPanMetaModel => _uiPanMetaModel;

  QiMenLegacyDisplayBridge? _bridge;
  QiMenLegacyDisplayBridge? get shiJiaQiMen => _bridge;
  set shiJiaQiMen(QiMenLegacyDisplayBridge? value) {
    _bridge = value;
    notifyListeners();
  }

  Map<HouTianGua, UIEachGongModel?> _gongUIMapper = {};

  PanDisplayConfig _displayConfig = const PanDisplayConfig.defaultConfig();
  PanDisplayConfig get displayConfig => _displayConfig;

  void updateDisplayConfig(PanDisplayConfig config) {
    _displayConfig = config;
    notifyListeners();
  }

  /// 构建 AI 上下文
  ///
  /// 使用 [QiMenPanMapper] 将老 model 转为 domain entity 后序列化。
  AiContext? buildAiContext() {
    final bridge = _bridge;
    if (bridge == null) return null;

    final pan = bridge.pan!;
    final entity = AiEntity(
      id: pan.id,
      type: 'qimen_pan',
      name: pan.brief,
      description: PanSerializer.toDescription(pan, config: _displayConfig),
      rawData: PanSerializer.toMap(pan, config: _displayConfig),
    );

    return AiContext(
      moduleName: 'xuan-qimendunjia',
      intention: '用户已排好一个奇门局，请根据盘局信息进行分析。如需排其他时间的盘，可使用 qimen_tools 工具。',
      entities: [entity],
    );
  }

  /// 外部拉起的盘（从 AI Tool 排盘结果）
  QiMenPan? _externalPan;
  QiMenPan? get externalPan => _externalPan;

  /// 加载外部盘（从 AI Tool 排盘结果拉起）。
  ///
  /// 将 [QiMenPan] entity 转换回 [QiMenLegacyDisplayBridge]，
  /// 调用 [createDisplayBridge] 以完整填充 UI 数据。
  void loadExternalPan(QiMenPan pan) {
    _log.info('[loadExternalPan] loading external pan: '
        'id=${pan.id}, brief=${pan.brief}, '
        'time=${pan.panDateTime}');
    _externalPan = pan;

    // Convert entity ShiJiaJu → model ShiJiaJu
    // 此 ViewModel 是传统时家专用页面；非时家盘不会到达此分支。
    final entityJu = pan.shiJiaJu!;

    // Use default PanArrangeSettings (matching PanSettings.defaultSettings())
    final defaultSettings = PanArrangeSettings(
      arrangeType: ArrangeType.CHAI_BU,
      jiGong: CenterGongJiGongType.KUN_GEN_GONG,
      starMonthTokenType: MonthTokenTypeEnum.ZHU_QI,
      starFourWeiGongType: GongTypeEnum.GONG_GUA,
      doorFourWeiGongType: GongTypeEnum.GONG_GUA,
      godWithGongTypeEnum: GodWithGongTypeEnum.GONG_GUA_ONLY,
      ganGongType: GanGongTypeEnum.WANG_MU,
    );

    // Re-derive QiMenLegacyDisplayBridge from model data — this populates
    // _bridge, _uiPanMetaModel, _gongUIMapper, etc.
    createDisplayBridge(
      pan.plateType,
      pan.panDateTime,
      entityJu,
      defaultSettings,
    );
  }

  UIEachGongModel? _selectedGong;
  UIEachGongModel? get selectedGong => _selectedGong;

  UIGongExplains? _selectedGongExplain;
  UIGongExplains? get selectedGongExplain => _selectedGongExplain;
  // each gong
  UIEachGongModel? get kanGong => _gongUIMapper[HouTianGua.Kan];
  UIEachGongModel? get genGong => _gongUIMapper[HouTianGua.Gen];
  UIEachGongModel? get zhenGong => _gongUIMapper[HouTianGua.Zhen];
  UIEachGongModel? get xunGong => _gongUIMapper[HouTianGua.Xun];
  UIEachGongModel? get liGong => _gongUIMapper[HouTianGua.Li];
  UIEachGongModel? get kunGong => _gongUIMapper[HouTianGua.Kun];
  UIEachGongModel? get duiGong => _gongUIMapper[HouTianGua.Dui];
  UIEachGongModel? get qianGong => _gongUIMapper[HouTianGua.Qian];
  UIEachGongModel? get zhongGong {
    if (_bridge != null && _bridge!.plateType == PlateType.FEI_PAN) {
      return _gongUIMapper[HouTianGua.Center];
    } else {
      return null;
    }
  }

  UIEachGongModel? _generateEachGong(HouTianGua gua,
      UITenGanKeYingGeJu tenGanKeYingGeJu, List<QiYiRuGong>? qiYiRuGongList) {
    if (shiJiaQiMen != null) {
      return UIEachGongModel(
          gua: gua,
          gong: _bridge!.gongModelMapper[gua]!,
          gongWangShuai: _bridge!.gongWangShuaiMapper[gua]!,
          tenGanKeYingGeJu: tenGanKeYingGeJu,
          panMete: _uiPanMetaModel!,
          eachGongGeJu: EnumMostPopularGeJu.checkGeJuAtEachGong(
              _bridge!.timeJiaZi,
              _bridge!.sixJiaXunHeader,
              _bridge!.displayState.zhiShiDoor,
              _bridge!.gongModelMapper[gua]!),
          qiYiRuGongList: qiYiRuGongList);
    }
    return null;
  }

  // Map<HouTianGua,UITenGanKeYingGeJu> tenGanKeYingGeJuMapper = {};

  ShiJiaQiMenViewModel(this.context, this._qiMenDataRepository);

  UIEachGongModel? getGongByGua(HouTianGua gongGua) {
    return _gongUIMapper[gongGua];
  }

  Future<void> selectGong(HouTianGua? gongGua) async {
    if (_selectedGong == null && _gongUIMapper[gongGua] != null) {
      UIEachGongModel selectedGong = _gongUIMapper[gongGua]!;

      EachGong gong = selectedGong.gong;
      var fixedList = [
        loadAllTenGanKeYingForCurrentGong(_uiPanMetaModel!.xunHeaderTianGan,
            gong.tianPan, gong.diPan, gong.tianPanJiGan, gong.diPanJiGan),
        loadDoorStarKeYing(gong.door, gong.star as NineStarsEnum),
        loadThreeQiRuGong(gong.gongGua, gong.tianPan),
        loadEightDoorGanKeYing(gong.door, gong.tianPan),
        loadTianPanGanRuGong(gong.gongGua, gong.tianPan),
        loadEightDoorKeYing(
            gong.door,
            EightDoorEnum.listOrderedByGongNumber
                .firstWhere((t) => t.originalGong == gong.gongGua))
      ];
      bool withTianGanJiGan = gong.tianPanJiGan != null;
      if (withTianGanJiGan) {
        fixedList.addAll([
          loadEightDoorGanKeYing(gong.door, gong.tianPanJiGan!),
          loadThreeQiRuGong(gong.gongGua, gong.tianPanJiGan!),
          loadTianPanGanRuGong(gong.gongGua, gong.tianPanJiGan!),
        ]);
      }
      EachGongGeJu eachGongGeJu = EnumMostPopularGeJu.checkGeJuAtEachGong(
          _bridge!.timeJiaZi,
          _bridge!.sixJiaXunHeader,
          _bridge!.displayState.zhiShiDoor,
          gong);
      Future.wait(fixedList).then((values) {
        _selectedGongExplain = UIGongExplains(
            // selectedGong: selectedGong,
            doorStarKeYing: values[1] as DoorStarKeYing?,
            qiYiRuGong: values[2] as QiYiRuGong?,
            doorGanKeYingString: values[3] as String?,
            tianPanGanRuGong: values[4] as String?,
            uiGongTenGanKeYing: values[0] as UIGongTenGanKeYing,
            eightDoorKeYingMapper: values[5] as Map<YinYang, EightDoorKeYing>,
            doorJiGanKeYingString:
                withTianGanJiGan ? values[6] as String? : null,
            jiGanThreeRuGong:
                withTianGanJiGan ? values[7] as QiYiRuGong? : null,
            tianPanJiGanRuGong: withTianGanJiGan ? values[8] as String? : null,
            eachGongGeJu: eachGongGeJu);
        notifyListeners();
      });
      _selectedGong = selectedGong;
      notifyListeners();

      //
      // DoorStarKeYing? doorStarKeYing = await loadDoorStarKeYing(gong.door, gong.star);
      // QiYiRuGong? qiYiRuGong =  await loadThreeQiRuGong(gong.gongGua, gong.tianPan);
      // String? doorGanKeYingString = await loadEightDoorGanKeYing(gong.door, gong.tianPan);
      // String? tianPanGanRuGong = await loadTianPanGanRuGong(gong.gongGua, gong.tianPan);
      //
      // Map<YinYang,EightDoorKeYing>? eightDoorKeYingMapper = await loadEightDoorKeYing(gong.door,EightDoorEnum.listOrderedByGongNumber.firstWhere((t)=>t.originalGong == gong.gongGua));
      // UIGongTenGanKeYing uiGongTenGanKeYing = await loadAllTenGanKeYingForCurrentGong(_uiPanMetaModel!.xunHeaderTianGan,gong.tianPan,gong.diPan,gong.tianPanJiGan,gong.diPanJiGan);
      //
      // QiYiRuGong? jiGanThreeRuGong;
      // String? doorJiGanKeYingString;
      // String? tianPanJiGanRuGong;
      // if (gong.tianPanJiGan!=null){
      //   doorJiGanKeYingString = await loadEightDoorGanKeYing(gong.door, gong.tianPanJiGan!);
      //   jiGanThreeRuGong = await loadThreeQiRuGong(gong.gongGua, gong.tianPanJiGan!);
      //   tianPanJiGanRuGong = await loadTianPanGanRuGong(gong.gongGua, gong.tianPanJiGan!);
      // }
      // _selectedGong = UIGongExplains(
      //   // selectedGong: selectedGong,
      //   doorStarKeYing:doorStarKeYing,
      //  qiYiRuGong:qiYiRuGong,
      //   doorGanKeYingString:doorGanKeYingString,
      //   tianPanGanRuGong:tianPanGanRuGong,
      //   uiGongTenGanKeYing:uiGongTenGanKeYing,
      //   eightDoorKeYingMapper:eightDoorKeYingMapper,
      //   jiGanThreeRuGong:jiGanThreeRuGong,
      //   doorJiGanKeYingString:doorJiGanKeYingString,
      //   tianPanJiGanRuGong:tianPanJiGanRuGong,
      // );
    } else {
      _selectedGong = null;
      _selectedGongExplain = null;
    }
    notifyListeners();
  }

  void createDisplayBridge(PlateType plateType, DateTime dateTime,
      entity.ShiJiaJu shiJiaJu, PanArrangeSettings settings) {
    final bridge = QiMenLegacyDisplayBridge.fromRawComponents(
      plateType: plateType,
      shiJiaJu: shiJiaJu,
      settings: settings,
    );
    _uiPanMetaModel = UIPanMetaModel(
      yinYangDun: shiJiaJu.yinYangDun,
      zhiShiDoor: bridge.displayState.zhiShiDoor,
      zhiFuStar: bridge.displayState.zhiFuStar,
      xunHeaderTianGan: bridge.xunHeaderTianGan,
      timeXunKong: bridge.displayState.timeXunKong,
      horseLocation: bridge.displayState.horseLocation,
      monthToken: bridge.monthToken,
    );
    _bridge = bridge;
    // 三奇入宫的三奇 与 宫Mapper
    Map<TianGan, HouTianGua> sanQiRuGongMapper = {};
    for (var g in bridge.gongModelMapper.values) {
      if (g.tianPan.isThreeQi) {
        sanQiRuGongMapper[g.tianPan] = g.gongGua;
      }
      if (g.tianPanJiGan != null && g.tianPanJiGan!.isThreeQi) {
        sanQiRuGongMapper[g.tianPanJiGan!] = g.gongGua;
      }
    }

    Future.wait([
      loadTenGanKeYingGeJu(
          plateType, bridge.xunHeaderTianGan, bridge.gongModelMapper),
      listThreeQiRuGong(sanQiRuGongMapper)
    ]).then((resList) {
      debugPrint("Logic: ten gan ke ying loadded ${resList.first.length}");
      for (var gua in HouTianGua.values) {
        if (gua == HouTianGua.Center && plateType == PlateType.ZHUAN_PAN) {
        } else {
          _gongUIMapper[gua] = _generateEachGong(
            gua,
            resList.first[gua] as UITenGanKeYingGeJu,
            resList[1][gua] == null
                ? null
                : (resList[1][gua] as List<QiYiRuGong>),
          );
        }
      }
      notifyListeners();
    });
    // notifyListeners();
  }

  void reset() {
    _bridge = null;
    _uiPanMetaModel = null;
    // tenGanKeYingGeJuMapper = {};
    _gongUIMapper = {};
    notifyListeners();
  }

  Future<DoorStarKeYing?> loadDoorStarKeYing(
      EightDoorEnum door, NineStarsEnum star) async {
    return await _qiMenDataRepository.getDoorStarKeYing(
      door: door,
      star: star,
    );
  }

  Future<String?> loadEightDoorGanKeYing(
      EightDoorEnum door, TianGan tianPanGan) async {
    return await _qiMenDataRepository.getEightDoorGanKeYing(
      door: door,
      gan: tianPanGan,
    );
  }

  // tuple1 天盘干、地盘干 十干克应
  // tuple2 天盘寄干、地盘干 十干克应
  // tuple3 天盘干、地盘寄干 十干克应
  // tuple4 天盘寄干、地盘寄干 十干克应
  Future<UIGongTenGanKeYing> loadAllTenGanKeYingForCurrentGong(
    TianGan xunShouGan,
    TianGan tianPanGan,
    TianGan diPanGan,
    TianGan? tianPanJiGan,
    TianGan? diPanJiGan,
  ) async {
    debugPrint("loadAllTenGanKeYingForCurrentGong");
    final repo = _qiMenDataRepository;
    TenGanKeYing tianDiPanKeYing = await repo.getTenGanKeYing(
        tianPan: tianPanGan, diPan: diPanGan);
    TenGanKeYing? tianPanJiaDiPanKey;
    if (xunShouGan == tianPanGan) {
      tianPanJiaDiPanKey =
          await repo.getTenGanKeYing(tianPan: TianGan.JIA, diPan: diPanGan);
    }
    TenGanKeYing? tianPanJiDiPanKeYing;
    TenGanKeYing? tianPanJiJiaDiPanKeYing;
    if (tianPanJiGan != null) {
      tianPanJiDiPanKeYing =
          await repo.getTenGanKeYing(tianPan: tianPanJiGan, diPan: diPanGan);
      if (xunShouGan == tianPanJiGan) {
        tianPanJiJiaDiPanKeYing =
            await repo.getTenGanKeYing(tianPan: TianGan.JIA, diPan: diPanGan);
      }
    }

    TenGanKeYing? tianPanDiPanJiGanKeYing;
    TenGanKeYing? tianPanDiPanJiJiaKeYing;
    if (diPanJiGan != null) {
      tianPanDiPanJiGanKeYing =
          await repo.getTenGanKeYing(tianPan: tianPanGan, diPan: diPanJiGan);
      if (xunShouGan == diPanJiGan) {
        tianPanDiPanJiJiaKeYing =
            await repo.getTenGanKeYing(tianPan: TianGan.JIA, diPan: diPanJiGan);
      }
    }

    TenGanKeYing? tianPanJiDiPanJiGanKeYing;
    TenGanKeYing? tianPanJiaDiPanJiaGanKeYing;
    if (tianPanJiGan != null && diPanJiGan != null) {
      tianPanJiDiPanJiGanKeYing =
          await repo.getTenGanKeYing(tianPan: tianPanJiGan, diPan: diPanJiGan);
      if (xunShouGan == tianPanJiGan) {
        tianPanJiaDiPanJiaGanKeYing =
            await repo.getTenGanKeYing(tianPan: TianGan.JIA, diPan: TianGan.JIA);
      }
    }
    return UIGongTenGanKeYing(
      tianDiPanKeYing: tianDiPanKeYing,
      tianPanJiaDiPanKey: tianPanJiaDiPanKey,
      tianPanJiDiPanKeYing: tianPanJiDiPanKeYing,
      tianPanJiJiaDiPanKeYing: tianPanJiJiaDiPanKeYing,
      tianPanDiPanJiGanKeYing: tianPanDiPanJiGanKeYing,
      tianPanDiPanJiJiaKeYing: tianPanDiPanJiJiaKeYing,
      tianPanJiDiPanJiGanKeYing: tianPanJiDiPanJiGanKeYing,
      tianPanJiaDiPanJiaGanKeYing: tianPanJiaDiPanJiaGanKeYing,
    );
  }

  Future<TenGanKeYing?> loadTenGanKeyYing(
      TianGan tianPanGan, TianGan diPanGan) async {
    debugPrint("loadTenGanKeyYing");
    return await _qiMenDataRepository.getTenGanKeYing(
      tianPan: tianPanGan,
      diPan: diPanGan,
    );
    // if (tianPanGan == TianGan.JIA && diPanGan == TianGan.BING){
    //   debugPrint(loadResult[tianPanGan]?[TianGan.BING]);
    // }
  }

  Future<Map<YinYang, EightDoorKeYing>?> loadEightDoorKeYing(
      EightDoorEnum door, EightDoorEnum fixDoor) async {
    /// YinYang  阳为动应，阴为静应

    return await _qiMenDataRepository.getEightDoorKeYing(
      door: door,
      fixDoor: fixDoor,
    );
  }

  /// 当前只有 三奇入宫
  Future<QiYiRuGong?> loadThreeQiRuGong(
      HouTianGua gongGua, TianGan tianPanGan) async {
    if (tianPanGan.isThreeQi) {
      return await _qiMenDataRepository.getQiYiRuGong(
        gong: gongGua,
        gan: tianPanGan,
      );
    }
    return null;
  }

  Future<Map<HouTianGua, List<QiYiRuGong>>> listThreeQiRuGong(
      Map<TianGan, HouTianGua> mapper) async {
    Map<HouTianGua, List<QiYiRuGong>> res = {};
    for (var mapperEntry in mapper.entries) {
      final item = await _qiMenDataRepository.getQiYiRuGong(
        gong: mapperEntry.value,
        gan: mapperEntry.key,
      );
      if (!res.containsKey(mapperEntry.value)) {
        res[mapperEntry.value] = [item!];
      } else {
        res[mapperEntry.value]!.add(item!);
      }
    }

    return res;
  }

  Future<String?> loadTianPanGanRuGong(
      HouTianGua gongGua, TianGan tianPanGan) async {
    return await _qiMenDataRepository.getTianGanRuGongDisease(
      gong: gongGua,
      gan: tianPanGan,
    );
  }

  Future<Map<HouTianGua, UITenGanKeYingGeJu>> loadTenGanKeYingGeJu(
      PlateType plateType,
      TianGan xunShouGan,
      Map<HouTianGua, EachGong> gong) async {
    final repo = _qiMenDataRepository;
    Map<HouTianGua, UITenGanKeYingGeJu> result = {};
    for (var entry in gong.entries) {
      if (plateType == PlateType.ZHUAN_PAN && entry.key == HouTianGua.Center) {
        continue;
      }
      TenGanKeYingGeJu tianGeJu =
          await repo.getTenGanKeYingGeJu(tianPan: entry.value.tianPan, diPan: entry.value.diPan);
      TenGanKeYingGeJu? tianDunJiaGeJu;
      if (entry.value.tianPan == xunShouGan) {
        tianDunJiaGeJu = await repo.getTenGanKeYingGeJu(tianPan: TianGan.JIA, diPan: entry.value.diPan);
      }
      TenGanKeYingGeJu? diDunJiaGeJu;
      if (entry.value.diPan == xunShouGan) {
        diDunJiaGeJu = await repo.getTenGanKeYingGeJu(tianPan: entry.value.tianPan, diPan: TianGan.JIA);
      }
      TenGanKeYingGeJu? diPanJiGeJu;
      TenGanKeYingGeJu? diPanJiJiaGeJu;
      TenGanKeYingGeJu? tianDunJiaDiPanJi;
      if (entry.value.diPanJiGan != null) {
        diPanJiGeJu = await repo.getTenGanKeYingGeJu(tianPan: entry.value.tianPan, diPan: entry.value.diPanJiGan!);
        if (entry.value.diPanJiGan == xunShouGan) {
          diPanJiJiaGeJu = await repo.getTenGanKeYingGeJu(tianPan: entry.value.tianPan, diPan: TianGan.JIA);
        }
        if (entry.value.tianPan == xunShouGan) {
          tianDunJiaDiPanJi = await repo.getTenGanKeYingGeJu(tianPan: TianGan.JIA, diPan: entry.value.diPanJiGan!);
        }
      }
      TenGanKeYingGeJu? tianPanJiGeJu;
      TenGanKeYingGeJu? tianPanJiJiaGeJu;
      TenGanKeYingGeJu? tianPanJiGanDiPanJia;
      if (entry.value.tianPanJiGan != null) {
        tianPanJiGeJu = await repo.getTenGanKeYingGeJu(tianPan: entry.value.tianPanJiGan!, diPan: entry.value.diPan);
        if (entry.value.tianPanJiGan == xunShouGan) {
          tianPanJiJiaGeJu = await repo.getTenGanKeYingGeJu(tianPan: TianGan.JIA, diPan: entry.value.diPan);
        }
        if (entry.value.diPan == xunShouGan) {
          tianPanJiGanDiPanJia = await repo.getTenGanKeYingGeJu(tianPan: entry.value.tianPanJiGan!, diPan: TianGan.JIA);
        }
      }
      TenGanKeYingGeJu? tianDiPanJia; // 天地盘相同，且同为"遁干"
      if (entry.value.tianPan == entry.value.diPan &&
          entry.value.tianPan == xunShouGan) {
        tianDiPanJia = await repo.getTenGanKeYingGeJu(tianPan: TianGan.JIA, diPan: TianGan.JIA);
      }
      TenGanKeYingGeJu? tianDiJiGan;
      TenGanKeYingGeJu? tianDiJiaGanJiaGeJu;
      // print("${entry.value.tianPanJiGan != null}=====${entry.value.tianPanJiGan == entry.value.diPanJiGan}");
      if (entry.value.tianPanJiGan != null &&
          entry.value.tianPanJiGan == entry.value.diPanJiGan) {
        tianDiJiGan = await repo.getTenGanKeYingGeJu(tianPan: entry.value.tianPanJiGan!, diPan: entry.value.diPanJiGan!);
        if (entry.value.tianPanJiGan == xunShouGan) {
          tianDiJiaGanJiaGeJu = await repo.getTenGanKeYingGeJu(tianPan: TianGan.JIA, diPan: TianGan.JIA);
        }
      }

      result[entry.key] = UITenGanKeYingGeJu(
          gongGua: entry.key,
          tianGan: entry.value.tianPan,
          tianGeJu: tianGeJu,
          diGan: entry.value.diPan,
          isTianGanDunJia: entry.value.tianPan == xunShouGan,
          isDiGanDunJia: entry.value.diPan == xunShouGan,
          tianDunJiaGeJu: tianDunJiaGeJu,
          diDunJiaGeJu: diDunJiaGeJu,
          tianPanJiGan: entry.value.tianPanJiGan,
          tianPanJiGanGeJu: tianPanJiGeJu,
          diPanJiGan: entry.value.diPanJiGan,
          diPanJiGanGeJu: diPanJiGeJu,
          isTianJiGanJia: entry.value.tianPanJiGan == xunShouGan,
          isDiJiGanJia: entry.value.diPanJiGan == xunShouGan,
          tianJiGanJiaGeJu: tianPanJiJiaGeJu,
          diJiGanJiaGeJu: diPanJiJiaGeJu,
          tianDiJiGanGeJu: tianDiJiGan,
          tianDiPanGanGeJu: tianDiPanJia,
          tianDiJiaGanJiaGeJu: tianDiJiaGanJiaGeJu,
          tianPanJiGanDiPanJia: tianPanJiGanDiPanJia,
          tianDunJiaDiPanJi: tianDunJiaDiPanJi);
    }

    return result;
  }
}

class UIGongTenGanKeYing {
  TenGanKeYing tianDiPanKeYing;
  TenGanKeYing? tianPanJiaDiPanKey;
  TenGanKeYing? tianPanJiDiPanKeYing;
  TenGanKeYing? tianPanJiJiaDiPanKeYing;
  TenGanKeYing? tianPanDiPanJiGanKeYing;
  TenGanKeYing? tianPanDiPanJiJiaKeYing;
  TenGanKeYing? tianPanJiDiPanJiGanKeYing;
  TenGanKeYing? tianPanJiaDiPanJiaGanKeYing;
  UIGongTenGanKeYing({
    required this.tianDiPanKeYing,
    required this.tianPanJiaDiPanKey,
    required this.tianPanJiDiPanKeYing,
    required this.tianPanJiJiaDiPanKeYing,
    required this.tianPanDiPanJiGanKeYing,
    required this.tianPanDiPanJiJiaKeYing,
    required this.tianPanJiDiPanJiGanKeYing,
    required this.tianPanJiaDiPanJiaGanKeYing,
  });
}

class UIGongExplains {
  // UIEachGongModel selectedGong;
  DoorStarKeYing? doorStarKeYing;
  QiYiRuGong? qiYiRuGong;
  String? doorGanKeYingString;
  String? tianPanGanRuGong;
  UIGongTenGanKeYing uiGongTenGanKeYing;
  Map<YinYang, EightDoorKeYing>? eightDoorKeYingMapper;
  QiYiRuGong? jiGanThreeRuGong;
  String? doorJiGanKeYingString;
  String? tianPanJiGanRuGong;
  EachGongGeJu eachGongGeJu;
  UIGongExplains({
    // required this.selectedGong,
    required this.doorStarKeYing,
    required this.qiYiRuGong,
    required this.doorGanKeYingString,
    required this.tianPanGanRuGong,
    required this.uiGongTenGanKeYing,
    required this.eightDoorKeYingMapper,
    required this.jiGanThreeRuGong,
    required this.doorJiGanKeYingString,
    required this.tianPanJiGanRuGong,
    required this.eachGongGeJu,
  });
}

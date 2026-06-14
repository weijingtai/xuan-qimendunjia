import 'package:flutter_test/flutter_test.dart';
import 'package:metaphysics_core/enums.dart';
import 'package:qimendunjia/domain/entities/base_ju.dart';
import 'package:qimendunjia/domain/entities/each_gong.dart';
import 'package:qimendunjia/domain/entities/qimen_pan.dart';
import 'package:qimendunjia/domain/entities/shi_jia_ju.dart';
import 'package:qimendunjia/domain/repositories/qimen_calculator_repository.dart';
import 'package:qimendunjia/domain/repositories/qimen_data_repository.dart';
import 'package:qimendunjia/domain/usecases/arrange_pan_usecase.dart';
import 'package:qimendunjia/domain/usecases/calculate_ju_usecase.dart';
import 'package:qimendunjia/domain/usecases/select_gong_usecase.dart';
import 'package:qimendunjia/enums/enum_arrange_plate_type.dart';
import 'package:qimendunjia/enums/enum_eight_door.dart';
import 'package:qimendunjia/enums/enum_eight_gods.dart';
import 'package:qimendunjia/enums/enum_fu_tou_scheme.dart';
import 'package:qimendunjia/enums/enum_ke_scheme.dart';
import 'package:qimendunjia/enums/enum_nine_stars.dart';
import 'package:qimendunjia/enums/enum_qi_men_jia.dart';
import 'package:qimendunjia/enums/enum_three_yuan.dart';
import 'package:qimendunjia/model/door_star_ke_ying.dart';
import 'package:qimendunjia/model/eight_door_ke_ying.dart';
import 'package:qimendunjia/model/qi_yi_ru_gong.dart';
import 'package:qimendunjia/model/ten_gan_ke_ying.dart';
import 'package:qimendunjia/model/ten_gan_ke_ying_ge_ju.dart';
import 'package:qimendunjia/presentation/models/qimen_state.dart';
import 'package:qimendunjia/presentation/viewmodels/qimen_viewmodel.dart';

class FakeQiMenCalculatorRepository implements QiMenCalculatorRepository {
  final BaseJu stubJu;
  final QiMenPan stubPan;
  bool shouldThrow = false;

  FakeQiMenCalculatorRepository({required this.stubJu, required this.stubPan});

  @override
  Future<BaseJu> calculateJu({
    required DateTime dateTime,
    required QiMenJia jia,
    required ArrangeType arrangeType,
    KeSchemeType? keScheme,
    FuTouSchemeType? fuTouScheme,
  }) async {
    if (shouldThrow) {
      throw QiMenCalculationException('Mock calculator error');
    }
    return stubJu;
  }

  @override
  Future<QiMenPan> arrangePan({
    required BaseJu ju,
    required PlateType plateType,
    required PanSettings settings,
  }) async {
    if (shouldThrow) {
      throw QiMenCalculationException('Mock arrange error');
    }
    return stubPan;
  }
}

class FakeQiMenDataRepository implements QiMenDataRepository {
  @override
  Future<TenGanKeYing> getTenGanKeYing({
    required TianGan tianPan,
    required TianGan diPan,
  }) async {
    return TenGanKeYing(
      juName: '双木成林',
      shortExplain: '伏吟',
      longExplain: '双木成林长解释',
      zhu: [],
      yiXiang: '意象',
      diseaseAtGongMapper: {},
      xiangList: [],
      others: [],
    );
  }

  @override
  Future<DoorStarKeYing?> getDoorStarKeYing({
    required EightDoorEnum door,
    required NineStarsEnum star,
  }) async {
    return DoorStarKeYing(
      door: door,
      star: star,
      jiXiong: JiXiongEnum.JI,
      description: '门星克应描述',
    );
  }

  @override
  Future<Map<YinYang, EightDoorKeYing>?> getEightDoorKeYing({
    required EightDoorEnum door,
    required EightDoorEnum fixDoor,
  }) async {
    return {
      YinYang.YANG: EightDoorKeYing(
        door: door,
        fixDoor: fixDoor,
        dongJingYing: YinYang.YANG,
        description: '八门克应动应',
      ),
    };
  }

  @override
  Future<QiYiRuGong?> getQiYiRuGong({
    required HouTianGua gong,
    required TianGan gan,
  }) async {
    return QiYiRuGong(
      gong: gong,
      qiYi: gan,
      geJuName: '三奇入宫格局',
      description: '描述',
      geJuJiXiong: JiXiongEnum.JI,
    );
  }

  @override
  Future<TenGanKeYingGeJu> getTenGanKeYingGeJu({
    required TianGan tianPan,
    required TianGan diPan,
  }) async {
    return TenGanKeYingGeJu(
      tianPan: tianPan,
      diPan: diPan,
      jiXiong: JiXiongEnum.JI,
      geJuNames: ['青龙合灵'],
      explains: ['吉'],
    );
  }

  @override
  Future<String?> getEightDoorGanKeYing({
    required EightDoorEnum door,
    required TianGan gan,
  }) async {
    return '八门干克应文本';
  }

  @override
  Future<String?> getTianGanRuGongDisease({
    required HouTianGua gong,
    required TianGan gan,
  }) async {
    return '天干入宫疾病描述';
  }

  @override
  Future<void> clearCache() async {}
}

void main() {
  late ShiJiaJu stubJu;
  late QiMenPan stubPan;
  late FakeQiMenCalculatorRepository calculatorRepository;
  late FakeQiMenDataRepository dataRepository;
  late CalculateJuUseCase calculateJuUseCase;
  late ArrangePanUseCase arrangePanUseCase;
  late SelectGongUseCase selectGongUseCase;
  late QiMenViewModel viewModel;

  setUp(() {
    stubJu = ShiJiaJu(
      id: 'test-ju-1',
      panDateTime: DateTime(2026, 6, 14, 12, 0),
      juNumber: 1,
      fuTouJiaZi: JiaZi.getByNumber(1), // 甲子
      yinYangDun: YinYang.YANG,
      jieQiAt: TwentyFourJieQi.MANG_ZHONG,
      jieQiStartAt: DateTime(2026, 6, 5),
      jieQiEnd: TwentyFourJieQi.XIA_ZHI,
      jieQiEndAt: DateTime(2026, 6, 21),
      atThreeYuan: EnumThreeYuan.START,
      fourZhuEightChar: '丙午 甲午 乙未 壬午',
    );

    stubPan = QiMenPan(
      id: 'test-pan-1',
      panDateTime: DateTime(2026, 6, 14, 12, 0),
      ju: stubJu,
      plateType: PlateType.ZHUAN_PAN,
      gongMapper: {
        HouTianGua.Kan: EachGong(
          gongNumber: 1,
          gongGua: HouTianGua.Kan,
          star: NineStarsEnum.PENG,
          door: EightDoorEnum.KAI,
          god: EightGodsEnum.ZHI_FU,
          diGod: EightGodsEnum.ZHI_FU,
          tianPan: TianGan.JIA,
          diPan: TianGan.JIA,
          tianPanAnGan: TianGan.JIA,
          renPanAnGan: TianGan.JIA,
          yinGan: TianGan.JIA,
        ),
      },
      zhiShiDoor: EightDoorEnum.KAI,
      zhiShiDoorAtGong: HouTianGua.Kan,
      zhiFuStar: NineStarsEnum.PENG,
      zhiFuStarAtGong: HouTianGua.Kan,
      isStarFuYin: false,
      isStarFanYin: false,
      isDoorFuYin: false,
      isDoorFanYin: false,
      isGanFuYin: false,
      isGanFanYin: false,
      horseLocation: DiZhi.ZI,
      panGeJuList: [],
    );

    calculatorRepository = FakeQiMenCalculatorRepository(stubJu: stubJu, stubPan: stubPan);
    dataRepository = FakeQiMenDataRepository();

    calculateJuUseCase = CalculateJuUseCase(calculatorRepository);
    arrangePanUseCase = ArrangePanUseCase(calculatorRepository);
    selectGongUseCase = SelectGongUseCase(dataRepository);

    viewModel = QiMenViewModel(calculateJuUseCase, arrangePanUseCase, selectGongUseCase);
  });

  group('QiMenViewModel Tests using Fake Repositories', () {
    test('initial state', () {
      expect(viewModel.state, QiMenViewState.initial);
      expect(viewModel.qiMenState, isA<QiMenIdle>());
      expect(viewModel.selectedGong, isNull);
      expect(viewModel.gongDetailInfo, isNull);
      expect(viewModel.errorMessage, isNull);
    });

    test('calculateAndArrangePan success flow', () async {
      await viewModel.calculateAndArrangePan(
        dateTime: DateTime(2026, 6, 14, 12, 0),
        arrangeType: ArrangeType.CHAI_BU,
        plateType: PlateType.ZHUAN_PAN,
      );

      expect(viewModel.state, QiMenViewState.success);
      expect(viewModel.qiMenState, isA<QiMenSuccess>());
      expect(viewModel.currentJu, stubJu);
      expect(viewModel.currentPan, stubPan);
      expect(viewModel.errorMessage, isNull);
    });

    test('calculateAndArrangePan error flow', () async {
      calculatorRepository.shouldThrow = true;

      await viewModel.calculateAndArrangePan(
        dateTime: DateTime(2026, 6, 14, 12, 0),
        arrangeType: ArrangeType.CHAI_BU,
        plateType: PlateType.ZHUAN_PAN,
      );

      expect(viewModel.state, QiMenViewState.error);
      expect(viewModel.qiMenState, isA<QiMenError>());
      expect(viewModel.currentJu, isNull);
      expect(viewModel.currentPan, isNull);
      expect(viewModel.errorMessage, contains('Mock calculator error'));
    });

    test('selectGong flow after successful pan arrange', () async {
      // 1. Arrange a pan first
      await viewModel.calculateAndArrangePan(
        dateTime: DateTime(2026, 6, 14, 12, 0),
        arrangeType: ArrangeType.CHAI_BU,
        plateType: PlateType.ZHUAN_PAN,
      );

      // 2. Select Kan Gong
      final gong = viewModel.currentPan!.getGong(HouTianGua.Kan)!;
      await viewModel.selectGong(gong);

      expect(viewModel.state, QiMenViewState.success);
      expect(viewModel.selectedGong, gong);
      expect(viewModel.gongDetailInfo, isNotNull);
      expect(viewModel.gongDetailInfo!.tenGanKeYing!.tianDiKeYing.juName, '双木成林');
      expect(viewModel.gongDetailInfo!.doorStarKeYing!.description, '门星克应描述');
    });

    test('selectGong without arranged pan throws error', () async {
      final dummyGong = EachGong(
        gongNumber: 1,
        gongGua: HouTianGua.Kan,
        star: NineStarsEnum.PENG,
        door: EightDoorEnum.KAI,
        god: EightGodsEnum.ZHI_FU,
        diGod: EightGodsEnum.ZHI_FU,
        tianPan: TianGan.JIA,
        diPan: TianGan.JIA,
        tianPanAnGan: TianGan.JIA,
        renPanAnGan: TianGan.JIA,
        yinGan: TianGan.JIA,
      );

      await viewModel.selectGong(dummyGong);

      expect(viewModel.state, QiMenViewState.error);
      expect(viewModel.errorMessage, contains('请先排盘'));
    });

    test('unselectGong resets selected gong states', () async {
      await viewModel.calculateAndArrangePan(
        dateTime: DateTime(2026, 6, 14, 12, 0),
        arrangeType: ArrangeType.CHAI_BU,
        plateType: PlateType.ZHUAN_PAN,
      );

      final gong = viewModel.currentPan!.getGong(HouTianGua.Kan)!;
      await viewModel.selectGong(gong);
      expect(viewModel.selectedGong, gong);

      viewModel.unselectGong();
      expect(viewModel.selectedGong, isNull);
      expect(viewModel.gongDetailInfo, isNull);
      expect(viewModel.state, QiMenViewState.success);
    });

    test('reset clears everything to initial states', () async {
      await viewModel.calculateAndArrangePan(
        dateTime: DateTime(2026, 6, 14, 12, 0),
        arrangeType: ArrangeType.CHAI_BU,
        plateType: PlateType.ZHUAN_PAN,
      );

      viewModel.reset();
      expect(viewModel.state, QiMenViewState.initial);
      expect(viewModel.qiMenState, isA<QiMenIdle>());
      expect(viewModel.selectedGong, isNull);
      expect(viewModel.gongDetailInfo, isNull);
    });
  });
}

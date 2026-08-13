import 'package:flutter_test/flutter_test.dart';
import 'package:metaphysics_core/enums.dart';
import 'package:metaphysics_core/models/eight_chars.dart';
import 'package:metaphysics_core/models/jie_qi_info.dart';
import 'package:qimendunjia/domain/entities/base_ju.dart';
import 'package:qimendunjia/domain/entities/each_gong.dart';
import 'package:qimendunjia/domain/entities/qimen_pan.dart';
import 'package:qimendunjia/domain/entities/shi_jia_ju.dart';
import 'package:qimendunjia/domain/pipeline/qimen_chart_params.dart';
import 'package:qimendunjia/domain/pipeline/qimen_pipeline_executor.dart';
import 'package:qimendunjia/domain/repositories/qimen_calculator_repository.dart';
import 'package:qimendunjia/domain/repositories/qimen_data_repository.dart';
import 'package:qimendunjia/model/door_star_ke_ying.dart';
import 'package:qimendunjia/model/eight_door_ke_ying.dart';
import 'package:qimendunjia/model/qi_yi_ru_gong.dart';
import 'package:qimendunjia/model/ten_gan_ke_ying.dart';
import 'package:qimendunjia/model/ten_gan_ke_ying_ge_ju.dart';
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
import 'package:qimendunjia/presentation/models/qimen_state.dart';
import 'package:qimendunjia/presentation/viewmodels/qimen_viewmodel.dart';
import 'package:repository_interface_divination_pipeline/repository_interface_divination_pipeline.dart';
import 'package:repository_interface_qimendunjia/repository_interface_qimendunjia.dart';

class _FakeQiMenCalculatorRepository implements QiMenCalculatorRepository {
  final BaseJu stubJu;
  final QiMenPan stubPan;

  _FakeQiMenCalculatorRepository({
    required this.stubJu,
    required this.stubPan,
  });

  @override
  Future<BaseJu> calculateJu({
    required DateTime dateTime,
    required QiMenJia jia,
    required ArrangeType arrangeType,
    KeSchemeType? keScheme,
    FuTouSchemeType? fuTouScheme,
  }) async {
    return stubJu;
  }

  @override
  Future<QiMenPan> arrangePan({
    required BaseJu ju,
    required PlateType plateType,
    required PanSettings settings,
  }) async {
    return stubPan;
  }
}

/// 内存 QimenRecordRepository。
class _InMemoryQimenRecordRepository implements QimenRecordRepository {
  final List<QimenDivinationRecordContract> _records = [];

  @override
  Future<String> saveRecord(QimenDivinationRecordContract record) async {
    _records.add(record);
    return record.uuid;
  }

  @override
  Future<List<QimenDivinationRecordContract>> getAllRecords() async {
    return List.of(_records);
  }

  @override
  Future<QimenDivinationRecordContract?> getRecordByUuid(String uuid) async {
    for (final r in _records) {
      if (r.uuid == uuid) return r;
    }
    return null;
  }

  @override
  Future<bool> softDeleteRecord(String uuid) async {
    _records.removeWhere((r) => r.uuid == uuid);
    return true;
  }

  @override
  Stream<List<QimenDivinationRecordContract>> watchAllRecords() async* {
    yield List.of(_records);
  }
}

/// 固定 ResolvedMoment，隔离真实历法计算。
class _FixedMomentResolver implements MomentResolver {
  const _FixedMomentResolver();

  @override
  ResolvedMoment resolve(DivinationMoment moment) => ResolvedMoment(
        source: moment,
        nominalTime: DateTime(2026, 6, 14, 12, 0),
        eightChars: EightChars(
          year: JiaZi.getFromGanZhiValue('丙午')!,
          month: JiaZi.getFromGanZhiValue('甲午')!,
          day: JiaZi.getFromGanZhiValue('乙未')!,
          time: JiaZi.getFromGanZhiValue('壬午')!,
        ),
        lunar: const LunarDate(month: 4, day: 29, isLeapMonth: false),
        jieQi: JieQiInfo(
          jieQi: TwentyFourJieQi.MANG_ZHONG,
          startAt: DateTime(2026, 6, 5),
          endAt: DateTime(2026, 6, 21),
        ),
      );

  @override
  List<ResolvedMoment> resolveCandidates(
    DivinationMoment moment,
    CandidateSpec spec,
  ) => [];
}

/// 模拟新路径失败，验证回退。
class _ThrowingMomentResolver implements MomentResolver {
  const _ThrowingMomentResolver();

  @override
  ResolvedMoment resolve(DivinationMoment moment) {
    throw StateError('模拟新路径失败');
  }

  @override
  List<ResolvedMoment> resolveCandidates(
    DivinationMoment moment,
    CandidateSpec spec,
  ) => [];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ShiJiaJu stubJu;
  late QiMenPan stubPan;
  late _FakeQiMenCalculatorRepository calculatorRepository;
  late _InMemoryQimenRecordRepository recordRepo;
  late QiMenViewModel viewModel;

  QiMenViewModel _buildViewModel({
    QimenPipelineExecutor? pipelineExecutor,
  }) {
    calculatorRepository = _FakeQiMenCalculatorRepository(
      stubJu: stubJu,
      stubPan: stubPan,
    );
    return QiMenViewModel(
      CalculateJuUseCase(calculatorRepository),
      ArrangePanUseCase(calculatorRepository),
      SelectGongUseCase(_EmptyQiMenDataRepository()),
      recordRepository: recordRepo,
      pipelineExecutor: pipelineExecutor,
    );
  }

  setUp(() {
    stubJu = ShiJiaJu(
      id: 'test-ju-1',
      panDateTime: DateTime(2026, 6, 14, 12, 0),
      juNumber: 1,
      fuTouJiaZi: JiaZi.getByNumber(1),
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
    recordRepo = _InMemoryQimenRecordRepository();
  });

  group('QiMenViewModel pipeline 接线', () {
    test('A: 注入 executor 后排盘真实执行 Pipeline，落库走 Record，产出与直接调用 executor 逐字段一致', () async {
      final executor = QimenPipelineExecutor(
        momentResolver: const _FixedMomentResolver(),
        recordRepository: recordRepo,
      );
      viewModel = _buildViewModel(pipelineExecutor: executor);

      await viewModel.calculateAndArrangePan(
        dateTime: DateTime(2026, 6, 14, 12, 0),
        arrangeType: ArrangeType.CHAI_BU,
        plateType: PlateType.ZHUAN_PAN,
      );

      // 老路径照常产出盘面
      expect(viewModel.state, QiMenViewState.success);
      expect(viewModel.errorMessage, isNull);

      // executor 真的被执行到
      final request = viewModel.lastPipelineRequest;
      expect(request, isNotNull);
      expect(request!.params.jia, QiMenJia.SHI);
      expect(request.params.arrangeType, ArrangeType.CHAI_BU);
      expect(request.params.plateType, PlateType.ZHUAN_PAN);
      expect(request.params.uuid, isNotEmpty);

      final pipelineRecord = viewModel.lastPipelineRecord;
      expect(pipelineRecord, isNotNull);

      // 落库走 Record（老路径 _saveRecordIfAvailable 也会落库一条 legacy contract，
      // 这里只断言 pipeline Record 确实被落库）
      final saved = await recordRepo.getAllRecords();
      expect(saved.any((r) => r.uuid == request.params.uuid), isTrue);

      // 与直接调用 executor 的产出逐字段一致
      final direct = await executor.execute(
        ChartRequest<QimenChartParams>(
          moment: request.moment,
          params: request.params,
        ),
      );
      final directJson = direct.toJson();
      final recordJson = pipelineRecord!.toJson();
      expect(recordJson['uuid'], directJson['uuid']);
      expect(recordJson['juType'], directJson['juType']);
      expect(recordJson['juNumber'], directJson['juNumber']);
      expect(recordJson['datetimeJson'], directJson['datetimeJson']);
      expect(recordJson['paramsJson'], directJson['paramsJson']);
      expect(recordJson['createdAt'], directJson['createdAt']);
    });

    test('B: 未注入 executor 时不崩、Pipeline 不走、老路径照常', () async {
      viewModel = _buildViewModel();

      await viewModel.calculateAndArrangePan(
        dateTime: DateTime(2026, 6, 14, 12, 0),
        arrangeType: ArrangeType.CHAI_BU,
        plateType: PlateType.ZHUAN_PAN,
      );

      expect(viewModel.state, QiMenViewState.success);
      expect(viewModel.errorMessage, isNull);
      expect(viewModel.lastPipelineRequest, isNull);
      expect(viewModel.lastPipelineRecord, isNull);
    });

    test('B2: 注入 executor 但 Pipeline 抛错时不崩、老路径照常产出', () async {
      final executor = QimenPipelineExecutor(
        momentResolver: const _ThrowingMomentResolver(),
        recordRepository: recordRepo,
      );
      viewModel = _buildViewModel(pipelineExecutor: executor);

      await viewModel.calculateAndArrangePan(
        dateTime: DateTime(2026, 6, 14, 12, 0),
        arrangeType: ArrangeType.CHAI_BU,
        plateType: PlateType.ZHUAN_PAN,
      );

      expect(viewModel.state, QiMenViewState.success);
      expect(viewModel.errorMessage, isNull);
      expect(viewModel.lastPipelineRecord, isNull);
    });

    test('C: QimenChartParams toJson/fromJson 互逆 round-trip', () {
      final params = QimenChartParams(
        uuid: 'qimen-test-001',
        createdAt: DateTime(2026, 6, 14, 12, 0),
        question: '测试问题',
        jia: QiMenJia.SHI,
        arrangeType: ArrangeType.ZHI_RUN,
        plateType: PlateType.FEI_PAN,
        panSettings: PanSettings.defaultSettings(),
        keScheme: KeSchemeType.EIGHT_KE_WU_MA_DUN,
        fuTouScheme: FuTouSchemeType.JIA_FU_TOU,
      );
      final decoded = QimenChartParams.fromJson(params.toJson());
      expect(decoded.uuid, params.uuid);
      expect(decoded.createdAt, params.createdAt);
      expect(decoded.question, params.question);
      expect(decoded.jia, params.jia);
      expect(decoded.arrangeType, params.arrangeType);
      expect(decoded.plateType, params.plateType);
      expect(decoded.panSettings, isNotNull);
      expect(decoded.panSettings!.arrangeType, params.panSettings!.arrangeType);
      expect(decoded.panSettings!.jiGong, params.panSettings!.jiGong);
      expect(decoded.panSettings!.starMonthTokenType,
          params.panSettings!.starMonthTokenType);
      expect(decoded.panSettings!.starFourWeiGongType,
          params.panSettings!.starFourWeiGongType);
      expect(decoded.panSettings!.doorFourWeiGongType,
          params.panSettings!.doorFourWeiGongType);
      expect(decoded.panSettings!.godWithGongType,
          params.panSettings!.godWithGongType);
      expect(decoded.panSettings!.ganGongType, params.panSettings!.ganGongType);
      expect(decoded.panSettings!.keScheme, params.panSettings!.keScheme);
      expect(decoded.panSettings!.fuTouScheme, params.panSettings!.fuTouScheme);
      expect(decoded.keScheme, params.keScheme);
      expect(decoded.fuTouScheme, params.fuTouScheme);
    });

    test('C2: fromJson 缺字段套默认不抛', () {
      final decoded = QimenChartParams.fromJson(const {});
      expect(decoded.uuid, '');
      expect(decoded.question, isNull);
      expect(decoded.jia, QiMenJia.SHI);
      expect(decoded.arrangeType, ArrangeType.CHAI_BU);
      expect(decoded.plateType, PlateType.ZHUAN_PAN);
      expect(decoded.panSettings, isNull);
      expect(decoded.keScheme, isNull);
      expect(decoded.fuTouScheme, isNull);
      expect(decoded.createdAt, DateTime.fromMillisecondsSinceEpoch(0));
    });

    test('C3: fromJson 类型不合法/非法枚举名抛 FormatException，不静默兜底', () {
      expect(
        () => QimenChartParams.fromJson(const {'uuid': 123}),
        throwsFormatException,
      );
      expect(
        () => QimenChartParams.fromJson(const {'jia': 'NOT_A_JIA'}),
        throwsFormatException,
      );
      expect(
        () => QimenChartParams.fromJson(const {'arrangeType': 7}),
        throwsFormatException,
      );
      expect(
        () => QimenChartParams.fromJson(const {'plateType': 'notAPlate'}),
        throwsFormatException,
      );
      expect(
        () => QimenChartParams.fromJson(const {'keScheme': 'notAKeScheme'}),
        throwsFormatException,
      );
      expect(
        () => QimenChartParams.fromJson(const {'createdAt': 'not-a-date'}),
        throwsFormatException,
      );
    });
  });
}

/// 空 QiMenDataRepository（本测试不触发选宫）。
class _EmptyQiMenDataRepository implements QiMenDataRepository {
  @override
  Future<TenGanKeYing> getTenGanKeYing({
    required TianGan tianPan,
    required TianGan diPan,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<DoorStarKeYing?> getDoorStarKeYing({
    required EightDoorEnum door,
    required NineStarsEnum star,
  }) async {
    return null;
  }

  @override
  Future<Map<YinYang, EightDoorKeYing>?> getEightDoorKeYing({
    required EightDoorEnum door,
    required EightDoorEnum fixDoor,
  }) async {
    return null;
  }

  @override
  Future<QiYiRuGong?> getQiYiRuGong({
    required HouTianGua gong,
    required TianGan gan,
  }) async {
    return null;
  }

  @override
  Future<TenGanKeYingGeJu> getTenGanKeYingGeJu({
    required TianGan tianPan,
    required TianGan diPan,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<String?> getEightDoorGanKeYing({
    required EightDoorEnum door,
    required TianGan gan,
  }) async {
    return null;
  }

  @override
  Future<String?> getTianGanRuGongDisease({
    required HouTianGua gong,
    required TianGan gan,
  }) async {
    return null;
  }

  @override
  Future<void> clearCache() async {}
}

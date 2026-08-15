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

class _CountingQimenRecordRepository implements QimenRecordRepository {
  final List<QimenDivinationRecordContract> savedRecords = [];
  int saveCount = 0;

  @override
  Future<String> saveRecord(QimenDivinationRecordContract record) async {
    saveCount++;
    savedRecords.add(record);
    return record.uuid;
  }

  @override
  Future<List<QimenDivinationRecordContract>> getAllRecords() async {
    return List.of(savedRecords);
  }

  @override
  Future<QimenDivinationRecordContract?> getRecordByUuid(String uuid) async {
    for (final r in savedRecords) {
      if (r.uuid == uuid) return r;
    }
    return null;
  }

  @override
  Future<bool> softDeleteRecord(String uuid) async {
    savedRecords.removeWhere((r) => r.uuid == uuid);
    return true;
  }

  @override
  Stream<List<QimenDivinationRecordContract>> watchAllRecords() async* {
    yield List.of(savedRecords);
  }
}

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
  ) =>
      [];
}

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

void main() {
  test('奇门排盘 Pipeline 落库后互斥守卫生效，避免写入两条不同 uuid 的重复记录', () async {
    final stubJu = ShiJiaJu(
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

    final stubPan = QiMenPan(
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

    final calcRepo = _FakeQiMenCalculatorRepository(
      stubJu: stubJu,
      stubPan: stubPan,
    );
    final dataRepo = _EmptyQiMenDataRepository();
    final countingRepo = _CountingQimenRecordRepository();

    final executor = QimenPipelineExecutor(
      momentResolver: const _FixedMomentResolver(),
      recordRepository: countingRepo,
    );

    final viewModel = QiMenViewModel(
      CalculateJuUseCase(calcRepo),
      ArrangePanUseCase(calcRepo),
      SelectGongUseCase(dataRepo),
      recordRepository: countingRepo,
      pipelineExecutor: executor,
    );

    await viewModel.calculateAndArrangePan(
      dateTime: DateTime(2026, 6, 14, 12, 0),
      arrangeType: ArrangeType.CHAI_BU,
      plateType: PlateType.ZHUAN_PAN,
    );

    // 断言：Pipeline 成功落库后，saveRecord 应该恰好只被调用 1 次
    expect(countingRepo.saveCount, 1,
        reason: 'Pipeline 成功落库后，不应再重复调用 legacy _saveRecordIfAvailable 保存第二条记录');
    expect(countingRepo.savedRecords.length, 1);
  });
}

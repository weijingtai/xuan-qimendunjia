import 'package:qimendunjia/domain/entities/base_ju.dart';
import 'package:qimendunjia/enums/enum_fu_tou_scheme.dart';
import 'package:qimendunjia/enums/enum_ke_scheme.dart';
import 'package:qimendunjia/enums/enum_qi_men_jia.dart';
import 'package:qimendunjia/model/shi_jia_ju.dart';
import 'package:qimendunjia/utils/ke_jia_qi_men_ju_calculator.dart';
import 'package:qimendunjia/utils/nian_jia_qi_men_ju_calculator.dart';
import 'package:qimendunjia/utils/qi_men_ju_calculator.dart';
import 'package:qimendunjia/utils/ri_jia_qi_men_ju_calculator.dart';
import 'package:qimendunjia/utils/yue_jia_qi_men_ju_calculator.dart';
import 'package:qimendunjia/data/models/mappers/shi_jia_ju_mapper.dart';
import 'package:qimendunjia/domain/entities/ke_jia_ju.dart';
import 'package:qimendunjia/domain/entities/nian_jia_ju.dart';
import 'package:qimendunjia/domain/entities/ri_jia_ju.dart';
import 'package:qimendunjia/domain/entities/yue_jia_ju.dart';
import 'package:qimendunjia/domain/entities/shi_jia_ju.dart' as entity;

/// 奇门计算器数据源接口
///
/// 定义计算局数的标准接口；通过 [supportedJia] 暴露所属"家"维度，
/// 便于 Repository 在双维 Map（jia × arrangeType）中分发。
///
/// 返回 domain 层 [BaseJu]，时家 DataSource 通过协变返回 [entity.ShiJiaJu]，
/// 月/年家 DataSource 返回各自家级实体。
abstract class QiMenCalculatorDataSource {
  /// 计算局数
  ///
  /// [dateTime] 起盘时间
  ///
  /// 返回 domain 层 BaseJu；具体类型由实现类的协变返回决定。
  Future<BaseJu> calculate(DateTime dateTime);

  /// 获取计算器名称
  String get name;

  /// 所属家（默认时家；日/月/年家在自家 DataSource 内 override）
  QiMenJia get supportedJia => QiMenJia.SHI;
}

/// 时家计算器内部实现：调用 model 层计算器并 mapper 转 entity
entity.ShiJiaJu _shiJiaModelToEntity(ShiJiaJu modelJu) =>
    ShiJiaJuMapper.fromModel(modelJu);

/// 拆补法计算器数据源（时家）
class ChaiBuCalculatorDataSource implements QiMenCalculatorDataSource {
  @override
  Future<entity.ShiJiaJu> calculate(DateTime dateTime) async {
    final modelJu = ChaiBuCalculator(dateTime: dateTime).calculate();
    return _shiJiaModelToEntity(modelJu);
  }

  @override
  String get name => '拆补法';

  @override
  QiMenJia get supportedJia => QiMenJia.SHI;
}

/// 置润法计算器数据源（时家）
class ZhiRunCalculatorDataSource implements QiMenCalculatorDataSource {
  @override
  Future<entity.ShiJiaJu> calculate(DateTime dateTime) async {
    final modelJu = ZhiRunCalculator(dateTime: dateTime).calculate();
    return _shiJiaModelToEntity(modelJu);
  }

  @override
  String get name => '置润法';

  @override
  QiMenJia get supportedJia => QiMenJia.SHI;
}

/// 茅山法计算器数据源（时家）
class MaoShanCalculatorDataSource implements QiMenCalculatorDataSource {
  @override
  Future<entity.ShiJiaJu> calculate(DateTime dateTime) async {
    final modelJu = MaoShanCalculator(dateTime: dateTime).calculate();
    return _shiJiaModelToEntity(modelJu);
  }

  @override
  String get name => '茅山法';

  @override
  QiMenJia get supportedJia => QiMenJia.SHI;
}

/// 阴盘法计算器数据源（时家）
class YinPanCalculatorDataSource implements QiMenCalculatorDataSource {
  @override
  Future<entity.ShiJiaJu> calculate(DateTime dateTime) async {
    final modelJu = YinPanCalculator(dateTime: dateTime).calculate();
    return _shiJiaModelToEntity(modelJu);
  }

  @override
  String get name => '阴盘法';

  @override
  QiMenJia get supportedJia => QiMenJia.SHI;
}

/// 月家奇门计算器数据源
///
/// 月家有两种三元定局策略（[YueJiaSanYuanStrategy]）：
/// - COARSE（5 年一局，默认）→ 通常注册到 ArrangeType.CHAI_BU
/// - FINE（10 月一局，细分循环）→ 通常注册到 ArrangeType.ZHI_RUN
class YueJiaCalculatorDataSource implements QiMenCalculatorDataSource {
  final YueJiaSanYuanStrategy strategy;

  YueJiaCalculatorDataSource({
    this.strategy = YueJiaSanYuanStrategy.COARSE,
  });

  @override
  Future<YueJiaJu> calculate(DateTime dateTime) async {
    return YueJiaQiMenJuCalculator(
      dateTime: dateTime,
      strategy: strategy,
    ).calculate();
  }

  @override
  String get name {
    switch (strategy) {
      case YueJiaSanYuanStrategy.COARSE:
        return '月家奇门（粗分·5年一局）';
      case YueJiaSanYuanStrategy.FINE:
        return '月家奇门（细分·10月一局）';
    }
  }

  @override
  QiMenJia get supportedJia => QiMenJia.YUE;
}

/// 年家奇门计算器数据源
///
/// 年家不分拆补/置润；所有 ArrangeType 同映射到此 DataSource。
class NianJiaCalculatorDataSource implements QiMenCalculatorDataSource {
  @override
  Future<NianJiaJu> calculate(DateTime dateTime) async {
    return NianJiaQiMenJuCalculator(dateTime: dateTime).calculate();
  }

  @override
  String get name => '年家奇门';

  @override
  QiMenJia get supportedJia => QiMenJia.NIAN;
}

/// 日家奇门计算器数据源
///
/// 日家不分拆补/置润；所有 ArrangeType 同映射到此 DataSource。
/// 日家以"日"为单位起盘，专司择吉用途（详见
/// `docs/more_qimen/qimen_jia_comparison.md` §一）。
class RiJiaCalculatorDataSource implements QiMenCalculatorDataSource {
  @override
  Future<RiJiaJu> calculate(DateTime dateTime) async {
    return RiJiaQiMenJuCalculator(dateTime: dateTime).calculate();
  }

  @override
  String get name => '日家奇门';

  @override
  QiMenJia get supportedJia => QiMenJia.RI;
}

/// 刻家奇门计算器数据源
///
/// 刻家奇门是时家奇门的细分扩展。两种刻制方案：
/// - 十刻五子建元：一时辰 10 刻、每刻 12 分钟（默认）
/// - 八刻五马遁：一时辰 8 刻、每刻 15 分钟
/// 所有 ArrangeType 同映射到此 DataSource —— 内部固定用拆补法
/// 起本时辰时家初局，再按刻干支推移。
class KeJiaCalculatorDataSource implements QiMenCalculatorDataSource {
  /// [QiMenCalculatorDataSource.calculate] 默认入口，使用十刻方案。
  ///
  /// 如需指定刻制，调用 [calculateWithScheme]。
  @override
  Future<KeJiaJu> calculate(DateTime dateTime) async {
    return KeJiaQiMenJuCalculator(dateTime: dateTime).calculate();
  }

  /// 按指定刻制方案与符头派别计算
  Future<KeJiaJu> calculateWithScheme(
    DateTime dateTime,
    KeSchemeType keScheme, {
    FuTouSchemeType fuTouScheme = FuTouSchemeType.JIA_JI_FU_TOU,
  }) async {
    return KeJiaQiMenJuCalculator(
      dateTime: dateTime,
      keScheme: keScheme,
      fuTouScheme: fuTouScheme,
    ).calculate();
  }

  @override
  String get name => '刻家奇门';

  @override
  QiMenJia get supportedJia => QiMenJia.KE;
}

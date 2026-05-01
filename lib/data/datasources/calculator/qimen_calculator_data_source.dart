import 'package:qimendunjia/domain/entities/base_ju.dart';
import 'package:qimendunjia/enums/enum_qi_men_jia.dart';
import 'package:qimendunjia/model/shi_jia_ju.dart';
import 'package:qimendunjia/utils/qi_men_ju_calculator.dart';
import 'package:qimendunjia/utils/yue_jia_qi_men_ju_calculator.dart';
import 'package:qimendunjia/data/models/mappers/shi_jia_ju_mapper.dart';
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
/// 月家不分拆补/置润；所有 ArrangeType 同映射到此 DataSource。
class YueJiaCalculatorDataSource implements QiMenCalculatorDataSource {
  @override
  Future<YueJiaJu> calculate(DateTime dateTime) async {
    return YueJiaQiMenJuCalculator(dateTime: dateTime).calculate();
  }

  @override
  String get name => '月家奇门';

  @override
  QiMenJia get supportedJia => QiMenJia.YUE;
}

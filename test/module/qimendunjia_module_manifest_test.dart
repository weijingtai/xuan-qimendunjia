import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qimendunjia/qimendunjia.dart';
import 'package:repository_interface_qimendunjia/repository_interface_qimendunjia.dart';

void main() {
  group('QimendunjiaModuleManifest 公共 API', () {
    test('从 barrel 导入后 Manifest 与 NavigatorGenerator 均可访问', () {
      // 引用静态成员即可证明类型已从 barrel 导出（编译期保证）
      expect(QimendunjiaModuleManifest.id, isA<String>());
      expect(NavigatorGenerator.routes, isA<Map<String, dynamic>>());
    });

    test('模块元信息具体值', () {
      expect(QimendunjiaModuleManifest.id, 'qimendunjia');
      expect(QimendunjiaModuleManifest.displayNameKey, 'module_qimendunjia_name');
      expect(QimendunjiaModuleManifest.version, '0.1.0');
      expect(QimendunjiaModuleManifest.minShellVersion, '0.1.0-a3');
    });

    test('createProviders 装配后返回空 provider 列表（命令式 serviceLocator 模式）', () {
      // 命令式装配：init 以副作用完成，返回空列表是奇门既有架构约定
      final providers = QimendunjiaModuleManifest.createProviders(
        _FakeOfficialRuleRepository(),
        _FakeRecordRepository(),
      );
      expect(providers, isEmpty);
    });
  });

  group('NavigatorGenerator 路由表', () {
    test('routes 非空且含已知路由键', () {
      final routes = NavigatorGenerator.routes;
      expect(routes, isNotEmpty);

      // 已知的具体路由键（来自 navigator.dart 定义）
      expect(routes.keys, contains('/qimendunjia'));
      expect(routes.keys, contains('/qimendunjia/mvvm'));
      expect(routes.keys, contains('/qimendunjia/multi_jia'));
    });

    test('generateRoute 对已知路由返回 MaterialPageRoute', () {
      final route = NavigatorGenerator.generateRoute(
        const RouteSettings(name: '/qimendunjia'),
      );
      expect(route, isA<MaterialPageRoute>());
    });

    test('generateRoute 对未知路由返回错误页 Route', () {
      final route = NavigatorGenerator.generateRoute(
        const RouteSettings(name: '/nonexistent/route'),
      );
      expect(route, isA<Route<dynamic>>());
    });
  });
}

/// 假官方规则仓储，仅供 createProviders 副作用装配测试。
class _FakeOfficialRuleRepository implements QimendunjiaOfficialRuleRepository {
  @override
  Future<String> loadTenGanKeYingJson() async => '{}';

  @override
  Future<String> loadTenGanKeYingGeJuJson() async => '{}';

  @override
  Future<String> loadDoorGanKeYingJson() async => '{}';

  @override
  Future<String> loadQiYiRuGongJson() async => '{}';

  @override
  Future<String> loadQiYiRuGongDiseaseJson() async => '{}';

  @override
  Future<String> loadDoorStarKeYingJson() async => '{}';

  @override
  Future<String> loadEightDoorKeYingJson() async => '{}';
}

/// 假记录仓储，仅供 createProviders 副作用装配测试。
class _FakeRecordRepository implements QimenRecordRepository {
  @override
  Future<String> saveRecord(QimenDivinationRecordContract record) async => 'fake-uuid';

  @override
  Future<List<QimenDivinationRecordContract>> getAllRecords() async => [];

  @override
  Future<QimenDivinationRecordContract?> getRecordByUuid(String uuid) async => null;

  @override
  Future<bool> softDeleteRecord(String uuid) async => true;

  @override
  Stream<List<QimenDivinationRecordContract>> watchAllRecords() async* {
    yield [];
  }
}

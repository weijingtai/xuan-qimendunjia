import 'package:qimendunjia/domain/entities/base_ju.dart';
import 'package:qimendunjia/domain/entities/qimen_pan.dart';

/// 奇门遁甲密封状态类
///
/// 使用 Dart 3 sealed class 表示 ViewModel 的核心状态。
/// 子类：
/// - [QiMenIdle]         — 初始状态，尚未排盘
/// - [QiMenCalculating]  — 计算中 / 排盘中 / 加载宫位详情中
/// - [QiMenSuccess]      — 排盘成功，持有 [pan] 和 [ju]
/// - [QiMenError]        — 发生错误，持有 [message]
sealed class QiMenState {
  const QiMenState();
}

/// 初始状态
class QiMenIdle extends QiMenState {
  const QiMenIdle();
}

/// 计算中（涵盖计算局数、排盘、加载宫位详情等异步操作）
class QiMenCalculating extends QiMenState {
  const QiMenCalculating();
}

/// 排盘成功
///
/// 持有完整盘局 [pan] 和局信息 [ju]。
/// 使用 [BaseJu] 以支持时/日/月/年/刻五家。
class QiMenSuccess extends QiMenState {
  final QiMenPan pan;
  final BaseJu ju;
  const QiMenSuccess({required this.pan, required this.ju});
}

/// 发生错误
class QiMenError extends QiMenState {
  final String message;
  const QiMenError(this.message);
}

import 'package:qimendunjia/presentation/models/qimen_display_state.dart';

/// Sealed union representing the full UI state of any QiMen page.
///
/// Pages pattern-match on this to decide what to render:
/// - [empty]   → show input form (no pan yet)
/// - [loading] → show spinner / skeleton
/// - [success] → show pan with [QiMenDisplayState]
/// - [error]   → show error message + retry
///
/// This replaces the scattered `QiMenViewState` enum + nullable data fields
/// previously living inside ViewModel and page-level state.
sealed class QiMenUiState {
  const QiMenUiState();

  /// Factory for the initial / idle state.
  const factory QiMenUiState.empty() = QiMenUiStateEmpty;

  /// Factory for loading (calculating ju, arranging pan, or loading detail).
  const factory QiMenUiState.loading() = QiMenUiStateLoading;

  /// Factory for success with display data.
  const factory QiMenUiState.success(QiMenDisplayState displayState) =
      QiMenUiStateSuccess;

  /// Factory for error with message.
  const factory QiMenUiState.error(String message) = QiMenUiStateError;

  // ---------------------------------------------------------------------------
  // Pattern-matching helpers (for pages that don't use Dart 3 switch expressions)
  // ---------------------------------------------------------------------------

  T when<T>({
    required T Function() empty,
    required T Function() loading,
    required T Function(QiMenDisplayState displayState) success,
    required T Function(String message) error,
  }) {
    final self = this;
    if (self is QiMenUiStateEmpty) return empty();
    if (self is QiMenUiStateLoading) return loading();
    if (self is QiMenUiStateSuccess) return success(self.displayState);
    if (self is QiMenUiStateError) return error(self.message);
    throw StateError('Unknown QiMenUiState: $runtimeType');
  }

  /// Convenience getters
  bool get isEmpty => this is QiMenUiStateEmpty;
  bool get isLoading => this is QiMenUiStateLoading;
  bool get isSuccess => this is QiMenUiStateSuccess;
  bool get isError => this is QiMenUiStateError;
}

/// No pan computed yet — input form should be shown.
class QiMenUiStateEmpty extends QiMenUiState {
  const QiMenUiStateEmpty();
}

/// Pan is being computed (ju calculation, pan arrangement, or detail loading).
class QiMenUiStateLoading extends QiMenUiState {
  const QiMenUiStateLoading();
}

/// Pan computed successfully.
class QiMenUiStateSuccess extends QiMenUiState {
  final QiMenDisplayState displayState;
  const QiMenUiStateSuccess(this.displayState);
}

/// An error occurred.
class QiMenUiStateError extends QiMenUiState {
  final String message;
  const QiMenUiStateError(this.message);
}

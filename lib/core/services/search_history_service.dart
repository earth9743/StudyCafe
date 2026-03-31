import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences 기반 검색 기록 관리 서비스
///
/// 최대 [maxHistoryCount]개의 검색어를 LIFO 순서로 저장한다.
/// 중복 검색어는 기존 항목을 제거하고 최신 위치로 이동시킨다.
class SearchHistoryService {
  SearchHistoryService(this._prefs);

  final SharedPreferences _prefs;

  static const String _storageKey = 'search_history';
  static const int maxHistoryCount = 20;

  /// 저장된 검색 기록을 최신순으로 반환한다.
  List<String> getHistory() {
    return _prefs.getStringList(_storageKey) ?? [];
  }

  /// 검색어를 기록에 추가한다.
  ///
  /// - 빈 문자열이나 공백만 있는 검색어는 무시한다.
  /// - 이미 존재하는 검색어는 최신 위치(인덱스 0)로 이동한다.
  /// - 최대 [maxHistoryCount]개를 초과하면 가장 오래된 항목을 제거한다.
  Future<void> addQuery(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    final history = getHistory();

    // 중복 제거 후 맨 앞에 삽입
    history.remove(trimmed);
    history.insert(0, trimmed);

    // 최대 개수 제한
    if (history.length > maxHistoryCount) {
      history.removeRange(maxHistoryCount, history.length);
    }

    await _prefs.setStringList(_storageKey, history);
  }

  /// 특정 검색어를 기록에서 삭제한다.
  Future<void> removeQuery(String query) async {
    final history = getHistory();
    history.remove(query);
    await _prefs.setStringList(_storageKey, history);
  }

  /// 모든 검색 기록을 삭제한다.
  Future<void> clearAll() async {
    await _prefs.remove(_storageKey);
  }
}

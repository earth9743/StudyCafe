import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kagong_map/core/services/search_history_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences 인스턴스 프로바이더
final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) async {
  return SharedPreferences.getInstance();
});

/// SearchHistoryService 프로바이더
final searchHistoryServiceProvider = FutureProvider<SearchHistoryService>((ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return SearchHistoryService(prefs);
});

/// 검색 기록 상태를 관리하는 Notifier
///
/// 검색 기록의 추가, 삭제, 전체 삭제를 처리하며
/// UI에 반응적으로 상태를 전달한다.
class SearchHistoryNotifier extends AsyncNotifier<List<String>> {
  @override
  Future<List<String>> build() async {
    final service = await ref.watch(searchHistoryServiceProvider.future);
    return service.getHistory();
  }

  /// 검색어를 기록에 추가한다.
  Future<void> addQuery(String query) async {
    final service = await ref.read(searchHistoryServiceProvider.future);
    await service.addQuery(query);
    state = AsyncData(service.getHistory());
  }

  /// 특정 검색어를 기록에서 삭제한다.
  Future<void> removeQuery(String query) async {
    final service = await ref.read(searchHistoryServiceProvider.future);
    await service.removeQuery(query);
    state = AsyncData(service.getHistory());
  }

  /// 모든 검색 기록을 삭제한다.
  Future<void> clearAll() async {
    final service = await ref.read(searchHistoryServiceProvider.future);
    await service.clearAll();
    state = const AsyncData([]);
  }
}

/// 검색 기록 상태 프로바이더
final searchHistoryProvider =
    AsyncNotifierProvider<SearchHistoryNotifier, List<String>>(
  SearchHistoryNotifier.new,
);

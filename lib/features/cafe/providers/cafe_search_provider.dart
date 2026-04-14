import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:kagong_map/core/services/kakao_search_service.dart';
import 'package:kagong_map/core/constants/cafe_franchises.dart';
import 'package:kagong_map/features/cafe/domain/models/cafe_place_model.dart';

final kakaoSearchServiceProvider = Provider<KakaoSearchService>((ref) {
  return KakaoSearchService();
});

/// 한글 자모(미완성 글자)인지 확인
bool _endsWithIncompleteJamo(String text) {
  if (text.isEmpty) return false;
  final lastChar = text.codeUnitAt(text.length - 1);
  // ㄱ~ㅎ (0x3131~0x314E) 또는 ㅏ~ㅣ (0x314F~0x3163)
  return (lastChar >= 0x3131 && lastChar <= 0x3163);
}

class CafeSearchQueryNotifier extends Notifier<String> {
  Timer? _debounceTimer;
  TextEditingController? _controller;

  @override
  String build() {
    ref.onDispose(() => _debounceTimer?.cancel());
    return '';
  }

  void attachController(TextEditingController controller) {
    _controller = controller;
  }

  void setQuery(String query) => state = query;

  /// 디바운스 적용 - 한글 조합 완료 후에만 검색 실행
  void setQueryDebounced(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      // 타이머 실행 시점의 실제 텍스트를 사용
      final currentText = _controller?.text ?? query;

      // 아직 조합 중이면 검색하지 않음
      if (_controller != null &&
          _controller!.value.composing != TextRange.empty) {
        return;
      }

      // 마지막 글자가 미완성 자모(ㄹ, ㅁ 등)이면 검색하지 않음
      if (_endsWithIncompleteJamo(currentText)) {
        return;
      }

      state = currentText;
    });
  }
}

final cafeSearchQueryProvider =
    NotifierProvider<CafeSearchQueryNotifier, String>(
        CafeSearchQueryNotifier.new);

/// 카카오 로컬 검색 API를 사용한 카페 검색
///
/// 현재 위치 좌표 + 반경 5km + 거리순 정렬을 카카오 API에 위임하여
/// 기존의 다중 검색 + 클라이언트 정렬 로직을 단순화한다.
/// 프랜차이즈 사전은 부분 일치 보완용으로 유지한다.
final cafeSearchResultsProvider =
    FutureProvider.autoDispose<List<CafePlaceModel>>((ref) async {
  final query = ref.watch(cafeSearchQueryProvider);
  if (query.trim().length < 2) return [];

  final service = ref.watch(kakaoSearchServiceProvider);

  // 현재 위치 가져오기
  Position? position;
  try {
    position = await Geolocator.getLastKnownPosition() ??
        await Geolocator.getCurrentPosition();
  } catch (_) {
    // 위치 권한 없으면 좌표 없이 검색
  }

  // 프랜차이즈 사전에서 매칭되는 브랜드명 수집
  final franchiseBrands = <String>{};
  for (final entry in cafeFranchiseMap.entries) {
    if (query.contains(entry.key) || query.startsWith(entry.key)) {
      franchiseBrands.add(entry.value);
    }
  }

  // 카카오 API로 검색 실행
  final futures = <Future<List<CafePlaceModel>>>[];

  if (position != null) {
    // 좌표 있으면: 원본 쿼리 + 카페 카테고리 필터 + 거리순
    futures.add(service.searchPlaces(
      query,
      x: position.longitude,
      y: position.latitude,
      radius: 5000,
      categoryGroupCode: 'CE7',
      sort: 'distance',
    ));

    // 카페 카테고리 없이도 검색 (카페가 아닌 카테고리로 등록된 경우 대비)
    futures.add(service.searchPlaces(
      '$query 카페',
      x: position.longitude,
      y: position.latitude,
      radius: 5000,
      sort: 'distance',
    ));

    // 프랜차이즈 브랜드명 추가 검색
    for (final brand in franchiseBrands) {
      futures.add(service.searchPlaces(
        brand,
        x: position.longitude,
        y: position.latitude,
        radius: 5000,
        categoryGroupCode: 'CE7',
        sort: 'distance',
      ));
    }
  } else {
    // 좌표 없으면: 정확도순 검색
    futures.add(service.searchPlaces(query, categoryGroupCode: 'CE7'));
    futures.add(service.searchPlaces('$query 카페'));

    for (final brand in franchiseBrands) {
      futures.add(service.searchPlaces(brand, categoryGroupCode: 'CE7'));
    }
  }

  final results = await Future.wait(futures);

  // 모든 결과 병합 후 중복 제거 (같은 이름+주소 기준)
  final seen = <String>{};
  final merged = <CafePlaceModel>[];
  for (final places in results) {
    for (final place in places) {
      final key = '${place.name}|${place.address}';
      if (seen.add(key)) {
        merged.add(place);
      }
    }
  }

  // 카카오 API가 거리순으로 반환하므로 추가 정렬은 불필요하지만,
  // 다중 검색 결과 병합 시 순서가 섞일 수 있으므로 위치 있을 때만 재정렬
  if (position != null) {
    merged.sort((a, b) {
      final distA = int.tryParse(a.distance ?? '') ?? 999999;
      final distB = int.tryParse(b.distance ?? '') ?? 999999;
      return distA.compareTo(distB);
    });
  }

  return merged;
});

/// 일반 장소 검색 (카페 카테고리 필터 없이)
///
/// "부천역", "강남역" 등 카페가 아닌 장소를 검색할 때 사용한다.
/// 카페 검색 결과와 중복되지 않는 장소만 반환한다.
final placeSearchResultsProvider =
    FutureProvider.autoDispose<List<CafePlaceModel>>((ref) async {
  final query = ref.watch(cafeSearchQueryProvider);
  if (query.trim().length < 2) return [];

  final service = ref.watch(kakaoSearchServiceProvider);

  Position? position;
  try {
    position = await Geolocator.getLastKnownPosition() ??
        await Geolocator.getCurrentPosition();
  } catch (_) {}

  List<CafePlaceModel> places;
  if (position != null) {
    places = await service.searchPlaces(
      query,
      x: position.longitude,
      y: position.latitude,
      radius: 20000,
      sort: 'accuracy',
      size: 5,
    );
  } else {
    places = await service.searchPlaces(
      query,
      sort: 'accuracy',
      size: 5,
    );
  }

  // 카페 카테고리(CE7) 결과 제외 — 카페는 cafeSearchResultsProvider에서 처리
  return places
      .where((p) => !p.category.contains('카페'))
      .toList();
});

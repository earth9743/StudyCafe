import 'dart:async';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:kagong_map/core/services/naver_search_service.dart';
import 'package:kagong_map/features/cafe/domain/models/naver_place_model.dart';

final naverSearchServiceProvider = Provider<NaverSearchService>((ref) {
  return NaverSearchService();
});

/// 한글 자모(미완성 글자)인지 확인
bool _endsWithIncompleteJamo(String text) {
  if (text.isEmpty) return false;
  final lastChar = text.codeUnitAt(text.length - 1);
  // ㄱ~ㅎ (0x3131~0x314E) 또는 ㅏ~ㅣ (0x314F~0x3163)
  return (lastChar >= 0x3131 && lastChar <= 0x3163);
}

/// 두 좌표 간 거리 계산 (Haversine, km)
double _distanceKm(double lat1, double lng1, double lat2, double lng2) {
  const R = 6371.0; // 지구 반지름 (km)
  final dLat = _toRad(lat2 - lat1);
  final dLng = _toRad(lng2 - lng1);
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(_toRad(lat1)) * cos(_toRad(lat2)) * sin(dLng / 2) * sin(dLng / 2);
  final c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return R * c;
}

double _toRad(double deg) => deg * pi / 180;

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

/// 검색 결과를 현재 위치 기준 가까운 순으로 정렬
final cafeSearchResultsProvider =
    FutureProvider.autoDispose<List<NaverPlaceModel>>((ref) async {
  final query = ref.watch(cafeSearchQueryProvider);
  if (query.trim().length < 2) return [];

  final service = ref.watch(naverSearchServiceProvider);
  final places = await service.searchPlaces('$query 카페');

  // 현재 위치 기준 거리순 정렬
  try {
    final position = await Geolocator.getLastKnownPosition() ??
        await Geolocator.getCurrentPosition();
    places.sort((a, b) {
      final distA =
          _distanceKm(position.latitude, position.longitude, a.lat, a.lng);
      final distB =
          _distanceKm(position.latitude, position.longitude, b.lat, b.lng);
      return distA.compareTo(distB);
    });
  } catch (_) {
    // 위치 권한 없으면 기본 순서 유지
  }

  return places;
});

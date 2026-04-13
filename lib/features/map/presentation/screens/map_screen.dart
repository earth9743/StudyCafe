import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:kagong_map/core/services/kakao_search_service.dart';
import 'package:kagong_map/core/theme/app_colors.dart';
import 'package:kagong_map/features/cafe/domain/models/cafe_place_model.dart';
import 'package:kagong_map/features/cafe/presentation/widgets/cafe_detail_bottom_sheet.dart';
import 'package:kagong_map/features/cafe/providers/cafe_search_provider.dart';
import 'package:kagong_map/features/cafe/providers/search_history_provider.dart';

/// 메인 지도 화면 - 네이버 지도 표시
class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  bool _isMapReady = false;
  bool _isSearching = false;
  NaverMapController? _mapController;
  final _searchController = TextEditingController();
  final _kakaoService = KakaoSearchService();

  /// 현재 지도에 표시 중인 주변 카페 목록 (마커 탭 시 상세 표시용)
  final Map<String, CafePlaceModel> _nearbyCafes = {};
  Timer? _cameraIdleTimer;

  /// 커스텀 카페 마커 아이콘 (한 번 생성 후 재사용)
  NOverlayImage? _cafeMarkerIcon;

  @override
  void dispose() {
    _searchController.dispose();
    _cameraIdleTimer?.cancel();
    super.dispose();
  }

  /// 현재 위치로 카메라 이동
  Future<void> _moveToCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      final position = await Geolocator.getCurrentPosition();
      final target = NLatLng(position.latitude, position.longitude);

      await _mapController?.updateCamera(
        NCameraUpdate.scrollAndZoomTo(target: target, zoom: 15),
      );

      // 현재 위치 마커
      final marker = NMarker(id: 'my_location', position: target);
      marker.setCaption(const NOverlayCaption(text: '내 위치'));
      _mapController?.addOverlay(marker);

      // 주변 카페 로드
      _loadNearbyCafes(position.latitude, position.longitude);
    } catch (e) {
      debugPrint('[Location] 위치 오류: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('위치를 가져올 수 없습니다')),
        );
      }
    }
  }

  /// 커스텀 카페 마커 아이콘 생성 (최초 1회)
  Future<NOverlayImage> _getOrCreateMarkerIcon() async {
    if (_cafeMarkerIcon != null) return _cafeMarkerIcon!;

    _cafeMarkerIcon = await NOverlayImage.fromWidget(
      context: context,
      widget: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(
          Icons.local_cafe,
          color: Colors.white,
          size: 14,
        ),
      ),
      size: const Size(30, 30),
    );

    return _cafeMarkerIcon!;
  }

  /// 주변 카페를 카카오 API로 검색하여 지도에 마커로 표시
  Future<void> _loadNearbyCafes(double lat, double lng) async {
    try {
      final cafes = await _kakaoService.searchNearbyCafes(
        latitude: lat,
        longitude: lng,
        radius: 2000,
        size: 15,
      );

      if (!mounted || _mapController == null) return;

      _nearbyCafes.clear();

      final markerIcon = await _getOrCreateMarkerIcon();

      for (final cafe in cafes) {
        final markerId = 'cafe_${cafe.lat}_${cafe.lng}';
        _nearbyCafes[markerId] = cafe;

        final marker = NMarker(
          id: markerId,
          position: NLatLng(cafe.lat, cafe.lng),
          icon: markerIcon,
        );
        marker.setSize(const Size(30, 30));
        marker.setCaption(NOverlayCaption(
          text: cafe.name,
          textSize: 10,
          color: AppColors.textPrimary,
          haloColor: Colors.white,
        ));

        marker.setOnTapListener((overlay) {
          final tappedCafe = _nearbyCafes[overlay.info.id];
          if (tappedCafe != null && mounted) {
            // 마커 탭: 컴팩트 모드 (스크롤 업하면 전체 펼침)
            CafeDetailBottomSheet.showCompact(context, tappedCafe);
          }
        });

        _mapController?.addOverlay(marker);
      }

      debugPrint('[Map] 주변 카페 ${cafes.length}개 마커 표시');
    } catch (e) {
      debugPrint('[Map] 주변 카페 로드 실패: $e');
    }
  }

  void _showSearchSheet() {
    _searchController.clear();
    final notifier = ref.read(cafeSearchQueryProvider.notifier);
    notifier.setQuery('');
    notifier.attachController(_searchController);
    setState(() => _isSearching = true);
  }

  void _hideSearchSheet() {
    setState(() => _isSearching = false);
    FocusScope.of(context).unfocus();
  }

  /// 검색어를 기록에 저장하고 검색을 실행한다.
  void _executeSearchFromHistory(String query) {
    _searchController.text = query;
    ref.read(cafeSearchQueryProvider.notifier).setQuery(query);
    ref.read(searchHistoryProvider.notifier).addQuery(query);
  }

  Future<void> _selectPlace(CafePlaceModel place) async {
    // 현재 검색어를 기록에 저장
    final currentQuery = ref.read(cafeSearchQueryProvider);
    if (currentQuery.trim().isNotEmpty) {
      ref.read(searchHistoryProvider.notifier).addQuery(currentQuery.trim());
    }
    _hideSearchSheet();

    final target = NLatLng(place.lat, place.lng);

    // 선택된 카페로 카메라 이동 (onCameraIdle에서 주변 카페 자동 로드)
    await _mapController?.updateCamera(
      NCameraUpdate.scrollAndZoomTo(target: target, zoom: 16),
    );

    // 카페 선택 시 Bottom Sheet 표시
    if (mounted) {
      CafeDetailBottomSheet.show(context, place);
    }
  }

  /// 마이페이지 버튼
  Widget _buildMyPageButton() {
    return Container(
      height: 48,
      width: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        onPressed: () => context.push('/mypage'),
        icon: const Icon(Icons.person, color: AppColors.primary),
        tooltip: '마이페이지',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          NaverMap(
            options: const NaverMapViewOptions(
              initialCameraPosition: NCameraPosition(
                target: NLatLng(37.5665, 126.9780),
                zoom: 14,
              ),
              mapType: NMapType.basic,
              activeLayerGroups: [NLayerGroup.building, NLayerGroup.transit],
              locationButtonEnable: false,
              locale: NLocale('ko'),
            ),
            onMapReady: (controller) {
              debugPrint('[NaverMap] 지도 준비 완료');
              _mapController = controller;
              setState(() => _isMapReady = true);
              _moveToCurrentLocation();
            },
            onCameraIdle: () {
              // 카메라 이동 완료 시 디바운스 후 주변 카페 갱신
              _cameraIdleTimer?.cancel();
              _cameraIdleTimer = Timer(const Duration(milliseconds: 800), () async {
                if (_mapController == null || _isSearching || !mounted) return;
                final cameraPosition = await _mapController!.getCameraPosition();
                final target = cameraPosition.target;
                _loadNearbyCafes(target.latitude, target.longitude);
              });
            },
          ),
          // 지도 로딩 중 표시
          if (!_isMapReady)
            Container(
              color: Colors.white,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppColors.primary),
                    SizedBox(height: 16),
                    Text(
                      '지도를 불러오는 중...',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // 상단 검색바
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _showSearchSheet,
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Row(
                          children: [
                            SizedBox(width: 16),
                            Icon(Icons.search, color: AppColors.textSecondary),
                            SizedBox(width: 8),
                            Text(
                              '카페 이름을 입력해주세요',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildMyPageButton(),
                ],
              ),
            ),
          ),
          // 현재 위치 버튼 (우측 하단)
          Positioned(
            right: 16,
            bottom: 32,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                onPressed: _moveToCurrentLocation,
                icon: const Icon(Icons.my_location, color: AppColors.primary),
              ),
            ),
          ),
          // 검색 패널
          if (_isSearching) _buildSearchPanel(),
        ],
      ),
    );
  }

  Widget _buildSearchPanel() {
    final searchResults = ref.watch(cafeSearchResultsProvider);

    return Container(
      color: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    // Theme + CupertinoTheme 이중 래핑:
                    // iOS 한글 IME 조합 시 파란 밑줄 방지
                    // colorScheme.primary를 textPrimary로 덮어써야
                    // 조합 중 밑줄이 navy가 아닌 검정으로 표시됨
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: Theme.of(context).colorScheme.copyWith(
                          primary: AppColors.textPrimary,
                        ),
                        cupertinoOverrideTheme: const CupertinoThemeData(
                          primaryColor: AppColors.textPrimary,
                        ),
                        textSelectionTheme: TextSelectionThemeData(
                          cursorColor: AppColors.primary,
                          selectionColor:
                              Colors.grey.withValues(alpha: 0.15),
                          selectionHandleColor: AppColors.primary,
                        ),
                      ),
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        autocorrect: false,
                        enableSuggestions: false,
                        stylusHandwritingEnabled: false,
                        // Scan Text (iOS Live Text) 제거
                        contextMenuBuilder: (context, editableTextState) {
                          final buttonItems =
                              editableTextState.contextMenuButtonItems;
                          buttonItems.removeWhere((item) =>
                              item.type ==
                              ContextMenuButtonType.liveTextInput);
                          return AdaptiveTextSelectionToolbar.buttonItems(
                            anchors: editableTextState.contextMenuAnchors,
                            buttonItems: buttonItems,
                          );
                        },
                        cursorColor: AppColors.primary,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                        ),
                        decoration: InputDecoration(
                          hintText: '카페 이름을 입력해주세요 (예: 스타벅스)',
                          prefixIcon: const Icon(
                              Icons.search, color: AppColors.primary),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? GestureDetector(
                                  onTap: () {
                                    _searchController.clear();
                                    ref
                                        .read(cafeSearchQueryProvider.notifier)
                                        .setQuery('');
                                  },
                                  child: const Icon(
                                    Icons.close,
                                    size: 14,
                                    color: AppColors.textSecondary,
                                  ),
                                )
                              : null,
                          filled: true,
                          fillColor: AppColors.secondary,
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        onChanged: (value) {
                          setState(() {}); // X 버튼 표시/숨김 갱신
                          ref
                              .read(cafeSearchQueryProvider.notifier)
                              .setQueryDebounced(value);
                        },
                        onSubmitted: (value) {
                          ref
                              .read(cafeSearchQueryProvider.notifier)
                              .setQuery(value);
                          if (value.trim().isNotEmpty) {
                            ref
                                .read(searchHistoryProvider.notifier)
                                .addQuery(value.trim());
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: _hideSearchSheet,
                    child: const Text(
                      '취소',
                      style: TextStyle(color: AppColors.primary, fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: searchResults.when(
                data: (places) {
                  if (places.isEmpty) {
                    final query = ref.read(cafeSearchQueryProvider);
                    if (query.isEmpty) {
                      return _buildSearchHistoryList();
                    }
                    return const Center(
                      child: Text(
                        '검색 결과가 없습니다',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: places.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final place = places[index];
                      return ListTile(
                        leading: const Icon(
                          Icons.local_cafe,
                          color: AppColors.primary,
                        ),
                        title: Text(
                          place.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          place.roadAddress.isNotEmpty
                              ? place.roadAddress
                              : place.address,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                        onTap: () => _selectPlace(place),
                      );
                    },
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
                error: (e, _) => Center(
                  child: Text(
                    '검색 오류: $e',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 검색어가 비어 있을 때 최근 검색 기록을 표시한다.
  Widget _buildSearchHistoryList() {
    final historyAsync = ref.watch(searchHistoryProvider);

    return historyAsync.when(
      data: (history) {
        if (history.isEmpty) {
          return const Center(
            child: Text(
              '최근 검색 기록이 없습니다',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(
                '최근 검색',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: history.length,
                separatorBuilder: (_, _) => const Divider(
                  height: 1,
                  indent: 48,
                  color: AppColors.divider,
                ),
                itemBuilder: (context, index) {
                  final query = history[index];
                  return ListTile(
                    leading: const Icon(
                      Icons.history,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    title: Text(
                      query,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.close,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () {
                        ref
                            .read(searchHistoryProvider.notifier)
                            .removeQuery(query);
                      },
                    ),
                    contentPadding: const EdgeInsets.only(left: 16, right: 4),
                    onTap: () => _executeSearchFromHistory(query),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (_, _) => const Center(
        child: Text(
          '검색 기록을 불러올 수 없습니다',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      ),
    );
  }
}

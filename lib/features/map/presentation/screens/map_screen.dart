import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:kagong_map/core/theme/app_colors.dart';
import 'package:kagong_map/features/auth/providers/auth_provider.dart';
import 'package:kagong_map/features/cafe/domain/models/naver_place_model.dart';
import 'package:kagong_map/features/cafe/presentation/widgets/cafe_detail_bottom_sheet.dart';
import 'package:kagong_map/features/cafe/providers/cafe_search_provider.dart';

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

  @override
  void dispose() {
    _searchController.dispose();
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
    } catch (e) {
      debugPrint('[Location] 위치 오류: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('위치를 가져올 수 없습니다')),
        );
      }
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

  Future<void> _selectPlace(NaverPlaceModel place) async {
    _hideSearchSheet();

    final target = NLatLng(place.lat, place.lng);

    final marker = NMarker(
      id: '${place.lat}_${place.lng}',
      position: target,
    );
    marker.setCaption(NOverlayCaption(text: place.name));

    // 마커 탭 시에도 Bottom Sheet 표시
    marker.setOnTapListener((overlay) {
      if (mounted) {
        CafeDetailBottomSheet.show(context, place);
      }
    });

    _mapController?.clearOverlays();
    _mapController?.addOverlay(marker);

    await _mapController?.updateCamera(
      NCameraUpdate.scrollAndZoomTo(target: target, zoom: 16),
    );

    // 카페 선택 시 Bottom Sheet 표시
    if (mounted) {
      CafeDetailBottomSheet.show(context, place);
    }
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
                              '카페 검색',
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
                  Container(
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
                      onPressed: () {
                        ref.read(authControllerProvider.notifier).signOut();
                      },
                      icon: const Icon(Icons.logout, color: AppColors.primary),
                    ),
                  ),
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
                          hintText: '지역명 또는 카페 이름 검색',
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
                          filled: true,
                          fillColor: AppColors.secondary,
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        onChanged: (value) {
                          ref
                              .read(cafeSearchQueryProvider.notifier)
                              .setQueryDebounced(value);
                        },
                        onSubmitted: (value) {
                          ref
                              .read(cafeSearchQueryProvider.notifier)
                              .setQuery(value);
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
                      return const Center(
                        child: Text(
                          '검색어를 입력해주세요',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      );
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
}

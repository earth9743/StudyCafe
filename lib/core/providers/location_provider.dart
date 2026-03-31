import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

/// 현재 위치를 제공하는 Provider
/// 앱 시작 시 또는 검색 시 위치를 가져옴
final currentLocationProvider = FutureProvider<Position?>((ref) async {
  try {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    if (permission == LocationPermission.deniedForever) return null;

    return await Geolocator.getCurrentPosition();
  } catch (e) {
    return null;
  }
});

/// 현재 위치의 시/구 이름을 역지오코딩으로 추출하는 Provider
/// 예: "의왕시", "강남구" 등
/// 검색어에 지역명을 자동 추가하여 네이버 지역 검색 API의 한계를 보완
final currentLocalityProvider = FutureProvider<String?>((ref) async {
  final position = await ref.watch(currentLocationProvider.future);
  if (position == null) return null;

  try {
    final placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );

    if (placemarks.isEmpty) return null;

    final placemark = placemarks.first;
    debugPrint(
      '[Geocoding] locality: ${placemark.locality}, '
      'subLocality: ${placemark.subLocality}, '
      'administrativeArea: ${placemark.administrativeArea}, '
      'subAdministrativeArea: ${placemark.subAdministrativeArea}',
    );

    // 구(subLocality)가 있으면 우선 사용 (예: "강남구")
    // 없으면 시(locality) 사용 (예: "의왕시")
    // 둘 다 없으면 subAdministrativeArea 시도
    final locality = placemark.subLocality?.isNotEmpty == true
        ? placemark.subLocality
        : placemark.locality?.isNotEmpty == true
            ? placemark.locality
            : placemark.subAdministrativeArea;

    debugPrint('[Geocoding] 선택된 지역명: $locality');
    return locality;
  } catch (e) {
    debugPrint('[Geocoding] 역지오코딩 오류: $e');
    return null;
  }
});

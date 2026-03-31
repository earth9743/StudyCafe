import 'package:flutter_riverpod/flutter_riverpod.dart';
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

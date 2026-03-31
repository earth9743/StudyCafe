/// 카페 장소 모델
///
/// 검색 API(카카오/네이버)로부터 받은 장소 데이터를 통합하는 범용 모델.
/// 기존 NaverPlaceModel을 대체하며, 동일한 필드 구조를 유지한다.
class CafePlaceModel {
  final String name;
  final String roadAddress;
  final String address;
  final String category;
  final String phone;
  final double lat;
  final double lng;

  /// 카카오 API 응답의 거리(m). 좌표 파라미터 제공 시에만 값이 존재한다.
  final String? distance;

  const CafePlaceModel({
    required this.name,
    required this.roadAddress,
    required this.address,
    required this.category,
    required this.phone,
    required this.lat,
    required this.lng,
    this.distance,
  });

  /// 카카오 로컬 검색 API 응답(documents[] 항목)으로부터 모델을 생성한다.
  factory CafePlaceModel.fromKakaoJson(Map<String, dynamic> json) {
    return CafePlaceModel(
      name: json['place_name'] as String? ?? '',
      roadAddress: json['road_address_name'] as String? ?? '',
      address: json['address_name'] as String? ?? '',
      category: json['category_name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      lat: double.tryParse(json['y']?.toString() ?? '') ?? 0.0,
      lng: double.tryParse(json['x']?.toString() ?? '') ?? 0.0,
      distance: json['distance'] as String?,
    );
  }

  /// 네이버 지역 검색 API 응답(items[] 항목)으로부터 모델을 생성한다.
  /// 레거시 호환용으로 유지한다.
  factory CafePlaceModel.fromNaverJson(Map<String, dynamic> json) {
    final mapx = int.tryParse(json['mapx']?.toString() ?? '') ?? 0;
    final mapy = int.tryParse(json['mapy']?.toString() ?? '') ?? 0;

    return CafePlaceModel(
      name: (json['title'] as String? ?? '').replaceAll(RegExp(r'<[^>]*>'), ''),
      roadAddress: json['roadAddress'] as String? ?? '',
      address: json['address'] as String? ?? '',
      category: json['category'] as String? ?? '',
      phone: json['telephone'] as String? ?? '',
      lat: mapy / 10000000.0,
      lng: mapx / 10000000.0,
    );
  }
}

class NaverPlaceModel {
  final String name;
  final String roadAddress;
  final String address;
  final String category;
  final String phone;
  final double lat;
  final double lng;

  const NaverPlaceModel({
    required this.name,
    required this.roadAddress,
    required this.address,
    required this.category,
    required this.phone,
    required this.lat,
    required this.lng,
  });

  factory NaverPlaceModel.fromJson(Map<String, dynamic> json) {
    // 네이버 지역 검색 API: mapx/mapy는 WGS84 좌표 * 10,000,000
    final mapx = int.tryParse(json['mapx']?.toString() ?? '') ?? 0;
    final mapy = int.tryParse(json['mapy']?.toString() ?? '') ?? 0;

    return NaverPlaceModel(
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

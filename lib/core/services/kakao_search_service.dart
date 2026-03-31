import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:kagong_map/core/constants/app_constants.dart';
import 'package:kagong_map/features/cafe/domain/models/cafe_place_model.dart';

/// 카카오 로컬 검색 API를 사용한 장소 검색 서비스
///
/// 키워드 검색 및 카페 카테고리 필터링을 지원하며,
/// 좌표 기반 거리순 정렬을 카카오 API에 위임한다.
class KakaoSearchService {
  late final Dio _dio;

  KakaoSearchService() {
    _dio = Dio(BaseOptions(
      baseUrl: 'https://dapi.kakao.com',
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
      headers: {
        'Authorization': 'KakaoAK ${AppConstants.kakaoRestApiKey}',
      },
    ));
  }

  /// 키워드로 장소를 검색한다.
  ///
  /// [query] 검색어 (필수)
  /// [x] 경도 (longitude) - 거리순 정렬 및 거리 계산에 사용
  /// [y] 위도 (latitude) - 거리순 정렬 및 거리 계산에 사용
  /// [radius] 반경(m) - 최대 20000
  /// [categoryGroupCode] 카테고리 그룹 코드 (예: CE7 = 카페)
  /// [page] 페이지 번호 (1~45)
  /// [size] 한 페이지 결과 수 (1~15, 기본 15)
  Future<List<CafePlaceModel>> searchPlaces(
    String query, {
    double? x,
    double? y,
    int? radius,
    String? categoryGroupCode,
    String sort = 'distance',
    int page = 1,
    int size = 15,
  }) async {
    try {
      debugPrint('[KakaoSearch] 검색 시작: $query');

      final queryParameters = <String, dynamic>{
        'query': query,
        'sort': sort,
        'page': page,
        'size': size,
      };

      if (x != null && y != null) {
        queryParameters['x'] = x.toString();
        queryParameters['y'] = y.toString();
        if (radius != null) {
          queryParameters['radius'] = radius;
        }
      }

      if (categoryGroupCode != null) {
        queryParameters['category_group_code'] = categoryGroupCode;
      }

      final response = await _dio.get(
        '/v2/local/search/keyword.json',
        queryParameters: queryParameters,
      );

      debugPrint('[KakaoSearch] 응답 상태: ${response.statusCode}');

      final List<dynamic> documents = response.data['documents'] ?? [];
      debugPrint('[KakaoSearch] 결과 수: ${documents.length}');

      return documents
          .map((doc) =>
              CafePlaceModel.fromKakaoJson(doc as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      debugPrint('[KakaoSearch] API 오류: ${e.response?.statusCode}');
      debugPrint('[KakaoSearch] 응답 본문: ${e.response?.data}');
      debugPrint('[KakaoSearch] 메시지: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('[KakaoSearch] 일반 오류: $e');
      rethrow;
    }
  }

  /// 카페 카테고리로 키워드 검색을 수행한다.
  ///
  /// category_group_code=CE7을 사용하여 카페만 필터링하며,
  /// 현재 좌표 기준 거리순으로 정렬한다.
  Future<List<CafePlaceModel>> searchCafes(
    String query, {
    required double longitude,
    required double latitude,
    int radius = 5000,
  }) async {
    return searchPlaces(
      query,
      x: longitude,
      y: latitude,
      radius: radius,
      categoryGroupCode: 'CE7',
      sort: 'distance',
    );
  }

  /// 현재 위치 기반으로 주변 카페를 카테고리 검색한다 (키워드 없이).
  ///
  /// 카카오 카테고리 검색 API (`/v2/local/search/category.json`)를 사용하여
  /// CE7(카페) 카테고리의 장소를 거리순으로 반환한다.
  Future<List<CafePlaceModel>> searchNearbyCafes({
    required double longitude,
    required double latitude,
    int radius = 2000,
    int page = 1,
    int size = 15,
  }) async {
    try {
      debugPrint('[KakaoSearch] 주변 카페 검색: ($latitude, $longitude) 반경 ${radius}m');

      final response = await _dio.get(
        '/v2/local/search/category.json',
        queryParameters: {
          'category_group_code': 'CE7',
          'x': longitude.toString(),
          'y': latitude.toString(),
          'radius': radius,
          'sort': 'distance',
          'page': page,
          'size': size,
        },
      );

      final List<dynamic> documents = response.data['documents'] ?? [];
      debugPrint('[KakaoSearch] 주변 카페 결과: ${documents.length}개');

      return documents
          .map((doc) =>
              CafePlaceModel.fromKakaoJson(doc as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      debugPrint('[KakaoSearch] 주변 카페 검색 오류: ${e.response?.statusCode}');
      rethrow;
    } catch (e) {
      debugPrint('[KakaoSearch] 주변 카페 일반 오류: $e');
      rethrow;
    }
  }
}

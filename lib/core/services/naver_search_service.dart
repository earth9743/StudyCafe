import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:kagong_map/core/constants/app_constants.dart';
import 'package:kagong_map/features/cafe/domain/models/naver_place_model.dart';

class NaverSearchService {
  late final Dio _dio;

  NaverSearchService() {
    _dio = Dio(BaseOptions(
      baseUrl: 'https://openapi.naver.com',
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
      headers: {
        'X-Naver-Client-Id': AppConstants.naverClientId,
        'X-Naver-Client-Secret': AppConstants.naverClientSecret,
      },
    ));
  }

  /// 장소 검색 (네이버 지역 검색 API)
  Future<List<NaverPlaceModel>> searchPlaces(
    String query, {
    int display = 5,
  }) async {
    try {
      debugPrint('[NaverSearch] 검색 시작: $query');
      final response = await _dio.get(
        '/v1/search/local.json',
        queryParameters: {
          'query': query,
          'display': display,
        },
      );

      debugPrint('[NaverSearch] 응답 상태: ${response.statusCode}');

      final List<dynamic> items = response.data['items'] ?? [];
      return items
          .map((item) =>
              NaverPlaceModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      debugPrint('[NaverSearch] API 오류: ${e.response?.statusCode}');
      debugPrint('[NaverSearch] 응답 본문: ${e.response?.data}');
      debugPrint('[NaverSearch] 메시지: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('[NaverSearch] 일반 오류: $e');
      rethrow;
    }
  }
}

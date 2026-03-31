import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:kagong_map/core/theme/app_colors.dart';
import 'package:kagong_map/core/theme/app_text_styles.dart';
import 'package:kagong_map/features/cafe/domain/models/naver_place_model.dart';
import 'package:kagong_map/features/cafe/domain/models/review_model.dart';
import 'package:kagong_map/features/cafe/providers/review_provider.dart';
import 'package:kagong_map/features/cafe/presentation/widgets/review_write_sheet.dart';

/// 카페 상세 정보 Bottom Sheet
class CafeDetailBottomSheet extends ConsumerWidget {
  final NaverPlaceModel place;

  const CafeDetailBottomSheet({super.key, required this.place});

  String get _cafeId => generateCafeId(place.name, place.lat, place.lng);

  /// Bottom Sheet를 표시하는 정적 메서드
  static void show(BuildContext context, NaverPlaceModel place) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CafeDetailBottomSheet(place: place),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(cafeReviewStatsProvider(_cafeId));
    final reviewsAsync = ref.watch(cafeReviewsProvider(_cafeId));

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 드래그 핸들
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.secondaryDark,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 카페 이름 + 카테고리
                  _buildHeader(),
                  const SizedBox(height: 16),
                  // 주소
                  _buildInfoRow(Icons.place_outlined, _displayAddress),
                  if (place.phone.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _buildPhoneRow(),
                  ],
                  const SizedBox(height: 20),
                  // 혼잡도 / 콘센트 / 소음 (리뷰 평균)
                  _buildStatusSection(stats),
                  const SizedBox(height: 16),
                  // 별점 요약 + 리뷰 작성 버튼
                  _buildRatingSummary(context, stats),
                  const SizedBox(height: 16),
                  // 리뷰 목록
                  _buildReviewList(reviewsAsync),
                  const SizedBox(height: 20),
                  // 길찾기 버튼
                  _buildDirectionsButton(context),
                  SizedBox(
                      height: MediaQuery.of(context).padding.bottom + 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String get _displayAddress =>
      place.roadAddress.isNotEmpty ? place.roadAddress : place.address;

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.local_cafe,
            color: AppColors.primary,
            size: 28,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(place.name, style: AppTextStyles.h4),
              if (place.category.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  place.category,
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: AppTextStyles.bodyMedium),
        ),
      ],
    );
  }

  Widget _buildPhoneRow() {
    return GestureDetector(
      onTap: () => _makePhoneCall(place.phone),
      child: Row(
        children: [
          const Icon(Icons.phone_outlined,
              size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            place.phone,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.primary,
              decoration: TextDecoration.underline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSection(CafeReviewStats stats) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildStatusChip(
            icon: Icons.people_outline,
            label: '혼잡도',
            value: stats.crowdLabel,
            color: _crowdColor(stats),
          ),
          _buildDividerVertical(),
          _buildStatusChip(
            icon: Icons.power_outlined,
            label: '콘센트',
            value: stats.outletLabel,
            color: _outletColor(stats),
          ),
          _buildDividerVertical(),
          _buildStatusChip(
            icon: Icons.volume_up_outlined,
            label: '소음',
            value: stats.noiseLabel,
            color: _noiseColor(stats),
          ),
        ],
      ),
    );
  }

  Color _crowdColor(CafeReviewStats stats) {
    if (stats.reviewCount == 0) return AppColors.crowdUnknown;
    if (stats.averageCrowd <= 1.5) return AppColors.crowdLow;
    if (stats.averageCrowd <= 2.5) return AppColors.crowdModerate;
    return AppColors.crowdHigh;
  }

  Color _outletColor(CafeReviewStats stats) {
    if (stats.reviewCount == 0) return AppColors.crowdUnknown;
    if (stats.averageOutlet <= 1.5) return AppColors.outletAvailable;
    if (stats.averageOutlet <= 2.5) return AppColors.outletLimited;
    return AppColors.outletUnavailable;
  }

  Color _noiseColor(CafeReviewStats stats) {
    if (stats.reviewCount == 0) return AppColors.crowdUnknown;
    if (stats.averageNoise <= 1.5) return AppColors.noiseQuiet;
    if (stats.averageNoise <= 2.5) return AppColors.noiseModerate;
    return AppColors.noiseLoud;
  }

  Widget _buildStatusChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(height: 6),
          Text(label, style: AppTextStyles.caption),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTextStyles.labelSmall.copyWith(color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildDividerVertical() {
    return Container(
      width: 1,
      height: 40,
      color: AppColors.divider,
    );
  }

  Widget _buildRatingSummary(BuildContext context, CafeReviewStats stats) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          if (stats.reviewCount > 0) ...[
            Icon(Icons.star, size: 20, color: const Color(0xFFFFB800)),
            const SizedBox(width: 4),
            Text(
              stats.averageRating.toStringAsFixed(1),
              style: AppTextStyles.labelMedium.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '(${stats.reviewCount})',
              style: AppTextStyles.bodySmall,
            ),
          ] else ...[
            const Icon(Icons.star_outline,
                size: 20, color: AppColors.crowdUnknown),
            const SizedBox(width: 8),
            Text(
              '아직 리뷰가 없습니다',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary),
            ),
          ],
          const Spacer(),
          SizedBox(
            height: 34,
            child: ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final result = await ReviewWriteSheet.show(
                    context, place.name, _cafeId);
                if (result == true && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('리뷰가 등록되었습니다')),
                  );
                  // 다시 bottom sheet 열기
                  show(context, place);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                elevation: 0,
              ),
              child: Text(
                '리뷰 쓰기',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textOnPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewList(AsyncValue<List<ReviewModel>> reviewsAsync) {
    return reviewsAsync.when(
      data: (reviews) {
        if (reviews.isEmpty) return const SizedBox.shrink();
        // 최근 3개만 표시
        final displayReviews = reviews.take(3).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('최근 리뷰', style: AppTextStyles.labelMedium),
            const SizedBox(height: 10),
            ...displayReviews.map((review) => _buildReviewItem(review)),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildReviewItem(ReviewModel review) {
    final dateStr = DateFormat('yyyy.MM.dd').format(review.createdAt);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // 별점
              ...List.generate(5, (i) => Icon(
                    i < review.rating ? Icons.star : Icons.star_border,
                    size: 14,
                    color: i < review.rating
                        ? const Color(0xFFFFB800)
                        : AppColors.secondaryDark,
                  )),
              const SizedBox(width: 8),
              Text(review.userName, style: AppTextStyles.caption),
              const Spacer(),
              Text(dateStr, style: AppTextStyles.caption),
            ],
          ),
          const SizedBox(height: 6),
          // 태그
          Row(
            children: [
              _buildReviewTag(review.crowdLevel.label),
              const SizedBox(width: 6),
              _buildReviewTag(review.outletLevel.label),
              const SizedBox(width: 6),
              _buildReviewTag(review.noiseLevel.label),
            ],
          ),
          if (review.content.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(review.content, style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textPrimary,
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildReviewTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: AppColors.primary,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildDirectionsButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: () => _openNaverMapDirections(),
        icon: const Icon(Icons.directions, color: AppColors.textOnPrimary),
        label: const Text('길찾기', style: AppTextStyles.button),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final uri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openNaverMapDirections() async {
    final naverMapUri = Uri.parse(
      'nmap://route/public?dlat=${place.lat}&dlng=${place.lng}&dname=${Uri.encodeComponent(place.name)}&appname=com.kagong.map',
    );
    final webUri = Uri.parse(
      'https://map.naver.com/v5/directions/-/-/-/transit?c=${place.lng},${place.lat},15,0,0,0,dh',
    );

    if (await canLaunchUrl(naverMapUri)) {
      await launchUrl(naverMapUri);
    } else {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    }
  }
}

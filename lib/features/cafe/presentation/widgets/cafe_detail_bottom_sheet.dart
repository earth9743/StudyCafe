import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:kagong_map/core/theme/app_colors.dart';
import 'package:kagong_map/core/theme/app_text_styles.dart';
import 'package:kagong_map/features/auth/providers/auth_provider.dart';
import 'package:kagong_map/features/cafe/domain/models/cafe_place_model.dart';
import 'package:kagong_map/features/cafe/domain/models/review_model.dart';
import 'package:kagong_map/features/cafe/providers/review_provider.dart';
import 'package:kagong_map/features/cafe/presentation/widgets/review_write_sheet.dart';

/// 카페 상세 정보 Bottom Sheet
/// - compact: 마커 탭 → 카페 이름 + 주소 + 전화 + 상태 (콘텐츠 크기에 딱 맞게)
/// - full: 검색 선택 or 컴팩트에서 "자세히 보기" → 리뷰 포함 전체
class CafeDetailBottomSheet extends ConsumerWidget {
  final CafePlaceModel place;
  final bool compact;

  const CafeDetailBottomSheet({
    super.key,
    required this.place,
    this.compact = false,
  });

  String get _cafeId => generateCafeId(place.name, place.lat, place.lng);

  /// 검색에서 선택 시: 전체 (리뷰 포함)
  static void show(BuildContext context, CafePlaceModel place) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CafeDetailBottomSheet(place: place),
    );
  }

  /// 마커 탭 시: 컴팩트 (콘텐츠에 딱 맞게)
  static void showCompact(BuildContext context, CafePlaceModel place) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CafeDetailBottomSheet(place: place, compact: true),
    );
  }

  String get _displayAddress =>
      place.roadAddress.isNotEmpty ? place.roadAddress : place.address;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(cafeReviewStatsProvider(_cafeId));
    final reviewsAsync = ref.watch(cafeReviewsProvider(_cafeId));
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      // 전체 모드일 때만 최대 높이 제한 (스크롤 가능)
      constraints: compact
          ? null
          : BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: compact
          ? _buildCompactContent(context, ref, stats, bottomPadding)
          : _buildFullContent(
              context, ref, stats, reviewsAsync, bottomPadding),
    );
  }

  /// 컴팩트 모드: 콘텐츠 크기에 딱 맞게 (Wrap 방식)
  Widget _buildCompactContent(
    BuildContext context,
    WidgetRef ref,
    CafeReviewStats stats,
    double bottomPadding,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildDragHandle(context),
        Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, bottomPadding + 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              const SizedBox(height: 14),
              _buildInfoRow(Icons.place_outlined, _displayAddress),
              if (place.phone.isNotEmpty) ...[
                const SizedBox(height: 10),
                _buildPhoneRow(),
              ],
              const SizedBox(height: 16),
              _buildStatusSection(stats),
              const SizedBox(height: 12),
              _buildCompactRatingRow(context, ref, stats),
              const SizedBox(height: 12),
              // 자세히 보기 버튼
              SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    show(context, place);
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    '자세히 보기',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 전체 모드: 스크롤 가능, 리뷰 포함
  Widget _buildFullContent(
    BuildContext context,
    WidgetRef ref,
    CafeReviewStats stats,
    AsyncValue<List<ReviewModel>> reviewsAsync,
    double bottomPadding,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildDragHandle(context),
        Flexible(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20, 0, 20, bottomPadding + 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 14),
                _buildInfoRow(Icons.place_outlined, _displayAddress),
                if (place.phone.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _buildPhoneRow(),
                ],
                const SizedBox(height: 16),
                _buildStatusSection(stats),
                const SizedBox(height: 16),
                _buildRatingSummary(context, ref, stats),
                const SizedBox(height: 16),
                _buildReviewList(context, ref, reviewsAsync),
                const SizedBox(height: 16),
                _buildWriteReviewCTA(context, ref),
                const SizedBox(height: 8),
                _buildDirectionsLink(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────── 공통 위젯 ───────────────────────────

  Widget _buildDragHandle(BuildContext context) {
    return Align(
      alignment: Alignment.topRight,
      child: Padding(
        padding: const EdgeInsets.only(top: 12, right: 12),
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: AppColors.secondary,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.close,
              size: 18,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  /// 컴팩트 모드: 평점 + 리뷰 보기/쓰기 버튼
  Widget _buildCompactRatingRow(
      BuildContext context, WidgetRef ref, CafeReviewStats stats) {
    final isLoggedIn = ref.watch(authStateProvider).value != null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          if (stats.reviewCount > 0) ...[
            const Icon(Icons.star, size: 18, color: Color(0xFFFFB800)),
            const SizedBox(width: 4),
            Text(
              stats.averageRating.toStringAsFixed(1),
              style: AppTextStyles.labelMedium.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 3),
            Text('(${stats.reviewCount})',
                style: AppTextStyles.caption),
          ] else ...[
            const Icon(Icons.star_outline,
                size: 18, color: AppColors.crowdUnknown),
            const SizedBox(width: 6),
            Text(
              '리뷰 없음',
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textSecondary),
            ),
          ],
          const Spacer(),
          if (stats.reviewCount > 0) ...[
            SizedBox(
              height: 28,
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  show(context, place);
                },
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  textStyle: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
                child: const Text('리뷰 보기'),
              ),
            ),
            const SizedBox(width: 4),
          ],
          SizedBox(
            height: 28,
            child: OutlinedButton.icon(
              onPressed: () async {
                if (!isLoggedIn) {
                  _showLoginRequiredDialog(context);
                  return;
                }
                final result =
                    await ReviewWriteSheet.show(context, place.name, _cafeId);
                if (result == true && context.mounted) {
                  Navigator.of(context).pop();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('리뷰가 등록되었습니다')),
                    );
                    showCompact(context, place);
                  }
                }
              },
              icon: const Icon(Icons.edit_outlined, size: 12),
              label: const Text('리뷰 쓰기'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary, width: 0.8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                textStyle: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

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
          child: Text(place.name, style: AppTextStyles.h4),
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
    return Container(width: 1, height: 40, color: AppColors.divider);
  }

  // ─────────────────── 전체 모드 전용 ───────────────────

  void _showLoginRequiredDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          '로그인이 필요합니다',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: const Text(
          '리뷰를 작성하려면 로그인이 필요합니다.\n로그인 화면으로 이동하시겠습니까?',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text(
              '취소',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.push('/login');
            },
            child: const Text(
              '로그인',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingSummary(
      BuildContext context, WidgetRef ref, CafeReviewStats stats) {
    final isLoggedIn = ref.watch(authStateProvider).value != null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          if (stats.reviewCount > 0) ...[
            const Icon(Icons.star, size: 20, color: Color(0xFFFFB800)),
            const SizedBox(width: 4),
            Text(
              stats.averageRating.toStringAsFixed(1),
              style: AppTextStyles.labelMedium.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 4),
            Text('(${stats.reviewCount}개 리뷰)', style: AppTextStyles.bodySmall),
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
            height: 30,
            child: OutlinedButton.icon(
              onPressed: () async {
                if (!isLoggedIn) {
                  _showLoginRequiredDialog(context);
                  return;
                }
                final result =
                    await ReviewWriteSheet.show(context, place.name, _cafeId);
                if (result == true && context.mounted) {
                  Navigator.of(context).pop();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('리뷰가 등록되었습니다')),
                    );
                    show(context, place);
                  }
                }
              },
              icon: const Icon(Icons.edit_outlined, size: 13),
              label: const Text('리뷰 쓰기'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary, width: 0.8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                textStyle: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewList(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<ReviewModel>> reviewsAsync,
  ) {
    return reviewsAsync.when(
      data: (reviews) {
        if (reviews.isEmpty) return const SizedBox.shrink();
        return _ReviewListContent(
          reviews: reviews,
          onReviewTap: (review) => _showReviewDetail(context, review),
          buildReviewItem: (review) => _buildReviewItem(review, context),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
        ),
      ),
      error: (e, s) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            Text(
              '리뷰를 불러오지 못했습니다',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () {
                // ignore: unused_result
                ref.refresh(cafeReviewsProvider(_cafeId));
              },
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('다시 시도'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                textStyle: AppTextStyles.labelSmall,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewItem(ReviewModel review, BuildContext context) {
    final dateStr = DateFormat('yyyy.MM.dd').format(review.createdAt);
    return GestureDetector(
      onTap: () => _showReviewDetail(context, review),
      child: Container(
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
                ...List.generate(
                    5,
                    (i) => Icon(
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
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                _buildReviewTag('혼잡도', review.crowdLevel.label),
                _buildReviewTag('콘센트', review.outletLevel.label),
                _buildReviewTag('소음', review.noiseLevel.label),
              ],
            ),
            if (review.content.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                review.content,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (review.photoUrls.isNotEmpty) ...[
              const SizedBox(height: 8),
              SizedBox(
                height: 60,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: review.photoUrls.length,
                  separatorBuilder: (c, i) => const SizedBox(width: 6),
                  itemBuilder: (_, index) => ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(
                      review.photoUrls[index],
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Container(
                        width: 60,
                        height: 60,
                        color: AppColors.secondary,
                        child: const Icon(
                          Icons.broken_image_outlined,
                          color: AppColors.textHint,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
            // 상세보기 힌트
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '자세히 보기',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 리뷰 상세 보기 바텀시트
  void _showReviewDetail(BuildContext context, ReviewModel review) {
    final dateStr = DateFormat('yyyy.MM.dd HH:mm').format(review.createdAt);
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // X 버튼
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 12, right: 12),
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: AppColors.secondary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20, 0, 20, bottomPadding + 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 작성자 + 날짜
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.person,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              review.userName,
                              style: AppTextStyles.labelMedium.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(dateStr, style: AppTextStyles.caption),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 별점
                    Row(
                      children: [
                        ...List.generate(
                          5,
                          (i) => Icon(
                            i < review.rating ? Icons.star : Icons.star_border,
                            size: 24,
                            color: i < review.rating
                                ? const Color(0xFFFFB800)
                                : AppColors.secondaryDark,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${review.rating}.0',
                          style: AppTextStyles.labelMedium.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 상세 태그 (혼잡도, 콘센트, 소음)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          _buildDetailRow(
                            Icons.people_outline,
                            '혼잡도',
                            review.crowdLevel.label,
                          ),
                          const Divider(height: 16, color: AppColors.divider),
                          _buildDetailRow(
                            Icons.power_outlined,
                            '콘센트',
                            review.outletLevel.label,
                          ),
                          const Divider(height: 16, color: AppColors.divider),
                          _buildDetailRow(
                            Icons.volume_up_outlined,
                            '소음',
                            review.noiseLevel.label,
                          ),
                        ],
                      ),
                    ),

                    // 리뷰 내용
                    if (review.content.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        review.content,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textPrimary,
                          height: 1.5,
                        ),
                      ),
                    ],

                    // 사진
                    if (review.photoUrls.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                        ),
                        itemCount: review.photoUrls.length,
                        itemBuilder: (_, index) => GestureDetector(
                          onTap: () => _showFullScreenPhoto(
                            context,
                            review.photoUrls,
                            index,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              review.photoUrls[index],
                              fit: BoxFit.cover,
                              errorBuilder: (c, e, s) => Container(
                                color: AppColors.secondary,
                                child: const Icon(
                                  Icons.broken_image_outlined,
                                  color: AppColors.textHint,
                                  size: 24,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 10),
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  void _showFullScreenPhoto(
    BuildContext context,
    List<String> photoUrls,
    int initialIndex,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _FullScreenPhotoViewer(
          photoUrls: photoUrls,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  Widget _buildReviewTag(String category, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$category: $value',
        style: AppTextStyles.caption.copyWith(
          color: AppColors.primary,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildWriteReviewCTA(BuildContext context, WidgetRef ref) {
    final isLoggedIn = ref.watch(authStateProvider).value != null;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: () async {
          if (!isLoggedIn) {
            _showLoginRequiredDialog(context);
            return;
          }
          final result =
              await ReviewWriteSheet.show(context, place.name, _cafeId);
          if (result == true && context.mounted) {
            Navigator.of(context).pop();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('리뷰가 등록되었습니다')),
              );
              show(context, place);
            }
          }
        },
        icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.primary),
        label: Text(
          '리뷰 쓰기',
          style: AppTextStyles.button.copyWith(
            color: AppColors.primary,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.primary, width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Widget _buildDirectionsLink() {
    return Center(
      child: TextButton.icon(
        onPressed: () => _openInNaverMap(),
        icon: const Icon(Icons.open_in_new, size: 14, color: AppColors.textSecondary),
        label: Text(
          '네이버 지도에서 보기',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
            decoration: TextDecoration.underline,
          ),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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

  Future<void> _openInNaverMap() async {
    final naverAppUri = Uri.parse(
      'nmap://place?lat=${place.lat}&lng=${place.lng}'
      '&name=${Uri.encodeComponent(place.name)}'
      '&appname=com.yjh.kagong.kagongMap',
    );
    final webUri = Uri.parse(
      'https://map.naver.com/v5/search/${Uri.encodeComponent(place.name)}',
    );

    if (await canLaunchUrl(naverAppUri)) {
      await launchUrl(naverAppUri);
    } else {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    }
  }
}

/// 전체 화면 사진 뷰어
class _FullScreenPhotoViewer extends StatefulWidget {
  final List<String> photoUrls;
  final int initialIndex;

  const _FullScreenPhotoViewer({
    required this.photoUrls,
    required this.initialIndex,
  });

  @override
  State<_FullScreenPhotoViewer> createState() => _FullScreenPhotoViewerState();
}

class _FullScreenPhotoViewerState extends State<_FullScreenPhotoViewer> {
  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: widget.photoUrls.length > 1
            ? Text(
                '${_currentIndex + 1} / ${widget.photoUrls.length}',
                style: const TextStyle(color: Colors.white, fontSize: 16),
              )
            : null,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.photoUrls.length,
        onPageChanged: (index) => setState(() => _currentIndex = index),
        itemBuilder: (_, index) => InteractiveViewer(
          minScale: 0.5,
          maxScale: 3.0,
          child: Center(
            child: Image.network(
              widget.photoUrls[index],
              fit: BoxFit.contain,
              errorBuilder: (c, e, s) => const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.broken_image_outlined,
                    color: Colors.white54,
                    size: 48,
                  ),
                  SizedBox(height: 12),
                  Text(
                    '이미지를 불러올 수 없습니다',
                    style: TextStyle(color: Colors.white54, fontSize: 14),
                  ),
                ],
              ),
              loadingBuilder: (_, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                    color: Colors.white54,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// 리뷰 목록: 처음 3개만 보여주고 "더 보기" 누르면 전체 표시
class _ReviewListContent extends StatefulWidget {
  final List<ReviewModel> reviews;
  final void Function(ReviewModel) onReviewTap;
  final Widget Function(ReviewModel) buildReviewItem;

  const _ReviewListContent({
    required this.reviews,
    required this.onReviewTap,
    required this.buildReviewItem,
  });

  @override
  State<_ReviewListContent> createState() => _ReviewListContentState();
}

class _ReviewListContentState extends State<_ReviewListContent> {
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final displayReviews = _showAll
        ? widget.reviews
        : widget.reviews.take(3).toList();
    final hasMore = !_showAll && widget.reviews.length > 3;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('최근 리뷰', style: AppTextStyles.labelMedium),
            const SizedBox(width: 6),
            Text(
              '${widget.reviews.length}개',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...displayReviews.map((review) => widget.buildReviewItem(review)),
        if (hasMore)
          Center(
            child: TextButton(
              onPressed: () => setState(() => _showAll = true),
              child: Text(
                '리뷰 ${widget.reviews.length - 3}개 더 보기',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
